require 'i18nliner/errors'
require 'i18nliner/call_helpers'
require 'i18nliner/extractors/sexp_helper'
require 'nokogiri'
require 'ruby_parser'
require 'ruby2ruby'

module I18nliner
  module PreProcessors
    class ErbPreProcessor

      class Context
        attr_reader :buffer, :parent

        def initialize(parent = nil)
          @parent = parent
          @buffer = ''
        end

        def <<(string)
          if string =~ ERB_T_BLOCK_EXPRESSION
            TBlock.new(self)
          else
            @buffer << string
            self
          end
        end

        def result
          @buffer
        end
      end

      class Helper
        include Extractors::SexpHelper

        DEFINITIONS = [
          {:method => :link_to, :pattern => /link_to/, :arg => 0}
        ]
        RUBY2RUBY = Ruby2Ruby.new
        PARSER = RubyParser.new

        def self.match_for(string)
          DEFINITIONS.each do |info|
            return Helper.new(info, string) if string =~ info[:pattern]
          end
          nil
        end

        attr_reader :placeholder, :wrapper
        attr_accessor :content

        def initialize(info, source)
          @arg = info[:arg]
          @method = info[:method]
          @source = source
        end

        SEXP_ARG_OFFSET = 3
        def wrappable?
          return @wrappable if !@wrappable.nil?
          begin
            sexps = PARSER.parse(@source)
            @wrappable = sexps.sexp_type == :call &&
                         sexps[1].nil? &&
                         sexps[2] == @method &&
                         sexps[@arg + SEXP_ARG_OFFSET]
            extract_content!(sexps) if @wrappable
            @wrappable
          end
        end

        def extract_content!(sexps)
          sexp = sexps[@arg + SEXP_ARG_OFFSET]
          if stringish?(sexp)
            @content = string_from(sexp)
          else
            @placeholder = RUBY2RUBY.process(sexp)
          end
          sexps[@arg + SEXP_ARG_OFFSET] = Sexp.new(:str, "\\1")
          @wrapper = RUBY2RUBY.process(sexps)
        end
      end

      class TBlock < Context
        include CallHelpers

        def <<(string)
          case string
          when ERB_BLOCK_EXPRESSION
            if string =~ ERB_T_BLOCK_EXPRESSION
              TBlock.new(self)
            else
              raise TBlockNestingError.new("can't nest block expressions inside a t block")
            end
          when ERB_STATEMENT
            if string =~ ERB_END_STATEMENT
              @parent << result
            else
              raise TBlockNestingError.new("can't nest statements inside a t block")
            end
          else
            # expressions and the like are handled a bit later
            # TODO: perhaps a tad more efficient to capture/transform them
            # here?
            @buffer << string
            self
          end
        end

        def result
          key, default, options, wrappers = normalize_call
          result = "<%= t :#{key}, #{default}"
          result << ", " << options if options
          result << ", " << wrappers if wrappers
          result << " %>"
        end

        # get a unique and reasonable looking key for a given erb
        # expression
        def infer_interpolation_key(string, others)
          key = string.downcase
          key.sub!(/\.html_safe\z/, '')
          key.gsub!(/[^a-z0-9]/, ' ')
          key.strip!
          key.gsub!(/ +/, '_')
          key.slice!(20)
          i = 0
          base_key = key
          while others.key?(key) && others[key] != string
            key = "#{base_key}_#{i}"
            i += 1
          end
          key
        end

        def extract_wrappers!(source, wrappers, placeholder_map)
          source = extract_html_wrappers!(source, wrappers, placeholder_map)
          source = extract_helper_wrappers!(source, wrappers, placeholder_map)
          source
        end

        def find_or_add_wrapper(wrapper, wrappers)
          unless pos = wrappers.index(wrapper)
            pos = wrappers.size
            wrappers << wrapper
          end
          pos
        end

        # incidentally this converts entities to their corresponding values
        def extract_html_wrappers!(source, wrappers, placeholder_map)
          default = ''
          nodes = Nokogiri::HTML.fragment(source).children
          nodes.each do |node|
            if node.is_a?(Nokogiri::XML::Text)
              default << node.content
            elsif text = extract_text(node)
              wrapper = node.to_s.sub(text, "\\\\1")
              wrapper = prepare_wrapper(wrapper, placeholder_map)
              pos = find_or_add_wrapper(wrapper, wrappers)
              default << wrap(text, pos + 1)
            else # no wrapped text (e.g. <input>)
              key = "__I18NLINER_#{placeholder_map.size}__"
              placeholder_map[key] = node.to_s.inspect << ".html_safe"
              default << key
            end
          end
          default
        end

        def extract_helper_wrappers!(source, wrappers, placeholder_map)
          source.gsub(TEMP_PLACEHOLDER) do |string|
            if (helper = Helper.match_for(placeholder_map[string])) && helper.wrappable?
              placeholder_map.delete(string)
              if helper.placeholder # e.g. link_to(name) -> *%{name}*
                helper.content = "__I18NLINER_#{placeholder_map.size}__"
                placeholder_map[helper.content] = helper.placeholder
              end
              pos = find_or_add_wrapper(helper.wrapper, wrappers)
              wrap(helper.content, pos + 1)
            else
              string
            end
          end
        end

        def prepare_wrapper(content, placeholder_map)
          content = content.inspect
          content.gsub!(TEMP_PLACEHOLDER) do |key|
            "\#{#{placeholder_map[key]}}"
          end
          content
        end

        def extract_temp_placeholders!
          extract_placeholders!(@buffer, ERB_EXPRESSION, false) do |str, map|
            ["__I18NLINER_#{map.size}__", str]
          end
        end

        def extract_placeholders!(buffer = @buffer, pattern = ERB_EXPRESSION, wrap_placeholder = true)
          map = {}
          buffer.gsub!(pattern) do |str|
            key, str = yield($~[:content], map)
            map[key] = str
            wrap_placeholder ? "%{#{key}}" : key
          end
          map
        end

        TEMP_PLACEHOLDER = /(?<content>__I18NLINER_\d+__)/
        def normalize_call
          wrappers = []

          temp_map = extract_temp_placeholders!
          default = extract_wrappers!(@buffer, wrappers, temp_map)
          options = extract_placeholders!(default, TEMP_PLACEHOLDER) do |str, map|
            [infer_interpolation_key(temp_map[str], map), temp_map[str]]
          end

          default.strip!
          default.gsub!(/\s+/, ' ')

          key = infer_key(default)
          default = default.inspect
          options = options_to_ruby(options)
          wrappers = wrappers_to_ruby(wrappers)
          [key, default, options, wrappers]
        end

        def options_to_ruby(options)
          return if options.size == 0
          options.map do |key, value|
            ":" << key << " => (" << value << ")"
          end.join(", ")
        end

        def wrappers_to_ruby(wrappers)
          return if wrappers.size == 0
          ":wrappers => [" << wrappers.join(", ") << "]"
        end

        def extract_text(root_node)
          text = nil
          nodes = root_node.children.to_a
          while node = nodes.shift
            if node.is_a?(Nokogiri::XML::Text) && !node.content.strip.empty?
              raise UnwrappableContentError.new "multiple text nodes in html markup" if text
              text = node.content
            else
              nodes.concat node.children
            end
          end
          text
        end

        def wrap(text, index)
          delimiter = "*" * index
          "" << delimiter << text << delimiter
        end

        def infer_wrappers(source)
          wrappers = []
          [source, wrappers]
        end
      end

      # need to evaluate all expressions and statements, so we can
      # correctly match the start/end of the `t` block expression
      # (including nested ones)
      ERB_EXPRESSION = /<%=\s*(?<content>.*?)\s*%>/
      ERB_BLOCK_EXPRESSION = /
        \A
        <%=
        .*?
        (\sdo|\{)
        \s*
        %>
        \z
      /x
      ERB_T_BLOCK_EXPRESSION = /
        \A
        <%=
        \s*
        t
        \s*?
        (\(\)\s*)?
        (\sdo|\{)
        \s*
        %>
        \z
      /x
      ERB_STATEMENT = /\A<%[^=]/
      ERB_END_STATEMENT = /
        \A
        <%
        \s*
        (end|\})
        (\W|%>\z)
      /x
      ERB_TOKENIZER = /(<%.*?%>)/

      def self.process(source)
        new(source).result
      end

      def initialize(source)
        @source = source
      end

      def result
        # the basic idea:
        # 1. whenever we find a t block expr, go till we find the end
        # 2. if we find another t block expr before the end, goto step 1
        # 3. capture any inline expressions along the way
        # 4. if we find *any* other statement or block expr, abort,
        #    since it's a no-go
        # TODO get line numbers for errors
        ctx = @source.split(ERB_TOKENIZER).inject(Context.new, :<<)
        raise MalformedErbError.new('possibly unterminated block expression') if ctx.parent
        ctx.result
      end
    end
  end
end

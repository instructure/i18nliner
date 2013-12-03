require 'i18nliner/errors'
require 'nokogiri'

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

      class TBlock < Context
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
          default, options, wrappers = normalize_call
          result = "<%= t "
          result << default
          result << ", " << options if options
          result << ", " << wrappers if wrappers
          result << " %>"
        end

        # get a unique and reasonable looking key for a given erb
        # expression
        def infer_key(string, others)
          key = string.downcase
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

        def extract_wrappers!(placeholder_map)
          default = ''
          wrappers = []
          nodes = Nokogiri::HTML.fragment(@buffer).children
          nodes.each do |node|
            if node.is_a?(Nokogiri::XML::Text)
              default << node.content
            else
              # TODO: handle standalone content (i.e. not wrappers, e.g.
              # <input>)
              text, wrapper = handle_node(node)
              wrappers << prepare_wrapper(wrapper, placeholder_map)
              default << wrap(text, wrappers.length)
            end
          end
          [default, wrappers]
        end

        def prepare_wrapper(content, placeholder_map)
          content = content.inspect
          content.gsub!(TEMP_PLACEHOLDER) do |key|
            '#{' + placeholder_map[key] + '}'
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
          default = ''
          options = {}
          wrappers = []
          if @buffer =~ /</
            temp_map = extract_temp_placeholders!
            default, wrappers = extract_wrappers!(temp_map)
            options = extract_placeholders!(default, TEMP_PLACEHOLDER) do |str, map|
              [temp_map[str], infer_key(temp_map[str], map)]
            end
          else
            options = extract_placeholders!{ |str, map| [infer_key(str, map), str] }
            default << @buffer
          end
          default = default.strip.inspect
          options = options_to_ruby(options)
          wrappers = wrappers_to_ruby(wrappers)
          [default, options, wrappers]
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

        def handle_node(root_node)
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
          [text, root_node.to_s.sub(text, "\\\\1")]
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

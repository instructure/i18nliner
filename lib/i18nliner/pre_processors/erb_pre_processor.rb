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
          #when ERB_EXPRESSION
            # TODO: capture/transform it into placeholder
          when ERB_STATEMENT
            if string =~ ERB_END_STATEMENT
              @parent << result
            else
              raise TBlockNestingError.new("can't nest statements inside a t block")
            end
          else
            @buffer << string
            self
          end
        end

        def result
          default, options = normalize_call
          result = "<%= t "
          result << default.strip.inspect
          result << ", " << options.inspect if options.size > 0
          result << " %>"
        end

        def normalize_call
          default = ''
          options = {}
          wrappers = []
          if @buffer =~ /</
            # TODO: expressions -> temp placeholders
            nodes = Nokogiri::HTML.fragment(@buffer).children
            nodes.each do |node|
              if node.is_a?(Nokogiri::XML::Text)
                default << node.content
              else
                # TODO: handle standalone content (i.e. not wrappers,
                # e.g. <input>)
                text, wrapper = handle_node(node)
                wrappers << wrapper
                default << wrap(text, wrappers.length)
              end
            end
            # TODO: temp placeholders -> placeholders (+ wrappers)
          else
            default << @buffer
            # TODO: expressions -> placeholders (+ wrappers)
          end
          options[:wrappers] = wrappers unless wrappers.empty?
          [default, options]
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
      ERB_EXPRESSION = /\A<%=/
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

require 'i18nliner/errors'
require 'nokogiri'

module I18nliner
  module PreProcessors
    class ErbPreProcessor

      class Block
        attr_reader :buffer
        def initialize(string = '', translate = false)
          @initial = string
          @translate = translate
          @buffer = ''
        end

        def translate?
          @translate
        end

        def close(terminator)
          if translate?
            inlinify
          else
            '' << @initial << @buffer << terminator
          end
        end

        def inlinify
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
          if @buffer =~ /<[^%]/
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

      # need to evaluate all block expressions, so we can correctly
      # match the start/end of the `t` block expression (including
      # nested ones)
      BLOCK_EXPR_START = /
        <%=
        \s*
        (?<expression>      (?: [^%] | %[^>] )+?)
        \s*
        (?<block_delimiter> do | \{ )
        \s*
        %>
        /x
      BLOCK_EXPR_END = /
        <%
        \s*
        (?<block_delimiter> end | \} )
        \s*
        %>
        /x
      REMOVE_CAPTURES = /\(\?<[^>]+>/
      BLOCK_EXPR = /
        (
          #{BLOCK_EXPR_START.to_s.gsub(REMOVE_CAPTURES, '(?:')} |
          #{BLOCK_EXPR_END.to_s.gsub(REMOVE_CAPTURES, '(?:')}
        )
      /x

      def self.process(source)
        new(source).result
      end

      def initialize(source)
        @source = source
      end

      def result
        # TODO get line numbers for errors
        @stack = [Block.new]
        @source.split(BLOCK_EXPR).each do |string|
          if string =~ BLOCK_EXPR_START
            translate = Regexp.last_match[:expression] == 't'
            push(string, translate) 
          elsif string =~ BLOCK_EXPR_END # TODO: we get false positives here, e.g. `end` of an `if`
            pop(string)
          else
            append(string)
          end
        end
        if @stack.size > 1
          raise MalformedErbError.new('possibly unterminated block expression')
        end
        @stack.first.buffer
      end

      def push(string, translate)
        if !translate && @stack.last.translate?
          raise BlockExprNestingError.new("can't nest block expressions inside a t block")
        end
        block = Block.new(string, translate)
        @stack.push block
      end

      def pop(string)
        final = @stack.pop.close(string)
        @stack.last.buffer << final
      end

      def append(string)
        @stack.last.buffer << string
      end
    end
  end
end

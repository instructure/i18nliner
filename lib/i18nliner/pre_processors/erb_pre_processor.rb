module I18nliner
  module PreProcessors
    class ErbPreProcessor

      class Block
        attr_reader :buffer
        def initialize(string = '', translate = '')
          @initial = string
          @translate = translate
          @buffer = ''
        end

        def translate?
          @translate
        end

        def close(terminator)
          return inlinify if translate?
          '' << @initial << @buffer << terminator
        end

        def inlinify
          "<%= t #{@buffer.inspect} %>"
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
          elsif string =~ BLOCK_EXPR_END
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

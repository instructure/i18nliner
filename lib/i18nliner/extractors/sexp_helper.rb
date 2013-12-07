module I18nliner
  module Extractors
    module SexpHelper
      def string_concatenation?(exp)
        exp.sexp_type == :call &&
        exp[2] == :+ &&
        exp.last &&
        exp.last.sexp_type == :str
      end

      def string_from(exp)
        exp.shift
        lhs = exp.shift
        exp.shift
        rhs = exp.shift
        if lhs.sexp_type == :str
          lhs.last + rhs.last
        elsif string_concatenation?(lhs)
          string_from(lhs) + rhs.last
        else
          UnsupportedExpression
        end
      end

      class UnsupportedExpression; end
    end
  end
end

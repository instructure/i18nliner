# frozen_string_literal: true

module I18nliner
  module Extractors
    module SexpHelper
      def stringish?(exp)
        exp && (exp.sexp_type == :str || string_concatenation?(exp))
      end

      def string_concatenation?(exp)
        exp.sexp_type == :call &&
          exp[2] == :+ &&
          exp.last &&
          exp.last.sexp_type == :str
      end

      def raw(exp)
        exp.shift
        exp.shift
      end

      def string_from(exp)
        return raw(exp) if exp.sexp_type == :str

        exp.shift
        lhs = exp.shift
        exp.shift
        rhs = exp.shift
        if lhs.sexp_type == :str
          lhs.last + rhs.last
        elsif stringish?(lhs)
          string_from(lhs) + rhs.last
        else
          process(lhs)
          UnsupportedExpression
        end
      end

      UnsupportedExpression = Object.new.freeze
    end
  end
end

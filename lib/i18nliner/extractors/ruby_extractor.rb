require 'sexp_processor'
require 'i18nliner/errors'
require 'i18nliner/extractors/translate_call'
require 'i18nliner/extractors/sexp_helper'

module I18nliner
  module Extractors
    class RubyExtractor < ::SexpProcessor
      include SexpHelper

      TRANSLATE_CALLS = [:t, :translate]
      attr_reader :current_line

      def initialize(sexps, scope)
        @sexps = sexps
        @scope = scope
        super()
      end

      def each_translation(&block)
        @block = block
        process(@sexps)
      end

      def process_call(exp)
        exp.shift
        receiver = process(exp.shift)
        receiver = receiver.last if receiver
        method = exp.shift

        if extractable_call?(receiver, method)
          @current_line = exp.line

          # convert s-exps into literals where possible 
          args = process_arguments(exp)

          process_translate_call(receiver, method, args)
        else
          # even if this isn't a translate call, its arguments might contain
          # one
          process exp.shift until exp.empty?
        end

        s
      end

     protected

      def extractable_call?(receiver, method)
        TRANSLATE_CALLS.include?(method) && (receiver.nil? || receiver == :I18n)
      end

      def process_translate_call(receiver, method, args)
        call = TranslateCall.new(@scope, @current_line, receiver, method, args)
        call.translations.each &@block
      end

     private

      def process_arguments(args)
        values = []
        while arg = args.shift
          values << evaluate_expression(arg)
        end
        values
      end

      def evaluate_expression(exp)
        if exp.sexp_type == :lit || exp.sexp_type == :str
          exp.shift
          return exp.shift
        end
        return string_from(exp) if string_concatenation?(exp)
        return hash_from(exp) if exp.sexp_type == :hash
        process(exp)
        UnsupportedExpression
      end

      def hash_from(exp)
        exp.shift
        values = exp.map{ |e| evaluate_expression(e) }
        Hash[*values]
      end
    end
  end
end

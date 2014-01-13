require 'i18nliner/processors/abstract_processor'
require 'i18nliner/extractors/ruby_extractor'
require 'i18nliner/scope'

module I18nliner
  module Processors
    class RubyProcessor < AbstractProcessor
      default_pattern '*.rb'

      def check_contents(source, scope = Scope.new)
        sexps = RubyParser.new.parse(pre_process(source))
        extractor = Extractors::RubyExtractor.new(sexps, scope)
        extractor.each_translation do |key, value|
          @translation_count += 1
          @translations.line = extractor.current_line
          @translations[key] = value
        end
      end

      def source_for(file)
        File.read(file)
      end

      def scope_for(path)
        Scope.root
      end

      def pre_process(source)
        source
      end
    end
  end
end

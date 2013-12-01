module I18nliner
  module Processors
    class RubyProcessor < AbstractProcessor
      def check_file(file)
        sexps = RubyParser.new.parse(source_for(file))
        extractor = Extractors::RubyExtractor.new(sexps, scope_for(file))
        extractor.each_translation do |key, value|
          @translations.line = extractor.line
          @translations[key] = value
        end
      end

      def source_for(file)
        File.read(file)
      end

      def scope_for(path)
        Scope.new
      end
    end
  end
end

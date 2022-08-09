require 'i18nliner/processors/abstract_processor'
require 'i18nliner/extractors/ruby_extractor'
require 'i18nliner/scope'
require 'i18nliner/controller_scope'

module I18nliner
  module Processors
    class RubyProcessor < AbstractProcessor
      default_pattern '*.rb'

      def check_contents(source, scope = Scope.new)
        return if source !~ Extractors::RubyExtractor.pattern
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

      if defined?(::Rails)
        CONTROLLER_PATH = %r{\A(.*/)?app/controllers/(.*)_controller\.rb\z}
        def scope_for(path)
          scope = path.dup
          if scope.sub!(CONTROLLER_PATH, '\2')
            scope = scope.gsub(/\/_?/, '.')
            ControllerScope.new(scope, :allow_relative => true, :context => self)
          else
            Scope.root
          end
        end
      else
        def scope_for(path)
          Scope.root
        end
      end

      def pre_process(source)
        source
      end
    end
  end
end

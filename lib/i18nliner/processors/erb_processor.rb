require 'erubis'
require 'i18nliner/processors/ruby_processor'
require 'i18nliner/pre_processors/erb_pre_processor'

module I18nliner
  module Processors
    class ErbProcessor < RubyProcessor
      def pre_process(source)
        source = PreProcessors::ErbPreProcessor.process(source)
        Erubis::Eruby.new(source).src
      end

      def scope_for(path)
        scope = path.gsub(/(\A|.*\/)app\/views\/|\.html\z|(\.html)?\.erb\z/, '')
        scope = scope.gsub(/\/_?/, '.')
        Scope.new(scope, :allow_relative => true)
      end
    end
  end
end

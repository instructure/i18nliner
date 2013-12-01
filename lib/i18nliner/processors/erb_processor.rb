module I18nliner
  module Processors
    class ErbProcessor < RubyProcessor
      def source_for(file)
        # TODO: pre-process for block fu
        Erubis::Eruby.new(super).src
      end

      def scope_for(path)
        scope = path.gsub(/(\A|.*\/)app\/views\/|\.html\z|(\.html)?\.erb\z/, '')
        scope = scope.gsub(/\/_?/, '.')
        Scope.new(scope, :allow_relative => true)
      end
    end
  end
end

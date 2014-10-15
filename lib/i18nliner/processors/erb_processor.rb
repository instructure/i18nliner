if defined?(::Rails)
  require 'i18nliner/erubis'
else
  require 'erubis'
end
require 'i18nliner/processors/ruby_processor'
require 'i18nliner/pre_processors/erb_pre_processor'

module I18nliner
  module Processors
    class ErbProcessor < RubyProcessor
      default_pattern '*.erb'

      if defined?(::Rails) # block expressions and all that jazz
        def pre_process(source)
          I18nliner::Erubis.new(source).src
        end
      else
        def pre_process(source)
          source = PreProcessors::ErbPreProcessor.process(source)
          Erubis::Eruby.new(source).src
        end
      end

      VIEW_PATH = %r{\A(.*/)?app/views/(.*?)\.(erb|html\.erb)\z}
      def scope_for(path)
        scope = path.dup
        if scope.sub!(VIEW_PATH, '\2')
          scope = scope.gsub(/\/_?/, '.')
          Scope.new(scope, :allow_relative => true, :remove_whitespace => true, :context => self)
        else
          Scope.root
        end
      end
    end
  end
end

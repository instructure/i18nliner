require 'i18nliner/scope'
require 'i18nliner/call_helpers'

module I18nliner
  module Extensions
    module Core
      include CallHelpers

      def translate(*args)
        key, default, options = *infer_arguments(Scope.root, args)
        options ||= {}
        super key, options.merge(:default => default)
      end
      alias :t :translate
    end
  end
end

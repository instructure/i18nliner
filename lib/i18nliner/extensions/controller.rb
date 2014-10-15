require 'i18nliner/base'
require 'i18nliner/call_helpers'
require 'i18nliner/extensions/inferpolation'

module I18nliner
  module Extensions
    module Controller
      include Inferpolation

      def i18n_scope; end

      def translate(*args)
        key, options = CallHelpers.infer_arguments(args)
        options = inferpolate(options) if I18nliner.infer_interpolation_values
        options[:i18n_scope] = i18n_scope
        super(key, options)
      end
      alias :t :translate
      alias :t! :translate
      alias :translate! :translate
    end
  end
end



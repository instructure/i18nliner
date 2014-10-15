require 'i18nliner/base'
require 'i18nliner/call_helpers'
require 'i18nliner/extensions/inferpolation'

module I18nliner
  module Extensions
    module Model
      include Inferpolation

      def i18n_scope; end

      def translate(*args)
        key, options = CallHelpers.infer_arguments(args)
        options = inferpolate(options) if I18nliner.infer_interpolation_values
        options[:i18n_scope] = i18n_scope
        I18n.translate(key, options)
      end
      alias :t :translate
      alias :t! :translate
      alias :translate! :translate

      def localize(*args)
        I18n.localize(*args)
      end
      alias :l :localize
    end
  end
end


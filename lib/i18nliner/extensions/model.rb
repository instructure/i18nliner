require 'i18nliner/base'
require 'i18nliner/call_helpers'
require 'i18nliner/extensions/inferpolation'

module I18nliner
  module Extensions
    module Model
      include Inferpolation

      PATH = "app/models"
      ALLOW_RELATIVE = false

      def translate(*args)
        key, options = CallHelpers.infer_arguments(args)
        options = inferpolate(options) if I18nliner.infer_interpolation_values
        I18n.t(key, options)
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


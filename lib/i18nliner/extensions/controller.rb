require 'i18nliner/base'
require 'i18nliner/call_helpers'
require 'i18nliner/extensions/inferpolation'

module I18nliner
  module Extensions
    module Controller
      include Inferpolation

      PATH = "app/controllers"
      ALLOW_RELATIVE = Rails.version >= '4'

      def translate(*args)
        key, options = CallHelpers.infer_arguments(args)
        options = inferpolate(options) if I18nliner.infer_interpolation_values
        super(key, options)
      end
      alias :t :translate
      alias :t! :translate
      alias :translate! :translate
    end
  end
end



require 'i18nliner/base'
require 'i18nliner/extensions/inferpolation'

module I18nliner
  module Extensions
    module View
      include Inferpolation

      PATH = "app/views"
      ALLOW_RELATIVE = true

      def translate(*args)
        key, options = CallHelper.infer_arguments(args)
        options = inferpolate(options) if I18nliner.infer_interpolation_values
        super(key, options)
      end
      alias :t :translate
    end
  end
end

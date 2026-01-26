# frozen_string_literal: true

require "i18nliner/base"
require "i18nliner/call_helpers"
require "i18nliner/extensions/inferpolation"

module I18nliner
  module Extensions
    module Model
      include Inferpolation

      def i18nliner_scope; end

      def translate(*args)
        key, options = CallHelpers.infer_arguments(args)
        options = inferpolate(options) if I18nliner.infer_interpolation_values
        options[:i18nliner_scope] = i18nliner_scope
        I18n.translate(key, **options)
      end
      alias_method :t, :translate
      alias_method :t!, :translate
      alias_method :translate!, :translate

      def localize(*)
        I18n.localize(*)
      end
      alias_method :l, :localize

      def self.included(klass)
        klass.extend(self)
      end
    end
  end
end

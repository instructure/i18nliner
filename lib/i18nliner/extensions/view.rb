require 'i18nliner/base'
require 'i18nliner/call_helpers'
require 'i18nliner/extensions/inferpolation'

module I18nliner
  module Extensions
    module View
      include Inferpolation

      PATH = "app/views"
      ALLOW_RELATIVE = true

      def translate(*args)
        # if a block gets through to here, it either means:
        # 1. the user did something weird (e.g. <%= t{ "haha" } %>)
        # 2. the erb pre processor missed it somehow (bug)
        raise ArgumentError.new("block syntax not supported") if block_given?
        raise ArgumentError.new("wrong number of arguments (0 for 1..3)") if args.empty?
        key, options = CallHelpers.infer_arguments(args)
        options = inferpolate(options) if I18nliner.infer_interpolation_values
        super(key, options)
      end
      alias :t :translate
    end
  end
end

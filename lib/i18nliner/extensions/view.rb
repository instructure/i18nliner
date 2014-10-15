require 'i18nliner/base'
require 'i18nliner/call_helpers'
require 'i18nliner/extensions/inferpolation'

module I18nliner
  module Extensions
    module View
      include Inferpolation

      def i18n_scope; end

      def translate(*args)
        # if a block gets through to here, it either means:
        # 1. the user did something weird (e.g. <%= t{ "haha" } %>)
        # 2. the erb pre processor missed it somehow (bug)
        raise InvalidBlockUsageError.new("block translate calls need to be output (i.e. `<%=`) and the block body must be of the form `%>your string<%`") if block_given?
        raise ArgumentError.new("wrong number of arguments (0 for 1..3)") if args.empty? || args.size > 3
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

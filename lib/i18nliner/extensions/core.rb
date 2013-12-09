require 'i18nliner/scope'
require 'i18nliner/call_helpers'
require 'active_support/core_ext/string/output_safety'

module I18nliner
  module Extensions
    module Core
      include CallHelpers

      def translate(*args)
        key, default, options = *infer_arguments(Scope.root, args)
        wrappers = options.delete(:wrappers)
        options ||= {}
        result = super(key, options.merge(:default => default))
        if wrappers
          result = apply_wrappers(result, wrappers)
        end
        result
      end
      alias :t :translate

     private

      def apply_wrappers(string, wrappers)
        string = string.html_safe? ? string.dup : ERB::Util.h(string)
        if wrappers.is_a?(Array)
          wrappers = Hash[wrappers.each_with_index.map{ |w, i| ['*' * (1 + i), w]}]
        end
        wrappers.sort_by{ |k, v| -k.length }.each do |k, v|
          pattern = pattern_for(k)
          string.gsub!(pattern, v)
        end
        string
      end

      def pattern_for(key)
        escaped_key = Regexp.escape(key)
        /#{escaped_key}(.*?)#{escaped_key}/
      end
    end
  end
end

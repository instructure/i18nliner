require 'i18nliner/scope'
require 'i18nliner/call_helpers'
require 'active_support/core_ext/string/output_safety'

module I18nliner
  module Extensions
    module Core
      def translate(*args)
        key, options = *CallHelpers.infer_arguments(args)

        scope = options.delete(:i18nliner_scope) || Scope.root
        inferred_key = options.delete(:i18nliner_inferred_key)
        key = CallHelpers.normalize_key(key, scope, inferred_key, options[:scope])

        if default = options[:default]
          options[:default] = CallHelpers.normalize_default(default, options)
        end

        wrappers = options.delete(:wrappers) || options.delete(:wrapper)
        result = super(key, **options)

        # Exit now unless we have a string or a thing that delegates to a string
        return result unless result.respond_to?(:gsub)

        was_html_safe = result.html_safe?
        # If you are actually using nonprintable characters in your source string, you should feel ashamed
        result = result.gsub("\\\\", "\uE124").gsub("\\*", "\uE123")
        result = result.html_safe if was_html_safe
        if wrappers
          result = apply_wrappers(result, wrappers)
        end
        was_html_safe = result.html_safe?
        result = result.gsub("\uE123", '*').gsub("\uE124", "\\")
        result = result.html_safe if was_html_safe

        result
      rescue ArgumentError
        raise
      end
      alias :t :translate
      alias :t! :translate
      alias :translate! :translate

      # can't super this one yet :-/
      def interpolate_hash_with_html_safety(string, values)
        if string.html_safe? || values.values.any?{ |v| v.is_a?(ActiveSupport::SafeBuffer) }
          string = ERB::Util.h(string) unless string.html_safe?
          values.each do |key, value|
            values[key] = ERB::Util.h(value) unless value.html_safe?
          end
          interpolate_hash_without_html_safety(string.to_str, values).html_safe
        else
          interpolate_hash_without_html_safety(string, values)
        end
      end

      def self.extended(base)
        base.instance_eval do
          alias :interpolate_hash_without_html_safety :interpolate_hash
          alias :interpolate_hash :interpolate_hash_with_html_safety
        end
      end

     private

      def apply_wrappers(string, wrappers)
        string = string.html_safe? ? string.dup : ERB::Util.h(string)
        unless wrappers.is_a?(Hash)
          wrappers = Array(wrappers)
          wrappers = Hash[wrappers.each_with_index.map{ |w, i| ['*' * (1 + i), w]}]
        end
        # If you are actually using nonprintable characters in your source string, you should feel ashamed
        string.gsub!("\\\\", 26.chr)
        string.gsub!("\\*", 27.chr)
        wrappers.sort_by{ |k, v| -k.length }.each do |k, v|
          pattern = pattern_for(k)
          string.gsub!(pattern, v)
        end
        string.gsub!(27.chr, '*')
        string.gsub!(26.chr, "\\")
        string.html_safe
      end

      def pattern_for(key)
        escaped_key = Regexp.escape(key)
        /#{escaped_key}(.*?)#{escaped_key}/
      end
    end
  end
end

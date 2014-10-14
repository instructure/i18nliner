require 'active_support/core_ext/string/inflections'
require 'i18nliner/base'
require 'i18nliner/call_helpers'
require 'i18nliner/errors'

module I18nliner
  module Extractors
    class TranslateCall
      include CallHelpers

      attr_reader :key, :default

      def initialize(scope, line, method, args, meta = {})
        @scope = scope
        @line = line
        @method = method
        @meta = meta

        normalize_arguments(args)

        validate
        normalize
      end

      def validate
        validate_key
        validate_default
        validate_options
      end

      def normalize
        @key = normalize_key(@key, @scope) unless @meta[:inferred_key]
        @default = normalize_default(@default, @options || {}, {:remove_whitespace => @scope.remove_whitespace?})
      end

      def translations
        return [] unless @default
        return [[@key, @default]] if @default.is_a?(String)
        @default.map { |key, value|
          ["#{@key}.#{key}", value]
        }
      end

      def validate_key
      end

      def validate_default
        return unless @default.is_a?(Hash)
        if (keys = @default.keys - ALLOWED_PLURALIZATION_KEYS).size > 0
          raise InvalidPluralizationKeyError.new(@line, keys)
        elsif REQUIRED_PLURALIZATION_KEYS & (keys = @default.keys) != REQUIRED_PLURALIZATION_KEYS
          raise MissingPluralizationKeyError.new(@line, keys)
        else
          @default.values.each do |value|
            raise InvalidPluralizationDefaultError.new(@line, value) unless value.is_a?(String)
          end
        end

        unless I18nliner.infer_interpolation_values
          if @default.is_a?(String)
            validate_interpolation_values(@key, @default)
          else
            @default.each_pair do |sub_key, default|
              validate_interpolation_values("#{@key}.#{sub_key}", default)
            end
          end
        end
      end

     private

      # Possible translate signatures:
      #
      # key [, options]
      # key, default_string [, options]
      # key, default_hash, options
      # default_string [, options]
      # default_hash, options
      def normalize_arguments(args)
        raise InvalidSignatureError.new(@line, args) if args.empty?

        @key, @options, *others = infer_arguments(args, @meta)

        raise InvalidSignatureError.new(@line, args) if !others.empty?
        raise InvalidSignatureError.new(@line, args) unless @key.is_a?(Symbol) || @key.is_a?(String)
        raise InvalidSignatureError.new(@line, args) unless @options.nil? || @options.is_a?(Hash)
        @default = @options.delete(:default) if @options
        raise InvalidSignatureError.new(@line, args) unless @default.nil? || @default.is_a?(String) || @default.is_a?(Hash)
      end

      def validate_interpolation_values(key, default)
        default.scan(/%\{([^\}]+)\}/) do |match|
          placeholder = match[0].to_sym
          next if @options.include?(placeholder)
          raise MissingInterpolationValueError.new(@line, placeholder)
        end
      end

      def validate_options
        if @default.is_a?(Hash)
          raise MissingCountValueError.new(@line) unless @options && @options.key?(:count)
        end
        return if @options.nil?
        @options.keys.each do |key|
          raise InvalidOptionKeyError.new(@line) unless key.is_a?(String) || key.is_a?(Symbol)
        end
      end
    end
  end
end

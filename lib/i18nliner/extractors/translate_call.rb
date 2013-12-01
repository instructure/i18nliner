require 'active_support/core_ext/string/inflections'
require 'i18nliner/call_helpers'
require 'i18nliner/errors'

module I18nliner
  module Extractors
    class TranslateCall
      include CallHelpers

      def initialize(scope, line, receiver, method, args)
        @scope = scope
        @line = line
        @receiver = receiver
        @method = method

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
        @key = normalize_key(@key, @scope, @receiver)
        @default = normalize_default(@default, @options || {})
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

        has_key = key_provided?(@scope, @receiver, *args)
        args.unshift infer_key(args[0]) if !has_key && args[0].is_a?(String) || args[0].is_a?(Hash)

        # [key, options] -> [key, nil, options]
        args.insert(1, nil) if has_key && args[1].is_a?(Hash) && args[2].nil?

        @key, @default, @options, *others = args

        raise InvalidSignatureError.new(@line, args) if !others.empty?
        raise InvalidSignatureError.new(@line, args) unless @key.is_a?(Symbol) || @key.is_a?(String)
        raise InvalidSignatureError.new(@line, args) unless @default.nil? || @default.is_a?(String) || @default.is_a?(Hash)
        raise InvalidSignatureError.new(@line, args) unless @options.nil? || @options.is_a?(Hash)
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

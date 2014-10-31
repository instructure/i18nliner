require 'zlib'
require 'i18n'
require 'i18nliner/base'

module I18nliner
  module CallHelpers
    ALLOWED_PLURALIZATION_KEYS = [:zero, :one, :few, :many, :other]
    REQUIRED_PLURALIZATION_KEYS = [:one, :other]

    def normalize_key(key, scope, inferred, i18n_scope)
      scope.normalize_key(key.to_s, inferred, i18n_scope)
    end

    def normalize_default(default, translate_options = {}, options = {})
      default = infer_pluralization_hash(default, translate_options)
      normalize_whitespace!(default, options)
      default
    end

    def normalize_whitespace!(default, options)
      if default.is_a?(Hash)
        default.each { |key, value| normalize_whitespace!(value, options) }
        return
      end

      return unless default.is_a?(String)

      if options[:remove_whitespace]
        default.gsub!(/\s+/, ' ')
        default.strip!
      else
        default.sub!(/\s*\n\z/, '')
        default.lstrip!
      end
    end

    def infer_pluralization_hash(default, translate_options)
      return default unless default.is_a?(String) &&
                            default =~ /\A[\w\-]+\z/ &&
                            translate_options.include?(:count)
      {:one => "1 #{default}", :other => "%{count} #{default.pluralize}"}
    end

    def infer_key(default, translate_options = {})
      return unless default && (default.is_a?(String) || default.is_a?(Hash))
      default = default[:other].to_s if default.is_a?(Hash)
      keyify(normalize_default(default, translate_options, :remove_whitespace => true))
    end

    def keyify_underscored(string)
      key = I18n.transliterate(string, :locale => I18n.default_locale).to_s
      key.downcase!
      key.gsub!(/[^a-z0-9_]+/, '_')
      key.gsub!(/\A_|_\z/, '')
      key[0...I18nliner.underscored_key_length]
    end

    def keyify_underscored_crc32(string)
      checksum = Zlib.crc32("#{string.size.to_s}:#{string}").to_s(16)
      "#{keyify_underscored(string)}_#{checksum}"
    end

    def keyify(string)
      case I18nliner.inferred_key_format
      when :underscored       then keyify_underscored(string)
      when :underscored_crc32 then keyify_underscored_crc32(string)
      else                         string
      end
    end

    # Possible translate signatures:
    #
    # key [, options]
    # key, default_string [, options]
    # key, default_hash, options
    # default_string [, options]
    # default_hash, options
    def key_provided?(key_or_default = nil, default_or_options = nil, maybe_options = nil, *others)
      return false if key_or_default.is_a?(Hash)
      return true if key_or_default.is_a?(Symbol)
      raise ArgumentError.new("invalid key_or_default argument. expected String, Symbol or Hash, got #{key_or_default.class}") unless key_or_default.is_a?(String)
      return true if default_or_options.is_a?(String)
      return true if maybe_options
      return true if key_or_default =~ /\A\.?(\w+\.)+\w+\z/
      false
    end

    def pluralization_hash?(hash)
      hash.is_a?(Hash) &&
      hash.size > 0 &&
      (hash.keys - ALLOWED_PLURALIZATION_KEYS).size == 0
    end

    def infer_arguments(args)
      raise ArgumentError.new("wrong number of arguments (#{args.size} for 1..3)") if args.empty? || args.size > 3
      if args.size == 2 && args[1].is_a?(Hash) && args[1][:default]
        return args
      end

      has_key = key_provided?(*args)
      args.unshift infer_key(args[0]) unless has_key

      default = nil
      default_or_options = args[1]
      if args[2] || default_or_options.is_a?(String) || pluralization_hash?(default_or_options)
        default = args.delete_at(1)
      end
      args << {} if args.size == 1
      options = args[1]
      raise ArgumentError.new("invalid default translation. expected Hash or String, got #{default.class}") unless default.nil? || default.is_a?(String) || default.is_a?(Hash)
      raise ArgumentError.new("invalid options argument. expected Hash, got #{options.class}") unless options.is_a?(Hash)
      options[:default] = default if default
      options[:i18nliner_inferred_key] = true unless has_key
      args
    end

    extend self
  end
end

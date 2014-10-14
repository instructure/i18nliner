require 'zlib'
require 'i18n'
require 'i18nliner/base'

module I18nliner
  module CallHelpers
    ALLOWED_PLURALIZATION_KEYS = [:zero, :one, :few, :many, :other]
    REQUIRED_PLURALIZATION_KEYS = [:one, :other]

    def normalize_key(key, scope = Scope.root)
      scope.normalize_key(key.to_s)
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

    def infer_arguments(args, meta = {})
      if args.size == 2 && args[1].is_a?(Hash) && args[1][:default]
        return args
      end

      has_key = key_provided?(*args)
      meta[:inferred_key] = !has_key
      args.unshift infer_key(args[0]) unless has_key

      default_or_options = args[1]
      if args[2] || default_or_options.is_a?(String) || pluralization_hash?(default_or_options)
        options = args[2] ||= {}
        options[:default] = args.delete_at(1) if options.is_a?(Hash)
      end
      args << {} if args.size == 1
      args
    end

    extend self
  end
end

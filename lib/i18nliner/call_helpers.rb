require 'iconv'
require 'zlib'
require 'i18nliner'

module I18nliner
  module CallHelpers
    ALLOWED_PLURALIZATION_KEYS = [:zero, :one, :few, :many, :other]
    REQUIRED_PLURALIZATION_KEYS = [:one, :other]

    def normalize_key(key, scope = Scope.root)
      scope.normalize_key(key.to_s)
    end

    def normalize_default(default, translate_options = {})
      default = infer_pluralization_hash(default, translate_options)
      default.strip! if default.is_a?(String)
      default
    end

    def infer_pluralization_hash(default, translate_options)
      return default unless default.is_a?(String) &&
                            default =~ /\A[\w\-]+\z/ &&
                            translate_options.include?(:count)
      {:one => "1 #{default}", :other => "%{count} #{default.pluralize}"}
    end

    def infer_key(default, translate_options = {})
      default = default[:other].to_s if default.is_a?(Hash)
      keyify(normalize_default(default, translate_options))
    end

    def keyify_underscored(string)
      key = Iconv.iconv('ascii//translit//ignore', 'utf-8', string).to_s
      key.downcase!
      key.gsub!(/[^a-z0-9_]+/, '_')
      key.gsub!(/\A_|_\z/, '')
      key[0..50]
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
    def key_provided?(scope, key_or_default = nil, default_or_options = nil, maybe_options = nil, *others)
      return false if key_or_default.is_a?(Hash)
      return true if key_or_default.is_a?(Symbol)
      return true if default_or_options.is_a?(String)
      return true if maybe_options
      return true if I18nliner.look_up(normalize_key(key_or_default, scope))
      false
    end

    def infer_arguments(scope, args)
      has_key = key_provided?(scope, *args)
      args.unshift infer_key(args[0]) if !has_key && (args[0].is_a?(String) || args[0].is_a?(Hash))

      # [key, options] -> [key, nil, options]
      args.insert(1, nil) if has_key && args[1].is_a?(Hash) && args[2].nil?
      args
    end
  end
end

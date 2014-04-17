module I18nliner
  module Extractors
    class TranslationHash < Hash
      attr_accessor :line

      def self.new(hash = {})
        hash.is_a?(self) ? hash : super().replace(flatten(hash))
      end

      def self.flatten(hash, result = {}, prefix = "")
        hash.each do |key, value|
          if value.is_a?(Hash)
            flatten(value, result, "#{prefix}#{key}.")
          else
            result["#{prefix}#{key}"] = value
          end
        end
        result
      end

      def initialize(*args)
        super
        @total_size = 0
      end

      def []=(key, value)
        parts = key.split('.')
        leaf = parts.pop
        hash = self
        while part = parts.shift
          if hash[part]
            unless hash[part].is_a?(Hash)
              intermediate_key = key.sub((parts + [leaf]).join('.'), '')
              raise KeyAsScopeError, intermediate_key
            end
          else
            hash.store(part, {})
          end
          hash = hash[part]
        end
        if hash[leaf]
          if hash[leaf] != value
            if hash[leaf].is_a?(Hash)
              raise KeyAsScopeError.new(@line, key)
            else
              raise KeyInUseError.new(@line, key)
            end
          end
        else
          @total_size += 1
          hash.store(leaf, value)
        end
      end

      def expand_keys
        result = {}
        each do |key, value|
          parts = key.split(".")
          last = parts.pop
          parts.inject(result){ |h, k2| h[k2] ||= {}}[last] = value
        end
        result
      end
    end
  end
end

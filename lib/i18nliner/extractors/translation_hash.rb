module I18nLine
  module Extractors
    class TranslationHash < Hash
      attr_accessor :line

      def self.new(hash)
        hash.is_a?(self) ? hash : super
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
            hash[part] = {}
          end
          hash = hash[part]
        end
        if hash[leaf]
          if hash[leaf] != default
            if hash[leaf].is_a?(Hash)
              raise KeyAsScopeError.new(@line, key)
            else
              raise KeyInUseError.new(@line, key)
            end
          end
        else
          @total_size += 1
          hash[key] = value
        end
      end
    end
  end
end
module I18nliner
  module Extractors
    class TranslationHash < Hash
      attr_accessor :line

      def self.new(hash = {})
        hash.is_a?(self) ? hash : super().replace(hash)
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
          if hash[leaf] != default
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
    end
  end
end

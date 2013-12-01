module I18nliner
  module Extractors
    module AbstractExtractor
      def initialize(options = {})
        @scope = options[:scope] || ''
        @translations = TranslationHash.new(options[:translations] || {})
        @total = 0
        super()
      end

      def look_up(key)
        @translations[key]
      end

      def add_translation(full_key, default)
        @total += 1
        @translations[full_key] = default
      end

      def total_unique
        @translations.total_size
      end

      def self.included(base)
        base.instance_eval do
          attr_reader :total
          attr_accessor :translations, :scope
        end
      end
    end
  end
end


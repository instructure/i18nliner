require 'globby'
require 'i18nliner/base'
require 'i18nliner/processors'

module I18nliner
  module Processors
    class AbstractProcessor
      attr_reader :translation_count, :file_count

      def initialize(translations, options = {})
        @translations = translations
        @translation_count = 0
        @file_count = 0
        @only = options[:only]
        @checker = options[:checker] || method(:noop_checker)
        @pattern = options[:pattern] || self.class.default_pattern
      end

      def noop_checker(file)
        yield file
      end

      def files
        @files ||= begin
          files = Globby.select(Array(@pattern))
          files = files.select(Array(@only.dup)) if @only
          files.reject(I18nliner.ignore)
        end
      end

      def check_files
        Dir.chdir(I18nliner.base_path) do
          files.each do |file|
            @checker.call file, &method(:check_file)
          end
        end
      end

      def check_file(file)
        @file_count += 1
        check_contents(source_for(file), scope_for(file))
      end

      def self.inherited(klass)
        Processors.register klass
      end

      def self.default_pattern(*pattern)
        @pattern ||= []
        @pattern.concat(pattern)
      end
    end
  end
end

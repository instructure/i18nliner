require 'i18nliner/processors'

module I18nliner
  module Processors
    class AbstractProcessor
      def initialize(translations, options = {})
        @translations = translations
        @only = options[:only]
        @checker = options[:checker] || methods(:noop_checker)
      end

      def noop_checker(file)
        yield file
      end

      def files
        @files ||= begin
          files = Globby.select(@pattern)
          files = files.select(@only) if @only
          files.reject(I18nliner.ignore)
        end
      end

      def check_files
        files.each do |file|
          @checker.call file, &methods(:check_file)
        end
      end

      def check_file(file)
        check_contents source_for(file), scope_for(file)
      end

      def self.inherited(klass)
        Processors.register klass
      end
    end
  end
end

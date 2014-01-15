require 'i18nliner/commands/generic_command'
require 'i18nliner/extractors/translation_hash'
require 'active_support/core_ext/enumerable'
Dir[File.join(File.dirname(__FILE__), "../processors/*.rb")].each do |file|
  require "i18nliner/processors/#{File.basename(file)}"
end

module I18nliner
  module Commands
    class Check < GenericCommand
      attr_reader :translations, :errors

      def initialize(options)
        super
        @errors = []
        @translations = I18nliner::Extractors::TranslationHash.new(I18nliner.manual_translations)
      end

      def processors
        @processors ||= I18nliner::Processors.all.map do |klass|
          klass.new @translations,
                    :only => @options[:only],
                    :translations => @translations,
                    :checker => method(:check_file)
        end
      end

      def check_files
        processors.each &:check_files
      end

      def check_file(file)
        if yield file
          print green(".") unless @options[:silent]
        end
      rescue SyntaxError, StandardError, ExtractionError
        @errors << "#{$!}\n#{file}"
        print red("F") unless @options[:silent]
      end

      def success?
        @errors.empty?
      end

      def print_summary
        translation_count = processors.sum(&:translation_count)
        file_count = processors.sum(&:file_count)

        print "\n\n"

        @errors.each_with_index do |error, i|
          puts "#{i+1})"
          puts red(error)
          print "\n"
        end

        print "Finished in #{Time.now - @start} seconds\n\n"
        summary = "#{file_count} files, #{translation_count} strings, #{@errors.size} failures"
        puts success? ? green(summary) : red(summary)
      end

      def run
        check_files
        print_summary unless @options[:silent]
        success?
      end
    end
  end
end

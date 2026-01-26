# frozen_string_literal: true

require "ya2yaml"
require "fileutils"

module I18nliner
  module Commands
    class Dump < GenericCommand
      attr_reader :yml_file

      def initialize(options)
        super
        @translations = @options[:translations]
        @yml_file = @options[:file] ||
                    File.join(I18nliner.base_path, "config", "locales", "generated", "#{I18n.default_locale}.yml")
      end

      def run
        FileUtils.mkdir_p File.dirname(yml_file)
        File.write(yml_file, { I18n.default_locale.to_s => @translations }.ya2yaml(syck_compatible: true))
        puts "Wrote default translations to #{yml_file}" unless @options[:silent]
      end
    end
  end
end

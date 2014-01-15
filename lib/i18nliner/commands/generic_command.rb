require 'i18nliner/commands/basic_formatter'
require 'i18nliner/commands/color_formatter'

module I18nliner
  module Commands
    class GenericCommand
      include BasicFormatter

      def initialize(options)
        @options = options
        @start = Time.now
        extend ColorFormatter if $stdout.tty?
      end

      def success?
        true
      end

      def self.run(options)
        command = new(options)
        command.run
        command
      end
    end
  end
end

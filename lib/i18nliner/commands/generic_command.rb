module I18nliner
  module Commands
    class GenericCommand
      include BasicFormatter

      def initialize(options)
        @options = options
        @start = Time.now
        extend ColorFormatter if $stdout.tty?
      end

      def self.run(options)
        new(options).run
      end
    end
  end
end
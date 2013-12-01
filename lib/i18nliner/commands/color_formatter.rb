module I18nliner
  module Commands
    module ColorFormatter
      def red(text)
        "\e[31m#{text}\e[0m"
      end

      def green(text)
        "\e[32m#{text}\e[0m"
      end
    end
  end
end

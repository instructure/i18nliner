module I18nliner
  module Processors
    def self.register(klass)
      (@processors ||= []) << klass
    end

    def self.all
      @processors.dup
    end
  end
end

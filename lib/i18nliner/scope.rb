module I18nliner
  class Scope
    attr_reader :scope

    def initialize(scope = nil, options = {})
      @scope = scope ? "#{scope}." : scope
      @options = {
        :allow_relative => false
      }.merge(options)
    end

    def allow_relative?
      @options[:allow_relative]
    end

    def normalize_key(key)
      if allow_relative? && (key = key.dup) && key.sub!(/\A\./, '')
        scope + key
      else
        key
      end
    end
  end
end

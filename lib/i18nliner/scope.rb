module I18nliner
  class Scope
    attr_reader :scope
    attr_reader :allow_relative
    alias :allow_relative? :allow_relative
    attr_accessor :remove_whitespace
    alias :remove_whitespace? :remove_whitespace

    def initialize(scope = nil, options = {})
      @scope = scope ? "#{scope}." : scope
      @allow_relative = options.fetch(:allow_relative, false)
      @remove_whitespace = options.fetch(:remove_whitespace, false)
    end

    def normalize_key(key)
      if allow_relative? && (key = key.dup) && key.sub!(/\A\./, '')
        scope + key
      else
        key
      end
    end

    def self.root
      @root ||= new
    end
  end
end

module I18nliner
  class Scope
    attr_reader :scope
    attr_reader :allow_relative
    attr_reader :context
    alias :allow_relative? :allow_relative
    attr_accessor :remove_whitespace
    alias :remove_whitespace? :remove_whitespace

    def initialize(scope = nil, options = {})
      @scope = scope ? "#{scope}." : scope
      @allow_relative = options.fetch(:allow_relative, false)
      @remove_whitespace = options.fetch(:remove_whitespace, false)
      @context = options.fetch(:context, nil)
    end

    def normalize_key(key, inferred, i18n_scope)
      if allow_relative? && (key = key.dup) && key.sub!(/\A\./, '')
        scope + key
      else
        key
      end
    end

    def self.root
      @root ||= new
    end

    def root?
      scope.blank?
    end
  end
end

# frozen_string_literal: true

module I18nliner
  class Scope
    attr_reader :scope, :allow_relative, :context
    alias_method :allow_relative?, :allow_relative
    attr_accessor :remove_whitespace
    alias_method :remove_whitespace?, :remove_whitespace

    def initialize(scope = nil, options = {})
      @scope = scope ? "#{scope}." : scope
      @allow_relative = options.fetch(:allow_relative, false)
      @remove_whitespace = options.fetch(:remove_whitespace, false)
      @context = options.fetch(:context, nil)
    end

    def normalize_key(key, inferred, i18n_scope)
      return key if key.nil?
      return key.map { |k| normalize_key(k, inferred, i18n_scope) } if key.is_a?(Array)

      key = key.to_s.dup
      if allow_relative? && key.delete_prefix!(".")
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

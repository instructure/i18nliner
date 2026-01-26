# frozen_string_literal: true

require "i18n"

module I18nliner
  def self.ignore
    @ignore ||= begin
      path = File.join(base_path, ".i18nignore")
      File.exist?(path) ? File.read(path).split(/\r?\n|\r/) : []
    end
  end

  def self.translations; end

  def self.manual_translations
    I18n.t(:foo) # ensure backend is initialized
    # TODO: support additional backends
    I18n.backend.send(:translations)[I18n.default_locale]
  end

  def self.look_up(key) # rubocop:disable Naming/PredicateMethod
    I18n.exists?(I18n.locale, key)
  end

  def self.setting(key, value)
    instance_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{key}=(value)                              # def base_path=(value)
        @#{key} = value                               #   @base_path = value
      end                                             # end
                                                      #
      def #{key}(value = nil)                         # def base_path(value = nil)
        if value && block_given?                      #   if value && block_given?
          begin                                       #     begin
            value_was = @#{key}                       #       value_was = @base_path
            @#{key} = value                           #       @base_path = value
            yield                                     #       yield
          ensure                                      #     ensure
            @#{key} = value_was                       #       @base_path = value_was
          end                                         #     end
        else                                          #   else
          @#{key} = #{value.inspect} if @#{key}.nil?  #     @base_path = "./" if @base_path.nil?
          @#{key}                                     #     @base_path
        end                                           #   end
      end                                             # end
    RUBY
  end

  setting :inferred_key_format,        :underscored_crc32
  setting :infer_interpolation_values, true
  setting :base_path,                  "./"
  setting :underscored_key_length,     50
end

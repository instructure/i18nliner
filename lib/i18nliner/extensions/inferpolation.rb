module I18nliner
  module Extensions
    module Inferpolation
      def inferpolate(options)
        default = options[:default]
        return options unless default

        default.gsub!(/%\{((@)?\w+(.\w+)*)\}/).each do
          match = $~
          key = $1
          ivar = $2
          next match if options[key] || options[key.to_sym]
          parts = key.split('.')
          receiver = ivar ? instance_variable_get(parts.shift) : self
          value = parts.inject(receiver) do |obj, message|
            obj.respond_to?(message) ? obj.send(message) : nil
          end

          next match if value.nil?
          new_key = key.sub(/\@/, '').gsub('.', '_')
          options[new_key.to_sym] = value
          "%{#{new_key}}"
        end
        options
      end
    end
  end
end

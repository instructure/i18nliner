require "i18nliner/scope"

module I18nliner
  class ControllerScope < Scope
    def scope
      # best guess at current action, ymmv. we only add the action at this
      # point because the scope already has the controller path
      # see abstract_controller/translation.rb for reference
      if context.current_defn
        "#{super}.#{context.current_defn}"
      else
        super
      end
    end
  end
end

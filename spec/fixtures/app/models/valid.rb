class Group < ActiveRecord::Base
  def welcome_message
    t "welcome, %{name}"
  end
end

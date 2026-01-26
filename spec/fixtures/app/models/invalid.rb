# frozen_string_literal: true

class User < ActiveRecord::Base
  def welcome_message
    t "welcome, #{name}"
  end
end

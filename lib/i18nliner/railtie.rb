module I18nliner
  class Railtie < Rails::Railtie
    ActiveSupport.on_load :action_pack do
      ActionController::Base.include I18nliner::Extensions::Controller
      ActionView::Base.include I18nliner::Extensions::View
    end
    ActiveSupport.on_load :active_model do
      ActiveModel::Base.include I18nliner::Extensions::Model
    end
  end
end



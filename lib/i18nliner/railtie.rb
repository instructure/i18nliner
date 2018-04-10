require 'i18nliner/extensions/controller'
require 'i18nliner/extensions/view'
require 'i18nliner/extensions/model'

module I18nliner
  class Railtie < Rails::Railtie
    initializer 'i18nliner' do
      ActiveSupport.on_load :action_controller do
        ActionController::Base.send :include, I18nliner::Extensions::Controller
      end

      ActiveSupport.on_load :action_view do
        require 'i18nliner/erubi'
        ActionView::Template::Handlers::ERB.erb_implementation = I18nliner::Erubi
        ActionView::Base.send :include, I18nliner::Extensions::View
      end

      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.send :include, I18nliner::Extensions::Model
      end
    end

    rake_tasks do
      load "tasks/i18nliner.rake"
    end
  end
end



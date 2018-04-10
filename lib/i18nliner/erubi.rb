require 'action_view/template'
require 'i18nliner/pre_processors/erb_pre_processor'

module I18nliner
  class Erubi < ::ActionView::Template::Handlers::ERB::Erubi
    def initialize(source, options = {})
      source = I18nliner::PreProcessors::ErbPreProcessor.new(source).result
      super(source, options)
    end
  end
end


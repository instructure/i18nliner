require 'i18nliner/processors/erb_processor'
require 'i18nliner/extractors/translation_hash'

describe I18nliner::Processors::ErbProcessor do
  before do
    @translations = I18nliner::Extractors::TranslationHash.new
    @processor = I18nliner::Processors::ErbProcessor.new(@translations)
  end
  
  describe "#check_contents" do
    it "should extract valid translation calls" do
      @processor.check_contents(<<-SOURCE)
        <%= t "Inline!" %>
        <%= t do %>
          Zomg a block
          <a href="/nesting"
             title="<%= t do %>what is this?<% end %>"
             >with nesting</a>!!!
        <% end %>
        SOURCE
      @translations.values.sort.should == [
        "Inline!",
        "Zomg a block *with nesting*!!!",
        "what is this?"
      ]
    end
  end
end

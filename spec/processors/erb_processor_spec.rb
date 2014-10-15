require 'i18nliner/processors/erb_processor'
require 'i18nliner/extractors/translation_hash'
require 'i18nliner/scope'

describe I18nliner::Processors::ErbProcessor do
  before do
    @translations = I18nliner::Extractors::TranslationHash.new
    @processor = I18nliner::Processors::ErbProcessor.new(@translations)
  end
  
  describe "#scope_for" do
    context "with an erb template" do
      subject { @processor.scope_for("app/views/foos/show.html.erb") }

      specify { expect(subject).to be_allow_relative }
      specify { expect(subject).to be_remove_whitespace }
      specify { expect(subject.scope).to eq "foos.show." }
    end

    context "with anything else" do
      subject { @processor.scope_for("foo.erb") }

      specify { expect(subject).to be I18nliner::Scope.root }
    end
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

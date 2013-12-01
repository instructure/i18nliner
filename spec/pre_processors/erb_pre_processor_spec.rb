require 'i18nliner/pre_processors/erb_pre_processor'

describe I18nliner::PreProcessors::ErbPreProcessor do
  describe ".process" do
    def process(string)
      I18nliner::PreProcessors::ErbPreProcessor.process(string)
    end

    it "should transform t block expressions" do
      process("<%= t do %>hello world!<% end %>").should ==
        '<%= t "hello world!" %>'
    end

    it "should transform nested t block expressions"
    it "should not translate other block expressions"
    it "should reject malformed erb"
    it "should disallow nesting non-t block expressions in a t block expression"
    it "should create wrappers for markup"
    it "should create wrappers for link_to calls"
    it "should generate placeholders for inline expressions"
  end
end

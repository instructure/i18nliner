require 'i18nliner/pre_processors/erb_pre_processor'
require 'i18nliner/errors'

describe I18nliner::PreProcessors::ErbPreProcessor do
  describe ".process" do
    def process(string)
      I18nliner::PreProcessors::ErbPreProcessor.process(string)
    end

    it "should transform t block expressions" do
      process("<%= t do %>hello world!<% end %>").should ==
        '<%= t "hello world!" %>'
    end

    it "should strip whitespace from the translation" do
      process("<%= t do %> ohai!  <% end %>").should ==
        '<%= t "ohai!" %>'
    end

    it "should transform nested t block expressions in wrappers"

    it "should not translate other block expressions" do
      process(<<-SOURCE).
        <%= form_for do %>
          <%= t do %>Your Name<% end %>
          <input>
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= form_for do %>
          <%= t "Your Name" %>
          <input>
        <% end %>
        EXPECTED
    end

    it "should reject malformed erb" do
      expect { process("<%= t do %>") }.
        to raise_error(I18nliner::MalformedErbError)
    end

    it "should disallow nesting non-t block expressions in a t block expression" do
      expect { process("<%= t { %><%= s { %>nope<% } %><% } %>") }.
        to raise_error(I18nliner::TBlockNestingError)
    end

    it "should disallow statements in a t block expression" do
      expect { process("<%= t { %>I am <% if happy %>happy<% else %>sad<% end %><% } %>") }.
        to raise_error(I18nliner::TBlockNestingError)
    end

    it "should create wrappers for markup" do
      process(<<-SOURCE).
        <%= t do %>
          <b>bold</b>, or even <a href="#"><i><img>combos</i></a> get wrapper'd
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t "*bold*, or even **combos** get wrapper'd", {:wrappers=>["<b>\\\\1</b>", "<a href=\\\"#\\\"><i><img>\\\\1</i></a>"]} %>
        EXPECTED
    end

    it "should not create wrappers for markup with multiple text nodes" do
      expect { puts process("<%= t do %>this is <b><i>too</i> complicated</b><% end %>") }.
        to raise_error(I18nliner::UnwrappableContentError)
    end

    it "should create wrappers for link_to calls"
    it "should generate placeholders for inline expressions"
    it "should generate placeholders for empty markup"
  end
end

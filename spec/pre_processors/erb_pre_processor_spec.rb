# encoding: UTF-8
require 'i18nliner/pre_processors/erb_pre_processor'
require 'i18nliner/errors'

describe I18nliner::PreProcessors::ErbPreProcessor do
  describe ".process" do
    def process(string)
      I18nliner::PreProcessors::ErbPreProcessor.process(string)
    end

    it "should transform t block expressions" do
      process("<%= t do %>hello world!<% end %>").should ==
        '<%= t :hello_world_ad7076cc, "hello world!" %>'
    end

    it "should remove extraneous whitespace" do
      process("<%= t do %> ohai!\n lulz\t <% end %>").should ==
        '<%= t :ohai_lulz_992c25f8, "ohai! lulz" %>'
    end

    it "should not translate other block expressions" do
      process(<<-SOURCE).
        <%= form_for do %>
          <%= t do %>Your Name<% end %>
          <input>
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= form_for do %>
          <%= t :your_name_7665e1d8, "Your Name" %>
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
        <%= t :bold_or_even_combos_get_wrapper_d_17fcc6e, "*bold*, or even **combos** get wrapper'd", :wrappers => ["<b>\\\\1</b>", "<a href=\\\"#\\\"><i><img>\\\\1</i></a>"] %>
        EXPECTED
    end

    it "should not create wrappers for markup with multiple text nodes" do
      expect { puts process("<%= t do %>this is <b><i>too</i> complicated</b><% end %>") }.
        to raise_error(I18nliner::UnwrappableContentError)
    end

    it "should create wrappers for link_to calls with string content" do
      process(<<-SOURCE).
        <%= t do %>
          You should <%= link_to("create a profile", "/profile") %>
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t :you_should_create_a_profile_1d1e96d5, "You should *create a profile*", :wrappers => [link_to("\\\\1", "/profile")] %>
        EXPECTED
    end

    it "should create wrappers for link_to calls with other content" do
      process(<<-SOURCE).
        <%= t do %>
          Your account rep is <%= link_to(@user.name, "/user/\#{@user.id}") %>
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t :your_account_rep_is_user_name_f17470cd, "Your account rep is *%{user_name}*", :user_name => (@user.name), :wrappers => [link_to("\\\\1", "/user/\#{@user.id}")] %>
        EXPECTED
    end

    it "should generate placeholders for inline expressions" do
      process(<<-SOURCE).
        <%= t do %>
          Hello, <%= name %>
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t :hello_name_7d06d559, "Hello, %{name}", :name => (name) %>
        EXPECTED
    end

    it "should generate placeholders for inline expressions in wrappers" do
      process(<<-SOURCE).
        <%= t do %>
          Go to <a href="/asdf" title="<%= name %>">your account</a>
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t :go_to_your_account_1379b368, "Go to *your account*", :wrappers => ["<a href=\\"/asdf\\" title=\\"\#{name}\\">\\\\1</a>"] %>
        EXPECTED
    end

    # this is really the same as the one above, but it's good to have a
    # spec for this in case the underlying implementation changes
    # dramatically
    it "should transform nested t block expressions in wrappers" do
      process(<<-SOURCE).
        <%= t do %>
          Go to <a href="/asdf" title="<%= t do %>manage account stuffs, <%= name %><% end %>">your account</a>
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t :go_to_your_account_1379b368, "Go to *your account*", :wrappers => ["<a href=\\"/asdf\\" title=\\"\#{t :manage_account_stuffs_name_6705efd9, \"manage account stuffs, %{name}\", :name => (name)}\\">\\\\1</a>"] %>
        EXPECTED
    end

    it "should generate placeholders for empty markup" do
      process(<<-SOURCE).
        <%= t do %>
          Create <input name="count"> groups
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t :create_input_name_count_groups_c0f9b227, "Create %{input_name_count} groups", :input_name_count => ("<input name=\\"count\\">".html_safe) %>
        EXPECTED
    end

    it "should unescape entities" do
      process(<<-SOURCE).
        <%= t do %>
          &copy; <%= year %> ACME Corp. All Rights Reserved. Our lawyers &gt; your lawyers
        <% end %>
        SOURCE
      should == <<-EXPECTED
        <%= t :c_year_acme_corp_all_rights_reserved_our_lawyers_yo_c8062765, "© %{year} ACME Corp. All Rights Reserved. Our lawyers > your lawyers", :year => (year) %>
        EXPECTED
    end
  end
end

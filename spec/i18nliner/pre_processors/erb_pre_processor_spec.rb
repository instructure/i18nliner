# frozen_string_literal: true

require "i18nliner/pre_processors/erb_pre_processor"
require "i18nliner/errors"
require "active_support/core_ext/string/strip"

describe I18nliner::PreProcessors::ErbPreProcessor do
  before do
    allow_any_instance_of(I18nliner::PreProcessors::ErbPreProcessor::TBlock).to receive(:infer_key).and_return(:key) # rubocop:disable RSpec/AnyInstance
  end

  describe ".process" do
    def process(string, remove_blank_lines: true)
      result = I18nliner::PreProcessors::ErbPreProcessor.process(string)
      result.gsub!(/\n+%>/, " %>") if remove_blank_lines
      result
    end

    it "should transform t block expressions" do
      expect(process("<%= t do %>hello world!<% end %>")).to eq(
        '<%= t :key, "hello world!", :i18nliner_inferred_key => (true) %>'
      )
    end

    it "should remove extraneous whitespace from the default" do
      expect(process("<%= t do %> ohai!  lulz\t <% end %>")).to eq(
        '<%= t :key, "ohai! lulz", :i18nliner_inferred_key => (true) %>'
      )
    end

    # so that line numbers are close-ish when you get an error in a
    # multi-line t-block... an exception from an expression might not
    # match up perfectly, but it will at least point to the start of the
    # t-block
    it "should preserve all newlines in the generated erb" do
      expect(process(<<~ERB.strip_heredoc, remove_blank_lines: false)).
        <%= t do
        %>
          ohai!
          <%= test %>
          lulz
        <% end %>
      ERB
        to eq <<~ERB.strip_heredoc
          <%= t :key, "ohai! %{test} lulz", :test => (test), :i18nliner_inferred_key => (true)




          %>
        ERB
    end

    it "should not translate other block expressions" do
      expect(process(<<~ERB)).
        <%= form_for do %>
          <%= t do %>Your Name<% end %>
          <input>
        <% end %>
      ERB
        to eq <<~ERB
          <%= form_for do %>
            <%= t :key, "Your Name", :i18nliner_inferred_key => (true) %>
            <input>
          <% end %>
        ERB
    end

    it "should reject malformed erb" do
      expect { process("<%= t do %>") }
        .to raise_error(I18nliner::MalformedErbError)
    end

    it "should disallow nesting non-t block expressions in a t block expression" do
      expect { process("<%= t { %><%= s { %>nope<% } %><% } %>") }
        .to raise_error(I18nliner::TBlockNestingError)
      expect { process("<%= t { %><%= s(:some, :args) { |args, here, too| %>nope<% } %><% } %>") }
        .to raise_error(I18nliner::TBlockNestingError)
    end

    it "should disallow statements in a t block expression" do
      expect { process("<%= t { %>I am <% if happy %>happy<% else %>sad<% end %><% } %>") }
        .to raise_error(I18nliner::TBlockNestingError)
    end

    it "should create wrappers for markup" do
      expect(process(<<~ERB)).
        <%= t do %>
          <b>bold</b>, or even <a href="#"><i><img>combos</i></a> get wrapper'd
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "*bold*, or even **combos** get wrapper'd", :i18nliner_inferred_key => (true), :wrappers => ["<b>\\\\1</b>", "<a href=\\"#\\"><i><img>\\\\1</i></a>"] %>
        ERB
    end

    it "should not create wrappers for markup with multiple text nodes" do
      expect { process("<%= t do %>this is <b><i>too</i> complicated</b><% end %>") }
        .to raise_error(I18nliner::UnwrappableContentError)
    end

    it "should create wrappers for link_to calls with string content" do
      expect(process(<<~ERB)).
        <%= t do %>
          You should <%= link_to("create a profile", "/profile") %>.
          idk why <%= link_to "this " + "link", "/zomg" %> has concatention
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "You should *create a profile*. idk why **this link** has concatention", :i18nliner_inferred_key => (true), :wrappers => [link_to("\\\\1", "/profile"), link_to("\\\\1", "/zomg")] %>
        ERB
    end

    it "should create wrappers for link_to calls with other content" do
      expect(process(<<~ERB)).
        <%= t do %>
          Your account rep is <%= link_to(@user.name, "/user/\#{@user.id}") %>
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "Your account rep is *%{user_name}*", :user_name => (@user.name), :i18nliner_inferred_key => (true), :wrappers => [link_to("\\\\1", "/user/\#{@user.id}")] %>
        ERB
    end

    it "should reuse identical wrappers" do
      expect(process(<<~ERB)).
        <%= t do %>
          the wrappers for
          <%= link_to "these", url %> <%= link_to "links", url %> are the same,
          as are the ones for
          <b>these</b> <b>tags</b>
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "the wrappers for **these** **links** are the same, as are the ones for *these* *tags*", :i18nliner_inferred_key => (true), :wrappers => ["<b>\\\\1</b>", link_to("\\\\1", url)] %>
        ERB
    end

    it "should generate placeholders for inline expressions" do
      expect(process(<<~ERB)).
        <%= t do %>
          Hello, <%= name %>
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "Hello, %{name}", :name => (name), :i18nliner_inferred_key => (true) %>
        ERB
    end

    it "should generate placeholders for inline expressions in wrappers" do
      expect(process(<<~ERB)).
        <%= t do %>
          Go to <a href="/asdf" title="<%= name %>">your account</a>
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "Go to *your account*", :i18nliner_inferred_key => (true), :wrappers => ["<a href=\\"/asdf\\" title=\\"\#{name}\\">\\\\1</a>"] %>
        ERB
    end

    # this is really the same as the one above, but it's good to have a
    # spec for this in case the underlying implementation changes
    # dramatically
    it "should transform nested t block expressions in wrappers" do
      expect(process(<<~ERB)).
        <%= t do %>
          Go to <a href="/asdf" title="<%= t do %>manage account stuffs, <%= name %><% end %>">your account</a>
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "Go to *your account*", :i18nliner_inferred_key => (true), :wrappers => ["<a href=\\"/asdf\\" title=\\"\#{t :key, "manage account stuffs, %{name}", :name => (name), :i18nliner_inferred_key => (true)}\\">\\\\1</a>"] %>
        ERB
    end

    it "should generate placeholders for empty markup" do
      expect(process(<<~ERB)).
        <%= t do %>
          Create <input name="count"> groups
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "Create %{input_name_count} groups", :input_name_count => ("<input name=\\"count\\">".html_safe), :i18nliner_inferred_key => (true) %>
        ERB
    end

    it "should unescape entities" do
      expect(process(<<~ERB)).
        <%= t do %>
          &copy; <%= year %> ACME Corp. All Rights Reserved. Our lawyers &gt; your lawyers
        <% end %>
      ERB
        to eq <<~ERB
          <%= t :key, "© %{year} ACME Corp. All Rights Reserved. Our lawyers > your lawyers", :year => (year), :i18nliner_inferred_key => (true) %>
        ERB
    end
  end
end

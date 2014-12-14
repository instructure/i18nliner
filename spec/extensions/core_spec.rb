require 'i18n'
require 'i18nliner/extensions/core'

describe I18nliner::Extensions::Core do
  let(:i18n) do
    Module.new do
      extend(Module.new do
        def translate(*args)
          simple_translate(args[0], args[1])
        end

        def simple_translate(key, options)
          string = options.delete(:default)
          interpolate_hash(string, options)
        end

        def interpolate_hash(string, values)
          I18n.interpolate_hash(string, values)
        end
      end)
      extend I18nliner::Extensions::Core
    end
  end

  describe ".translate" do
    it "should should normalize the arguments passed into the original translate" do
      expect(i18n).to receive(:simple_translate).with("hello_name_84ff273f", :default => "Hello %{name}", :name => "bob")
      i18n.translate("Hello %{name}", :name => "bob")
    end

    it "should not mutate the arguments passed in" do
      expect(i18n).to receive(:simple_translate).with("my.key", :default => "ohai whitespace ")
      key = "my.key".freeze
      default = " ohai whitespace ".freeze
      expect {
        i18n.translate(key, default)
      }.to_not raise_error
    end

    it "should infer pluralization hashes" do
      expect(i18n).to receive(:simple_translate).with("count_lights_58339e29", :default => {:one => "1 light", :other => "%{count} lights"}, count: 1)
      i18n.translate("light", :count => 1)
    end

    it "should not stringify nil keys" do
      expect(i18n).to receive(:simple_translate).with(nil, {:default => [:foo, :bar]})
      i18n.translate(nil, {:default => [:foo, :bar]})
    end

    it "should stringify array keys, but not the array itself" do
      expect(i18n).to receive(:simple_translate).with(["bar", "baz"], {})
      i18n.translate([:bar, :baz])
    end

    context "with wrappers" do
      it "should apply a single wrapper" do
        result = i18n.translate("Hello *bob*.", :wrapper => '<b>\1</b>')
        result.should == "Hello <b>bob</b>."
      end

      it "should be html-safe" do
        result = i18n.translate("Hello *bob*.", :wrapper => '<b>\1</b>')
        result.should be_html_safe
      end

      it "should apply multiple wrappers" do
        result = i18n.translate("Hello *bob*. Click **here**", :wrappers => ['<b>\1</b>', '<a href="/">\1</a>'])
        result.should == "Hello <b>bob</b>. Click <a href=\"/\">here</a>"
      end

      it "should apply multiple wrappers with arbitrary delimiters" do
        result = i18n.translate("Hello !!!bob!!!. Click ???here???", :wrappers => {'!!!' => '<b>\1</b>', '???' => '<a href="/">\1</a>'})
        result.should == "Hello <b>bob</b>. Click <a href=\"/\">here</a>"
      end

      it "should html-escape the default when applying wrappers" do
        i18n.translate("*bacon* > narwhals", :wrappers => ['<b>\1</b>']).
          should == "<b>bacon</b> &gt; narwhals"
      end
    end
  end

  describe ".translate!" do
    it "should behave like translate" do
      expect(i18n).to receive(:simple_translate).with("hello_name_84ff273f", :default => "Hello %{name}", :name => "bob")
      i18n.translate!("Hello %{name}", :name => "bob")
    end
  end

  describe ".interpolate_hash" do
    it "should not mark the result as html-safe if none of the components are html-safe" do
      result = i18n.interpolate_hash("hello %{name}", :name => "<script>")
      result.should == "hello <script>"
      result.should_not be_html_safe
    end

    it "should html-escape values if the string is html-safe" do
      result = i18n.interpolate_hash("some markup: %{markup}".html_safe, :markup => "<html>")
      result.should == "some markup: &lt;html&gt;"
      result.should be_html_safe
    end

    it "should html-escape the string and other values if any value is html-safe strings" do
      markup = "<input>"
      result = i18n.interpolate_hash("type %{input} & you get this: %{output}", :input => markup, :output => markup.html_safe)
      result.should == "type &lt;input&gt; &amp; you get this: <input>"
      result.should be_html_safe
    end

    it "should not html-escape the string if the html-safe values are not strings" do
      markup = "<input>"
      result = i18n.interpolate_hash("my favorite number is %{number} & my favorite color is %{color}", :number => 1, :color => "red")
      result.should == "my favorite number is 1 & my favorite color is red"
      result.should_not be_html_safe
    end
  end
end


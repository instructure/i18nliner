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

    it "should apply wrappers" do
      result = i18n.translate("Hello *bob*. Click **here**", :wrappers => ['<b>\1</b>', '<a href="/">\1</a>'])
      result.should == "Hello <b>bob</b>. Click <a href=\"/\">here</a>"
      result.should be_html_safe
    end

    it "should html-escape the default when applying wrappers" do
      i18n.translate("*bacon* > narwhals", :wrappers => ['<b>\1</b>']).
        should == "<b>bacon</b> &gt; narwhals"
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

    it "should html-escape the string and other values if any value is html-safe" do
      markup = "<input>"
      result = i18n.interpolate_hash("type %{input} & you get this: %{output}", :input => markup, :output => markup.html_safe)
      result.should == "type &lt;input&gt; &amp; you get this: <input>"
      result.should be_html_safe
    end
  end
end


require 'i18nliner/extensions/core'

describe I18nliner::Extensions::Core do
  let(:i18n) do
    Module.new do
      extend(Module.new do
        def translate(*args)
          spy(*args)
        end

        def interpolate(string, options)
          string % options
        end
      end)
      extend I18nliner::Extensions::Core
    end
  end

  it "should should normalize the arguments passed into the original translate" do
    expect(i18n).to receive(:spy).with("hello_name_84ff273f", :default => "Hello %{name}", :name => "bob")
    i18n.translate("Hello %{name}", :name => "bob")
  end

  it "should apply wrappers" do
    i18n.should_receive(:spy) { |*args| args[1][:default] }
    i18n.translate("Hello *bob*. Click **here**", :wrappers => ['<b>\1</b>', '<a href="/">\1</a>']).
      should == "Hello <b>bob</b>. Click <a href=\"/\">here</a>"
  end

  it "should html-escape the default when applying wrappers" do
    i18n.should_receive(:spy) { |*args| args[1][:default] }
    i18n.translate("*bacon* > narwhals", :wrappers => ['<b>\1</b>']).
      should == "<b>bacon</b> &gt; narwhals"
  end
end


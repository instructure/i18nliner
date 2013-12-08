require 'i18nliner/extensions/core'

describe I18nliner::Extensions::Core do
  it "should should normalize the arguments passed into the original translate" do
    i18n = Module.new do
      extend(Module.new do
        def translate(*args)
          spy(*args)
        end
      end)
      extend I18nliner::Extensions::Core
    end
    expect(i18n).to receive(:spy).with("hello_name_84ff273f", :default => "Hello %{name}", :name => "bob")
    i18n.translate("Hello %{name}", :name => "bob")
  end
end


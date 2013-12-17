# encoding: UTF-8
require 'i18nliner/extensions/view'
require 'i18nliner/call_helpers'

describe I18nliner::Extensions::View do
  let(:i18n) do
    Module.new do
      extend(Module.new do
        def translate(*args)
          I18n.translate(*args)
        end
      end)
      extend I18nliner::Extensions::View
    end
  end


  describe "#translate" do
    it "should inferpolate" do
      i18n.stub(:foo).and_return("FOO")
      I18nliner::CallHelpers.stub(:infer_key).and_return(:key)

      expect(I18n).to receive(:translate).with(:key, :default => "hello %{foo}", :foo => "FOO")
      i18n.translate("hello %{foo}")
    end

    it "should raise an error when given a block" do
      expect {
        i18n.translate(:foo) {
          uhoh there was a bug with erb extraction
        }
      }.to raise_error /block syntax not supported/
      expect {
        i18n.translate
      }.to raise_error /wrong number of arguments/
    end
  end
end


# encoding: UTF-8
require 'i18nliner/extensions/model'
require 'i18nliner/call_helpers'

describe I18nliner::Extensions::Model do
  let(:i18n) do
    Module.new do
      extend I18nliner::Extensions::Model
    end
  end


  describe "#translate" do
    it "should inferpolate" do
      allow(i18n).to receive(:foo).and_return("FOO")
      allow(I18nliner::CallHelpers).to receive(:infer_key).and_return(:key)

      expect(I18n).to receive(:translate).with(:key, :default => "hello %{foo}", :foo => "FOO", :i18nliner_scope => i18n.i18nliner_scope, :i18nliner_inferred_key => true)
      i18n.translate("hello %{foo}")
    end

    it "should pass along its scope to I18n.t" do
      expect(I18n).to receive(:translate).with(:key, :default => "foo", :i18nliner_scope => i18n.i18nliner_scope)
      i18n.translate(:key, "foo")
    end
  end
end




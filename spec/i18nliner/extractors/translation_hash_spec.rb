# frozen_string_literal: true

require "i18nliner/errors"
require "i18nliner/extractors/translation_hash"

describe I18nliner::Extractors::TranslationHash do
  describe "#[]=" do
    let(:hash) { I18nliner::Extractors::TranslationHash.new }

    it "should accept identical key/values" do
      expect do
        hash["foo"] = "Foo"
        hash["foo"] = "Foo"
      end.not_to raise_error
      expect(hash).to eq({ "foo" => "Foo" })
    end

    it "should reject mismatched values" do
      expect do
        hash["foo"] = "Foo"
        hash["foo"] = "Bar"
      end.to raise_error(I18nliner::KeyInUseError)
    end

    it "should not let you use a key as a scope" do
      expect do
        hash["foo"] = "Foo"
        hash["foo.bar"] = "Bar"
      end.to raise_error(I18nliner::KeyAsScopeError)
    end

    it "should not let you use a scope as a key" do
      expect do
        hash["foo.bar"] = "Bar"
        hash["foo"] = "Foo"
      end.to raise_error(I18nliner::KeyAsScopeError)
    end
  end
end

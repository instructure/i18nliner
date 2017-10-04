# encoding: UTF-8
require 'i18nliner/base'
require 'i18nliner/scope'
require 'i18nliner/extractors/translate_call'

describe I18nliner::Extractors::TranslateCall do
  def call(scope, *args)
    I18nliner::Extractors::TranslateCall.new(scope, nil, :t, args)
  end

  let(:no_scope) { I18nliner::Scope.new(nil) }
  let(:scope) { I18nliner::Scope.new("foo", :auto => true, :allow_relative => true) }
  let(:erb_scope) { I18nliner::Scope.new(nil, :remove_whitespace => true) }

  describe "signature" do
    it "should reject extra arguments" do
      expect {
        call(no_scope, :key, "value", {}, :wat)
      }.to raise_error(I18nliner::InvalidSignatureError)
    end

    it "should accept a valid key or default" do
      expect {
        call(no_scope, "key", "value", {})
      }.to_not raise_error

      expect {
        call(no_scope, "key_or_value", {})
      }.to_not raise_error

      expect {
        call(no_scope, :key, {})
      }.to_not raise_error
    end

    it "should require at least a key or default" do
      expect {
        call(no_scope)
      }.to raise_error(I18nliner::InvalidSignatureError)
    end

    it "should require a literal default" do
      expect {
        call(no_scope, :key, Object.new)
      }.to raise_error(I18nliner::InvalidSignatureError)
    end

    # for legacy calls, e.g. t :key, :default => "foo"
    it "should allow the default to be specified in the options hash" do
      call = call(no_scope, :key, :default => "foo")
      expect(call.default).to eq "foo"
    end

    it "should not extract symbol defaults" do
      call = call(no_scope, :key, :default => :bar_key)
      expect(call.default).to be_nil
    end

    it "should extract the first string default" do
      call = call(no_scope, :key, :default => [:foo_key, :bar_key, "baz"])
      expect(call.default).to eq "baz"
    end

    it "should ensure options is a hash, if provided" do
      expect {
        call(no_scope, :key, "value", Object.new)
      }.to raise_error(I18nliner::InvalidSignatureError)
    end
  end

  describe "key inference" do
    it "should generate literal keys" do
      I18nliner.inferred_key_format :literal do
        expect(call(no_scope, "zomg key").translations).to eq(
          [["zomg key", "zomg key"]])
      end
    end

    it "should generate underscored keys" do
      I18nliner.inferred_key_format :underscored do
        expect(call(no_scope, "zOmg key!!").translations).to eq(
          [["zomg_key", "zOmg key!!"]])
      end
    end

    it "should transliterate underscored keys according to the default locale" do
      orig_locale = I18n.default_locale
      I18n.available_locales = [:en, :de]
      I18n.backend.store_translations(:de, :i18n => {
        :transliterate => {
          :rule => {
            "ü" => "ue",
            "ö" => "oe"
          }
        }
      })

      I18nliner.inferred_key_format :underscored do
        I18n.default_locale = :en
        expect(call(no_scope, "Jürgen").translations[0][0]).to eq "jurgen"
        I18n.default_locale = :de
        expect(call(no_scope, "Jürgen").translations[0][0]).to eq "juergen"
      end
      I18n.default_locale = orig_locale
    end

    it "should generate underscored + crc32 keys" do
      I18nliner.inferred_key_format :underscored_crc32 do
        expect(call(no_scope, "zOmg key!!").translations).to eq(
          [["zomg_key_90a85b0b", "zOmg key!!"]])
      end
    end
  end

  describe "normalization" do
    it "should make keys absolute if scoped" do
      expect(call(scope, '.key', "value").translations[0][0]).to match /\Afoo\.key/
      expect(call(scope, ['.key1', '.key2'], "value").translations.map(&:first)).to eq ['foo.key1', 'foo.key2']
    end

    it "should strip leading whitespace from defaults" do
      expect(call(no_scope, "\t white  space \n\t ").translations[0][1]).to eq "white  space \n\t "
    end

    it "should strip all whitespace from defaults if the scope requests it" do
      expect(call(erb_scope, "\t white  space \n\t ").translations[0][1]).to eq "white space"
    end
  end

  describe "pluralization" do
    describe "keys" do
      it "should be inferred from a word" do
        translations = call(no_scope, "person", {:count => Object.new}).translations
        expect(translations.map(&:first).sort).to eq ["count_people_489946e7.one", "count_people_489946e7.other"]
      end

      it "should be inferred from a hash" do
        translations = call(no_scope, {:one => "just you", :other => "lotsa peeps"}, {:count => Object.new}).translations
        expect(translations.map(&:first).sort).to eq ["lotsa_peeps_41499c40.one", "lotsa_peeps_41499c40.other"]
      end
    end

    describe "defaults" do
      it "should be inferred" do
        translations = call(no_scope, "person", {:count => Object.new}).translations
        expect(translations.map(&:last).sort).to eq ["%{count} people", "1 person"]
      end

      it "should not be inferred if given multiple words" do
        translations = call(no_scope, "happy person", {:count => Object.new}).translations
        expect(translations.map(&:last)).to eq ["happy person"]
      end
    end

    it "should accept valid hashes" do
      expect(call(no_scope, {:one => "asdf", :other => "qwerty"}, :count => 1).translations.sort).to eq(
        [["qwerty_98185351.one", "asdf"], ["qwerty_98185351.other", "qwerty"]])
      expect(call(no_scope, :some_stuff, {:one => "asdf", :other => "qwerty"}, :count => 1).translations.sort).to eq(
        [["some_stuff.one", "asdf"], ["some_stuff.other", "qwerty"]])
    end

    it "should reject invalid keys" do
      expect {
        call(no_scope, {:one => "asdf", :twenty => "qwerty"}, :count => 1)
      }.to raise_error(I18nliner::InvalidPluralizationKeyError)
    end

    it "should require essential keys" do
      expect {
        call(no_scope, {:one => "asdf"}, :count => 1)
      }.to raise_error(I18nliner::MissingPluralizationKeyError)
    end

    it "should reject invalid count defaults" do
      expect {
        call(no_scope, {:one => "asdf", :other => Object.new}, :count => 1)
      }.to raise_error(I18nliner::InvalidPluralizationDefaultError)
    end

    it "should complain if no :count is provided" do
      expect {
        call(no_scope, {:one => "asdf", :other => "qwerty"})
      }.to raise_error(I18nliner::MissingCountValueError)
    end
  end

  describe "validation" do
    it "should require all interpolation values" do
      I18nliner.infer_interpolation_values false do
        expect {
          call(no_scope, "asdf %{bob}")
        }.to raise_error(I18nliner::MissingInterpolationValueError)
      end
    end

    it "should require all interpolation values in count defaults" do
      I18nliner.infer_interpolation_values false do
        expect {
          call(no_scope, {:one => "asdf %{bob}", :other => "querty"})
        }.to raise_error(I18nliner::MissingInterpolationValueError)
      end
    end

    it "should ensure option keys are symbols or strings" do
      expect {
        call(no_scope, "hello", {Object.new => "okay"})
      }.to raise_error(I18nliner::InvalidOptionKeyError)
    end
  end
end

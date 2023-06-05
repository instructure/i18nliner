require 'ruby_parser'
require 'i18nliner/errors'
require 'i18nliner/scope'
require 'i18nliner/extractors/ruby_extractor'

describe I18nliner::Extractors::RubyExtractor do
  def extract(source, scope = I18nliner::Scope.new(nil))
    sexps = RubyParser.new.parse(source)
    extractor = I18nliner::Extractors::RubyExtractor.new(sexps, scope)
    translations = []
    extractor.each_translation { |translation| translations << translation }
    Hash[translations]
  end

  def assert_error(*args)
    error = args.pop
    expect {
      extract(*args)
    }.to raise_error(error)
  end

  describe "#each_translation" do
    it "should ignore non-t calls" do
      expect(extract("foo 'Foo'")).to eq({})
    end

    it "should ignore t! calls" do
      expect(extract("t! something")).to eq({})
    end

    it "should not extract t calls with no default" do
      expect(extract("t :foo")).to eq({})
    end

    it "should extract valid t calls" do
      expect(extract("t 'Foo'")).to eq(
        {"foo_f44ad75d" => "Foo"})
      expect(extract("t :bar, 'Baz'")).to eq(
        {"bar" => "Baz"})
      expect(extract("t 'lol', 'wut'")).to eq(
        {"lol" => "wut"})
      expect(extract("translate 'one', {:one => '1', :other => '2'}, :count => 1")).to eq(
        {"one.one" => "1", "one.other" => "2"})
      expect(extract("t({:one => 'just one', :other => 'zomg lots'}, :count => 1)")).to eq(
        {"zomg_lots_a54248c9.one" => "just one", "zomg_lots_a54248c9.other" => "zomg lots"})
      expect(extract("t 'foo2', <<-STR\nFoo\nSTR")).to eq(
        {'foo2' => "Foo"})
      expect(extract("t 'foo', 'F' + 'o' + 'o'")).to eq(
        {'foo' => "Foo"})
    end

    it "should handle omitted values in hashes" do
      expect { extract("t('foo %{count}', count:)") }.not_to raise_error
    end

    it "should bail on invalid t calls" do
      assert_error "t foo", I18nliner::InvalidSignatureError
      assert_error "t :foo, foo", I18nliner::InvalidSignatureError
      assert_error "t :foo, \"hello \#{man}\"", I18nliner::InvalidSignatureError
      assert_error "t :a, \"a\", {}, {}", I18nliner::InvalidSignatureError
      assert_error "t({:one => '1', :other => '2'})", I18nliner::MissingCountValueError
    end
  end
end

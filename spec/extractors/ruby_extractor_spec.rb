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
      extract("foo 'Foo'").should == {}
    end

    it "should ignore t! calls" do
      extract("t! something").should == {}
    end

    it "should not extract t calls with no default" do
      extract("t :foo").should == {}
    end

    it "should extract valid t calls" do
      extract("t 'Foo'").should ==
        {"foo_f44ad75d" => "Foo"}
      extract("t :bar, 'Baz'").should ==
        {"bar" => "Baz"}
      extract("t 'lol', 'wut'").should ==
        {"lol" => "wut"}
      extract("translate 'one', {:one => '1', :other => '2'}, :count => 1").should == 
        {"one.one" => "1", "one.other" => "2"}
      extract("t({:one => 'just one', :other => 'zomg lots'}, :count => 1)").should ==
        {"zomg_lots_a54248c9.one" => "just one", "zomg_lots_a54248c9.other" => "zomg lots"}
      extract("t 'foo2', <<-STR\nFoo\nSTR").should ==
        {'foo2' => "Foo"}
      extract("t 'foo', 'F' + 'o' + 'o'").should ==
        {'foo' => "Foo"}
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

require 'i18nliner/extensions/inferpolation'
require 'ostruct'

describe I18nliner::Extensions::Inferpolation do

  let(:foo) do
    foo = OpenStruct.new(:bar => OpenStruct.new(:baz => "lol"), :bar2 => "foo")
    foo.instance_variable_set(:@bar, foo.bar)
    foo.instance_variable_set(:@bar2, "foo")
    foo.extend I18nliner::Extensions::Inferpolation
    foo
  end

  it "should inferpolate valid instance methods and chains" do
    options = {:default => "hello %{bar.baz} %{bar2}"}
    foo.inferpolate(options).should == {
      :default => "hello %{bar_baz} %{bar2}",
      :bar_baz => foo.bar.baz,
      :bar2 => foo.bar2
    }
  end

  it "should inferpolate valid instance variables and chains" do
    options = {:default => "hello %{@bar.baz} %{@bar2}"}
    foo.inferpolate(options).should == {
      :default => "hello %{bar_baz} %{bar2}",
      :bar_baz => foo.bar.baz,
      :bar2 => foo.bar2
    }
  end

  it "should not inferpolate invalid instance methods and chains" do
    options = {:default => "hello %{lol} %{bar.baz.lol}"}
    foo.inferpolate(options).should == options
  end

  it "should not inferpolate invalid instance variables and chains" do
    options = {:default => "hello %{@lol} %{@bar.baz.lol}"}
    foo.inferpolate(options).should == options
  end
end

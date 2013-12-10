require 'i18nliner/extensions/inferpolation'
require 'ostruct'

describe I18nliner::Extensions::Inferpolation do
  
  let(:foo) do
    foo = OpenStruct.new(:bar => OpenStruct.new(:baz => "lol"))
    foo.instance_variable_set(:@bar, foo.bar)
    foo.extend I18nliner::Extensions::Inferpolation
    foo
  end

  it "should inferpolate valid instance method chains" do
    options = {:default => "hello %{bar.baz}"}
    foo.inferpolate(options).should == {
      :default => "hello %{bar_baz}",
      :bar_baz => foo.bar.baz
    }
  end

  it "should inferpolate valid instance variable chains" do
    options = {:default => "hello %{@bar.baz}"}
    foo.inferpolate(options).should == {
      :default => "hello %{bar_baz}",
      :bar_baz => foo.bar.baz
    }
  end

  it "should not inferpolate invalid instance method chains" do
    options = {:default => "hello %{lol} %{bar.baz.lol}"}
    foo.inferpolate(options).should == options
  end

  it "should not inferpolate invalid instance variable chains" do
    options = {:default => "hello %{@lol} %{@bar.baz.lol}"}
    foo.inferpolate(options).should == options
  end
end

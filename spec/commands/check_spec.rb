require 'i18nliner/commands/check'

describe I18nliner::Commands::Check do
  describe ".run" do

    around do |example|
      I18nliner.base_path "spec/fixtures" do
        example.run
      end
    end

    it "should find errors" do
      allow(I18nliner).to receive(:manual_translations).and_return({})
      checker = I18nliner::Commands::Check.new({:silent => true})
      checker.check_files
      checker.translations.values.should == ["welcome, %{name}", "Hello World", "*This* is a test, %{user}"]
      checker.errors.size.should == 2
      checker.errors.each do |error|
        error.should =~ /\Ainvalid signature/
      end
    end
  end
end

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
      expect(checker.translations.values).to eq ["welcome, %{name}", "Hello World", "*This* is a test, %{user}"]
      expect(checker.errors.size).to eq 2
      checker.errors.each do |error|
        expect(error).to match /\Ainvalid signature/
      end
    end
  end
end

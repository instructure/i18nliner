require 'i18nliner/processors/ruby_processor'
require 'i18nliner/extractors/translation_hash'
require 'i18nliner/scope'

describe I18nliner::Processors::RubyProcessor do
  before do
    @translations = I18nliner::Extractors::TranslationHash.new
    @processor = I18nliner::Processors::RubyProcessor.new(@translations)
  end

  describe "#scope_for" do
    if defined?(::Rails) && ::Rails.version > '4'
      context "with a controller" do
        subject { @processor.scope_for("app/controllers/foos/bars_controller.rb") }

        specify { expect(subject).to be_allow_relative }
        specify { expect(subject.scope).to eq "foos.bars." }
      end
    end

    context "with any old ruby file" do
      subject { @processor.scope_for("foo.rb") }

      specify { expect(subject).to be I18nliner::Scope.root }
    end
  end
end


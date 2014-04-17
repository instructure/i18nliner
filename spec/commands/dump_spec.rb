# encoding: UTF-8
require 'i18nliner/commands/dump'
require 'i18nliner/extractors/translation_hash'
require 'tmpdir'

describe I18nliner::Commands::Dump do
  describe ".run" do

    around do |example|
      Dir.mktmpdir do |dir|
        I18nliner.base_path dir do
          example.run
        end
      end
    end

    it "should dump translations in utf8" do
      translations = I18nliner::Extractors::TranslationHash.new('i18n' => "Iñtërnâtiônàlizætiøn")
      dumper = I18nliner::Commands::Dump.new({:silent => true, :translations => translations})
      dumper.run
      File.read(dumper.yml_file).gsub(/\s+$/, '').should == <<-YML.strip_heredoc.strip
        ---
        #{I18n.default_locale}:
          i18n: Iñtërnâtiônàlizætiøn
      YML
    end
  end
end


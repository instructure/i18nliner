# encoding: UTF-8
require 'i18nliner/commands/dump'
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
      dumper = I18nliner::Commands::Dump.new({:silent => true, :translations => {'i18n' => "Iñtërnâtiônàlizætiøn"}})
      dumper.run
      File.read(dumper.yml_file).gsub(/\s+$/, '').should == <<-YML.strip_heredoc.strip
        ---
        #{I18n.default_locale}:
          i18n: Iñtërnâtiônàlizætiøn
      YML
    end
  end
end


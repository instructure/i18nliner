namespace :i18nliner do
  desc "Verifies all translation calls"
  task :check => :environment do
    require 'i18nliner/commands/check'

    options = {:only => ENV['ONLY']}
    @command = I18nliner::Commands::Check.run(options)
    @command.success? or exit 1
  end

  desc "Generates a new [default_locale].yml file for all translations"
  task :dump => :check do
    require 'i18nliner/commands/dump'

    options = {:translations => @command.translations, :file => ENV['YML_FILE']}
    @command = I18nliner::Commands::Dump.run(options)
    @command.success? or exit 1
  end
end


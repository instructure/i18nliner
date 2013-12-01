namespace :i18nliner do
  desc "Verifies all translation calls"
  task :check => :environment do
    options = {:only => ENV['ONLY'])}
    @command = I18nliner::Commands::Check.run(options) or exit 1
  end

  desc "Generates a new [default_locale].yml file for all translations"
  task :dump => :check do
    options = {:translations => @command.translations}
    @command = I18nliner::Commands::Dump.run(options) or exit 1
  end
end


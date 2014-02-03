ENV['RAILS_ENV'] ||= 'test'
ENV['SKIP_RAILS_ADMIN_INITIALIZER'] = 'false'

require File.expand_path("../dummy_app/config/environment.rb",  __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'factory_girl_rails'
require 'faker'
require 'capybara/rspec'
require 'devise'
require 'warden'
require 'capybara/poltergeist'

Rails.backtrace_cleaner.remove_silencers!
Capybara.javascript_driver = :poltergeist

#For debugging purposes:
#http://www.jonathanleighton.com/articles/2012/poltergeist-0-6-0/
# Capybara.register_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new(app, inspector: true)
#    #page.driver.debug
# end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Capybara::DSL
  config.mock_with :rspec
  config.infer_base_class_for_anonymous_controllers = false
  config.include Devise::TestHelpers, :type => :controller
  config.order = "random"
  
  # for focusing
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    DatabaseCleaner.strategy = (example.metadata[:js]) ? :truncation : :transaction

    DatabaseCleaner.start
    RailsAdmin::Config.reset
    RailsAdmin.config do |c|
      c.included_models = Basepack::Utils.detect_models
    end
    RailsAdmin::AbstractModel.reset
    RailsAdmin::Config.yell_for_non_accessible_fields = false
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # config.before(:each) do
    #Warden.test_mode!
    #user = FactoryGirl.create(:user)
    #login_as(user, :scope => :user)

    # sign_in(user, :scope => :user)
  # end
  # config.after(:each) do
  #   Warden.test_reset!
  # end


  config.include BasepackHelper #, type: :feature
end



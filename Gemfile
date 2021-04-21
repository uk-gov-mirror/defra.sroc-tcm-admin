# frozen_string_literal: true

source "https://rubygems.org"
ruby "2.7.1"

# Rails must be v6.1.3.1 or greater to avoid the issue around earlier versions of mimemagic and its use of GPL licensed
# data. See https://github.com/rails/rails/issues/41750 and https://github.com/DEFRA/sroc-tcm-admin/pull/405 for more
# details
gem "rails", ">= 6.1.3.1"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.2"

gem "aws-sdk", "~> 2"
# bootstrap 4
gem "bootstrap", "~> 4.3.1"
gem "bstard"
gem "devise"
gem "devise_invitable"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# jquery needed by bootstrap for rails 5.1+
gem "jquery-rails"
gem "jquery-ui-rails"
gem "kaminari"
# Wrapper for the OAuth 2.0 specification (https://oauth.net/2/). Needed to
# authenticate with the Charging Module API
gem "oauth2"
gem "rails-i18n"
# Use Redis adapter to run Action Cable in production
gem "redis", "~> 3.2"
gem "resque"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
gem "secure_headers"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
gem "whenever", require: false

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"

group :production do
  gem "airbrake", "~> 11.0"
  # Use passenger as the app server in production. The environment web-ops have
  # built currently expects this to be the case
  gem "passenger", "~> 5.1", require: false
end

group :development do
  # Manages our rubocop style rules for all defra ruby projects
  gem "defra_ruby_style"
  gem "listen", ">= 3.0.5", "< 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "web-console"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug"
  # Shim to load environment variables from a .env file into ENV in development
  # and test
  gem "dotenv-rails"
  # Use Puma as the app server in development as test
  gem "puma"
  # Project uses RSpec as its test framework
  gem "rspec-rails"
end

group :test do
  gem "capybara"
  gem "capybara-selenium"
  # Needed because the existing minitest suite leaves data in the DB which interferes with the rspec tests
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
  gem "mocha"
  gem "rails-controller-testing"
  gem "selenium-webdriver"
  # Generates a test coverage report on every `bundle exec rspec` call. We use
  # the output to feed SonarCloud's stats and analysis. It does not yet support
  # v0.18 hence locked to 0.17
  gem "simplecov", "~> 0.17.1", require: false
  # Stubbing HTTP requests
  gem "webmock"
end

# frozen_string_literal: true

source "https://rubygems.org"
ruby "2.7.1"

# Temporarily commented out due to the issue caused by mimemagic, a dependency of activestorage being yanked from
# RubyGems. See https://github.com/rails/rails/issues/41750
# Referencing the rails dependencies directly was inspired by
# https://github.com/DFE-Digital/early-careers-framework/pull/178
# gem "rails", "~> 6.0.3"
# These rails gems need to be commented out to avoid bringing mimemagic in
# activestorage is the gem that has a dependency on marcel, which has the dependency on mimemagic
# gem "activestorage", "~> 6.0.3"
# actionmailbox and actiontext both have a dependency on activestorage
# gem "actionmailbox", "~> 6.0.3"
# gem "actiontext", "~> 6.0.3"
gem "actioncable", "~> 6.0.3"
gem "actionmailer", "~> 6.0.3"
gem "actionpack", "~> 6.0.3"
gem "actionview", "~> 6.0.3"
gem "activejob", "~> 6.0.3"
gem "activemodel", "~> 6.0.3"
gem "activerecord", "~> 6.0.3"
gem "activesupport", "~> 6.0.3"
gem "bundler", ">= 1.3.0"
gem "railties", "~> 6.0.3"
gem "sprockets-rails", ">= 2.0.0"

# Use postgresql as the database for Active Record
gem "pg", "~> 0.18"

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
  gem "factory_bot_rails", "~> 4.0"
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

group :benchmark do
  gem "benchmark-ips"
  gem "flamegraph"
  gem "memory_profiler"
  gem "rack-mini-profiler"
  gem "stackprof"
end

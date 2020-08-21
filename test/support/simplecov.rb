# frozen_string_literal: true

require "simplecov"

# We start it with the rails param to ensure it includes coverage for all code
# started by the rails app, and not just the files touched by our unit tests.
# This gives us the most accurate assessment of our unit test coverage
# https://github.com/colszowka/simplecov#getting-started
SimpleCov.start("rails") do
  # We filter the tests folders, mainly to ensure that any dummy apps don't get
  # included in the coverage report. However our intent is that nothing in the
  # test folders should be included
  add_filter "/spec/"
  add_filter "/test/"

  # Our db folder contains migrations and seeding, functionality we are ok not
  # to have tests for
  add_filter "/db/"

  add_group "Forms", "app/forms"
  add_group "Helpers", "app/helpers"
  add_group "Jobs", "app/jobs"
  add_group "Lib", "app/lib"
  add_group "Mailers", "app/mailers"
  add_group "Presenters", "app/presenters"
  add_group "Services", "app/services"
  add_group "Validators", "app/validators"
  add_group "Tasks", "lib/tasks"
end

# Use test suite name to help simplecov merge minitest and rspec results
# https://github.com/simplecov-ruby/simplecov#test-suite-names
SimpleCov.command_name "test:unit:mini"

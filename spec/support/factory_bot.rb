# frozen_string_literal: true

require "factory_bot_rails"

FactoryBot.automatically_define_enum_traits = false

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

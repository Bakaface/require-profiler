# frozen_string_literal: true

require "rails"

class SlowApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(IO::NULL)

  initializer :slow_initializer do
    require "leaf_a"
  end

  config.to_prepare do
    require "leaf_b"
  end

  config.after_initialize do
    require "leaf_c"
  end
end

Rails.application.initialize!

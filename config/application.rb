# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Only the frameworks the app uses. Mailer, Mailbox, Action Text, Active
# Storage and Action Cable are not loaded, which also keeps their advisories
# out of the running process.
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FtfAssessment
  class Application < Rails::Application
    config.load_defaults 8.1
  end
end

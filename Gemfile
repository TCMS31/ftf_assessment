# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'bootsnap', require: false
gem 'importmap-rails', '~> 2.2'
# Used by WikipediaClient to extract article paragraphs. It arrives transitively
# via rails-html-sanitizer, but the app requires it directly, so declare it.
gem 'nokogiri', '~> 1.19'
gem 'pg', '~> 1.7'
gem 'puma', '~> 8.0'
gem 'rails', '~> 8.1.4'
gem 'sprockets-rails', '~> 3.5'
gem 'stimulus-rails', '~> 1.3'
gem 'turbo-rails', '~> 2.0'
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'rubocop', require: false
end

group :test do
  gem 'rspec-rails', '~> 8.1'
  gem 'shoulda-matchers', '~> 8.0'
  # Blocks real HTTP from the suite and lets the Wikipedia client be tested
  # against fixed responses.
  gem 'webmock', '~> 3.34'
end

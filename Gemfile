# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.3'

gem 'bootsnap', require: false
gem 'importmap-rails'
# Used by WikipediaClient to extract article paragraphs. It arrives transitively
# via rails-html-sanitizer, but the app requires it directly, so declare it.
gem 'nokogiri', '~> 1.15'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'
gem 'rails', '~> 7.0.5'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'rubocop', require: false
end

group :test do
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  # Blocks real HTTP from the suite and lets the Wikipedia client be tested
  # against fixed responses.
  gem 'webmock'
end

# Gemfile
source 'https://rubygems.org'
ruby '3.2.2'

gem 'rails', '~> 7.1.0'

# Core
gem 'pg', '~> 1.5'
gem 'redis', '~> 5.0'
gem 'puma', '~> 6.0'

# Authentication & Authorization
gem 'devise', '~> 4.9'
gem 'pundit', '~> 2.3'
gem 'rolify', '~> 6.0'

# API
gem 'graphql', '~> 2.0'
gem 'graphiql-rails', '~> 2.0', group: :development
gem 'jbuilder', '~> 2.11'

# Real-time
gem 'actioncable', '~> 7.1'
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.2'

# Background Processing
gem 'sidekiq', '~> 7.1'
gem 'sidekiq-cron', '~> 1.10'
gem 'connection_pool', '~> 2.3'

# File Uploads
gem 'shrine', '~> 3.0'
gem 'aws-sdk-s3', '~> 1.120', require: false

# Payments
gem 'stripe', '~> 10.0'
gem 'pay', '~> 7.0'

# Analytics & UI
gem 'chartkick', '~> 5.0'
gem 'groupdate', '~> 6.0'
gem 'tailwindcss-rails', '~> 2.0'
gem 'view_component', '~> 3.0'

# Testing
gem 'rspec-rails', '~> 6.0'
gem 'factory_bot_rails', '~> 6.4'
gem 'capybara', '~> 3.39'
gem 'selenium-webdriver', '~> 4.10'
gem 'webdrivers', '~> 5.3'
gem 'shoulda-matchers', '~> 5.3'
gem 'simplecov', '~> 0.22', require: false

# Production
gem 'lograge', '~> 1.0'
gem 'sentry-rails', '~> 5.12'
gem 'sentry-ruby', '~> 5.12'
gem 'rack-attack', '~> 6.7'
gem 'brakeman', '~> 6.0', require: false

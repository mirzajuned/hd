source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
ruby '2.7.2'
gem 'rails', '~> 5.2', '>= 5.2.4.5'
gem 'responders', '~> 2.4'

gem 'json', '~> 2.5', '>= 2.5.1'

gem 'haml', '~> 5.0', '>= 5.0.4'
gem 'moment_timezone-rails', '~> 0.5.0'
gem 'momentjs-rails'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0', '>= 5.0.6'
# gem 'mongoid_paranoia'
# gem added to test features of chartkick
# gem 'active_median', '~> 0.1.0'

# gem 'wisper', '2.0.0'
# gem 'wisper-sidekiq', '~> 0.0.1'
#gem 'wisper-celluloid', '~> 0.0.1'

gem 'intl-tel-input-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.2', '>= 4.2.2'
gem 'rqrcode_png', '~> 0.1.5'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', '~> 0.12.3', platforms: :ruby

gem 'execjs', '2.7.0'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.3', '>= 4.3.1'
gem 'time_difference', '~> 0.4.2'

gem 'simple_form', '~> 5.1'

gem 'remotipart', '~> 1.3', '>= 1.3.1'
gem 'smarter_csv', '~> 1.1', '>= 1.1.4'

gem 'auto-session-timeout', '~> 0.9.2'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'carrierwave', '~> 0.11.2'
# gem 'carrierwave', '~> 1.3.2'
gem 'hashie', '~> 3.4', '>= 3.4.6'
gem 'turbolinks', '~> 5.0.1'
gem 'ventable', '~> 1.0'
gem 'wicked_pdf', '~> 1.1'
# gem 'wkhtmltopdf-binary-edge', '~> 0.12.3.0' # 0.12.3.0 , 0.12.2.1
group :development, :production do
  gem 'wkhtmltopdf-binary-edge', '~> 0.12.3.0' # 0.12.3.0 , 0.12.2.1
end
# gem 'carrierwave-base64','~> 2.6.1'
# gem 'carrierwave-data-uri','~> 0.2.0'
gem 'erubis', '~> 2.7'
gem 'fiscali', '~> 2.4', '>= 2.4.3'
gem 'global', '~> 0.1.2'
gem 'inline_svg', '~> 0.11.1'
gem 'mongoid-ancestry', '~> 0.4.2'

# Mongoid
gem 'bson', '~> 4.12'
gem 'mongo', '~> 2.14'
gem 'mongoid', '~> 7.2', '>= 7.2.1'

gem 'rqrcode'

gem 'barby', '~> 0.6.2'

gem 'axlsx', git: 'https://github.com/randym/axlsx.git', ref: 'c8ac844'
gem 'caxlsx_rails'
gem 'rubyzip', '>= 1.2.1'

gem 'ipaddr', '~> 1.2'

gem 'apipie-rails', '~> 0.5.4'
gem 'carrierwave-mongoid', '~> 1.3'
gem 'nested_form', '~> 0.3.2'
# gem 'faker', git: 'https://github.com/stympy/faker'
gem 'faker', '~> 2.6'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.6', '>= 2.6.1'
gem 'lockup'
gem 'pry-rails', '~> 0.3.4', group: :development

group :development, :test, :cicd1, :cicd2, :cicd3, :qa1, :qa2, :qa3, :qa4, :qa5, :qa6, :qa7, :qa8, :qa9, :qa10, :uat, :preprod, :stage, :preproduction do
  gem 'fast_stack', '~> 0.2.0'
  gem 'flamegraph', '~> 0.9.5'
  gem 'memory_profiler', '~> 0.9.7'
  gem 'rack-mini-profiler', '~> 0.10.1'
  gem 'stackprof', '~> 0.2.10'
end

gem 'will_paginate', '~> 3.1', '>= 3.1.5'

gem 'data-confirm-modal', '~> 1.3'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', '~> 2.0', '>= 2.0.4', require: false
end

group :development, :test do
  # gem 'factory_bot_rails' # removed from development to only test.
  gem 'jasmine', '~> 2.5', '>= 2.5.1'
  gem 'letter_opener', '~> 1.4.1'
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 3.5', '>= 3.5.2'
  # for running js with capybara
  gem 'chromedriver-helper', '~> 1.0'
  gem 'selenium-webdriver', '~> 3.0', '>= 3.0.5'
  # for performance testing
  gem 'bullet', '~> 5.5'
  gem 'byebug', '~> 11.1', '>= 11.1.3'
  gem 'ffi', '~> 1.15.4'
  gem 'meta_request', '~> 0.7.2'
  gem 'puma', '~> 5.5.2'

  gem 'rubocop', '~> 0.80.0'
  gem 'rubocop-performance'

  gem 'erb_lint', require: false

  gem 'brakeman', '~> 5.1', '>= 5.1.1'
  gem 'bundle-audit', '~> 0.1.0'
  # The word "Pentest" is taken from penetration testing, which simulates cyberattacks
  # This gem loads controller methods of Rails project and cracks against it.
  gem 'pentest'
end

group :test do
  # gem 'shoulda-matchers', require: false  #gem was removed by rakesh, because it was buggy
  gem 'capybara', '~> 2.12'
  gem 'database_cleaner', '~> 1.5', '>= 1.5.3'
  gem 'factory_bot_rails'
  # gem 'factory_girl_rails', '~> 4.8', require: false
  gem 'guard-rspec', '~> 4.7', '>= 4.7.3'
  gem 'launchy', '~> 2.4', '>= 2.4.3'
  gem 'rspec-benchmark', '~> 0.3.0'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'simplecov', require: false
  gem 'state_machines_rspec', '~> 0.3.2'
  # gem 'mongoid-rspec', '~> 3.0'     not compatible with mongo 6 "https://github.com/mongoid/mongoid-rspec/issues/169"
end

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1', '>= 3.1.11'
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
gem 'unicorn', '~> 5.8'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'authority', '~> 3.2', '>= 3.2.2'
# gem 'nokogiri', '~> 1.7', '>= 1.7.0.1'
gem 'nokogiri', '>= 1.11.4'
gem 'rmagick', '~> 4.2', '>= 4.2.2'
gem 'rolify', '~> 5.1'

gem 'mime-types', '~> 3.1'
gem 'mini_magick', '~> 4.6'

gem 'sidekiq', '~> 6.0', '>= 6.0.7'

gem 'whenever', '~> 1.0'

gem 'state_machine', '~> 1.2'
gem 'state_machines', '~> 0.5.0'
gem 'state_machines-audit_trail', '~> 1.0', '>= 1.0.2'

gem 'enumerize', '~> 2.4.0'
gem 'state_machines-mongoid', '~> 0.2.0'

# Use redis as session store
gem 'redis-rails', '~> 5.0', '>= 5.0.1'
gem 'redis-session-store', '~> 0.11.1'
# gem 'redis-store', '~> 1.3.0'
gem 'redis-store', '>= 1.4.0'

gem 'newrelic-infinite_tracing', '~> 7.1'
gem 'newrelic_rpm', '~> 7.1'

# for client side validations
gem 'client_side_validations', '~> 18.0'
gem 'client_side_validations-simple_form', '~> 12.1'
gem 'dicom', '~> 0.9.7'
gem 'jquery-validation-rails'

gem 'high_voltage', '~> 3.0'
gem 'spreadsheet', '~> 1.1', '>= 1.1.4'
gem "roo", "~> 2.8.0"

gem 'fog-aws', '~> 0.8.1'

gem 'searchkick', '~> 4.3'

gem 'exception_notification', '~> 4.2', '>= 4.2.1'
gem 'gcm', '~> 0.1.1'
gem 'jquery-fileupload-rails', '~> 0.4.7'

# This gem loads environment variables as per your environments
gem 'dotenv-rails', '~> 2.2', '>= 2.2.1'

gem 'redis', '4.1.3'

gem 'rails-assets-jquery-textcomplete', source: 'https://rails-assets.org'

gem 'aws-sdk', '~> 2.10.25' # tHIS IS TO ACCESS AWS FOR RUBY

gem 'unicorn-worker-killer', '~> 0.4.4'

gem 'doorkeeper-mongodb', '~> 4.1'

gem 'rest-client', '~> 2.0', '>= 2.0.2'

# for times in different timezones
gem 'tzinfo', '~> 1.2', '>= 1.2.2'

# for analytics date calculation
gem 'date_breakup', '~> 2.0' # developed by Huzi

# captcha to protect your sites from fraudulent activities, spam, and abuse.
gem 'recaptcha', '5.8.1'

source 'http://rubygems.org'


### Basic
gem 'rack', '1.3.5'
gem 'rack-cache'
gem 'rake', '0.9.2.2'
gem 'rails', '3.1.3'
gem 'bundler', '>= 1.0.0'
gem 'thin', :require => false

### Database Adapter
# Using Postgresql for all environments.
gem 'pg'

### Roles and Authentication
gem 'cancan' 
gem 'devise' # Devise must be required before RailsAdmin

### Versioning
gem 'paper_trail'

### Views
gem 'kaminari'
gem 'squeel'

### File Uploading and Image Processing
gem 'mini_magick', '3.3'
gem 'fog'
gem 'carrierwave'

### S3 Asset hosting
gem "asset_sync"

### Parsing
gem 'nokogiri'

### Permalink
# gem 'RedCloth'
gem 'stringex'
gem 'friendly_id', '~> 4.0.0'

### Comment System
gem 'opinio', '~> 0.3.3'
gem 'rakismet'

### Queue
gem 'resque'
# gem 'resque-timeout', '1.0.0'
# gem 'resque-ensure-connected'
# gem 'SystemTimer', '1.2.1', :platforms => :ruby_18 #(not using ruby 1.8)

### ASYNC Mailing
# gem 'mail'
# gem 'resque_mailer'

gem "libv8"
gem "execjs"
gem "therubyracer", :require => 'v8'
gem 'json'
gem 'sass'
gem 'sass-rails',   '~> 3.1.5'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

# jQuery
gem 'jquery-rails'

# Search and Indexing
# gem 'sunspot'
# gem 'sunspot_rails'
# gem 'sunspot_solr' # optional pre-packaged Solr distribution for use in development
# gem 'sunspot_with_kaminari'


# Settings
gem 'rails-settings-cached', "0.1.2", :require => 'rails-settings'
    # :git => 'git://github.com/huacnlee/rails-settings-cached.git'

### i18n Translation on DB
gem 'i18n-active_record',
    :require => 'i18n/active_record',
    :git => 'git://github.com/svenfuchs/i18n-active_record.git'

  
group :development do
  gem 'rspec', "2.8.0"
  gem "rspec-rails", "2.8.1"
  gem 'nifty-generators'
  gem 'hirb'
  # Nice progress when rake indexing with solr
  gem 'progress_bar'
  gem 'foreman'
end

group :test do
  gem 'webrat', "0.7.3"
  gem 'rspec', "2.8.0"
  gem "rspec-rails", "2.8.1"
  gem "factory_girl", "~> 2.5.0"
  gem "factory_girl_rails", '~> 1.6.0'
  gem "cucumber-rails", ">= 1.0.2"
  gem "capybara", ">= 1.0.1"
  gem "database_cleaner", ">= 0.6.7"
  gem "launchy", ">= 2.0.5"
  gem "sqlite3"
  gem 'autotest'
  gem 'autotest-rails'
  gem 'sunspot_test'
  gem 'turn', '~> 0.8.3', :require => false
end



### Active Admin, loaded at end. 
gem "meta_search", '1.1.1'
gem 'activeadmin', :git => "git://github.com/gregbell/active_admin.git"

gem 'tinymce-rails'

# Twitter Bootstrap for Rails 3.1 Asset Pipeline
gem 'twitter-bootstrap-rails', "1.4.3"
  # :git => "git://github.com/seyhunak/twitter-bootstrap-rails.git"

# Error Emails
gem "exception_notification", :require => 'exception_notifier',
  :git => "git://github.com/smartinez87/exception_notification.git"


###############
## Searching ##
###############

gem 'sunspot', "2.0.0.pre.111215" #:git => "git://github.com/sunspot/sunspot.git"
gem 'sunspot_rails', "2.0.0.pre.111215" #:git => "git://github.com/sunspot/sunspot.git"

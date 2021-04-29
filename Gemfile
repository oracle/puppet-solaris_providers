source ENV['GEM_SOURCE'] || "https://rubygems.org"

group(:development, :test) do
  gem 'metadata-json-lint'
  gem 'puppet-blacksmith'
  gem 'puppetlabs_spec_helper', :require => true
  gem 'rspec-puppet', :require => true
  gem 'rspec', :require => false
  gem 'rake', '>= 12.3.3', :require => false
  gem 'pry', :require => false
  gem 'pry-rescue', :require => false
  gem 'pry-stack_explorer', :require => false
  gem 'psych', :require => false
  gem 'puppet', '4.7.0', :require => true
  gem 'pkg-config', :require => false
  gem 'semantic_puppet'
  # Docs
  gem 'puppet-strings'
  gem 'redcarpet'
end

gem "rubocop", ">= 0.49.0", :platforms => [:ruby]
gem 'beaker', '~> 2.0', :require => false, :group => :acceptance
gem 'beaker-rspec', '5.6.0', :require => false, :group => :acceptance

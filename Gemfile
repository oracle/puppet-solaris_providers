source ENV['GEM_SOURCE'] || "https://rubygems.org"

group(:development) do
  gem 'puppet-blacksmith'
  gem 'pry', :require => false
  gem 'pry-rescue', :require => false
  gem 'pry-stack_explorer', :require => false
  # Code style
  gem 'rubocop', '>= 0.49.0', :platforms => [:ruby]
  # Docs
  gem 'puppet-strings'
  gem 'redcarpet'
end

group(:development, :test) do
  gem 'metadata-json-lint'
  gem 'puppetlabs_spec_helper', :require => true
  gem 'rspec-puppet', :require => true
  gem 'rspec', :require => false
  gem 'rake', '>= 13.4.2', :require => false
  gem 'puppet', '7.27.0', :require => true
  gem 'base64', :require => false
  gem 'ffi', :require => false
  gem 'getoptlong', :require => false
  gem 'racc', :require => false
  gem 'syslog', :require => false
end

group(:acceptance, :optional => true) do
  gem 'beaker', '~> 2.0', :require => false
  gem 'beaker-rspec', '5.6.0', :require => false
end

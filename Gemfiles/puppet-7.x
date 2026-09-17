source ENV['GEM_SOURCE'] || "https://rubygems.org"

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

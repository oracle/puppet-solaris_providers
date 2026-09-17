source ENV['GEM_SOURCE'] || "https://rubygems.org"

group(:development, :test) do
  gem 'metadata-json-lint'
  gem 'puppetlabs_spec_helper', :require => true
  gem 'rspec-puppet', :require => true
  gem 'rspec', :require => false
  gem 'rake', '>= 12.3.3', :require => false
  gem 'puppet', '5.5.21', :require => true
end

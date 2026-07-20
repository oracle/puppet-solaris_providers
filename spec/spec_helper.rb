require 'facter'
require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

begin
  require 'pry'
rescue LoadError
  # We mostly don't care if this fails unless
  # we added a call to binding.pry in code for testing
end

RSpec.configure do |config|
  config.mock_with :mocha
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # Facter 4 may resolve provider-selection facts after specs install strict
  # FileTest stubs for Solaris binaries. Resolve and cache those facts first so
  # Facter does not inspect its own fact files while the stubs are active.
  config.before(:suite) do
    if Gem::Version.new(Facter.version) >= Gem::Version.new('4.0.0')
      %i[operatingsystem osfamily kernelrelease].each do |fact|
        Puppet.runtime[:facter].value(fact)
      end
    end
  end
end

include Mocha::API
mocha_setup

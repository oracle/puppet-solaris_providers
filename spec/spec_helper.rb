#dir = File.expand_path(File.dirname(__FILE__))
#$LOAD_PATH.unshift File.join(dir, 'lib')
require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
#    config.mock_with :mocha
    config.example_status_persistence_file_path = 'spec/examples.txt'
end

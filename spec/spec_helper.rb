require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'pry'

RSpec.configure do |config|
    config.mock_with :mocha
    config.example_status_persistence_file_path = 'spec/examples.txt'
end

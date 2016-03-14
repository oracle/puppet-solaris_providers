dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(dir, 'lib')

RSpec.configure do |config|
    config.mock_with :mocha
    # Support old :should syntax
    config.expect_with(:rspec) { |c| c.syntax = :should }
end

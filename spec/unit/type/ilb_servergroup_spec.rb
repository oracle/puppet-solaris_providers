require 'spec_helper'

describe Puppet::Type.type(:ilb_servergroup) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "sg1",
      :ensure => :present,
    }
      end

  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }


  let(:error_pattern) { /Invalid/ }

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end
end

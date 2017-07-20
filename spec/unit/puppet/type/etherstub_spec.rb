require 'spec_helper'

describe Puppet::Type.type(:etherstub) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "es1",
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

  describe "parameter" do
    [:name].each { |type|
      context "accepts #{type}" do
        (%w(s1 es1 es1.1 es1_1) << ("a" * 31 << "1")).
          each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        (%w(es1-1 es1/1 e$1) << ("a" * 32 << "1")).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:temporary].each { |type|
      context "accepts #{type}" do
        %w(true false).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(yes no).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
  end
end

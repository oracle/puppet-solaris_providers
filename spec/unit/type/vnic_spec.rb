require 'spec_helper'

describe Puppet::Type.type(:vnic) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "vnic1",
      :ensure => :present,
      :lower_link => 'net1',
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

  describe "has property" do
    [ :lower_link, :mac_address ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
    end

  describe "parameter" do
    [:name].each { |type|
      context "accepts #{type}" do
        %w(ne1 net1 net10 vnic1/net1 foo-ab1/net1).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(n$t1 net n1 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:mac_address].each { |type|
      context "accepts #{type}" do
        %w(a1:b2:c3:d4:e5:f6).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(zz:b2:c3:d4:e5:f6).each do |thing|
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

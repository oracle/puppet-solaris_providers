require 'spec_helper'

describe Puppet::Type.type(:boot_environment) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "be1",
      :ensure => :present,
      :description => 'new be',
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
    [ :activate, ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
    end

  describe "parameter" do
    [:name].each { |type|
      context "accepts #{type}" do
        %w(be e1.1-test:2_2).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(be$1 ^bad test&fail).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:activate].each { |type|
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
    [:options].each { |type|
      context "accepts #{type}" do
        [
          {"aclinherit" => "passthrough-mode-preserve" },
          {
            "aclinherit" => "passthrough-mode-preserve",
            "share.auto" => "off"
          }
        ].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        [
          "some string",
          %w(an array),
          {
            "inv&lid" => "passthrough-mode-preserve",
          }
        ].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }

    [:description, :clone_be, :zpool].each do |type|
      # These parameters currently have no validation
      # it should be added and verified
      context "accepts #{type}" do
        %w(something).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(someth!ng).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    end
  end
end

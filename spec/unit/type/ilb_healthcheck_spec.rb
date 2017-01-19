require 'spec_helper'

describe Puppet::Type.type(:ilb_healthcheck) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "hc1",
      :ensure => :present,
      :timeout => '10',
      :count => '3',
      :interval => '90',
      :test => 'tcp'
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
    [ :ensure, :timeout, :count, :interval, :test,
      :default_ping].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
    end

  describe "parameter validation" do
    %w( timeout count interval ).each { |type|
      context "accepts #{type}" do
        %w( 0 1 10 100 ).each do |thing|
          it thing.inspect do
            params[:timeout] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w( 0.5 a one 10.5 ).each do |thing|
          it thing.inspect do
            params[:timeout] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }

    context "accepts test" do
      %w(
        tcp udp /fully/qual/path
      ).each do |thing|
        it thing.inspect do
          params[:test] = thing
          expect { resource }.not_to raise_error
        end
      end
    end
    context "rejects test" do
      %w(
        ssh non/qual/path
      ).each do |thing|
        it thing.inspect do
          params[:test] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end
    end
    context "accepts default_ping" do
      [:true,:false].each { |thing|
        it thing.inspect do
          params[:default_ping] = thing
          expect { resource }.not_to raise_error
        end
      }
    end
    context "rejects default_ping" do
      ["no","ok",0].each { |thing|
        it thing.inspect do
          params[:default_ping] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      }
    end
  end
end


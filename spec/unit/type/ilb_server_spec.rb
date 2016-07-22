#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:ilb_server) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "sg1:localhost:2000-2100",
      :ensure => :present
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
    [ :server, :port ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
  end

  describe "parameter validation" do
    context "accepts server" do
      %w(
           foo.com
           1.2.3.4
           [fe80::3e07:54ff:fe53:c704]
           fe80::3e07:54ff:fe53:c704
      ).each do |thing|
        it thing.inspect do
          params[:server] = thing
          expect { resource }.not_to raise_error
        end
      end
    end # Accepts Server
    context "rejects server" do
      %w(
           foo..com
           1.2.3.256
      ).each do |thing|
        it thing.inspect do
          params[:server] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end
    end # Rejects Server
    context "accepts port" do
      %w(
           80
           http
           2048-3000
      ).each do |thing|
        it thing.inspect do
          params[:port] = thing
          expect { resource }.not_to raise_error
        end
      end
    end # Accepts Port
    context "rejects port" do
      %w(
           2048:3000
           -1
           65536
           80-65536
           -1-80
           http-https
           http,https
           80,443
      ).each do |thing|
        it thing.inspect do
          params[:port] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end
    end # Rejects Port
  end
end

#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:ilb_servergroup) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "sg1",
      :ensure => :present,
      :server => 'localhost:2000-2100',
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
    [ :server ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
  end

  describe "parameter validation" do
    context "accepts server" do
      %w(
           foo.com
           foo.com:80
           foo.com:http
           foo.com:2048-3000
           1.2.3.4
           1.2.3.4:80
           1.2.3.4:2048-3000
           [fe80::3e07:54ff:fe53:c704]
           [fe80::3e07:54ff:fe53:c704]:80
           [fe80::3e07:54ff:fe53:c704]:2048-3000
      ).each do |thing|
        it thing.inspect do
          params[:server] = thing
          expect { resource }.not_to raise_error
        end
      end
      context "array of entries" do
        [ %w(foo.com
             1.2.3.4:2048-3000
             [fe80::3e07:54ff:fe53:c704]:2048-3000
            ),
            %w(bar.com
             baz.com
             quux.com
              ),
        ].each do |thing|
          it thing.inspect do
            params[:server] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
    end # Accepts
    context "rejects server" do
      %w(
           foo..com
           1.2.3.256
           fe80::3e07:54ff:fe53:c704
           [fe80::3e07:54ff:fe53:c704]:2048:3000
           foo.com:-1
           foo.com:65536
           foo.com:80-65536
           foo.com:-1-80
           foo.com:http-https
           foo.com:http,https
           foo.com:80,443
      ).each do |thing|
        it thing.inspect do
          params[:server] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end
      context "array with invalid entry" do
        [ %w(foo..com
             1.2.3.4:2048-3000
             [fe80::3e07:54ff:fe53:c704]:2048-3000
            ),
            %w(bar.com
             baz.com
             quux.com::80
              ),
        ].each do |thing|
          it thing.inspect do
            params[:server] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    end
  end
end

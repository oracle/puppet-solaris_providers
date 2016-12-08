#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:protocol_properties).provider(:protocol_properties) do

  let(:params) do
    {
      :name => 'icmp',
      :properties => {
        'max-buf' => 262999,
      }
    }
  end
  let(:resource) { Puppet::Type.type(:protocol_properties).new(params) }
  let(:provider) {
     provider = described_class.new(resource)
     provider.instance_variable_set(:@property_hash, property_hash)
     return provider
  }

  # Fake a property hash
  let(:property_hash) do
    {
      :name => 'icmp',
      :properties => {
        'max-buf' => 262144,
      },
      :ensure => :present,
    }
  end

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ipadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ipadm').returns true
  end

  describe "responds to" do
    [:exists?, :create, :properties ].each { |method|
      it { is_expected.to respond_to(method) }
    }
  end
  describe "does not respond to" do
    [:destroy].each { |method|
      it { is_expected.not_to respond_to(method) }
    }
  end

  describe "#instances" do
    described_class.expects(:ipadm).with(
      'show-prop', '-c', '-o',
      'PROTO,PROPERTY,CURRENT,DEFAULT,PERSISTENT,POSSIBLE,PERM',
    ).returns File.read(
                my_fixture('show-prop_PROTO___PERM.txt'))


      instances = described_class.instances.map { |p|
        hsh={}
        [
          :ensure,
          :name, :properties
        ].each { |fld|
          hsh[fld] = p.get(fld)
        }
        hsh
      }

      it "has three(9) results" do
        expect(instances.size).to eq(9)
      end

      context "second instance (defaults)" do
        hsh = {:ensure=>:present,
               :name=>"ipv6",
               :properties=>{"forwarding"=>"off", "hoplimit"=>"255", "hostmodel"=>"weak", "send-redirects"=>"on"}
        }
        [:ensure,:name,:properties].each { |k|
          it "has expected #{k}" do
            expect(instances[1][k]).to eq(hsh[k])
          end
        }
      end
      context "third instance (non-default)" do
        hsh = {:ensure=>:present,
               :name=>"ip",
               :temporary=>:absent,
               :properties=>{"icmp-accept-clear"=>"on", "igmp-accept-clear"=>"on", "pim-accept-clear"=>"on", "ndp-unsolicit-count" => "3","ndp-unsolicit-interval" => "2000","persock-require-priv" => "on", "arp-publish-count"=>"5", "arp-publish-interval"=>"2000", "verify-bind"=>"on"}
        }
        [:ensure,:name,:properties].each { |k|
          it "has expected #{k}" do
            expect(instances[2][k]).to eq(hsh[k])
          end
        }
      end
  end
  describe ".create" do
    it "throws an exception" do
      expect{provider.create}.to raise_error(Puppet::Error, /must exist/)
    end
  end
  describe ".insync?" do
    it "is true with value == value" do
      expect(resource.parameter(:properties).insync?(params[:properties].dup)).to eq(true)
    end
    it "is false with value != value" do
        expect(resource.parameter(:properties).insync?(property_hash[:properties])).to eq(false)
    end
  end
  describe ".properties=" do
    it "changes single protocol single property" do
      args=%w(set-prop -p max-buf=262999 icmp)
      described_class.expects(:ipadm).with(*args)
      expect(provider.properties=params[:properties]).to eq params[:properties]
    end
    it "changes single protocol multiple properties" do
      params[:properties]["igmp-accept-clear"] = "off"
      args=[%w(set-prop -p max-buf=262999 icmp),
            args=%w(set-prop -p  igmp-accept-clear=off icmp)]
      described_class.expects(:ipadm).with(*args[0])
      described_class.expects(:ipadm).with(*args[1])
      expect(provider.properties=params[:properties]).to eq params[:properties]
    end
  end
end

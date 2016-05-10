#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/address_object'
require_relative '../../../../lib/puppet/provider/address_object/solaris.rb'

describe Puppet::Type.type(:address_object).provider(:address_object) do

  let(:resource) { Puppet::Type.type(:address_object).new(
    { :name => 'myobj',
    }
  )}
  let(:provider) { resource.provider }


  context 'with a local static address' do
    before :each do
      described_class.stubs(:ipadm).with("show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:static:ok:\\127.0.0.1/8"
    end

    it 'should find one object' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'should parse the object properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => "lo0/v4",
        :ensure => :present,
        :address => '127.0.0.1/8',
        :remote_address => nil,
        :address_type => 'static',
        :down => :false, 
        :enable => :true
      } )
    end
  end

  context 'with a point-to-point address' do
    before :each do
      described_class.stubs(:ipadm).with("show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:static:ok:\\127.0.0.1/8->\\1.2.3.4/8"
    end

    it 'should parse the object properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => "lo0/v4",
        :ensure => :present,
        :address => '127.0.0.1/8',
        :remote_address => '1.2.3.4/8',
        :address_type => 'static',
        :down => :false, 
        :enable => :true
      } )
    end
  end

  context 'with a dhcp address' do
    before :each do
      described_class.stubs(:ipadm).with("show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:dhcp:ok:?"
    end

    it 'should parse the object properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => "lo0/v4",
        :ensure => :present,
        :address => nil,
        :remote_address => nil,
        :address_type => 'dhcp',
        :down => :false, 
        :enable => :true
      } )
    end
  end

  context 'with a disabled state' do
    before :each do
      described_class.stubs(:ipadm).with("show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:dhcp:disabled:?"
    end

    it 'should parse the object properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => "lo0/v4",
        :ensure => :present,
        :address => nil,
        :remote_address => nil,
        :address_type => 'dhcp',
        :down => :false, 
        :enable => :false
      } )
    end
  end

  context 'with a down state' do
    before :each do
      described_class.stubs(:ipadm).with("show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:dhcp:down:?"
    end

    it 'should parse the object properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => "lo0/v4",
        :ensure => :present,
        :address => nil,
        :remote_address => nil,
        :address_type => 'dhcp',
        :down => :true, 
        :enable => :true
      } )
    end
  end

  it 'should build create-addr options properly' do
    @resource ||= Puppet::Type.type(:address_object).new(
      { :name => 'myobj',
        :temporary => :true,
        :address_type => :static,
        :address => "1.2.3.4",
        :remote_address => "2.3.4.5",
        :down => :true,
        :seconds => 5,
        :hostname => "a.foo.com",
        :interface_id => "lo0",
        :remote_interface_id => "lo1",
        :stateful => :yes,
        :stateless => :no
      }
    )
    provider = @resource.provider
    options = provider.add_options
    expect(options).to eq(["-t", "-T", :static, "-a", "local=1.2.3.4", "-a", "remote=2.3.4.5", "-d", "-w", 5, "-h", "a.foo.com", "-i", "local=lo0", "-i", "remote=lo1", "-p", "stateful=yes", "-p", "stateless=no"])
  end

  [ "exists?", "add_options", "is_temp", "create", "destroy" ].each do |method|
    it "should have a #{method} method" do
      expect(provider.class.method_defined?(method)).to eq(true)
    end
  end

  [:address_type, :enable, :address, :remote_address, :down, :seconds,
   :hostname, :interface_id, :remote_interface_id, :stateful, 
   :stateless].each do |property|
      it "should find a reader for #{property}" do
        expect(provider.class.method_defined?(property)).to eq(true)
      end
  end

  [:enable, :down].each do |property|
      it "should find a writer for #{property}" do
        expect(provider.class.method_defined?(property.to_s+"=")).to eq(true)
      end
  end

end

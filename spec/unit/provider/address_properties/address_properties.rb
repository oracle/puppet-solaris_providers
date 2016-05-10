#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/address_properties'
require_relative '../../../../lib/puppet/provider/address_properties/solaris.rb'

describe Puppet::Type.type(:address_properties).provider(:address_properties) do

  let(:resource) { Puppet::Type.type(:address_properties).new(
    { :name => 'myobj',
    }
  )}
  let(:provider) { resource.provider }


  context 'with a multi-property interface' do
    before :each do
      described_class.stubs(:ipadm).with("show-addrprop", "-c", "-o", "ADDROBJ,PROPERTY,CURRENT").returns "lo0/v4:broadcast:\nlo0/v4:deprecated:off\nlo0/v4:prefixlen:8\nlo0/v4:private:off\nlo0/v4:reqhost:\nlo0/v4:transmit:on\nlo0/v4:zone:global"
    end

    it 'should find one object' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'should parse the object properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name       => "lo0/v4",
        :ensure     => :present,
        :properties => {
           "deprecated"=> "off", 
           "prefixlen" => "8", 
           "private"   => "off", 
           "transmit"  => "on", 
           "zone"      => "global"
         }
      } )
    end
  end

  [ "exists?", "create", "exec_cmd" ].each do |method|
    it "should have a #{method} method" do
      expect(provider.class.method_defined?(method)).to eq(true)
    end
  end

  [ "properties" ].each do |property|
      it "should find a writer for #{property}" do
        expect(provider.class.method_defined?(property.to_s+"=")).to eq(true)
      end
  end

end

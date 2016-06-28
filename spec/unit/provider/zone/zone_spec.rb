#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/zone'
require_relative '../../../../lib/puppet/provider/zone/solaris.rb'

describe Puppet::Type.type(:zone).provider(:solaris) do

  let(:resource) { Puppet::Type.type(:zone).new(
    { :name => 'foo',
    }
  )}
  let(:provider) { resource.provider }


  describe "when validating defined properties" do
    Puppet::Type.type(:zone).validproperties.each do |field|
      it "should find a reader for #{field}" do
        expect(provider.class.method_defined?(field.to_s)).to eq(true)
      end

      it "should find a writer for #{field}" do
        expect(provider.class.method_defined?(field.to_s+"=")).to eq(true)
      end
    end  # validproperties
  end  # validating default values

  context 'with two zones' do
    before :each do
      described_class.stubs(:adm).with(:list, "-cp").returns "0:global:running:/::solaris:shared:-::\n4:myzone:installed:/system/volatile/zones/myzone/zonepath:29be88cb-e61a-4204-8d9b-f4a61bf0efdd:solaris-kz:excl:R:solaris-kz:"
    end

    it 'should find two zones' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'should parse the first zone properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => 'global',
        :ensure => :running,
        :zonepath => '/',
        :brand => 'solaris',
        :iptype => 'shared'
      } )
    end

    it 'should parse the second zone properly' do
      expect(described_class.instances[1].instance_variable_get("@property_hash")).to eq( {
        :name => 'myzone',
        :ensure => :installed,
        :zonepath => '/system/volatile/zones/myzone/zonepath',
        :brand => 'solaris-kz',
        :iptype => 'excl'
      } )
    end

  end # with two zones

end

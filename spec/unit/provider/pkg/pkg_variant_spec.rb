#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:pkg_variant).provider(:pkg_variant) do

  let(:resource) { Puppet::Type.type(:pkg_variant).new(
    { :name => 'foo',
    }
  )}
  let(:provider) { described_class.new(resource) }


  context 'with two variants' do
    before :each do
      described_class.stubs(:pkg).with(:variant, "-H", "-F", "tsv").returns "variant.arch	i386\nvariant.opensolaris.zone	global"
    end

    it 'should find two variants' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'should parse the first variant with implementation properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => 'variant.arch',
        :ensure   => :present,
        :value  => "i386",
      } )
    end

    it 'should parse the second variant with no implementation properly' do
      expect(described_class.instances[1].instance_variable_get("@property_hash")).to eq( {
        :name => 'variant.opensolaris.zone',
        :ensure   => :present,
        :value  => "global",
      } )
    end
  end

  [ "value", "exists?", "create" ].each do |method|
    it "should have a #{method} method" do
      expect(provider.class.method_defined?(method)).to eq(true)
    end
  end
end

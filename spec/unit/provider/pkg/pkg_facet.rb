#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/pkg_facet'
require_relative '../../../../lib/puppet/provider/pkg_facet/solaris.rb'

describe Puppet::Type.type(:pkg_facet).provider(:pkg_facet) do

  let(:resource) { Puppet::Type.type(:pkg_facet).new(
    { :name => 'foo'
    }
  )}
  let(:provider) { resource.provider }


  context 'with two facets' do
    before :each do
      described_class.stubs(:pkg).with(:facet, "-H", "-F", "tsv").returns "facet.version-lock.system/foo/bar     True    local\nfacet.version-lock.system/foo2/bar     False    local"
    end

    it 'should find two facets' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'should parse the first facet properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => 'facet.version-lock.system/foo/bar',
        :ensure   => :present,
        :value  => "true"
      } )
    end

    it 'should parse the second facet properly' do
      expect(described_class.instances[1].instance_variable_get("@property_hash")).to eq( {
        :name => 'facet.version-lock.system/foo2/bar',
        :ensure   => :present,
        :value  => "false"
      } )
    end

  end

  [ "value", "exists?", "create", "destroy" ].each do |method|
    it "should have a #{method} method" do
      provider.class.method_defined?(method).should == true
    end
  end
end

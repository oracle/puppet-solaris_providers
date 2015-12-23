#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/pkg_mediator'
require_relative '../../../../lib/puppet/provider/pkg_mediator/solaris.rb'

describe Puppet::Type.type(:pkg_mediator).provider(:pkg_mediator) do

  let(:resource) { Puppet::Type.type(:pkg_mediator).new(
    { :name => 'foo',
    }
  )}
  let(:provider) { resource.provider }


  context 'with two mediators' do
    before :each do
      described_class.stubs(:pkg).with(:mediator, "-H", "-F", "tsv").returns "foo	local	1.0	system	fooimpl\nbar	vendor	2.0	vendor"
    end

    it 'should find two mediators' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'should parse the first mediator with implementation properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => 'foo',
        :ensure   => :present,
        :implementation  => "fooimpl",
        :version => "1.0"
      } )
    end

    it 'should parse the second mediator with no implementation properly' do
      expect(described_class.instances[1].instance_variable_get("@property_hash")).to eq( {
        :name => 'bar',
        :ensure   => :present,
        :implementation  => "None",
        :version => "2.0"
      } )
    end
  end

  [ "version", "exists?", "implementation", "build_flags", 
    "create", "destroy" ].each do |method|
    it "should have a #{method} method" do
      provider.class.method_defined?(method).should == true
    end
  end
end

#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/ldap'
require_relative '../../../../lib/puppet/provider/ldap/solaris.rb'

describe Puppet::Type.type(:ldap).provider(:ldap) do

  let(:provider) do
    @ldap_class = Puppet::Type.type(:ldap)
    @provider = @ldap_class.provider(:ldap)
    @provider.stubs(:suitable?).returns true
    described_class.new(:ldap)
  end

  svcprop = '/usr/bin/svcprop'

  describe "when validating defined properties" do
    props = `svcprop -a svc:/network/ldap/client`
    Puppet::Type.type(:ldap).validproperties.each do |field|
      pg = Puppet::Type.type(:ldap).propertybyname(field).pg

      it "should be able to see the #{pg}/#{field} SMF property" do
        expect(props =~ /tm_proppat_nt_#{pg}_#{field.to_s}\/name/).not_to eq(nil)
      end 

      it "should find a reader for #{field}" do
        expect(provider.class.method_defined?(field.to_s)).to eq(true)
      end

      it "should find a writer for #{field}" do
        expect(provider.class.method_defined?(field.to_s+"=")).to eq(true)
      end
    end  # validproperties
  end  # validating default values

  it "should have a flush method" do
    expect(provider.class.method_defined?("flush")).to eq(true)
  end

end

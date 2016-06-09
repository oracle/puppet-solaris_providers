#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/dns'
require_relative '../../../../lib/puppet/provider/dns/solaris.rb'

describe Puppet::Type.type(:dns).provider(:dns) do

  let(:provider) do
    @dns_class = Puppet::Type.type(:dns)
    @provider = @dns_class.provider(:dns)
    @provider.stubs(:suitable?).returns true
    described_class.new(:dns)
  end

  svcprop = '/usr/bin/svcprop'

  describe "when validating defined properties" do
    props = `svcprop -a svc:/network/dns/client`
    Puppet::Type.type(:dns).validproperties.each do |field|
      pg = "config"

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

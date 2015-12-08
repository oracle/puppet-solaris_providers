#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/nis'
require_relative '../../../../lib/puppet/provider/nis/solaris.rb'

describe Puppet::Type.type(:nis).provider(:nis) do

  let(:provider) do
    @nis_class = Puppet::Type.type(:nis)
    @provider = @nis_class.provider(:nis)
    @provider.stubs(:suitable?).returns true
    described_class.new(:nis)
  end

  svcprop = '/usr/bin/svcprop'

  describe "when validating defined properties" do
    props = ""
    [Client_fmri, Domain_fmri].each do |svc|
      props = props + `svcprop -a #{svc}`
    end

    Puppet::Type.type(:nis).validproperties.each do |field|
      pg = "config"

      it "should be able to see the #{pg}/#{field} SMF property" do
        (props =~ /tm_proppat_nt_#{pg}_#{field.to_s}\/name/).should_not == nil
      end 

      it "should find a reader for #{field}" do
        provider.class.method_defined?(field.to_s).should == true
      end

      it "should find a writer for #{field}" do
        provider.class.method_defined?(field.to_s+"=").should == true
      end
    end  # validproperties
  end  # validating default values

  it "should have a flush method" do
    provider.class.method_defined?("flush").should == true
  end

end

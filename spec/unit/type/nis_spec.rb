#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/nis'

describe Puppet::Type.type(:nis) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:domainname, :ypservers, :securenets, :use_broadcast, :use_ypsetme
    ].each do |prop|
      it "should have a #{prop} property" do
        @class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do

    describe "for domainname" do
      def validate(dname)
         @class.new(:name => @profile_name, :domainname => dname)
      end

      it "should allow a value to be set" do
        proc { validate "foo.com" }.
             should_not raise_error
      end
    end  # domainname


    describe "for ypservers" do
      error_pattern = /ypserver.*invalid/m

      def validate(hostname)
         @class.new(:name => @profile_name, :ypservers => hostname)
      end
 
      it "should reject hostnames greater than 255 characters" do
        proc { validate "aaaa." * 51 << "a"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostnames with double periods" do
        proc { validate "double..isbad.com"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostname segments larger than 63 characters" do
        proc { validate "my." << "a" * 64 << ".com"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostname segments not starting with a letter/digit" do
        proc { validate "my._invalid.hostname"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostname segments ending with a dash" do
        proc { validate "my.invalid-.hostname"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject invalid IP addresses" do
        proc { validate "192.168.1.256"
             }.should raise_error Puppet::Error, error_pattern
        proc { validate "192.168.1."
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should accept an array of valid values" do
        proc { validate [ "host1.hostarray.com", "host2.hostarray.com" ] }.
             should_not raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :ypservers => "host1.hostarray.com")
        mytype.property("ypservers").value.should be_an(Array)
      end
    end  # ypservers


    describe "for securenets" do
      def validate(snets)
         @class.new(:name => @profile_name, :securenets => snets)
      end

      it "should allow a value to be set" do
        proc { validate "foo.com" }.
             should_not raise_error
      end
    end  # securenets


    describe "for use_broadcast" do
      error_pattern = /broadcast.*Invalid/m

      def validate(ub)
         @class.new(:name => @profile_name, :use_broadcast => ub)
      end

      [ "true", "false" ].each do |ubval|
        it "should accept a value of #{ubval}" do
          proc { validate(ubval) }.should_not raise_error
        end
      end

      it "should reject invalid values" do
        proc { validate "foo"
             }.should raise_error Puppet::Error, error_pattern
      end
    end  # use_broadcast


    describe "for use_ypsetme" do
      error_pattern = /ypsetme.*Invalid/m

      def validate(ub)
         @class.new(:name => @profile_name, :use_ypsetme => ub)
      end

      [ "true", "false" ].each do |ubval|
        it "should accept a value of #{ubval}" do
          proc { validate(ubval) }.should_not raise_error
        end
      end

      it "should reject invalid values" do
        proc { validate "foo"
             }.should raise_error Puppet::Error, error_pattern
      end
    end  # use_ypsetme

  end # validating values
end

#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/address_properties'

describe Puppet::Type.type(:address_properties) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :address as its keyattribute" do
    @class.key_attributes.should == [:address]
  end

  describe "when validating properties" do
    [ :properties ].each do |prop|
      it "should have a #{prop} property" do
        @class.attrtype(prop).should == :property
      end
    end
  end # validating properties

  describe "when validating parameters" do
    [ :address, :temporary ].each do |prop|
      it "should have a #{prop} property" do
        @class.attrtype(prop).should == :param
      end
    end
  end # validating properties

  describe "when validating values" do

    describe "for ensure" do
      error_pattern = /Invalid value/m
      def validate(ens)
         @class.new(:name => @profile_name, :ensure => ens)
      end

      [ "present" ].each do |newval|
        it "should accept a value of #{newval}" do
          proc { validate(newval) }.should_not raise_error
        end
      end

      it "should reject invalid values" do
        proc { validate "foo" }.should raise_error Puppet::Error, error_pattern
      end
    end  # ensure

    describe "for temporary" do
      error_pattern = /temporary.*Invalid/m

      def validate(temp)
         @class.new(:name => @profile_name, :temporary => temp)
      end

      [ "true", "false" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          proc { validate(follow_val) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # temporary

    describe "for properties" do
      def validate(props)
         @class.new(:name => @profile_name, :properties => props)
      end

      it "should accept a hash value" do
        proc { validate ({"a" => "b"}) }.should_not raise_error
      end
    end  # seconds
 
  end # validating values
end

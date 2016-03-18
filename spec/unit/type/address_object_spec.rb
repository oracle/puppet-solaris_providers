#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/address_object'

describe Puppet::Type.type(:address_object) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating properties" do
    [ :address_type, :enable, :address, :remote_address, :down, :seconds,
      :hostname, :interface_id, :remote_interface_id, :stateful, :stateless
    ].each do |prop|
      it "should have a #{prop} property" do
        @class.attrtype(prop).should == :property
      end
    end
  end # validating properties

  describe "when validating parameters" do
    [ :name, :temporary
    ].each do |prop|
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

      [ "present", "absent" ].each do |newval|
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

    describe "for address_type" do
      error_pattern = /address_type.*Invalid/m

      def validate(atype)
         @class.new(:name => @profile_name, :address_type => atype)
      end

      [ :static, :dhcp, :addrconf, :from_gz ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          proc { validate(follow_val) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # address_type

    describe "for enable" do
      error_pattern = /enable.*Invalid/m

      def validate(enab)
         @class.new(:name => @profile_name, :enable => enab)
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
    end  # enable

    describe "for address" do
      error_pattern = /address.*Invalid/m
      def validate_static(addr)
         @class.new(:name => @profile_name, :address => addr,
                    :address_type => :static)
      end

      def validate_dhcp(addr)
         @class.new(:name => @profile_name, :address => addr,
                    :address_type => :dhcp)
      end

      it "should reject a value if address_type is not static" do
        proc { validate_dhcp "1.2.3.4"
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        proc { validate_static "1.2.3.4"
             }.should_not raise_error
      end
    end  # address

    describe "for remote_address" do
      error_pattern = /remote_address.*Invalid/m
      def validate_static(addr)
         @class.new(:name => @profile_name, :remote_address => addr,
                    :address_type => :static)
      end

      def validate_dhcp(addr)
         @class.new(:name => @profile_name, :remote_address => addr,
                    :address_type => :dhcp)
      end

      it "should reject a value if address_type is not static" do
        proc { validate_dhcp "1.2.3.4"
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        proc { validate_static "1.2.3.4"
             }.should_not raise_error
      end
    end  # remote_address

    describe "for down" do
      error_pattern = /down.*Invalid/m

      def validate_static(dwn)
         @class.new(:name => @profile_name, :down => dwn,
                    :address_type => :static)
      end

      def validate_dhcp(dwn)
         @class.new(:name => @profile_name, :down => dwn,
                    :address_type => :dhcp)
      end

      it "should reject a value if address_type is not static" do
        proc { validate_dhcp "true"
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end

      [ "true", "false" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          proc { validate_static(follow_val) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate_static("foobar") 
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end
    end  # down

    describe "for seconds" do
      error_pattern = /seconds.*Invalid/m
      def validate_static(secs)
         @class.new(:name => @profile_name, :remote_address => secs,
                    :address_type => :static)
      end

      def validate_dhcp(secs)
         @class.new(:name => @profile_name, :remote_address => secs,
                    :address_type => :dhcp)
      end

      it "should reject a value if address_type is not dhcp" do
        proc { validate_static "20"
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept an integer value" do
        proc { validate_dhcp "5" }.should_not raise_error
      end

      it "should accept a value of forever" do
        proc { validate_dhcp "forever" }.should_not raise_error
      end

      it "should reject an invalid value" do
        proc { validate_dhcp "foobar" 
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end
    end  # seconds
 
    describe "for hostname" do
      error_pattern = /hostname.*Invalid/m
      def validate_static(hname)
         @class.new(:name => @profile_name, :hostname => hname,
                    :address_type => :static)
      end

      def validate_dhcp(hname)
         @class.new(:name => @profile_name, :hostname => hname,
                    :address_type => :dhcp)
      end

      it "should reject a value if address_type is not dhcp" do
        proc { validate_static "a.foobar.com"
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        proc { validate_dhcp "a.foobar.com"
             }.should_not raise_error
      end
    end  # hostname

    describe "for interface_id" do
      error_pattern = /interface_id.*Invalid/m
      def validate_static(iid)
         @class.new(:name => @profile_name, :interface_id => iid,
                    :address_type => :static)
      end

      def validate_addrconf(iid)
         @class.new(:name => @profile_name, :interface_id => iid,
                    :address_type => :addrconf)
      end

      it "should reject a value if address_type is not addrconf" do
        proc { validate_static "lo0/v4"
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        proc { validate_addrconf "lo0/v4"
             }.should_not raise_error
      end
    end  # interface_id

    describe "for remote_interface_id" do
      error_pattern = /remote_interface_id.*Invalid/m
      def validate_static(iid)
         @class.new(:name => @profile_name, :remote_interface_id => iid,
                    :address_type => :static)
      end

      def validate_addrconf(iid)
         @class.new(:name => @profile_name, :remote_interface_id => iid,
                    :address_type => :addrconf)
      end

      it "should reject a value if address_type is not addrconf" do
        proc { validate_static "lo0/v4"
             }.should raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        proc { validate_addrconf "lo0/v4"
             }.should_not raise_error
      end
    end  # remote_interface_id

    describe "for stateful" do
      error_pattern = /stateful.*Invalid/m

      def validate(sful)
         @class.new(:name => @profile_name, :stateful => sful)
      end

      [ "yes", "no" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          proc { validate(follow_val) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # stateful

    describe "for stateless" do
      error_pattern = /stateless.*Invalid/m
  
      def validate(sless)
         @class.new(:name => @profile_name, :stateless => sless)
      end

      [ "yes", "no" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          proc { validate(follow_val) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # stateless

  end # validating values
end

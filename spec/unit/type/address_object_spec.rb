#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/address_object'

describe Puppet::Type.type(:address_object) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect(@class.key_attributes).to eq([:name])
  end

  describe "when validating properties" do
    [ :address_type, :enable, :address, :remote_address, :down, :seconds,
      :hostname, :interface_id, :remote_interface_id, :stateful, :stateless
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:property)
      end
    end
  end # validating properties

  describe "when validating parameters" do
    [ :name, :temporary
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:param)
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
          expect { validate(newval) }.not_to raise_error
        end
      end

      it "should reject invalid values" do
        expect { validate "foo" }.to raise_error Puppet::Error, error_pattern
      end
    end  # ensure

    describe "for temporary" do
      error_pattern = /temporary.*Invalid/m

      def validate(temp)
         @class.new(:name => @profile_name, :temporary => temp)
      end

      [ "true", "false" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
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
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
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
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
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
        expect { validate_dhcp "1.2.3.4"
             }.to raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        expect { validate_static "1.2.3.4"
             }.not_to raise_error
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
        expect { validate_dhcp "1.2.3.4"
             }.to raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        expect { validate_static "1.2.3.4"
             }.not_to raise_error
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
        expect { validate_dhcp "true"
             }.to raise_error(Puppet::ResourceError, error_pattern)
      end

      [ "true", "false" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate_static(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate_static("foobar") 
             }.to raise_error(Puppet::ResourceError, error_pattern)
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
        expect { validate_static "20"
             }.to raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept an integer value" do
        expect { validate_dhcp "5" }.not_to raise_error
      end

      it "should accept a value of forever" do
        expect { validate_dhcp "forever" }.not_to raise_error
      end

      it "should reject an invalid value" do
        expect { validate_dhcp "foobar" 
             }.to raise_error(Puppet::ResourceError, error_pattern)
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
        expect { validate_static "a.foobar.com"
             }.to raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        expect { validate_dhcp "a.foobar.com"
             }.not_to raise_error
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
        expect { validate_static "lo0/v4"
             }.to raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        expect { validate_addrconf "lo0/v4"
             }.not_to raise_error
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
        expect { validate_static "lo0/v4"
             }.to raise_error(Puppet::ResourceError, error_pattern)
      end

      it "should accept a value" do
        expect { validate_addrconf "lo0/v4"
             }.not_to raise_error
      end
    end  # remote_interface_id

    describe "for stateful" do
      error_pattern = /stateful.*Invalid/m

      def validate(sful)
         @class.new(:name => @profile_name, :stateful => sful)
      end

      [ "yes", "no" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
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
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # stateless

  end # validating values
end

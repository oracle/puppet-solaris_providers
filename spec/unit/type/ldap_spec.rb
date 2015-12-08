#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/ldap'

describe Puppet::Type.type(:ldap) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:profile, :server_list, :preferred_server_list, :search_base, 
     :search_scope, :authentication_method, :credential_level, 
     :search_time_limit, :bind_time_limit, :follow_referrals, :profile_ttl, 
     :attribute_map, :objectclass_map, :service_credential_level, 
     :service_authentication_method, :service_search_descriptor, :bind_dn, 
     :bind_passwd, :enable_shadow_update, :admin_bind_dn, :admin_bind_passwd, 
     :host_certpath
    ].each do |prop|
      it "should have a #{prop} property" do
        @class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for server_list" do
      error_pattern = /default_server.*invalid/m

      def validate(hostname)
         @class.new(:name => @profile_name, :server_list => hostname)
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
                            :server_list => "host1.hostarray.com")
        mytype.property("server_list").value.should be_an(Array)
      end
    end  # server_list


    describe "for preferred_server_list" do
      error_pattern = /preferred_server entry.*invalid/m

      def validate(hostname)
         @class.new(:name => @profile_name, 
                    :preferred_server_list => hostname)
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
                            :preferred_server_list => "host1.hostarray.com")
        mytype.property("preferred_server_list").value.should be_an(Array)
      end
    end  # preferred_server_list


    describe "for search_scope" do
      error_pattern = /Parameter search_scope failed/

      def validate(scope)
         @class.new(:name => @profile_name, 
                    :search_scope => scope)
      end

      [ "base", "one", "sub" ].each do |scope_type|
        it "should accept a value of #{scope_type}" do
          proc { validate(scope_type) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError, 
                                                       error_pattern)
      end
    end  # search_scope


    describe "for authentication_method" do
      error_pattern = /Parameter authentication_method failed/

      def validate(method)
         @class.new(:name => @profile_name, 
                    :authentication_method => method)
      end

      [ "none", "simple", "sasl/CRAM-MD5", "sasl/DIGEST-MD5",
        "sasl/GSSAPI", "tls:simple", "tls:sasl/CRAM-MD5",
        "tls:sasl/DIGEST-MD5" 
      ].each do |method_type|
        it "should accept a value of #{method_type}" do
          proc { validate(method_type) }.should_not raise_error
        end
      end

      it "should accept an array of valid values" do
        proc { validate ["simple", "sasl/CRAM-MD5"] }.should_not raise_error
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError, 
                                                       error_pattern)
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :authentication_method => "simple")
        mytype.property("authentication_method").value.should be_an(Array)
      end
    end  # authentication_method


    describe "for credential_level" do
      error_pattern = /Parameter credential_level failed/

      def validate(level)
         @class.new(:name => @profile_name, 
                    :credential_level => level)
      end

      [ "anonymous", "proxy", "self" ].each do |cred_level|
        it "should accept a value of #{cred_level}" do
          proc { validate(cred_level) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError, 
                                                       error_pattern)
      end
    end  # credential_level


    describe "for attribute_map" do
      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :attribute_map => "foobar")
        mytype.property("attribute_map").value.should be_an(Array)
      end
    end  # attribute_map


    describe "for objectclass_map" do
      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :objectclass_map => "foobar")
        mytype.property("objectclass_map").value.should be_an(Array)
      end
    end  # objectclass_map


    describe "for follow_referrals" do
      error_pattern = /Parameter follow_referrals failed/

      def validate(follow)
         @class.new(:name => @profile_name, 
                    :follow_referrals => follow)
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
    end  # follow_referrals


    describe "for service_credential_level" do
      error_pattern = /Parameter service_credential_level failed/

      def validate(level)
         @class.new(:name => @profile_name, 
                    :service_credential_level => level)
      end

      [ "anonymous", "proxy" ].each do |level_val|
        it "should accept a value of #{level_val}" do
          proc { validate(level_val) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError, 
                                                       error_pattern)
      end
    end  # service_credential_level


    describe "for service_authentication_method" do
      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :service_authentication_method => "foobar")
        mytype.property("service_authentication_method").value.should 
                                                               be_an(Array)
      end
    end  # service_authentication_method


    describe "for bind_dn" do
      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :bind_dn => "foobar")
        mytype.property("bind_dn").value.should be_an(Array)
      end
    end  # bind_dn


    describe "for enable_shadow_update" do
      error_pattern = /Parameter enable_shadow_update failed/

      def validate(enable)
         @class.new(:name => @profile_name, 
                    :enable_shadow_update => enable)
      end

      [ "true", "false" ].each do |enable_val|
        it "should accept a value of #{enable_val}" do
          proc { validate(enable_val) }.should_not raise_error
        end
      end

      it "should reject an invalid value" do
        proc { validate("foobar") }.should raise_error(Puppet::ResourceError, 
                                                       error_pattern)
      end
    end  # enable_shadow_update

  end # validating values
end

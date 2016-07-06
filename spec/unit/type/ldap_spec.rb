#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:ldap) do

  let(:params) do
    {
      :name => "ldap_type",
      :ensure => :present,
    }
      end

  let(:error_pattern) { /value:.*invalid/ }

  before do
    @profile_name = "rspec profile"
  end

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end

  describe "has the property" do
    [:profile, :server_list, :preferred_server_list, :search_base,
      :search_scope, :authentication_method, :credential_level,
      :search_time_limit, :bind_time_limit, :follow_referrals, :profile_ttl,
      :attribute_map, :objectclass_map, :service_credential_level,
      :service_authentication_method, :service_search_descriptor, :bind_dn,
      :bind_passwd, :enable_shadow_update, :admin_bind_dn, :admin_bind_passwd,
      :host_certpath
    ].each do |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "when validating values for" do
    [:server_list, :preferred_server_list].each do |prop|
      describe prop do
        klass = Puppet::Type.type(:ldap)
        before(:each) do
          params[:name] = prop.to_s
          error_pattern
        end

        it "rejects hostnames greater than 255 characters" do
          params[prop] = "aaaa." * 51 << "a"
          expect { klass.new(params)
          }.to raise_error(Puppet::Error, error_pattern)
        end

        it "rejects hostnames with double periods" do
          params[prop] = "double..isbad.com"
          expect { klass.new(params)
          }.to raise_error(Puppet::Error, error_pattern)
        end

        it "rejects hostname segments larger than 63 characters" do
          params[prop] = "my." << "a" * 64 << ".com"
          expect { klass.new(params)
          }.to raise_error(Puppet::Error, error_pattern)
        end

        it "rejects hostname segments not starting with a letter/digit" do
          params[prop] = "my._invalid.hostname"
          expect { klass.new(params)
          }.to raise_error(Puppet::Error, error_pattern)
        end

        it "rejects hostname segments ending with a dash" do
          params[prop] = "my.invalid-.hostname"
          expect { klass.new(params)
          }.to raise_error(Puppet::Error, error_pattern)
        end

        ["192.168.1.253","1.2.3.4"].each do |ip|
          it "accepts valid IP addresses #{ip}" do
            params[prop] = ip
            expect { klass.new(params)
            }.not_to raise_error
          end
        end

        ["192.168.1.256","192.168.1."].each do |ip|
          it "rejects invalid IP addresses #{ip}" do
            params[prop] = ip
            expect { klass.new(params)
            }.to raise_error(Puppet::Error, error_pattern)
          end
        end

        it "accepts an array of valid values" do
          params[prop] = [ "host1.hostarray.com", "host2.hostarray.com" ]
          expect { klass.new(params)
          }.not_to raise_error
        end

        it "returns an array for a single value" do
          mytype = klass.new(:name => @profile_name,
                             :server_list => "host1.hostarray.com")
          expect(mytype.property("server_list").value).to be_an(Array)
        end
      end  # server_list, preferred_server_list
    end

    describe "search_scope" do
      error_pattern = /Parameter search_scope failed/

        def validate(scope)
          described_class.new(:name => @profile_name,
                              :search_scope => scope)
        end

      [ "base", "one", "sub" ].each do |scope_type|
        it "accepts a value of #{scope_type}" do
          expect { validate(scope_type) }.not_to raise_error
        end
      end

      it "rejects an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                     error_pattern)
      end
    end  # search_scope


    describe "authentication_method" do
      error_pattern = /Parameter authentication_method failed/

        def validate(method)
          described_class.new(:name => @profile_name,
                              :authentication_method => method)
        end

      [ "none", "simple", "sasl/CRAM-MD5", "sasl/DIGEST-MD5",
        "sasl/GSSAPI", "tls:simple", "tls:sasl/CRAM-MD5",
        "tls:sasl/DIGEST-MD5"
      ].each do |method_type|
        it "accepts a value of #{method_type}" do
          expect { validate(method_type) }.not_to raise_error
        end
      end

      it "accepts an array of valid values" do
        expect { validate ["simple", "sasl/CRAM-MD5"] }.not_to raise_error
      end

      it "rejects an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                     error_pattern)
      end

      it "returns an array for a single value" do
        mytype = described_class.new(:name => @profile_name,
                                     :authentication_method => "simple")
        expect(mytype.property("authentication_method").value).to be_an(Array)
      end
    end  # authentication_method


    describe "credential_level" do
      error_pattern = /Parameter credential_level failed/

        def validate(level)
          described_class.new(:name => @profile_name,
                              :credential_level => level)
        end

      [ "anonymous", "proxy", "self" ].each do |cred_level|
        it "accepts a value of #{cred_level}" do
          expect { validate(cred_level) }.not_to raise_error
        end
      end

      it "rejects an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                     error_pattern)
      end
    end  # credential_level


    describe "attribute_map" do
      it "returns an array for a single value" do
        mytype = described_class.new(:name => @profile_name,
                                     :attribute_map => "foobar")
        expect(mytype.property("attribute_map").value).to be_an(Array)
      end
    end  # attribute_map


    describe "objectclass_map" do
      it "returns an array for a single value" do
        mytype = described_class.new(:name => @profile_name,
                                     :objectclass_map => "foobar")
        expect(mytype.property("objectclass_map").value).to be_an(Array)
      end
    end  # objectclass_map


    describe "follow_referrals" do
      error_pattern = /Parameter follow_referrals failed/

        def validate(follow)
          described_class.new(:name => @profile_name,
                              :follow_referrals => follow)
        end

      [ "true", "false" ].each do |follow_val|
        it "accepts a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "rejects an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                     error_pattern)
      end
    end  # follow_referrals


    describe "service_credential_level" do
      error_pattern = /Parameter service_credential_level failed/

        def validate(level)
          described_class.new(:name => @profile_name,
                              :service_credential_level => level)
        end

      [ "anonymous", "proxy" ].each do |level_val|
        it "accepts a value of #{level_val}" do
          expect { validate(level_val) }.not_to raise_error
        end
      end

      it "rejects an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                     error_pattern)
      end
    end  # service_credential_level


    describe "service_authentication_method" do
      it "returns an array for a single value" do
        mytype = described_class.new(:name => @profile_name,
                                     :service_authentication_method => "foobar")
        expect(mytype.property("service_authentication_method").value).to be_an(Array)
      end
    end  # service_authentication_method


    describe "bind_dn" do
      it "returns an array for a single value" do
        mytype = described_class.new(:name => @profile_name,
                                     :bind_dn => "foobar")
        expect(mytype.property("bind_dn").value).to be_an(Array)
      end
    end  # bind_dn


    describe "enable_shadow_update" do
      error_pattern = /Parameter enable_shadow_update failed/

        def validate(enable)
          described_class.new(:name => @profile_name,
                              :enable_shadow_update => enable)
        end

      [ "true", "false" ].each do |enable_val|
        it "accepts a value of #{enable_val}" do
          expect { validate(enable_val) }.not_to raise_error
        end
      end

      it "rejects an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                     error_pattern)
      end
    end  # enable_shadow_update

  end # validating values
end

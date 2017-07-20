require 'spec_helper'

describe Puppet::Type.type(:ldap).provider(:solaris) do


  let(:instances) do
    Process.stubs(:euid).returns(0)
    described_class.expects(:svcprop).with("-p", "config", "-p", "cred", Ldap_fmri).returns File.read(my_fixture('svcsprop_p_config_p_cred_Ldap_fmri.txt'))
    described_class.instances.map { |inst|
      hsh = {
        :ensure => inst.get(:ensure),
        :name => inst.get(:name),
      }
      properties.each { |prop|
        hsh[prop] = inst.get(prop)
      }
      hsh
    }
  end


  let(:resource) do
    Puppet::Type.type(:ldap).new(
      :name => "current",
      :ensure => :present
    )
  end

  let(:provider) do
    described_class.new(:ldap)
  end

  let(:properties) {
    # This is duplicated from @properties for scoping
    @properties = [:profile, :server_list, :preferred_server_list, :search_base, :search_scope,
                   :authentication_method, :credential_level, :search_time_limit,
                   :bind_time_limit, :follow_referrals, :profile_ttl, :attribute_map,
                   :objectclass_map, :service_credential_level, :service_authentication_method,
                   :service_search_descriptor, :bind_dn, :bind_passwd, :enable_shadow_update,
                   :admin_bind_dn, :admin_bind_passwd, :host_certpath]
  }

  # remove ensure from the expected properties
  let(:expectedproperties) { Puppet::Type.type(:ldap).validproperties - [:ensure] }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/bin/svcprop').returns true
    FileTest.stubs(:executable?).with('/usr/bin/svcprop').returns true
  end

  # ensure we have all listed properties, addition of new properties will result
  # in an error here and require the various property arrays to be updated
  it "has only expected methods" do
    expect(properties).to eq(expectedproperties)
  end

  context "responds to" do
    # No setter methods
    [:ensure,:flush].each { |method|
      it method do is_expected.to respond_to(method) end
    }

    # This is duplicated due to scoping
    @properties = [:profile, :server_list, :preferred_server_list, :search_base, :search_scope,
                   :authentication_method, :credential_level, :search_time_limit,
                   :bind_time_limit, :follow_referrals, :profile_ttl, :attribute_map,
                   :objectclass_map, :service_credential_level, :service_authentication_method,
                   :service_search_descriptor, :bind_dn, :bind_passwd, :enable_shadow_update,
                   :admin_bind_dn, :admin_bind_passwd, :host_certpath]

    @properties.each { |method|
      it method do is_expected.to respond_to(method) end
      it "#{method}=".intern do is_expected.to respond_to("#{method}=".to_sym) end
    }

  end # properties

  describe ".instances" do
    before(:all) do
      # LDAP provider checks the euid of the running process
      Process.stubs(:euid).returns(0)
    end

    it "returns one instance" do
      expect(instances.size).to eq(1)
    end

    it "raises an error for non-root user" do
      Process.stubs(:euid).returns(501)
      expect{ described_class.instances }.to raise_error(RuntimeError,/non-root/)
    end

    # properties set to :absent are not defined in the fixture. They may be added manually if desired
    describe "resource has expected SMF properties" do
      {
        :name => "current",
        :profile => %q(bar-tls),
        :server_list => %q(lc-bar-02.us.foo.com \\ lc-foo-02.us.foo.com \\ lc-foo-01.us.foo.com),
        :preferred_server_list => %q(lc-bar-02.us.foo.com \\ lc-foo-02.us.foo.com \\ lc-foo-01.us.foo.com),
        :search_base => %q(dc=foo,dc=com),
        :search_scope => %q(one),
        :authentication_method => %q(tls:simple),
        :credential_level => %q(proxy),
        :search_time_limit => %q(30),
        :bind_time_limit => %q(10),
        :follow_referrals => %q(false),
        :profile_ttl => %q(43200),
        :attribute_map => :absent,
        :objectclass_map => :absent,
        :service_credential_level => :absent,
        :service_authentication_method => :absent,
        :service_search_descriptor => %q(passwd:dc=foo,dc=com?sub? shadow:dc=foo,dc=com?sub? rpc:ou=rpc,ou=foo.corp.com,o=nl,dc=foo,dc=com amgh:nismapname=amgh,ou=foo.corp.com,o=nl,dc=foo,dc=com protocols:ou=protocols,ou=foo.corp.com,o=nl,dc=foo,dc=com services:ou=services,ou=foo.corp.com,o=nl,dc=foo,dc=com aliases:ou=aliases,ou=foo.corp.com,o=nl,dc=foo,dc=com netgroup:ou=netgroup,dc=foo,dc=com auto_share:automountmapname=auto_share,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_re:automountmapname=auto_re,ou=foo.corp.com,o=nl,dc=foo,dc=com auto_master:automountmapname=auto_master,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_home:automountmapname=auto_home,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_direct:automountmapname=auto_direct,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_galileo:automountmapname=auto_galileo,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_java:automountmapname=auto_java,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_ws:automountmapname=auto_ws,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_wwss:automountmapname=auto_wwss,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_scde:automountmapname=auto_scde,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_micro:automountmapname=auto_micro,ou=automount,ou=pd_sca,ou=foo.corp.com,o=nl,dc=foo,dc=com auto_shared:automountmapname=auto_shared,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_src:automountmapname=auto_src,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_workspace:automountmapname=auto_workspace,ou=foo.corp.com,o=nl,dc=foo,dc=com auto_micro_people:automountmapname=auto_micro_people,ou=automount,ou=pd_sca,ou=foo.corp.com,o=nl,dc=foo,dc=com auto_ON:automountmapname=auto_ON,ou=it.bar.sun.com,o=nl,dc=foo,dc=com auto_import:automountmapname=auto_import,ou=it.bar.sun.com,o=nl,dc=foo,dc=com printers:ou=printers,ou=foo.corp.com,o=nl,dc=foo,dc=com group:ou=groups,dc=foo,dc=com),
      :bind_dn => %q(cn=admin,ou=users,dc=foo,dc=com),
      :bind_passwd => %q({NS1}c2ab9ff37b69c4b5a665a2b15d003bba0779),
      :enable_shadow_update => :absent,
      :admin_bind_dn => :absent,
      :admin_bind_passwd => :absent,
      :host_certpath => :absent
      }.each_pair do |field,value|
        pg = Puppet::Type.type(:ldap).propertybyname(field).pg rescue "unknown"
        it "#{pg}/#{field}" do
          expect(instances[0][field]).to eq(value)
        end
      end  # validproperties
    end
  end  # validating instances

  describe "property=" do
    it "formats string arguments" do
      resource[:search_base] = %q(dc=foo,dc=com)
      testval = %q(dc=bar,dc=com)
      newval = %q(dc=bar,dc=com)
      described_class.expects(:svccfg).with("-s", Ldap_fmri, "setprop", "config/search_base=", testval )
      expect(provider.search_base=newval).to eq(newval)
    end

    it "formats array arguments" do
      resource[:server_list] = "foo.com"
      newval = %w(baz.com quux.com)
      testval = %w^( baz.com quux.com )^
      described_class.expects(:svccfg).with("-s", Ldap_fmri, "setprop", "config/server_list=", testval )
      expect(provider.server_list=newval).to eq(newval)
    end

    it "formats :absent argument" do
      testval = %q^\'\'^
      described_class.expects(:svccfg).with("-s", Ldap_fmri, "setprop", "config/profile=", testval )
      expect(provider.send(:profile=,:absent)).to eq(testval)
    end
  end
end

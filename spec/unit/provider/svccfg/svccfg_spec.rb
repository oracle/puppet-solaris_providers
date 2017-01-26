require 'spec_helper'

describe Puppet::Type.type(:svccfg).provider(:svccfg) do

  let(:params) do
    {
      :name => "foo",
      :fmri => "svc:/application/puppet:agent",
      :property => "refresh/timeout_seconds",
      :type => :count,
      :value => 0,
      :ensure => :present,
      # resource auto generates this from the above
      :prop_fmri => "svc:/application/puppet:agent/:properties/refresh/timeout_seconds"
    }
  end

  let(:resource) { Puppet::Type.type(:svccfg).new(params) }
  let(:provider) { described_class.new(resource) }
  let(:pg_fmri) { params[:prop_fmri].slice(0,params[:prop_fmri].rindex('/')) }

  before(:each) do

    FileTest.stubs(:file?).with('/usr/bin/svcprop').returns true
    FileTest.stubs(:executable?).with('/usr/bin/svcprop').returns true
    FileTest.stubs(:file?).with('/usr/sbin/svccfg').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/svccfg').returns true
  end

  [ "exists?", "delcust", "create", "destroy" ].each do |method|
    it "should have a #{method} method" do
      expect(provider.class.method_defined?(method)).to be true
    end
  end

  describe ".instances" do
    it "should have an instances method" do
      expect(described_class).to respond_to :instances
    end

    describe "should get a list of service properties" do
      described_class.expects(:svcprop).with("-a", "-f", "*").returns File.read(my_fixture('svcprop_a_f.txt'))
      instances = described_class.instances.map { |p|
        {
          :name => p.get(:name),
          :fmri => p.get(:fmri),
          :property => p.get(:property),
          :type => p.get(:type),
          :value => p.get(:value),
          :ensure => p.get(:ensure),
        }
      }
      it "with the expected number of instances" do
        expect(instances.size).to eq(43)
      end

      [
        {
          :name=>"svc:/network/bridge/:properties/config/force-protocol",
          :fmri=>"svc:/network/bridge", :property=>"config/force-protocol",
          :type=>"count", :value=>"3", :ensure=>:present
        },

        {
          :name=>"svc:/network/bridge/:properties/config/forward-delay",
          :fmri=>"svc:/network/bridge", :property=>"config/forward-delay",
          :type=>"count", :value=>"3840", :ensure=>:present
        },

        {
          :name=>"svc:/network/nfs/nlockmgr:default/:properties/nfs-props/lockd_listen_backlog",
          :fmri=>"svc:/network/nfs/nlockmgr:default",
          :property=>"nfs-props/lockd_listen_backlog", :type=>"integer", :value=>"32",
          :ensure=>:present
        },

        {
          :name=>"svc:/network/nfs/server:default/:properties/nfs-props/max_connections",
          :fmri=>"svc:/network/nfs/server:default",
          :property=>"nfs-props/max_connections", :type=>"integer", :value=>"-1",
          :ensure=>:present
        },

        {
          :name=>"svc:/smf/manifest/:properties/lib_svc_manifest_system_pfexecd_xml/md5sum",
          :fmri=>"svc:/smf/manifest",
          :property=>"lib_svc_manifest_system_pfexecd_xml/md5sum", :type=>"opaque",
          :value=>"ad8c591e772544921760bf65b1dfc038", :ensure=>:present
        },

        {
          :name=>"svc:/smf/manifest/:properties/lib_svc_manifest_system_picl_xml/md5sum",
          :fmri=>"svc:/smf/manifest",
          :property=>"lib_svc_manifest_system_picl_xml/md5sum", :type=>"opaque",
          :value=>"1e0224ad7830c013b50ece40c0cf7f56", :ensure=>:present
        },

        {
          :name=>"svc:/network/nis/domain:default/:properties/config/domainname",
          :fmri=>"svc:/network/nis/domain:default", :property=>"config/domainname",
          :type=>"hostname", :value=>"oracle.com", :ensure=>:present
        },

        {
          :name=>"svc:/network/dns/client:default/:properties/config/nameserver",
          :fmri=>"svc:/network/dns/client:default", :property=>"config/nameserver",
          :type=>"net_address", :value=>"10.10.10.197 10.10.10.198 192.192.192.132",
          :ensure=>:present
        },

        {
          :name=>"svc:/network/install:default/:properties/install_ipv4_interface/default_route",
          :fmri=>"svc:/network/install:default",
          :property=>"install_ipv4_interface/default_route", :type=>"net_address_v4",
          :value=>"10.10.10.1", :ensure=>:present
        },

        {
          :name=>"svc:/network/install:default/:properties/install_ipv4_interface/static_address",
          :fmri=>"svc:/network/install:default",
          :property=>"install_ipv4_interface/static_address", :type=>"net_address_v4",
          :value=>"10.10.10.91/24", :ensure=>:present
        },

        {
          :name=>"svc:/network/install:default/:properties/install_ipv6_interface/default_route",
          :fmri=>"svc:/network/install:default",
          :property=>"install_ipv6_interface/default_route", :type=>"net_address_v6",
          :value=>"::0", :ensure=>:present
        },

        {
          :name=>"svc:/network/install:default/:properties/install_ipv6_interface/interface_id",
          :fmri=>"svc:/network/install:default",
          :property=>"install_ipv6_interface/interface_id", :type=>"net_address_v6",
          :value=>"::0/0", :ensure=>:present
        },

        {
          :name=>"svc:/system/install/telemetry-manager:files/:properties/periodic/jitter",
          :fmri=>"svc:/system/install/telemetry-manager:files",
          :property=>"periodic/jitter", :type=>"time", :value=>"60", :ensure=>:present
        },

        {
          :name=>"svc:/system/install/telemetry-manager:files/:properties/periodic/period",
          :fmri=>"svc:/system/install/telemetry-manager:files",
          :property=>"periodic/period", :type=>"time", :value=>"86400",
          :ensure=>:present
        },

        {
          :name=>"svc:/system/security/security-extensions:default/:properties/restarter_actions/refresh_complete",
          :fmri=>"svc:/system/security/security-extensions:default",
          :property=>"restarter_actions/refresh_complete", :type=>"time",
          :value=>"1461283526.654946000", :ensure=>:present
        },

        {
          :name=>"svc:/network/ip-interface-management:default/:properties/tm_proppat_t_static-route_destination-type/constraint_name",
          :fmri=>"svc:/network/ip-interface-management:default",
          :property=>"tm_proppat_t_static-route_destination-type/constraint_name",
          :type=>"astring", :value=>"any host net", :ensure=>:present
        },

        {
          :name=>"svc:/application/cups/in-lpd:default/:properties/general/action_authorization",
          :fmri=>"svc:/application/cups/in-lpd:default",
          :property=>"general/action_authorization", :type=>"astring",
          :value=>"solaris.smf.manage.cups", :ensure=>:present
        },

        {
          :name=>"svc:/application/cups/in-lpd:default/:properties/inetd_start/exec",
          :fmri=>"svc:/application/cups/in-lpd:default", :property=>"inetd_start/exec",
          :type=>"astring", :value=>"/usr/lib/cups/daemon/cups-lpd\\ -o\\ document-format=application/octet-stream",
          :ensure=>:present
        },
        {
          :name=>"svc:/application/database/mysql:version_56/:properties/tm_common_name/C",
          :fmri=>"svc:/application/database/mysql:version_56",
          :property=>"tm_common_name/C", :type=>"ustring",
          :value=>"MySQL\\ Database\\ Management\\ System", :ensure=>:present
        },

        {
          :name=>"svc:/network/inetd:default/:properties/tm_pgpatt_method/description_C",
          :fmri=>"svc:/network/inetd:default",
          :property=>"tm_pgpatt_method/description_C", :type=>"ustring",
          :value=>"A\\ method\\ defines\\ how\\ inetd\\ interacts\\ with\\ its\\ services.\\ \\ inetd_start\\ is\\ executed\\ to\\ handle\\ a\\ connection.\\ \\ inetd_offline\\ is\\ executed\\ when\\ the\\ service\\ is\\ taken\\ offline.\\ \\ inetd_online\\ is\\ executed\\ when\\ the\\ service\\ is\\ taken\\ from\\ offline\\ to\\ online.\\ \\ inetd_disable\\ is\\ executed\\ when\\ the\\ service\\ is\\ disabled.\\ \\ inetd_refresh\\ is\\ executed\\ when\\ the\\ service\\ is\\ refreshed.",
          :ensure=>:present },


        {
          :name=>"svc:/application/cups/in-lpd:default/:properties/filesystem_minimal/entities",
          :fmri=>"svc:/application/cups/in-lpd:default",
          :property=>"filesystem_minimal/entities", :type=>"fmri",
          :value=>"svc:/system/filesystem/minimal", :ensure=>:present
        },

        {
          :name=>"svc:/application/cups/in-lpd:default/:properties/loopback/entities",
          :fmri=>"svc:/application/cups/in-lpd:default", :property=>"loopback/entities",
          :type=>"fmri", :value=>"svc:/network/loopback", :ensure=>:present
        },

        {
          :name=>"svc:/application/cups/in-lpd:default/:properties/inetd_start/use_profile",
          :fmri=>"svc:/application/cups/in-lpd:default",
          :property=>"inetd_start/use_profile", :type=>"boolean", :value=>"false",
          :ensure=>:present
        },

        {
          :name=>"svc:/application/cups/scheduler:default/:properties/general/active",
          :fmri=>"svc:/application/cups/scheduler:default", :property=>"general/active",
          :type=>"boolean", :value=>"true", :ensure=>:present
        },

      ].each_with_index do |h,i|
        it "should parse type #{h[:type]} for property #{h[:name]}" do
          expect(instances[i]).to eq(h)
        end
      end
    end
  end
  context "#create" do
    let(:munge) {
      munge = Class.new
      munge.extend PuppetX::Oracle::SolarisProviders::Util::Svcs
      munge.extend Puppet
    }
    context "input munging" do
      {
        :astring=> "a string",
        :ustring=> "still a string",
        :boolean=> "true",
        :count=> "1",
        :integer=> "10",
        :time => "1339662573.051463000"
      }.each_pair { |thing,value|
        it "creates with #{thing}" do
          params[:name]  = "create-#{thing}"
          params[:type]  = thing
          params[:value] = value
          params[:fmri]  = "svc:/bogus/service"
          params[:property] = "config/something"
          described_class.expects(:svccfg).with(
            "-s", params[:fmri],
            "setprop",
            params[:property],
            "=", "#{params[:type]}:",
            munge.munge_value(value,thing)
          )
          described_class.expects(:svccfg).with("-s", params[:fmri], "refresh")
          described_class.expects(:svcprop).with("-f", params[:prop_fmri])
          described_class.expects(:svcprop).with(pg_fmri)
          expect(provider.create).to eq(nil)
        end
      }

      # This is probably a bad example. I'm not sure that we will ever
      # get an actual array here or why it needs to be wrapped in another
      # array but if there is an array it seems to be handled correctly
      {
        :opaque=> ['asasd wewerwef','bcsdf'],
        :astring=> ['asasd wewerwef','bcsdf'],
        :ustring=> ['asasd wewerwef','bcsdf'],
      }.each { |thing,arry|
        it "#{thing} array treated as list" do
          params[:name]  = "create-#{thing}"
          params[:type]  = thing
          params[:value] = [arry]
          params[:fmri]  = "svc:/bogus/service"
          params[:property] = "config/something"
          described_class.expects(:svccfg).with(
            "-s", params[:fmri],
            "setprop",
            params[:property],
            "=", "#{params[:type]}:",
            munge.munge_value(arry,thing)
          )
          described_class.expects(:svccfg).with("-s", params[:fmri], "refresh")
          described_class.expects(:svcprop).with("-f", params[:prop_fmri])
          described_class.expects(:svcprop).with(pg_fmri)
          expect(provider.create).to eq(nil)
        end
      }
      {
        :fmri=> ['svc:/foo svc:/bar','svc:/foo'],
        :host=> ['foo.com bar.com','foo.com'],
        :hostname=> ['a.foo.com b.bar.com','a.foo.com'],
        :net_address=> ['1.2.3.4 3.4.5.6','1.2.3.4'],
        :net_address_v4=> ['1.2.3.4 3.4.5.6','1.2.3.4'],
        :net_address_v6 => ['ff::00 fe::00','ff::00'],
        :uri => ['thing:/stuff thing:/stuff2','thing:/stuff']
      }.each { |thing,arry|
        it "#{thing} value treated as list" do
          params[:name]  = "create-#{thing}"
          params[:type]  = thing
          params[:value] = arry[0]
          params[:fmri]  = "svc:/bogus/service"
          params[:property] = "config/something"
          described_class.expects(:svccfg).with(
            "-s", params[:fmri],
            "setprop",
            params[:property],
            "=", "#{params[:type]}:",
            munge.munge_value(arry[0],thing)
          )
          described_class.expects(:svccfg).with("-s", params[:fmri], "refresh")
          described_class.expects(:svcprop).with("-f", params[:prop_fmri])
          described_class.expects(:svcprop).with(pg_fmri)
          expect(provider.create).to eq(nil)
        end
        it "#{thing} value passes through unmunged" do
          params[:name]  = "create-#{thing}"
          params[:type]  = thing
          params[:value] = arry[1]
          params[:fmri]  = "svc:/bogus/service"
          params[:property] = "config/something"
          described_class.expects(:svccfg).with(
            "-s", params[:fmri],
            "setprop",
            params[:property],
            "=", "#{params[:type]}:",
            munge.munge_value(arry[1],thing)
          )
          described_class.expects(:svccfg).with("-s", params[:fmri], "refresh")
          described_class.expects(:svcprop).with("-f", params[:prop_fmri])
          described_class.expects(:svcprop).with(pg_fmri)
          expect(provider.create).to eq(nil)
        end
      }
      it "passes unmunged value without type" do
        params.delete(:type)
        params[:value] = "this is an astring"
        munged = munge.munge_value(params[:value])
        described_class.expects(:svccfg).with(
          "-s", params[:fmri],
          "setprop",
          params[:property],
          "=",
          munged
        )
        described_class.expects(:svccfg).with("-s", params[:fmri], "refresh")
        provider.stubs(:pg_exists?).returns true
        expect(provider.create).to eq(nil)
      end

      {
        %q(simple string) => %q(simple\\ string),
        %q(it's less simple) => %q(it\\'s\\ less\\ simple),
        %q(echo foo > /etc/shadow) => %q(echo\\ foo\\ \\>\\ /etc/shadow)
      }.each_pair { |k,v|
        it "escapes shell characters in strings" do
          params[:type] = :astring
          params[:value] = k
          expect(provider.to_svcs(k)).to eq(v)
        end
      }

      # String escapes in multi-value types generally can't be tested here as
      # they must first be valid and are weeded out by the input validation
      # on the puppet type
    end

    context "property group" do
      it "executes svccfg addpg for a defined type" do
        params[:property] = "pkg"
        params[:type]     = :application
        params.delete(:value)
        described_class.expects(:svccfg).with(
          "-s", params[:fmri],
          "addpg",
          params[:property],
          params[:type].to_s
        )
        described_class.expects(:svccfg).with("-s", params[:fmri], "refresh")
        expect(provider.create).to eq(nil)
      end
      it "executes svccfg addpg for a user supplied type" do
        params[:property] = "pkg"
        params[:type]     = "foobar"
        params.delete(:value)
        described_class.expects(:svccfg).with(
          "-s", params[:fmri],
          "addpg",
          params[:property],
          params[:type].to_s
        )
        described_class.expects(:svccfg).with("-s", params[:fmri], "refresh")
        expect(provider.create).to eq(nil)
      end
      it "automatically creates a non-existent pg with type :application" do
        pg = params[:property].slice(0,params[:property].rindex('/'))
        # Create the property group
        described_class.expects(:svccfg).with(
          "-s", params[:fmri],
          "addpg", pg, :application
        )
        # Create the property
        described_class.expects(:svccfg).with(
          "-s", params[:fmri], "setprop",
          params[:property],
          '=', "#{params[:type]}:",
          munge.munge_value(params[:value],params[:type])
        )
        # refresh the service
        described_class.expects(:svccfg).with("-s",params[:fmri],"refresh")
        expect(provider.create).to eq(nil)
      end
    end
  end
  context "#destroy" do
    it "does not require value for ensure => :absent" do
      params={:ensure=>:absent, :fmri => "svc:/application/puppet:agent"}
      expect{resource}.not_to raise_error
    end
    it "removes a property with delprop" do
      described_class.expects(:svccfg).with("-s",params[:fmri],"delprop",params[:property])
      described_class.expects(:svccfg).with("-s",params[:fmri],"refresh")
      expect(provider.destroy).to eq(nil)
    end
    it "removes a property group with delprop" do
      params[:property] = "tm_proppat_nt_config_user"
      described_class.expects(:svccfg).with("-s",params[:fmri],"delprop",params[:property])
      described_class.expects(:svccfg).with("-s",params[:fmri],"refresh")
      expect(provider.destroy).to eq(nil)
    end
  end
  context "#delcust" do
    it "should delcust"
    it "should delcust property"
  end
end

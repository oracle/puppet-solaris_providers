require 'spec_helper'

describe Puppet::Type.type(:nsswitch).provider(:solaris) do

  let(:params) do
    {
      :name => "current",
      :rpc => "files ldap",
      :ensure => :present,
    }
  end

  let(:resource) { Puppet::Type.type(:nsswitch).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/svccfg').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/svccfg').returns true
    FileTest.stubs(:file?).with('/usr/bin/svcprop').returns true
    FileTest.stubs(:executable?).with('/usr/bin/svcprop').returns true
  end

  context "responds to" do
    (Puppet::Type.type(:nsswitch).validproperties -
     [:ensure]).each { |property|
      it property do is_expected.to respond_to(property.intern) end
      it "#{property}=" do is_expected.to respond_to("#{property}=".intern) end
    }

    %w(
      exists?
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
    }
  end

  describe "should get a list of nsswitchs" do
    described_class.expects(:svcprop).
      with("-p", "config", Nsswitch_fmri).returns File.read(
                                                    my_fixture('svcprop_nsswitch.txt'))
    instances = described_class.instances.map { |p|
      hsh={}
      Puppet::Type.type(:nsswitch).validproperties.each { |fld|
        hsh[fld] = p.get(fld)
      }
      hsh
    }
    it "has one(1) results" do
      expect(instances.size).to eq(1)
    end

    it "equal to" do
      expect(instances[-1]).to eq(
                                 {:ensure=>:present,
                                  :default=>"files ldap dns",
                                  :host=>"files ldap dns",
                                  :password=>"files ldap dns",
                                  :group=>"files ldap dns",
                                  :network=>"files ldap dns",
                                  :rpc=>"files ldap dns",
                                  :ether=>"files ldap dns",
                                  :netmask=>"files ldap dns",
                                  :bootparam=>"files ldap dns",
                                  :publickey=>"files ldap dns",
                                  :netgroup=>"files ldap dns",
                                  :automount=>"files ldap dns",
                                  :alias=>"files ldap dns",
                                  :service=>"files ldap dns",
                                  :project=>"files ldap dns",
                                  :auth_attr=>"files ldap dns",
                                  :prof_attr=>"files ldap dns",
                                  :tnrhtp=>"files ldap dns",
                                  :tnrhdb=>"files ldap dns",
                                  :sudoer=>"files ldap dns",
                                  :ipnodes=>:absent,
                                  :protocol=>:absent,
                                  :printer=>"user files"}
                               )
    end
  end

  context "#create" do
    it "throws an error" do
      expect{provider.create}.to raise_error(Puppet::Error, /can only/)
    end
  end
  context "#destroy" do
    it "throws an error" do
      expect{provider.destroy}.to raise_error(Puppet::Error, /can only/)
    end
  end

  # This is sort of overkill since we are defining the methods automatically
  Puppet::Type.type(:nsswitch).validproperties.each { |thing|
    next if thing==:ensure
    #if thing == :alias
     # xit "verify alias processing it fails in puppet 3.6.2 spec tests"
     # next
    # end
  context "##{thing}=" do
    it "sets value" do
      described_class.expects(:svccfg).with(
        '-s', Nsswitch_fmri, "setprop", "config/#{thing}=files")
      expect(provider.send("#{thing}=".intern,"files")).to eq('files')
    end
    it "sets complex value" do
      described_class.expects(:svccfg).with(
        '-s', Nsswitch_fmri, "setprop",
        "config/#{thing}=files dns:\\[notfound=return\\]")
      expect(provider.send("#{thing}=".intern,"files dns:[notfound=return]")).
        to eq('files dns:[notfound=return]')
    end
  end
  }
end

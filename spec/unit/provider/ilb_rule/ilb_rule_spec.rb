#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:ilb_rule).provider(:ilb_rule) do

  let(:params) do
    {
      :name=>"nat1", :ensure=>:present,
      :servergroup=>"sg10", :persistent=>"/24", :enabled=>:true,
      :vip=>"81.0.0.10", :port=>"5000-5009", :protocol=>:tcp,
      :lbalg=>"roundrobin", :topo_type=>:nat,
      :proxy_src=>"60.0.0.101-60.0.0.104", :hc_name=>"hc1", :hc_port=>:any,
      :conn_drain=>"180", :nat_timeout=>"180", :persist_timeout=>"180"
    }
  end
  let(:resource) { Puppet::Type.type(:ilb_rule).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ilbadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ilbadm').returns true
  end

  describe "responds to" do
    [:exists?, :create, :destroy, :enabled, :enabled=].each { |method|
      it { is_expected.to respond_to(method) }
    }
  end

  describe "#instances" do
    described_class.expects(:ilbadm).with(
      'show-rule', '-f').returns File.read(
        my_fixture('show-rule_f.txt'))

      instances = described_class.instances.map { |p|
        hsh={}
        [
          :name, :ensure,
          :persistent, :enabled,
          :vip, :port, :protocol,
          :lbalg, :topo_type, :proxy_src,
          :hc_name, :hc_port,
          :conn_drain, :nat_timeout, :persist_timeout
        ].each { |fld|
          hsh[fld] = p.get(fld)
        }
        hsh
      }


      it "has five(5) results" do
        expect(instances.size).to eq(5)
      end

      it "first instance is nat1" do
        expect(instances[0]).to eq(
          {:name=>"nat1", :ensure=>:present, :persistent=>"/24",
           :enabled=>:true, :vip=>"81.0.0.10", :port=>"5000-5009",
           :protocol=>:tcp, :lbalg=>"roundrobin", :topo_type=>:nat,
           :proxy_src=>"60.0.0.101-60.0.0.104", :hc_name=>"hc1",
           :hc_port=>:any, :conn_drain=>"180", :nat_timeout=>"180",
           :persist_timeout=>"180"}
        )
      end
      it "third instance is rule3 (IPv6)" do
        expect(instances[2]).to eq(
          {:name=>"rule3", :ensure=>:present, :persistent=>:absent,
           :enabled=>:true, :vip=>"2003::1", :port=>"21", :protocol=>:tcp,
           :lbalg=>"roundrobin", :topo_type=>:dsr, :proxy_src=>:absent,
           :hc_name=>:absent, :hc_port=>:absent,
           :conn_drain=>:absent, :nat_timeout=>:absent,
           :persist_timeout=>:absent}
        )
      end
      it "last instance is rule5 (IPv4)" do
        expect(instances[-1]).to eq(
          {:name=>"rule5", :ensure=>:present, :persistent=>:absent,
           :enabled=>:true, :vip=>"1.2.3.6", :port=>"21", :protocol=>:tcp,
           :lbalg=>"roundrobin", :topo_type=>:dsr, :proxy_src=>:absent,
           :hc_name=>:absent, :hc_port=>:absent,
           :conn_drain=>:absent, :nat_timeout=>:absent,
           :persist_timeout=>:absent}
        )
      end
  end
  describe ".create" do
    it "creates a rule" do
      described_class.expects(:ilbadm).with(
        'create-rule', '-e', '-p',
        '-i', 'vip=81.0.0.10,port=5000-5009,protocol=tcp',
        '-m', 'lbalg=roundrobin,proxy_src=60.0.0.101-60.0.0.104,type=nat',
        '-h', 'hc-name=hc1,hc-port=any',
        '-t', 'conn-drain=180,nat-timeout=180,persist-timeout=180',
        '-o', 'sg10', 'nat1'
      )
      expect(provider.create).to eq nil
    end
  end
  describe ".destroy" do
    it "destroys a server" do
      described_class.expects(:ilbadm).with(
        'delete-rule', resource[:name]
      )
      expect(provider.destroy).to eq nil
    end
  end

  # Unlike the other setter methods enable does not delete then re-create
  describe ".enabled=" do
    # :absent sid is not vaild in normal execution
    # This is bypassing resource property fetching and calling the
    # method directly
    it "enables a server" do
      described_class.expects(:ilbadm).with('enable-rule', resource[:name])
      expect(provider.enabled=:true).to eq(:true)
    end
    it "disables a server" do
      described_class.expects(:ilbadm).with('disable-rule', resource[:name])
      expect(provider.enabled=:false).to eq(:false)
    end
  end
  [
    :persistent=,
    :vip=, :port=, :protocol=,
    :lbalg=, :topo_type=, :proxy_src=,
    :hc_name=, :hc_port=,
    :conn_drain=, :nat_timeout=, :persist_timeout=
  ].each { |method|
    describe ".#{method}" do
      it "destroys then re-creates the rule" do
        described_class.expects(:ilbadm).with('delete-rule', resource[:name])
        described_class.expects(:ilbadm).with(
          'create-rule', '-e', '-p',
          '-i', 'vip=81.0.0.10,port=5000-5009,protocol=tcp',
          '-m', 'lbalg=roundrobin,proxy_src=60.0.0.101-60.0.0.104,type=nat',
          '-h', 'hc-name=hc1,hc-port=any',
          '-t', 'conn-drain=180,nat-timeout=180,persist-timeout=180',
          '-o', 'sg10', 'nat1'
        )
        # There is no validation in the setter methods only in the resource
        # creation
        expect(provider.send(method,"foo")).to eq("foo")
      end
    end
  }
end

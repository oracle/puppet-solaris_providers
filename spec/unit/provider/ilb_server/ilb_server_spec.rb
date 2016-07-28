#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:ilb_server).provider(:ilb_server) do

  let(:params) do
    {
      :name => 'sg1|localhost|80',
    }
  end
  let(:resource) { Puppet::Type.type(:ilb_server).new(params) }
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
      'show-servergroup', '-o', 'SGNAME,SERVERID,MINPORT,MAXPORT,IP_ADDRESS',
      '-p').returns File.read(
      my_fixture('show-servergroup_o_SGNAME_SERVERID_MINPORT_MAXPORT_IP_ADDRESS_p.txt'))

    described_class.expects(:ilbadm).with(
      'show-server', '-o', 'servergroup,serverid,status',
      '-p').returns File.read(
        my_fixture('show-server_o_servergroup_serverid_status_p.txt'))

    instances = described_class.instances.map { |p|
    {
          :ensure => p.get(:ensure),
          :name => p.get(:name),
          :server => p.get(:server),
          :servergroup => p.get(:servergroup),
          :port => p.get(:port),
          :sid => p.get(:sid),
          :enabled => p.get(:enabled),
          }
    }

      it "has twelve(12) results" do
        expect(instances.size).to eq(12)
      end

      it "first instance is sg1|10.1.1.3|21" do
        expect(instances[0]).to eq(
          {:ensure=>:present, :name=>"sg1|10.1.1.3|21",
           :server=>"10.1.1.3", :servergroup=>"sg1",
           :port=>"21", :sid=>"_sg1.0", :enabled=>:false}
        )
      end
      it "last instance is sg3_v6|[2000::ff]|21" do
        expect(instances[-1]).to eq(
          {:ensure=>:present, :name=>"sg3_v6|[2000::ff]|21",
           :server=>"[2000::ff]", :servergroup=>"sg3_v6",
           :port=>"21", :sid=>"_sg3_v6.1", :enabled=>:true}
        )
      end
  end
  describe ".create" do
    it "creates a server" do
      described_class.expects(:ilbadm).with(
        'add-server', '-s', "server=#{resource[:server]}:#{resource[:port]}",
        resource[:servergroup]
      )
      expect(provider.create).to eq nil
    end
  end
  describe ".destroy" do
    it "destroys a server" do
      described_class.expects(:ilbadm).with(
        'remove-server', '-s', "server=absent",
        resource[:servergroup]
      )
      expect(provider.destroy).to eq nil
    end
  end
  describe ".enabled=" do
    # :absent sid is not vaild in normal execution
    # This is bypassing resource property fetching and calling the
    # method directly
    it "enables a server" do
      described_class.expects(:ilbadm).with('enable-server',:absent)
      expect {provider.enabled=:true}.not_to raise_error
    end
    it "disables a server" do
      described_class.expects(:ilbadm).with('disable-server',:absent)
      expect {provider.enabled=:false}.not_to raise_error
    end
  end
end

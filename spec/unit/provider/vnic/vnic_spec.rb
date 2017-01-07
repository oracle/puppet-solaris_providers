#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:vnic).provider(:vnic) do

  let(:params) do
    {
      :name => "vnic1",
      :lower_link => "net1",
      :ensure => :present,
    }
  end

  let(:resource) { Puppet::Type.type(:vnic).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/dladm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/dladm').returns true
    FileTest.stubs(:file?).with('/usr/sbin/zpool').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/zpool').returns true
  end

  context "responds to" do
    %w(
      lower_link mac_address
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
      it "#{property}=" do is_expected.to respond_to("#{property}=".intern) end
    }

    %w(
      exists? add_options
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
    }
  end

  describe "should get a list of vnics" do
    described_class.expects(:dladm).
      with('show-vnic', '-p', '-o', 'link,over,macaddress').returns File.read(
                                  my_fixture('dladm_show-vnic_p_link,over,macaddress.txt'))
    instances = described_class.instances.map { |p|
      hsh={}
      [:name, :lower_link, :mac_address].each { |fld|
        hsh[fld] = p.get(fld)
      }
      hsh
    }
    it "has ten(10) results" do
      expect(instances.size).to eq(10)
    end

    it "first instance is foo-ld03/net0" do
      expect(instances[0][:name]).to eq("foo-ld03/net0")
    end
    it "first instance lower_link is net0" do
      expect(instances[0][:lower_link]).to eq('net0')
    end
    it "first instance mac_address is net0" do
      expect(instances[0][:mac_address]).to eq('2:8:20:e8:42:11')
    end
    it "last instance is s12b113-backup-1" do
      expect(instances[-1]).to eq(
                                 {:name=>"foo-ld01/net0", :lower_link=>"net0",
                                 :mac_address=>"2:8:20:45:ec:25"}
                               )
    end
  end

  context "#create" do
    it "creates a vnic" do
      described_class.expects(:dladm).
        with('create-vnic', '-l', params[:lower_link], params[:name])
      expect(provider.create).to eq(nil)
    end
    it "creates a vnic with mac_address" do
      params[:mac_address] = 'a1:b2:c3:d4:e5:f6'
      described_class.expects(:dladm).
        with(
          'create-vnic', '-l', params[:lower_link], '-m', params[:mac_address],
          params[:name]
        )
      expect(provider.create).to eq(nil)
    end
    it "creates a vnic with temporary" do
      params[:temporary] = :true
      described_class.expects(:dladm).
        with(
          'create-vnic', '-l', params[:lower_link], '-t', params[:name]
        )
      expect(provider.create).to eq(nil)
    end
  end

  context "#destroy" do
    it "destroys a vnic" do
      described_class.expects(:dladm).with('delete-vnic', params[:name])
      expect(provider.destroy).to eq(nil)
    end
  end
  context "#lower_link=" do
    it "modifies a vnic" do
      described_class.expects(:dladm).with('modify-vnic', '-l', 'net10', params[:name])
      expect(provider.lower_link='net10').to eq('net10')
    end
  end
  context "#mac_address=" do
    it "modifies a vnic" do
      described_class.expects(:dladm).with('modify-vnic', '-m', '1:2:3:4:5:6', params[:name])
      expect(provider.mac_address='1:2:3:4:5:6').to eq('1:2:3:4:5:6')
    end
  end
end

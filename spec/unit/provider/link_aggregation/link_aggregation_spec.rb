#!/usr/bin/env ruby

require 'spec_helper'
describe Puppet::Type.type(:link_aggregation).provider(:link_aggregation) do

  let!(:resource) do
    Puppet::Type.type(:link_aggregation).new(
      :name => "aggr10",
      :ensure => :present,
      :lower_links => ["net10", "net20"],
      :mode => "trunk",
      :policy => "L4",
      :address => "auto",
      :lacpmode => "off",
      :lacptimer => "short"
    )
      end
  let!(:provider) { resource.provider = described_class.new(resource) }


  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/dladm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/dladm').returns true
  end

  # setter methods because we are overriding them
  [:lower_links, :mode, :policy, :lacpmode, :lacptimer, :address,
    :lower_links=, :mode=, :policy=, :lacpmode=, :lacptimer=, :address=,
    :is_temporary? ] .each do |method|
    it { is_expected.to respond_to(method) }
    end

  describe "#instances" do
    it "should have an instances method" do
      expect(described_class).to respond_to :instances
    end

    # The list of aggregations
    described_class.expects(:dladm).with("show-aggr", "-p", "-o",
                                         "link,mode,policy,addrpolicy,lacpactivity,lacptimer")
    .returns File.read(my_fixture('dladm_show-aggr-p-o.txt'))

    # Just return the contents of this file for any aggr
    [0,1].each do |num|
      described_class.expects(:dladm).with("show-aggr", "-x", "-p", "-o", "port", "aggr#{num}")
      .returns File.read(my_fixture('dladm_show-aggr-x-p-o_port_aggrX.txt'))
    end

    instances = described_class.instances.map { |p|
      {
        :name => p.get(:name),
        :ensure => p.get(:ensure),
        :lower_links => p.get(:lower_links),
        :mode => p.get(:mode),
        :policy => p.get(:policy),
        :address => p.get(:address),
        :lacpmode => p.get(:lacpmode),
        :lacptimer => p.get(:lacptimer)
      }
    }

    it "with the expected number of instances" do
      expect(instances.size).to eq(2)
    end

    [
      {
      :name => "aggr0",
      :ensure => :present,
      :lower_links =>["net0", "net1"],
      :mode => "dlmp",
      :policy => :absent,
      :address => :absent,
      :lacpmode => :absent,
      :lacptimer => :absent
    },
      {
      :name => "aggr1",
      :ensure => :present,
      :lower_links =>["net0", "net1"],
      :mode => "trunk",
      :policy => "L4",
      :address => "auto",
      :lacpmode => "on",
      :lacptimer => "long"
    }
    ].each_with_index do |h,i|
      it "should parse #{h[:name]}" do
        expect(instances[i]).to eq(h)
      end
    end
      end

  context "validation" do
    it "should use correct args for create" do
      described_class.expects(:dladm).with("create-aggr", '-l', 'net10', '-l',
                                           'net20', '-m', :trunk, '-P', 'L4',
                                           '-L', :off, '-T', :short, '-u',
                                           'auto', 'aggr10')
      expect(provider.create).to eq(nil)
    end
    it "should use correct args for destroy" do
      described_class.expects(:dladm).with("delete-aggr", "aggr10")
      expect(provider.destroy).to eq(nil)
    end

    xdescribe 'lower_links=' do
      # meddling with pry it's right but it needs property_hash populated to
      # properly execute
      it "should add missing links" do
        # net5 will be added
        add_list=["net5"]
        if_list = resource[:lower_links] + add_list
        described_class.expects(:dladm).with("show-aggr", "-P", resource.name)
        described_class.expects(:dladm).with("add-aggr", "-l", *add_list, resource.name)
        expect(provider.lower_links=if_list).to eq(nil)
      end

      it "should remove extra links" do
        # net20 will be removed
        if_list=["net10"]
        remove_list=["net20"]
        described_class.expects(:dladm).with("show-aggr", "-P", resource.name)
        described_class.expects(:dladm).with("remove-aggr", "-l", *remove_list, resource.name)
        expect(provider.lower_links=if_list).to eq(nil)
      end
    end

    it "should use correct args for mode=" do
      described_class.expects(:dladm).with("show-aggr", "-P", resource.name)
      described_class.expects(:dladm).with("create-aggr", '-l', 'net10', '-l',
                                           'net20', '-m', :trunk, '-P', 'L4',
                                           '-L', :off, '-T', :short, '-u',
                                           'auto', 'aggr10')
      described_class.expects(:dladm).with("delete-aggr", resource.name)
      expect(provider.mode="trunk").to eq("trunk")
    end
    it "should use correct args for policy=" do
      described_class.expects(:dladm).with("show-aggr", "-P", resource.name)
      described_class.expects(:dladm).with("modify-aggr", "-P", "L2", resource.name)
      expect(provider.policy="L2").to eq("L2")
    end
    it "should use correct args for lacpmode=" do
      described_class.expects(:dladm).with("show-aggr", "-P", resource.name)
      described_class.expects(:dladm).with("modify-aggr", '-L', 'off', resource.name)
      expect(provider.lacpmode="off").to eq("off")
    end
    it "should use correct args for lacptimer=" do
      described_class.expects(:dladm).with("show-aggr", "-P", resource.name)
      described_class.expects(:dladm).with("modify-aggr", '-T', 'short', resource.name)
      expect(provider.lacptimer="short").to eq("short")
    end
    it "should use correct args for address=" do
      described_class.expects(:dladm).with("show-aggr", "-P", resource.name)
      described_class.expects(:dladm).with("modify-aggr", '-u', '0e:3b:32:eb:d9:eb', resource.name)
      expect(provider.address="0e:3b:32:eb:d9:eb").to eq("0e:3b:32:eb:d9:eb")
    end
    it "should use correct args for add_options" do
      expect(provider.add_options).to eq(["-l", "net10", "-l", "net20", "-m",
                                         :trunk, "-P", "L4", "-L", :off, "-T",
                                         :short, "-u", "auto"])
    end
    it "should fail in is_temporary? for temporary" do
      described_class.expects(:dladm).with("show-aggr", "-P", resource.name).returns
      expect(provider.is_temporary?).to eq(nil)
    end
    it "should not fail in is_temporary? for non-temporary" do
      described_class.expects(:dladm).with("show-aggr", "-P", resource.name).returns Puppet::Error
      expect{provider.is_temporary?}.not_to raise_error
    end
  end

end

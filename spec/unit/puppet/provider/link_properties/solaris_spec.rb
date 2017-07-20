#
require 'spec_helper'

describe Puppet::Type.type(:link_properties).provider(:solaris) do

  let(:params) do
    {
      :name => 'net0',
      :properties => {
        'cpus' => 1,
      }
    }
  end
  let(:resource) { Puppet::Type.type(:link_properties).new(params) }
  let(:provider) {
    provider = described_class.new(resource)
    provider.instance_variable_set(:@property_hash, property_hash)
    return provider
  }

  # Fake a property hash
  let(:property_hash) do
    {
      :name => 'net0',
      :properties => {
        'cpus' => 2,
      },
      :ensure => :present,
    }
  end

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/dladm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/dladm').returns true
  end

  describe "responds to" do
    [:exists?, :create, :properties ].each { |method|
      it { is_expected.to respond_to(method) }
    }
  end
  describe "does not respond to" do
    [:destroy].each { |method|
      it { is_expected.not_to respond_to(method) }
    }
  end

  describe "#instances" do
    described_class.expects(:dladm).with(
      'show-linkprop', '-c', '-o',
      'LINK,PROPERTY,PERM,VALUE,DEFAULT,POSSIBLE',
    ).returns File.read(
                my_fixture('dladm-show-linkprop_o_c_LINK___POSSIBLE.txt'))


    instances = described_class.instances.map { |p|
      hsh={}
      [
        :ensure,
        :name, :properties
      ].each { |fld|
        hsh[fld] = p.get(fld)
      }
      hsh
    }

    it "has one(1) result" do
      expect(instances.size).to eq(1)
    end

    context "with expected contents" do
      hsh = {:ensure=>:present,
             :name=>"net0",
             :properties=>{
               "allowed-dhcp-cids" => :absent,
               "allowed-ips" => "192.168.14.238",
               "authentication" => :absent,
               "autopush" => :absent,
               "cos" => "0",
               "cpus" => :absent,
               "ets-bw-local" => "0",
               "ets-bw-remote-advice" => "0",
               "forward" => "1",
               "mac-address" => "fa:16:3e:4:85:80",
               "max-bw" => :absent,
               "mtu" => "1446",
               "openvswitch" => "off",
               "pfcmap" => "11111111",
               "poll" => "auto",
               "pool" => :absent,
               "priority" => "medium",
               "protection" => :absent,
               "pvlan-tag-mode" => "primary",
               "rx-fanout" => "8",
               "speed-duplex" => :absent,
               "stp" => "1",
               "stp-cost" => "auto",
               "stp-edge" => "1",
               "stp-mcheck" => "0",
               "stp-p2p" => "auto",
               "stp-priority" => "128",
               "tag-mode" => "vlanonly",
               "virtual-switching" => "local",
               "vsi-manager-id" => :absent,
               "vsi-manager-id-encoding" => "oracle_v1",
               "zone" => :absent,}
            }
      [:ensure,:name,:properties].each { |k|
        it "has expected #{k}" do
          expect(instances[0][k]).to eq(hsh[k])
        end
      }
    end
  end
  describe ".create" do
    it "throws an exception" do
      expect{provider.create}.to raise_error(Puppet::Error, /must exist/)
    end
  end
  describe ".insync?" do
    it "is true with value == value" do
      expect(resource.parameter(:properties).insync?(params[:properties].dup)).to eq(true)
    end
    it "is false with value != value" do
      expect(resource.parameter(:properties).insync?(property_hash[:properties])).to eq(false)
    end
  end
  describe ".properties=" do
    it "changes single protocol single property" do
      args=%w(set-linkprop -p cpus=1 net0)
      described_class.expects(:dladm).with(*args)
      expect(provider.properties=params[:properties]).to eq params[:properties]
    end
    it "changes single protocol multiple properties" do
      params[:properties]["stp"] = 0
      args=%w(set-linkprop -p cpus=1,stp=0 net0)
      described_class.expects(:dladm).with(*args)
      expect(provider.properties=params[:properties]).to eq params[:properties]
    end
  end
end

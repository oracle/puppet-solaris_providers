require 'spec_helper'

describe Puppet::Type.type(:interface_properties).provider(:solaris) do

  let(:params) do
    {
      :name => 'net0',
      :properties => {
        'ipv4' => { "mtu" => 1776 },
        'ipv6' => { "mtu" => 2048 },
      }
    }
  end
  let(:resource) { Puppet::Type.type(:interface_properties).new(params) }
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
        'ipv4' => { "mtu" => 1550 },
        'ipv6' => { "mtu" => 2048 },
      },
      :ensure => :present,
    }
  end

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ipadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ipadm').returns true
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
    described_class.expects(:ipadm).with(
      'show-ifprop', '-c', '-o', 'IFNAME,PROPERTY,PROTO,CURRENT,DEFAULT',
    ).returns File.read(
      my_fixture('ipadm_show-ifprop_c_o_IFNAME-PROPERTY-PROTO-CURRENT-DEFAULT.txt'))


      instances = described_class.instances.map { |p|
        hsh={}
        [
          :ensure,
          :name, :temporary, :properties
        ].each { |fld|
          hsh[fld] = p.get(fld)
        }
        hsh
      }

      it "has three(3) results" do
        expect(instances.size).to eq(3)
      end

      context "second instance (defaults)" do
        hsh = {:ensure=>:present,
               :name=>"net0",
               :temporary=>:absent,
               :properties=>{"ipv4"=>{"arp"=>"on", "exchange-routes"=>"on", "forwarding"=>"off", "metric"=>"0", "mtu"=>"1500", "usesrc"=>"none"}, "ipv6"=>{"exchange-routes"=>"on", "forwarding"=>"off", "metric"=>"0", "mtu"=>"1500", "nud"=>"on", "usesrc"=>"none"}, "ip"=>{"standby"=>"off"}},
        }
        [:ensure,:name].each { |k|
          it "has expected #{k}" do
            expect(instances[1][k]).to eq(hsh[k])
          end
        }
        %w(ip ipv4 ipv6).each { |k|
          it "has expected properties=>#{k}" do
            expect(instances[1][:properties][k]).to eq(hsh[:properties][k])
          end
        }
      end
      context "third instance (non-default)" do
        hsh = {:ensure=>:present,
               :name=>"net4",
               :temporary=>:absent,
               :properties=>{
                 "ipv4"=>{"arp"=>"on", "exchange-routes"=>"off",
                          "forwarding"=>"off", "metric"=>"0",
                          "mtu"=>"1776", "usesrc"=>"none"
               },
               "ipv6"=>{"exchange-routes"=>"off",
                        "forwarding"=>"on", "metric"=>"0",
                        "mtu"=>"2048", "nud"=>"on",
                        "usesrc"=>"none"
               },
               "ip"=>{"standby"=>"off"}
               },
        }
        [:ensure,:name].each { |k|
          it "has expected #{k}" do
            expect(instances[2][k]).to eq(hsh[k])
          end
        }
        # Checking each nested hash individually results in clearer errors on
        # differences
        %w(ip ipv4 ipv6).each { |k|
          it "has expected properties=>#{k}" do
            expect(instances[2][:properties][k]).to eq(hsh[:properties][k])
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
  describe "interface/proto syntax" do
    it "munges old style properties" do
      params[:name] = "net0/ipv4"
      params[:properties] = params[:properties]["ipv4"]
      expect(resource[:properties]).to eq({"ipv4" => params[:properties]})
    end
    it "retains new style properties" do
      expect(resource[:properties]).to eq(params[:properties])
    end
  end
  describe ".properties=" do
    it "changes single protocol single property" do
      args=%w(set-ifprop -p mtu=1776 -m ipv4 net0)
      described_class.expects(:ipadm).with(*args)
      expect(provider.properties=params[:properties]).to eq params[:properties]
    end
    it "changes single protocol multiple properties" do
      args=[
        %w(set-ifprop -p mtu=1776 -m ipv4 net0),
        %w(set-ifprop -p nud=on -m ipv4 net0)]
      described_class.expects(:ipadm).with(*args[0])
      described_class.expects(:ipadm).with(*args[1])
      params[:properties]["ipv4"]["nud"] = "on"
      expect(provider.properties=params[:properties]).to eq params[:properties]
    end
    it "changes multiple protocol multiple properties" do
      args1=[
        %w(set-ifprop -p mtu=1776 -m ipv4 net0),
        %w(set-ifprop -p nud=on -m ipv4 net0)]
      described_class.expects(:ipadm).with(*args1[0])
      described_class.expects(:ipadm).with(*args1[1])
      args2=%w(set-ifprop -p nud=on -m ipv6 net0)
      described_class.expects(:ipadm).with(*args2)
      params[:properties]["ipv4"]["nud"] = "on"
      params[:properties]["ipv6"]["nud"] = "on"
      expect(provider.properties=params[:properties]).to eq params[:properties]
    end
  end
end

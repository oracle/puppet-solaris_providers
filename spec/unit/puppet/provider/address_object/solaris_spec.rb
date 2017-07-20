require 'spec_helper'
describe Puppet::Type.type(:address_object).provider(:solaris) do

  let(:resource) do
    Puppet::Type.type(:address_object).new(
      :name => 'myobj',
      :ensure => :present
    )
      end

  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ipadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ipadm').returns true
  end

  context "responds to" do
    [:address_type, :address, :remote_address, :down,
      :seconds, :hostname, :interface_id, :remote_interface_id, :stateful,
      :stateless ].each { |property|
      it property do is_expected.to respond_to(property) end
      it "#{property}=" do is_expected.to respond_to("#{property}=") end
    }

    [:enable,:exists?,:add_options,:is_temp].each { |property|
      it property do is_expected.to respond_to(property) end
    }
  end

  describe "creates a resource" do
    [
      [:temporary,:true,%w(-t)],
      [:address_type,:static,["-T", :static]],
      [:address_type,:vrrp,["-T", :vrrp]],
      [:routername,'1.2.3.4',["-n", '1.2.3.4']],
      [:address_type,:dhcp,["-T", :dhcp]],
      [:address,"1.2.3.4",%w(-a local=1.2.3.4)],
      [:remote_address,"1.2.3.4",%w(-a remote=1.2.3.4)],
      [:down,:true,%w(-d)],
      [:seconds,"10",%w(-w 10)],
      [:hostname,"foo",%w(-h foo)],
      [:interface_id,"::1a:2b:3c:4d",%w(-i local=::1a:2b:3c:4d)],
      [:remote_interface_id,"::1a:2b:3c:4d",%w(-i remote=::1a:2b:3c:4d)],
      [:stateful,"yes",%w(-p stateful=yes)],
      [:stateless,"no",%w(-p stateless=no)]
    ].each { |arr|
      it "sets the option for #{arr[0]}" do
        resource[arr[0]] = arr[1]
        expect(provider.add_options).to eq(*arr[2..-1])
      end
    }

    it 'with complex create-addr options' do
      resource[:temporary] = :true
      resource[:address_type] = :static
      resource[:address] = "1.2.3.4"
      resource[:remote_address] = "2.3.4.5"
      resource[:down] = :true
      resource[:stateful] = :yes
      resource[:stateless] = :no
      expect(provider.add_options).to eq(["-t", "-T", :static, "-a", "local=1.2.3.4", "-a", "remote=2.3.4.5", "-d", "-p", "stateful=yes", "-p", "stateless=no"])
    end
  end

  describe 'when parsing interfaces' do
    context 'with a local static address' do
      before :each do
        described_class.stubs(:ipadm).with(
          "show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:static:ok:\\127.0.0.1/8"
      end

      it 'should find one object' do
        expect(described_class.instances.size).to eq(1)
      end

      it 'should parse the object properly' do
        expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
          :name => "lo0/v4",
          :ensure => :present,
          :address => '127.0.0.1/8',
          :remote_address => :absent,
          :address_type => 'static',
          :down => :false,
          :enable => :true
        } )
          end
    end

    context 'with a point-to-point address' do
      before :each do
        described_class.stubs(:ipadm).with(
          "show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:static:ok:\\127.0.0.1/8->\\1.2.3.4/8"
      end

      it 'should parse the object properly' do
        expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
          :name => "lo0/v4",
          :ensure => :present,
          :address => '127.0.0.1/8',
          :remote_address => '1.2.3.4/8',
          :address_type => 'static',
          :down => :false,
          :enable => :true
        } )
          end
    end

    context 'with a dhcp address' do
      before :each do
        described_class.stubs(:ipadm).with(
          "show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:dhcp:ok:?"
      end

      it 'should parse the object properly' do
        expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq({
          :name=>"lo0/v4",
          :ensure=>:present,
          :address_type=>"dhcp",
          :seconds=>:absent,
          :hostname=>:absent
        }
        )
          end
    end

    context 'with a disabled state' do
      before :each do
        described_class.stubs(:ipadm).with(
          "show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:static:disabled:"
      end

      it 'should parse the object properly' do
        expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
          :name => "lo0/v4",
          :ensure => :present,
          :address => :absent,
          :remote_address => :absent,
          :address_type => 'static',
          :down => :true,
          :enable => :false
        } )
          end
    end

    context 'with a down state' do
      before :each do
        described_class.stubs(:ipadm).with(
          "show-addr", "-p", "-o", "addrobj,type,state,addr").returns "lo0/v4:static:down:"
      end

      it 'should parse the object properly' do
        expect(
          described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
          :name => "lo0/v4",
          :ensure => :present,
          :address => :absent,
          :remote_address => :absent,
          :address_type => 'static',
          :down => :true,
          :enable => :true
        } )
          end
    end
  end
end

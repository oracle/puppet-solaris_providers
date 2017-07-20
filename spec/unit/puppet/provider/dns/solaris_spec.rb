require 'spec_helper'

describe Puppet::Type.type(:dns).provider(:solaris) do

  let(:params) do
    {
      :name => "current",
      :ensure => :present
    }
  end
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:error_pattern) { /Invalid/ }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/svccfg').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/svccfg').returns true
    FileTest.stubs(:file?).with('/usr/bin/svcprop').returns true
    FileTest.stubs(:executable?).with('/usr/bin/svcprop').returns true
  end

  # Validate properties
  [:nameserver, :domain, :search, :sortlist, :options].each { |method|
    it { is_expected.to respond_to(method) }
    it { is_expected.to respond_to("#{method}=".to_sym) }
  }

  # There is no setter method for flush
  it { is_expected.to respond_to(:flush) }

  describe "#instances" do
    described_class.expects(:svcprop).with(
      "-p", "config", Dns_fmri).returns File.read(
                                          my_fixture('svcprop_p_config_Dns_fmri.txt'))

    instances = described_class.instances.map { |p|
      {
        :ensure => p.get(:ensure),
        :name => p.get(:name),
        :nameserver => p.get(:nameserver),
        :domain => p.get(:domain),
        :search => p.get(:search),
        :sortlist => p.get(:sortlist),
        :options => p.get(:options)
      }
    }

    it "should only have one result" do
      expect(instances.size).to eq(1)
    end

    { :name => 'current',
      :nameserver => %q(10.1.1.197 10.2.2.198 192.3.3.132),
      :domain => "oracle.com",
      :search => "us.oracle.com oracle.com",
      :sortlist => "10.1.2.3 10.2.3.4",
      :options => %q(retrans:3 retry:1 timeout:3 ndots:2)
    }.each_pair { |opt,value|

      it "has the correct #{opt}" do
        expect(instances[0][opt]).to eq(value)
      end
    }

    describe "when validating defined properties" do
      Puppet::Type.type(:dns).validproperties.each do |field|
        pg = "config"
        it "should be able to see the #{pg}/#{field} SMF property" do
          expect(instances[0][field]).not_to eq(nil)
        end
      end  # validproperties
    end  # validating default values
  end
  describe "correctly formats" do
    {
      :nameserver= => {
        :absent => %q^\'\'^,
        "1.2.3.4" => %q^1.2.3.4^,
        "fe80::3e07:54ff:fe53:c704" => %q^fe80::3e07:54ff:fe53:c704^,
        "[fe80::3e07:54ff:fe53:c704]" => %q^\\[fe80::3e07:54ff:fe53:c704\\]^,
        %w(1.2.3.4 2.3.4.5) => %w^( 1.2.3.4 2.3.4.5 )^
      },
      :domain= => {
        :absent => %q^\'\'^,
        "foo.com" => %q^foo.com^,
        "foo.bar.com" => %q^foo.bar.com^
      },
      :search= => {
        :absent => %q^\'\'^,
        "foo.com" => %q^foo.com^,
        "foo.bar.com" => %q^foo.bar.com^,
        %w(foo.com bar.com) => %w^( foo.com bar.com )^,
      },
      :sortlist= => {
        :absent => %q^\'\'^,
        "1.2.3.4" => %q^1.2.3.4^,
        %w"1.2.3.4 2.3.4.5" => %w^( 1.2.3.4 2.3.4.5 )^,
      },
      :options= => {
        :absent => %q^\'\'^,
        "debug" => %q^debug^,
        %w(debug timeout:3) => %w^( debug timeout:3 )^,
      }
    }.each_pair { |type,hsh|
      context type.inspect do
        hsh.each_pair { |k,v|
          it "#{k} -> #{v}" do
            described_class.expects(:svccfg).with(
              "-s", Dns_fmri, "setprop",
              "config/#{type.slice(0..-2)}=", v)
            expect(resource.send(type,k)).to eq(v)
          end
        }
      end
    }
  end
end

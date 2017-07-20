require 'spec_helper'

describe Puppet::Type.type(:ilb_healthcheck).provider(:solaris) do

  let(:params) do
    {
      :name => 'hc1',
      :timeout => '3',
      :count => '3',
      :interval => '30',
      :test => 'tcp'
    }
  end
  let(:resource) { Puppet::Type.type(:ilb_healthcheck).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ilbadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ilbadm').returns true
  end

  describe "responds to" do
    [:exists?, :create, :destroy ].each { |method|
      it { is_expected.to respond_to(method) }
    }
  end

  describe "#instances" do
    described_class.expects(:ilbadm).with(
      'show-healthcheck').returns File.read(
        my_fixture('show-healthcheck.txt'))

      instances = described_class.instances.map { |p|
        hsh={}
        (
         # Parameters must be enumerated individually
         [:name, :ensure] +
         Puppet::Type.type(:ilb_healthcheck).validproperties
        ).each { |fld|
          hsh[fld] = p.get(fld)
        }
          hsh
      }

      it "has two(2) results" do
        expect(instances.size).to eq(2)
      end

      it "first instance is hc1" do
        expect(instances[0]).to eq(
          {:name=>"hc1", :ensure=>:present, :timeout=>"2", :count=>"3",
           :interval=>"10", :test=>"tcp", :default_ping=>:true}
        )
      end
      it "last instance is hc2" do
        expect(instances[-1]).to eq(
          {:name=>"hc2", :ensure=>:present, :timeout=>"1", :count=>"5",
           :interval=>"20", :test=>"/bin/false", :default_ping=>:true}
        )
      end
  end
  describe ".create" do
    it "creates a healthcheck" do
      described_class.expects(:ilbadm).with(
        'create-healthcheck',
        '-h', 'hc-timeout=3,hc-count=3,hc-interval=30,hc-test=tcp',
        'hc1'
      )
      expect(provider.create).to eq nil
    end
    it "creates a healthcheck with ping disabled" do
      params[:default_ping] = :false
      described_class.expects(:ilbadm).with(
        'create-healthcheck', '-n',
        '-h', 'hc-timeout=3,hc-count=3,hc-interval=30,hc-test=tcp',
        'hc1'
      )
      expect(provider.create).to eq nil
    end
  end
  describe ".destroy" do
    it "destroys a healthcheck" do
      described_class.expects(:ilbadm).with(
        'delete-healthcheck', resource[:name]
      )
      expect(provider.destroy).to eq nil
    end
  end

  (
    Puppet::Type.type(:ilb_healthcheck).validproperties -
    [:ensure]
  )
  .each { |prop|
    describe ".#{prop}=" do
      it "destroys then re-creates the healthcheck" do
        described_class.expects(:ilbadm).with('delete-healthcheck', resource[:name])
      described_class.expects(:ilbadm).with(
        'create-healthcheck',
        '-h', 'hc-timeout=3,hc-count=3,hc-interval=30,hc-test=tcp',
        'hc1'
      )
        # There is no validation in the setter methods only in the resource
        # creation
        expect(provider.send("#{prop}=","foo")).to eq("foo")
      end
    end
  }
end

require 'spec_helper'

describe Puppet::Type.type(:ipmp_interface).provider(:ipmp_interface) do

  let(:params) do
    {
      :name => 'ipmp0',
      :interfaces => %w(net0 net1)
    }
  end
  let(:resource) { Puppet::Type.type(:ipmp_interface).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ipadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ipadm').returns true
  end

  describe "responds to" do
    [:exists?, :create, :destroy, :add_options ].each { |method|
      it { is_expected.to respond_to(method) }
    }
  end

  describe "#instances" do
    described_class.expects(:ipadm).with(
      'show-if', '-p', '-o', 'IFNAME,CLASS,PERSISTENT,OVER',
    ).returns File.read(
      my_fixture('show-if_p_o_IFNAME_CLASS_PERSISTENT_OVER.txt'))


      instances = described_class.instances.map { |p|
        hsh={}
        [
          :ensure,
          :name, :temporary, :interfaces
        ].each { |fld|
          hsh[fld] = p.get(fld)
        }
        hsh
      }

      it "has two(2) results" do
        expect(instances.size).to eq(2)
      end

      it "first instance is ipmp0" do
        expect(instances[0]).to eq(
          {:ensure=>:present, :name=>"ipmp0",
           :interfaces => %w(net1 net2),
           :temporary => :false }
        )
      end
      it "second instance is ipmp3" do
        expect(instances[1]).to eq(
          {:ensure=>:present, :name=>"ipmp3",
           :interfaces => %w(net3),
           :temporary => :true }
        )
      end
  end
  describe ".create" do
    it "creates an interface" do
      described_class.expects(:ipadm).with(
        'create-ipmp', '-i', params[:interfaces] * ',', params[:name]
      )
      expect(provider.create).to eq nil
    end
    it "creates a temporary interface" do
      params[:temporary] = :true
      described_class.expects(:ipadm).with(
        'create-ipmp', '-t', '-i', params[:interfaces] * ',', params[:name]
      )
      expect(provider.create).to eq nil
    end
  end
  describe ".destroy" do
    it "destroys an interface" do
      provider.instance_variable_set(
        :@property_hash,
        {
          # Fake the existence of the interface
          :ensure => :present,
          :interfaces => params[:interfaces],
        }
      )
      described_class.expects(:ipadm).with(
        'remove-ipmp', '-i', params[:interfaces] * ',', params[:name]
      )
      described_class.expects(:ipadm).with(
        'delete-ipmp', params[:name]
      )
      expect(provider.destroy).to eq nil
    end
  end
  describe ".interfaces=" do
    before(:each) do
      provider.instance_variable_set(
        :@property_hash,
        {:interfaces => params[:interfaces] }
      )
    end
    it "adds an interface " do
      described_class.expects(:ipadm).with(
        'add-ipmp','-i','net1000',params[:name])
      expect {provider.interfaces=(params[:interfaces] + ['net1000'])}.
        not_to raise_error
    end
    it "removes an interface" do
      described_class.expects(:ipadm).with(
        'remove-ipmp','-i','net1', params[:name])
      expect {provider.interfaces=%w(net0)}.not_to raise_error
    end
  end
  describe "temporary" do
    before(:each) do
      provider.instance_variable_set(
        :@property_hash,
        {
          # Fake the existence of the interface
          :ensure => :present,
          :interfaces => params[:interfaces],
          :temporary => :true }
      )
      params[:temporary]=:true
    end
    context ".interfaces=" do
      it "destroys and recreates the interface" do
        described_class.expects(:ipadm).with(
          'remove-ipmp', '-i', params[:interfaces] * ',', params[:name])
        described_class.expects(:ipadm).with(
          'delete-ipmp', params[:name]
        )
        described_class.expects(:ipadm).with(
          'create-ipmp', '-i', params[:interfaces] * ',', params[:name])
        # This isn't actually testing the addition. I can't figure out
        # how to mock it the correct way to change the interfaces for the
        # resource on the fly. It is however executing the remove and creation
        expect {provider.interfaces=(params[:interfaces] + %w(net1000))}.
          not_to raise_error
      end
    end
    context ".temporary=" do
      it "destroys and recreates the interface" do
        described_class.expects(:ipadm).with(
          'remove-ipmp', '-i', params[:interfaces] * ',', params[:name])
        described_class.expects(:ipadm).with(
          'delete-ipmp', params[:name]
        )
        described_class.expects(:ipadm).with(
          'create-ipmp', '-i', params[:interfaces] * ',', params[:name])
        expect {provider.temporary=:false}.
          not_to raise_error
      end
    end
  end
end

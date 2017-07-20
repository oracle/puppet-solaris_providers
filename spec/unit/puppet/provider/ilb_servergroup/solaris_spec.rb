require 'spec_helper'

describe Puppet::Type.type(:ilb_servergroup).provider(:solaris) do

  let(:params) do
    {
      :name => "sg1"
    }
  end
  let(:resource) { Puppet::Type.type(:ilb_servergroup).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ilbadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ilbadm').returns true
  end

  describe "responds to" do
    [:exists?, :create, :destroy].each { |method|
      it { is_expected.to respond_to(method) }
    }
  end

  describe "#instances" do
    described_class.expects(:ilbadm).with(
      'show-servergroup', '-o', 'sgname', '-p').returns File.read(
      my_fixture('show-servergroup_o_sgname_p.txt'))

    instances = described_class.instances.map { |p|
    {
          :ensure => p.get(:ensure),
          :name => p.get(:name),
          }
    }

      it "has four(4) results" do
        expect(instances.size).to eq(4)
      end

      it "first instance is sg1" do
        expect(instances[0][:name]).to eq('sg1')
      end
      it "last instance is sg4" do
        expect(instances[-1][:name]).to eq('sg4')
      end
  end
  describe ".create" do
    it "creates a server group" do
      described_class.expects(:ilbadm).with('create-servergroup', params[:name])
      expect(provider.create).to eq nil
    end
  end
  describe ".destroy" do
    it "destroys a server group" do
      described_class.expects(:ilbadm).with('delete-servergroup', params[:name])
      expect(provider.destroy).to eq nil
    end
  end
end

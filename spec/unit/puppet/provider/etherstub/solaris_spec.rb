require 'spec_helper'

describe Puppet::Type.type(:etherstub).provider(:solaris) do

  let(:params) do
    {
      :name => "es1",
      :ensure => :present,
    }
  end

  let(:resource) { Puppet::Type.type(:etherstub).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/dladm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/dladm').returns true
  end

  context "responds to" do
    %w(
      exists? add_options
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
    }
  end

  describe "should get a list resources" do
    described_class.expects(:dladm).
      with('show-etherstub', '-p', '-o', 'link').returns File.read(
                                                           my_fixture('dladm_show-etherstub_p_o_link.txt'))
    instances = described_class.instances.map { |p|
      hsh={}
      [:name].each { |fld|
        hsh[fld] = p.get(fld)
      }
      hsh
    }
    it "has five(5) results" do
      expect(instances.size).to eq(5)
    end

    it "first instance is S1" do
      expect(instances[0][:name]).to eq("S1")
    end
    it "second instance is s1" do
      expect(instances[1][:name]).to eq("s1")
    end
    it "last instance is s1" do
      expect(instances[-1][:name]).to eq("sf1_1")
    end
  end

  context "#create" do
    it "creates a etherstub" do
      described_class.expects(:dladm).
        with('create-etherstub', params[:name])
      expect(provider.create).to eq(nil)
    end
    it "creates a etherstub with temporary" do
      params[:temporary] = :true
      described_class.expects(:dladm).
        with(
          'create-etherstub', '-t', params[:name]
        )
      expect(provider.create).to eq(nil)
    end
  end

  context "#destroy" do
    it "destroys a etherstub" do
      described_class.expects(:dladm).with('delete-etherstub', params[:name])
      expect(provider.destroy).to eq(nil)
    end
  end
end

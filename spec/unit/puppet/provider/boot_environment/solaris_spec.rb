require 'spec_helper'
require 'mocha/api'

include Mocha::API
mocha_setup

describe Puppet::Type.type(:boot_environment).provider(:solaris) do

  let(:params) do
    {
      :name => "be1",
      :description => "new be",
      :ensure => :present,
      :options => { :property => 'value'},
    }
  end

  let(:resource) { Puppet::Type.type(:boot_environment).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/beadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/beadm').returns true
    FileTest.stubs(:file?).with('/usr/sbin/zpool').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/zpool').returns true
  end

  context "responds to" do
    %w(
      activate
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
      it "#{property}=" do is_expected.to respond_to("#{property}=".intern) end
    }

    %w(
      exists? build_flags
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
    }
  end

  describe "should get a list of service properties" do
    described_class.expects(:beadm).
      with(:list, '-H').returns File.read(
                                  my_fixture('beadm_list_H.txt'))
    instances = described_class.instances.map { |p|
      hsh={}
      [:name, :activate, :ensure, :running, :created].each { |fld|
        hsh[fld] = p.get(fld)
      }
      hsh
    }
    it "has two(2) results" do
      expect(instances.size).to eq(13)
    end

    it "first instance is active" do
      expect(instances[0][:activate]).to eq(:true)
    end
    it "first instance is running" do
      expect(instances[0][:running]).to eq(:true)
    end
    it "first instance has expected created" do
      # Don't use stringified time for comparison
      expect(instances[0][:created]).to eq(Time.at(1481572424))
    end
    it "last instance is s12b113-backup-1" do
      expect(instances[-1]).to eq(
                                 {:name=>"s12b113-backup-1", :activate=>:false,
                                  :ensure=>:present, :running => :false,
                                  :created => Time.at(1482172700)
                                }
                               )
    end
  end

  context "#create" do
    it "an inactive BE (by default)" do
      described_class.expects(:beadm).
        with(:create, '-d', '\'new be\'', '-o', 'property=value', 'be1')
      expect(provider.create).to eq(nil)
    end
    it "an inactive BE with :activate => false" do
      params[:activate] = :false
      described_class.expects(:beadm).
        with(:create, '-d', '\'new be\'', '-o', 'property=value', 'be1')
      expect(provider.create).to eq(nil)
    end
    it "an active BE with :activate => true" do
      params[:activate] = :true
      described_class.expects(:beadm).
        with(:create, '-a', '-d', '\'new be\'', '-o', 'property=value', 'be1')
      expect(provider.create).to eq(nil)
    end
    it "clones a BE" do
      params[:clone_be] = "foo"
      described_class.expects(:beadm).with(:list, '-H').returns("foo;")
      described_class.expects(:beadm).
        with(:create, '-d', '\'new be\'', '-e', 'foo', '-o', 'property=value', 'be1')
      expect(provider.create).to eq(nil)
    end
    it "fails if clone_be does not exist" do
      params[:clone_be] = "foo"
      described_class.expects(:beadm).with(:list, '-H').returns("bar;")
      expect{provider.create}.to raise_error(Puppet::Error, /not found/)
    end
    it "clones a BE snapshot" do
      params[:clone_be] = "foo@bar"
      described_class.expects(:beadm).
        with(:list, '-H', '-s').returns(";foo@bar;")
      described_class.expects(:beadm).
        with(:create, '-d', '\'new be\'', '-e', 'foo@bar', '-o', 'property=value', 'be1')
      expect(provider.create).to eq(nil)
    end
    it "fails if clone_be@snapshot does not exist" do
      params[:clone_be] = "foo@bar"
      described_class.expects(:beadm).
        with(:list, '-H', '-s').returns(";bar@foo;")
      expect{provider.create}.to raise_error(Puppet::Error, /not found/)
    end
    it "a BE in a specific zpool" do
      params[:zpool] = "foo"
      described_class.expects(:zpool_cmd).with(:list, '-o', 'name', '-H').returns("foo")
      described_class.expects(:beadm).
        with(:create, '-d', '\'new be\'', '-o', 'property=value', '-p', 'foo', 'be1')
      expect(provider.create).to eq(nil)
    end
    it "ignores zpool when clone_be is set" do
      params[:clone_be] = "foo@bar"
      params[:zpool] = "foo"
      described_class.expects(:beadm).with(:list, '-H', '-s').returns(";foo@bar;")
      described_class.expects(:beadm).
        with(:create, '-d', '\'new be\'', '-e', 'foo@bar', '-o', 'property=value', 'be1')
      expect(provider.create).to eq(nil)
    end
    it "fails if zpool does not exist" do
      params[:zpool] = "foo"
      described_class.expects(:zpool_cmd).with(:list, '-o', 'name', '-H').returns("bar")
      expect{provider.create}.to raise_error(Puppet::Error, /does not exist/)
    end
    it "escapes shell characters in option values" do
      params[:options] = {"foo"=>"$test a th!ng"}
      described_class.expects(:beadm).
        with(:create, '-d', '\'new be\'', '-o', 'foo=\\$test\\ a\\ th\\!ng', 'be1')
      expect(provider.create).to eq(nil)
    end
  end

  context "#destroy" do
    it "destroys an inactive BE" do
      described_class.expects(:beadm).with(:list, '-H', params[:name]).returns("foo;;")
      described_class.expects(:beadm).with(:destroy, '-f', '-F', params[:name])
      expect(provider.destroy).to eq(nil)
    end
    it "fails on an active BE" do
      described_class.expects(:beadm).with(:list, '-H', params[:name]).returns("foo;;N;")
      expect{provider.destroy}.to raise_error(Puppet::Error, /Unable.*destroy/)
    end
  end
  context "#activate=" do
    it "activates a BE" do
      described_class.expects(:beadm).with(:activate, params[:name])
      expect(provider.activate=:true).to eq(:true)
    end
  end
end

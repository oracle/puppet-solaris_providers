#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:dns).provider(:dns) do

  let(:resource) do
    Puppet::Type.type(:dns).new(
      :name => "current",
      :ensure => :present
    )
      end

  let(:provider) do
    described_class.new(:dns)
  end

  before(:each) do
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

      xit "has the correct options"

  describe "when validating defined properties" do
    Puppet::Type.type(:dns).validproperties.each do |field|
      pg = "config"

      it "should be able to see the #{pg}/#{field} SMF property" do
        expect(instances[0][field]).not_to eq(nil)
      end
    end  # validproperties
  end  # validating default values
  end

end

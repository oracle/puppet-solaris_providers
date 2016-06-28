#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:dns).provider(:dns) do

  let(:provider) do
    described_class.new(:dns)
  end

  before(:each) do
    FileTest.stubs(:file?).with('/usr/bin/svcprop').returns true
    FileTest.stubs(:executable?).with('/usr/bin/svcprop').returns true
  end

  describe "#instances" do
    described_class.expects(:svcprop).with("-p", "config", Dns_fmri).returns File.read(my_fixture('svcprop_p_config_Dns_fmri.txt'))
    props = described_class.instances.map { |p|
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
        expect(props.size).to eq(1)
      end

  describe "when validating defined properties" do
    Puppet::Type.type(:dns).validproperties.each do |field|
      pg = "config"

      it "should be able to see the #{pg}/#{field} SMF property" do
        expect(props[0][field]).not_to eq(nil)
      end

      it "should find a reader for #{field}" do
        expect(provider.class.method_defined?(field.to_s)).to eq(true)
      end

      it "should find a writer for #{field}" do
        expect(provider.class.method_defined?(field.to_s+"=")).to eq(true)
      end
    end  # validproperties
  end  # validating default values
  end

  it "should have a flush method" do
    expect(provider.class.method_defined?("flush")).to eq(true)
  end

end

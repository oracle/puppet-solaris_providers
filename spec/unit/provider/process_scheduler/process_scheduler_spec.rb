#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:process_scheduler).provider(:process_scheduler) do

  let(:params) do
    {
      :name => 'current',
    }
  end
  let(:resource) { Puppet::Type.type(:process_scheduler).new(params) }
  let(:provider) { described_class.new(resource) }
  let(:error_pattern) { /Cannot/ }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/dispadmin').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/dispadmin').returns true
  end

  %w(create destroy).each do |thing|
    describe "##{thing}" do
      it "throws an error" do
        expect{provider.send("#{thing}".intern)}.
          to raise_error(Puppet::Error, error_pattern)
      end
    end
  end

  context "responds to" do
    %w(
      scheduler
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
      it "#{property}=" do is_expected.to respond_to("#{property}=".intern) end
    }

    %w(
      exists?
    ).each { |property|
      it property do is_expected.to respond_to(property.intern) end
    }
  end

  describe "#instances" do
    described_class.expects(:dispadmin).with("-d").returns "FSS (Fair Share)"
    instances = described_class.instances
    it "has one(1) instance" do
      expect(instances.size).to eq(1)
    end
    it "is set to FSS" do
      expect(instances[0].scheduler).to eq("FSS")
    end
    it "defaults to TS" do
      described_class.expects(:dispadmin).with("-d").
        raises(Puppet::ExecutionFailure.new(
                 'dispadmin: Default scheduling class is not set')
              )
      instances = described_class.instances
      expect(instances[0].scheduler).to eq("TS")
    end
    it "raises an error for an unexpected output" do
      described_class.expects(:dispadmin).with("-d").
        raises(Puppet::ExecutionFailure.new('other'))
      expect{described_class.instances}.
        to raise_error(Puppet::ExecutionFailure, /other/)
    end
  end

  describe "#scheduler=" do
    [:RT,:TS,:IA,:FSS,:FX].each do |thing|
      it "sets #{thing}" do
        described_class.expects(:dispadmin).with("-d", thing)
        expect(provider.scheduler=thing).to eq(thing)
      end
    end
  end
end

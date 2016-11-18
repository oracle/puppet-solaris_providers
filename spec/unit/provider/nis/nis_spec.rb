#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nis).provider(:nis) do

  let(:instances) do
    described_class.expects(:svcprop).with(
      "-p", "config", Client_fmri).returns File.read(
      my_fixture('svcsprop_p_config_Client_fmri.txt'))

      described_class.expects(:svcprop).with(
        "-p", "config", Domain_fmri).returns File.read(
        my_fixture('svcsprop_p_config_Domain_fmri.txt'))

        described_class.instances.map { |inst|
          hsh = {}
          [
            :domainname, :ypservers, :securenets,
            :use_broadcast, :use_ypsetme,
            :ensure, :name ].each { |prop|
            hsh[prop] = inst.get(prop)
          }
          hsh
        }
            end


  let(:resource) do
    Puppet::Type.type(:nis).new(
      :name => "current",
      :ensure => :present
    )
      end

  let(:provider) do
    described_class.new(resource)
  end

  context "responds to" do
    [:domainname, :ypservers, :securenets, :use_broadcast, :use_ypsetme].each { |method|
      it method do is_expected.to respond_to(method) end
      it "#{method}=" do is_expected.to respond_to("#{method}=".to_sym) end
    }

    # No Setters
    [ :ensure, :flush ].each {| method|
      it method do is_expected.to respond_to(:method) end
    }
    end

    # ensure we have all listed properties, addition of new properties will result
    # in an error here and require the various property arrays to be updated
    it "has only expected methods" do
      expect([:domainname, :ypservers, :securenets, :use_broadcast, :use_ypsetme]).to eq(Puppet::Type.type(:nis).validproperties - [:ensure])
    end

  describe ".instances" do
    it "returns one instance" do
      expect(instances.size).to eq(1)
    end

    describe "resource has expected SMF properties" do
      #Puppet::Type.type(:nis).validproperties.each do |field|

      {
        :domainname => %q(oracle.com),
        :ypservers => :absent,
        :securenets => :absent,
        :use_broadcast => :absent,
        :use_ypsetme => :absent
      }.each_pair { |field, value|
        pg = "config"

        it "#{pg}/#{field}" do
          expect(instances[0][field]).to eq(value)
        end
      }
    end  # validating instances
    describe "property=" do
      it "formats string arguments" do
        resource[:domainname] = %q(oracle.com)
        newval = %q(foo.com)
        described_class.expects(:svccfg).with("-s", Domain_fmri, "setprop", "config/domainname=", newval )
        expect(provider.domainname=newval).to eq(newval)
      end

      it "formats array arguments" do
        newval = %w(1.2.3.4 2.3.4.5)
        testval = %q^\(1.2.3.4 2.3.4.5\)^
        described_class.expects(:svccfg).with("-s", Domain_fmri, "setprop", "config/ypservers=", testval )
        expect(provider.ypservers=newval).to eq(newval)
      end

      it "formats array of arrays arguments" do
        newval =  ['host 127.0.0.1','255.255.255.0 1.1.1.1']
        testval = %q^\(host\\ 127.0.0.1 255.255.255.0\\ 1.1.1.1\)^
        described_class.expects(:svccfg).with("-s", Domain_fmri, "setprop", "config/securenets=", testval )
        expect(provider.securenets=newval).to eq(newval)
      end

      it "formats empty arguments" do
        newval = %q(\'\')
        described_class.expects(:svccfg).with("-s", Client_fmri, "setprop", "config/use_broadcast=", newval )
        expect(provider.send(:use_broadcast=,:absent)).to eq(newval)
      end
    end
  end
end

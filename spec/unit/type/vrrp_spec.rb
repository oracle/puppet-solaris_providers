#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:vrrp) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "vrrp1",
      :ensure => :present,
      :router_type => 'l2',
      :interface_name => 'net0',
      :vrid => 1,
      :assoc_ipaddrs => ['1.1.1.2','1.1.1.3'],
      :primary_ipaddr => '1.1.1.1'
    }
      end

  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }


  let(:error_pattern) { /Invalid/ }

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end

  describe "has property" do
    [
     :ensure, :temporary, :enabled, :router_type, :adv_interval,
     :interface_name, :preempt, :accept, :priority, :vrid, :assoc_ipaddrs,
     :primary_ipaddr
    ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
    end

  describe "parameter" do
    [:temporary, :preempt, :accept].each { |type|
      context "accepts #{type}" do
        %w(true false True False).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(on off).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:enabled].each { |type|
      context "accepts #{type}" do
        %w(true false True temp_true temp_false).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(sometimes).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:router_type].each { |type|
      context "accepts #{type}" do
        %w(l2 l3 L2).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(l1 master).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:adv_interval].each { |type|
      context "accepts #{type}" do
        %w(10 2345 40950).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(a 9 40951).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:interface_name].each { |type|
      context "accepts #{type}" do
        %w(net0 foo).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        ['net0-0', "a"*17, "a"*2].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:priority].each { |type|
      context "accepts #{type}" do
        %w(1 10 255).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(a 0 256).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:vrid].each { |type|
      context "accepts #{type}" do
        %w(1 10 1000).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(a 1.1 _2).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:assoc_ipaddrs].each { |type|
      context "accepts #{type}" do
        [
          ['127.0.0.1','127.0.0.2/24'],
          ['2000::0','0::0/92'],
          ['foo','0::0/92'],
        ].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        [
          ['127.0.0.1','127.0.0.256/24'],
          ['ff:0','0::0/129'],
          ['foo..com','0::0/92'],
        ].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:primary_ipaddr].each { |type|
      context "accepts #{type}" do
        %w(127.0.0.1 1.2.3.4 fe::0).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(1.2.3.256 fg::0).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
  end

  xdescribe "autorequire" do
    context "package" do
      it "is not required when no matching resource exists"
      it "is required when matching resource exists"
    end
    context "service" do
      it "is not required when no matching resource exists"
      it "is required when matching resource exists"
    end
    context "vnic" do
      it "is not required when no matching resource exists"
      it "is required when matching resource exists"
    end
    context "ip_interface" do
      it "is not required when no matching resource exists"
      it "is required when matching resource exists"
    end
    context "ip_tunnel" do
      it "is not required when no matching resource exists"
      it "is required when matching resource exists"
    end
    context "link_aggregation" do
      it "is not required when no matching resource exists"
      it "is required when matching resource exists"
    end
    context "address_object" do
      it "is not required when no matching resource exists"
      it "is required when matching resource exists"
    end

    #context "servergroup" do
    #  def add_servergroup(name="sg1")
    #    sg = Puppet::Type.type('ilb_servergroup').new(:name => name)
    #    catalog.add_resource sg
    #    sg
    #  end
    #  it "does not require servergroup when no matching resource exists" do
    #    add_servergroup("sg2")
    #    catalog.add_resource resource
    #    expect(resource.autorequire).to be_empty
    #  end
    #  it "requires servergroup when matching resource exists" do
    #    # dafault params use sg1 for all examples
    #    sg = add_servergroup
    #    catalog.add_resource resource
    #    reqs = resource.autorequire
    #    expect(reqs.count).to eq 1
    #    expect(reqs[0].source).to eq sg
    #    expect(reqs[0].target).to eq resource
    #  end
   end
end

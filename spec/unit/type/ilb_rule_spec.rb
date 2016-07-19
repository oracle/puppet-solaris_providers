#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:ilb_rule) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "rule1",
      :ensure => :present,
      :vip => '10.10.10.1',
      :protocol => 'tcp',
      :port => '80',
      :persistent => 'false',
      :lbalg => 'hash_ip',
      :topo_type => 'dsr',
      :servergroup => 'sg1',
      :hc_name => 'hc1',
      :hc_port => 'any'
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
      :vip, :port, :protocol, # Incoming
      :lbalg, :topo_type, :proxy_src, :servergroup, # Handling Method
      :hc_name, :hc_port, # Healthcheck
      :conn_drain, :nat_timeout, :persist_timeout # Timers
    ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
    end

  describe "parameter" do
    [:vip].each { |type|
      context "accepts #{type}" do
        %w(1.2.3.4 10.10.10.1 fe80::3e07:54ff:fe53:c704 [fe80::3e07:54ff:fe53:c704]).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(1.2.3.256 fe80::3e07::c704).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:port].each { |type|
      context "accepts #{type}" do
        %w(1 80 443 https 80-90).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(-1 65536 -1-80 80-65536).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:protocol].each { |type|
      context "accepts #{type}" do
        %w(udp tcp).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(sip ldap).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:lbalg].each { |type|
      context "accepts #{type}" do
        %w(roundrobin hash_ip hash_ip_port hash_ip_vip).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(rr foo random).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:topo_type].each { |type|
      context "accepts #{type}" do
        %w(dsr nat half_nat).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(vcr double_nat).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:proxy_src].each { |type|
      context "accepts #{type}" do
        %w(127.0.0.1 10.10.10.11-10.10.10.20).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(1.2.3.256 10.10.10.1-10.10.10.12 10.10.10.11-10.10.11.12).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:servergroup].each { |type|
      context "accepts #{type}" do
        %w(sg1 foobar2).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(sg@dc1 foo.bar.1).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:hc_name].each { |type|
      context "accepts #{type}" do
        %w(hc1 foobar2 ).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(hc1$sg2 foo.com:hc1 ).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:hc_port].each { |type|
      context "accepts #{type}" do
        %w(any all 80).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(some most 80-443).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:conn_drain, :nat_timeout, :persist_timeout].each { |type|
      context "accepts #{type}" do
        %w(0 20 100).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(1.1 default -1).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:persistent].each { |type|
      context "accepts #{type}" do
        %w(true false 0 128).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(yes no 129).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
  end
  describe "autorequire" do
    context "servergroup" do
      def add_servergroup(name="sg1")
        sg = Puppet::Type.type('ilb_servergroup').new(:name => name)
        catalog.add_resource sg
        sg
      end
      it "does not require servergroup when no matching resource exists" do
        add_servergroup("sg2")
        catalog.add_resource resource
        expect(resource.autorequire).to be_empty
      end
      it "requires servergroup when matching resource exists" do
        # dafault params use sg1 for all examples
        sg = add_servergroup
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 1
        expect(reqs[0].source).to eq sg
        expect(reqs[0].target).to eq resource
      end
    end
    context "healthcheck" do
      def add_healthcheck(name="hc1")
        sg = Puppet::Type.type('ilb_healthcheck').new(:name => name)
        catalog.add_resource sg
        sg
      end
      it "does not require healthcheck when no matching resource exists" do
        add_healthcheck("hc2")
        catalog.add_resource resource
        expect(resource.autorequire).to be_empty
      end
      it "requires healthcheck when matching resource exists" do
        # dafault params use hc1 for all examples
        hc = add_healthcheck
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 1
        expect(reqs[0].source).to eq hc
        expect(reqs[0].target).to eq resource
      end
    end
  end
end

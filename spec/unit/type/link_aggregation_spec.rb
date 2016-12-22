#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:link_aggregation) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "aggr10",
      :ensure => :present,
      :lower_links => ["net10", "net20"],
      :mode => :trunk,
      :policy => "L4",
      :lacpmode => "off",
      :lacptimer => "short"
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
    [ :ensure, :lower_links, :mode, :policy,
      :lacpmode, :lacptimer, :address
    ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
  end

  describe "parameter" do
    {
      :lower_links => {
        :accepts => [ %w(net0), %w(net0 net1 net2), %w(ab1), %w(ab_1),
                      %w(a1b1), ("a"*15) + "0", %q(net10) ],
        :rejects => %w(a1 aaa aaaaaaaaaaaaaaa01 Net0) << "net11 net12",
      },
      :temporary => {
        :accepts => [:true,:false],
        :rejects => %w(yes no),
      },
      :mode => {
        :accepts => [:trunk,:dlmp],
        :rejects => %w(random)
      },
      :policy => {
        :accepts => %w(L2 L3 L4 L2,L3),
        :rejects => [:L1,"L3,L4","foo"].each,
      },
      :lacpmode => {
        :accepts => [:off, :active, :passive],
        :rejects => [:slow, "other"],
      },
      :lacptimer => {
        :accepts => [:short, :long],
        :rejects => [:forever,90],
      },
      :address => {
        :accepts => [ "2:8:20:9d:21:5f" ],
        :rejects => [ "1.2.3.4","LL:8:20:9d:21:5f",
                      "2:8:20:9d:21", "222:8:20:9d:21:5f" ],
      }
    }.each_pair { |target_param,cond|
      context "#{target_param}" do
        context "accepts" do
          cond[:accepts].each do |thing|
            it thing.inspect do
              params[target_param] = thing
              expect { resource }.not_to raise_error
            end
          end
        end # Accepts
        context "rejects" do
          cond[:rejects].each do |thing|
            it thing.inspect do
              params[target_param] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end # Rejects
      end
    }
  end
  describe "validation" do
    it "fails with mode and without lower_links defined" do
      expect{described_class.new(:name => 'aggr10', :mode => 'dlmp')}.to raise_error(Puppet::ResourceError)
    end
  end
  describe "autorequire" do
    context "ip_interface" do
      def add_resource(name,res_type)
        sg = Puppet::Type.type(res_type).new(:name => name)
        catalog.add_resource sg
        sg
      end
      it "does not require ip_interface when no matching resource exists" do
        add_resource("notnet0",'ip_interface')
        catalog.add_resource resource
        expect(resource.autorequire).to be_empty
      end
      it "requires ip_interface when matching resource exists" do
        new_res0 = add_resource('net10','ip_interface')
        new_res1 = add_resource('net20','ip_interface')
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 2
        expect(reqs[0].source).to eq new_res0
        expect(reqs[0].target).to eq resource
        expect(reqs[1].source).to eq new_res1
        expect(reqs[1].target).to eq resource
      end
    end
  end
end

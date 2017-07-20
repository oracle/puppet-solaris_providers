require 'spec_helper'

describe Puppet::Type.type(:interface_properties) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => 'net0',
      :properties => {
        'ipv4' => { "mtu" => 1776 },
        'ipv6' => { "mtu" => 2048 },
      }
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
    [ :properties ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
  end

  describe "parameter validation" do
    context "accepts interfaces" do
      [ %q(net0),
        %q(net0/ipv4),
        %q(ab1),
        %q(ab_1),
        %q(a1b1),
        ("a"*15) + "0"
      ].each do |thing|
        it thing.inspect do
          params[:name] = thing
          expect { resource }.not_to raise_error
        end
      end
    end # Accepts interface
    context "rejects interface" do
      %w(
        a1
        aaa
        aaaaaaaaaaaaaaa01
        Net0
      ).each do |thing|
        it thing.inspect do
          params[:name] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end
    end # Rejects interface
    context "accepts temporary" do
      [:true,:false].each do |thing|
        it thing.inspect do
          params[:temporary] = thing
          expect { resource }.not_to raise_error
        end
      end
    end # Accepts temporary
    context "rejects temporary" do
      %w(yes no).each do |thing|
        it thing.inspect do
          params[:temporary] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end
    end # Rejects temporary
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
        new_res0 = add_resource('net0','ip_interface')
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 1
        expect(reqs[0].source).to eq new_res0
        expect(reqs[0].target).to eq resource
      end
    end
  end
end

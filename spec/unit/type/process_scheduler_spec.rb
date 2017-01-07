#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:process_scheduler) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "current",
      :ensure => :present
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
    [ :scheduler, ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
  end

  describe "parameter" do
    [:scheduler].each { |type|
      context "accepts #{type}" do
        [:RT,:TS,:IA,:FSS,:FX].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        [:FAST].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
  end
end

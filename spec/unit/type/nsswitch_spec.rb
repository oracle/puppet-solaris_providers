#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:nsswitch) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "current",
      :host => 'files ldap dns',
      :ensure => :present
    }
  end

  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:error_pattern) { /Invalid database/ }
  @properties=Puppet::Type.type(:nsswitch).validproperties - [:ensure]

  it "should have :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end

  describe "has property" do
    (Puppet::Type.type(:nsswitch).validproperties - [:ensure]).each do |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "parameter" do
    (Puppet::Type.type(:nsswitch).validproperties - [:ensure]).each { |type|
      context "accepts #{type}" do
        (%w(files ldap dns) +
         [
           "files ldap dns",
           "files:[notfound=return]",
           "files ldap:[notfound=return]",
           "absent"
         ]

         ).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        (%w(guess hesiod filesldap ldapfiles) +
         ["files guess"]).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
        ["files files", "ldap files ldap"].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, /duplicate/)
          end
        end
        [""].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, /empty/)
          end
        end
      end
    }
  end
end

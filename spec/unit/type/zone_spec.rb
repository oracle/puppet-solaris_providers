#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/zone'

describe Puppet::Type.type(:zone) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect(@class.key_attributes).to eq([:name])
  end

  describe "when validating attributes" do
    [:id, :zonepath, :iptype, :brand
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:property)
      end
    end # properties

    [:config_profile, :zonecfg_export, :archive, :archived_zonename, 
     :clone, :sysidcfg, :install_args 
    ].each do |prop|
      it "should have a #{prop} parameter" do
        expect(@class.attrtype(prop)).to eq(:param)
      end
    end # parameters
  end # validating attributes

end

#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:pkg_mediator) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect( @class.key_attributes).to be == [:name]
  end

  describe "when validating attributes" do
    [ :ensure, :version, :implementation ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "when validating values" do

    describe "for ensure" do
      error_pattern = /Invalid value/m
      def validate(ens)
         @class.new(:name => @profile_name, :ensure => ens)
      end

      [ "present", "absent" ].each do |newval|
        it "should accept a value of #{newval}" do
          expect { validate(newval) }.not_to raise_error
        end
      end

      it "should reject invalid values" do
        expect { validate "foo" }.to raise_error(Puppet::Error, error_pattern)
      end
    end  # ensure

    describe "for version" do
      def validate(ver)
         @class.new(:name => @profile_name, :version => ver)
      end

      it "should accept a value" do
        expect { validate "foo" }.not_to raise_error
      end
    end  # version

    describe "for implementation" do
      def validate(imp)
         @class.new(:name => @profile_name, :implementation => imp)
      end

      it "should accept a value" do
        expect { validate "foo" }.not_to raise_error
      end
    end  # implementation


  end # validating values
end

require 'spec_helper'

describe Puppet::Type.type(:pkg_variant) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect(@class.key_attributes).to be == [:name]
  end

  describe "when validating attributes" do
    [ :ensure, :value ].each do |prop|
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

      [ "present" ].each do |newval|
        it "should accept a value of #{newval}" do
          expect { validate(newval) }.not_to raise_error
        end
      end

      it "should reject invalid values" do
        expect { validate "foo" }.to raise_error(Puppet::Error, error_pattern)
      end
    end  # ensure

    describe "for value" do
      def validate(val)
         @class.new(:name => @profile_name, :value => val)
      end

      it "should accept a value" do
        expect { validate "foo" }.not_to raise_error
      end
    end  # value

  end # validating values
end

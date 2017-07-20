require 'spec_helper'

describe Puppet::Type.type(:address_properties) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :address as its keyattribute" do
    expect(@class.key_attributes).to eq([:address])
  end

  describe "when validating properties" do
    [ :properties ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:property)
      end
    end
  end # validating properties

  describe "when validating parameters" do
    [ :address, :temporary ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:param)
      end
    end
  end # validating properties

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
        expect { validate "foo" }.to raise_error Puppet::Error, error_pattern
      end
    end  # ensure

    describe "for temporary" do
      error_pattern = /temporary.*Invalid/m

      def validate(temp)
         @class.new(:name => @profile_name, :temporary => temp)
      end

      [ "true", "false" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # temporary

    describe "for properties" do
      def validate(props)
         @class.new(:name => @profile_name, :properties => props)
      end

      it "should accept a hash value" do
        expect { validate ({"a" => "b"}) }.not_to raise_error
      end
    end  # seconds

  end # validating values
end

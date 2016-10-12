#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:nis) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect( @class.key_attributes).to be == [:name]
  end

  describe "when validating attributes" do
    [:domainname, :ypservers, :securenets, :use_broadcast, :use_ypsetme
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "when validating values" do

    describe "for domainname" do
      def validate(dname)
         @class.new(:name => @profile_name, :domainname => dname)
      end

      it "should allow a value to be set" do
        expect { validate "foo.com" }.not_to raise_error
      end
    end  # domainname


    describe "for ypservers" do
      error_pattern = /ypserver.*invalid/m

      def validate(hostname)
         @class.new(:name => @profile_name, :ypservers => hostname)
      end

      it "should reject hostnames greater than 255 characters" do
        expect { validate "aaaa." * 51 << "a"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostnames with double periods" do
        expect { validate "double..isbad.com"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostname segments larger than 63 characters" do
        expect { validate "my." << "a" * 64 << ".com"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostname segments not starting with a letter/digit" do
        expect { validate "my._invalid.hostname"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostname segments ending with a dash" do
        expect { validate "my.invalid-.hostname"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      ["192.168.1.253","1.2.3.4"].each do |ip|
        it "should accept valid IP addresses #{ip}" do
          expect { validate ip
          }.not_to raise_error
        end
      end

      ["192.168.1.256","192.168.1."].each do |ip|
        it "should reject invalid IP addresses #{ip}" do
          expect { validate ip
          }.to raise_error(Puppet::Error, error_pattern)
        end
      end


      it "should accept an array of valid values" do
        expect { validate(
            [ "host1.hostarray.com", "host2.hostarray.com" ])
        }.not_to raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name,
                            :ypservers => "host1.hostarray.com")
        expect(mytype.property("ypservers").value).to be_an(Array)
      end
    end  # ypservers


    describe "for securenets" do
      def validate(snets)
         @class.new(:name => @profile_name, :securenets => snets)
      end

      it "should fail if argument is not an array" do
        expect { @class.new(:name => @profile_name,
                            :securenets => {'host' => '1.1.1.1'})
        }.to raise_error(Puppet::Error, /is not an array/)
      end
      it "should allow a value to be set" do
        expect { @class.new(:name => @profile_name,
                            :securenets => [['host','1.1.1.1']])
        }.not_to raise_error
      end
      it "should allow multiple values to be set" do
        expect { @class.new(:name => @profile_name,
                            :securenets => [
                              ['255.255.255.0','1.1.1.1'],
                              ['host','1.1.1.2'],
                              ['host','1.1.1.3']
        ]
                           ) }.not_to raise_error
        end
      it "should fail on invalid multiple values" do
        expect { @class.new(:name => @profile_name,
                            :securenets => [
                              ['255.255.255.0','1.1.1.1'],
                              ['toast','1.1.1.2'],
                              ['host','1.1.1.3']
        ]
                           ) }.to raise_error(Puppet::Error, /Invalid address/)
        end
      it "should fail if argument value is not an IP address" do
        expect { @class.new(:name => @profile_name,
                            :securenets => [['host', '1.1.1']])
        }.to raise_error(Puppet::Error, /Invalid address/)
      end
    end  # securenets


    describe "for use_broadcast" do
      error_pattern = /broadcast.*Invalid/m

      def validate(ub)
         @class.new(:name => @profile_name, :use_broadcast => ub)
      end

      [ "true", "false" ].each do |ubval|
        it "should accept a value of #{ubval}" do
          expect { validate(ubval) }.to_not raise_error
        end
      end

      it "should reject invalid values" do
        expect { validate "foo"
             }.to raise_error(Puppet::Error, error_pattern)
      end
    end  # use_broadcast


    describe "for use_ypsetme" do
      error_pattern = /ypsetme.*Invalid/m

      def validate(ub)
         @class.new(:name => @profile_name, :use_ypsetme => ub)
      end

      [ "true", "false" ].each do |ubval|
        it "should accept a value of #{ubval}" do
          expect { validate(ubval) }.to_not raise_error
        end
      end

      it "should reject invalid values" do
        expect { validate "foo"
             }.to raise_error(Puppet::Error, error_pattern)
      end
    end  # use_ypsetme

  end # validating values
end

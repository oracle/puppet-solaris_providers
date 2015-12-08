#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/dns'

describe Puppet::Type.type(:dns) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:nameserver, :domain, :search, :sortlist, :options
    ].each do |prop|
      it "should have a #{prop} property" do
        @class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for nameserver" do
      error_pattern = /nameserver.*invalid/m

      def validate(hostname)
         @class.new(:name => @profile_name, :nameserver => hostname)
      end
 
      it "should reject hostnames greater than 255 characters" do
        proc { validate "aaaa." * 51 << "a"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostnames with double periods" do
        proc { validate "double..isbad.com"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostname segments larger than 63 characters" do
        proc { validate "my." << "a" * 64 << ".com"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostname segments not starting with a letter/digit" do
        proc { validate "my._invalid.hostname"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject hostname segments ending with a dash" do
        proc { validate "my.invalid-.hostname"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject invalid IP addresses" do
        proc { validate "192.168.1.256"
             }.should raise_error Puppet::Error, error_pattern
        proc { validate "192.168.1."
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should accept an array of valid values" do
        proc { validate [ "1.2.3.4", "2.3.4.5" ] }.
             should_not raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :nameserver => "1.2.3.4")
        mytype.property("nameserver").value.should be_an(Array)
      end
    end  # nameserver


    describe "for domain" do

      def validate(domain_val)
         @class.new(:name => @profile_name, :domain => domain_val)
      end
 
      it "should accept a value" do
        proc { validate "foo.com" }.
             should_not raise_error
      end
    end  # domain


    describe "for search" do
      def validate(search_val)
         @class.new(:name => @profile_name, :search => search_val)
      end

      it "should accept an array of valid values" do
        proc { validate [ "foo", "bar" ] }.
             should_not raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :search => "foo")
        mytype.property("search").value.should be_an(Array)
      end
    end  # search


    describe "for sortlist" do
      error_pattern = /sortlist.*invalid/m

      def validate(slist)
         @class.new(:name => @profile_name, :sortlist => slist)
      end
 
      it "should reject invalid IP addresses" do
        proc { validate "192.168.1.256"
             }.should raise_error Puppet::Error, error_pattern
        proc { validate "192.168.1."
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should accept an array of valid values" do
        proc { validate [ "1.2.3.4/5", "2.3.4.5/6" ] }.
             should_not raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name, 
                            :sortlist => "1.2.3.4/5")
        mytype.property("sortlist").value.should be_an(Array)
      end
    end  # sortlist

    describe "for options" do
      error_pattern = /option.*invalid/m

      def validate(op)
         @class.new(:name => @profile_name, :options => op)
      end
 
      it "should reject options with too many fields" do
        proc { validate "retry:1:2"
             }.should raise_error Puppet::Error, error_pattern
      end

      it "should reject invalid options" do
        proc { validate "foo"
             }.should raise_error Puppet::Error, error_pattern
        proc { validate "bar:1"
             }.should raise_error Puppet::Error, error_pattern
      end

      ["debug", "rotate", "no-check-names", "inet6"
      ].each do |op|
        it "should accept #{op} option with no arguments" do
          proc { validate "#{op}" }.
               should_not raise_error
        end  # arg

        it "should reject #{op} with one argument" do
          proc { validate "#{op}:1"
               }.should raise_error Puppet::Error, error_pattern
        end
      end  # simple_opts

      ["ndots", "timeout", "retrans", "attempts", "retry"
      ].each do |op|
        it "should accept #{op} option with one argument" do
          proc { validate "#{op}:1" }.
               should_not raise_error
        end  # opt arg

        it "should reject #{op} with no arguments" do
          proc { validate "#{op}"
               }.should raise_error Puppet::Error, error_pattern
        end
      end  # arg_opts

     it "should reject arguments that won't cast to integer" do
        proc { validate "retry:a"
             }.should raise_error Puppet::Error, error_pattern
     end

     it "should allow an empty value to clear" do
          proc { validate "" }.
               should_not raise_error
     end

    end  # options

  end # validating values
end

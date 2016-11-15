#!/usr/bin/env rspec

require 'spec_helper'
require_relative  '../../../lib/puppet/type/address_object'

describe Puppet::Type.type(:address_object) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect(@class.key_attributes).to eq([:name])
  end

  describe "when validating properties" do
    [ :address_type, :enable, :address, :remote_address, :down, :seconds,
      :hostname, :interface_id, :remote_interface_id, :stateful, :stateless
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:property)
      end
    end
  end # validating properties

  describe "when validating parameters" do
    [ :name, :temporary
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:param)
      end
    end
  end # validating properties

  describe "when validating values" do

    describe "for ensure" do
      error_pattern = /Invalid value/m
      def validate(ens)
         @class.new(:name => @profile_name, :address_type => :static, :ensure => ens)
      end

      [ "present", "absent" ].each do |newval|
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

    describe "for address_type" do
      error_pattern = /address_type.*Invalid/m

      def validate(atype)
        @class.new(:name => @profile_name, :address_type => atype)
      end

      context "implied" do
        (
          [[:address,'1.2.3.4'],[:remote_address,'foo'],[:down,'true']].product(
            [[:seconds,5],[:hostname,'bar']] +
            [[:interface_id,'net0/v4'],[:remote_interface_id,'net1/v4']])
        ).each do |a|
          it "should not accept both :#{a[0][0]} and :#{a[1][0]}" do
            expect { @class.new(:name => "#{a[0][0]}-#{a[1][0]}",
                                a[0][0] => a[0][1], a[1][0] => a[1][1])
            }.to raise_error(Puppet::ResourceError,
                             %r(incompatible property combination))

          end
        end
        (
          [[:address,'1.2.3.4'],[:remote_address,'foo'],[:down,'true']].permutation(2).to_a +
          [[:seconds,5],[:hostname,'bar']].permutation(2).to_a +
          [[:interface_id,'net0/v4'],[:remote_interface_id,'net1/v4']].permutation(2).to_a
        ).each do |a|
          it "should accept both :#{a[0][0]} and :#{a[1][0]}" do
            expect { @class.new(:name => "#{a[0][0]}-#{a[1][0]}",
                                a[0][0] => a[0][1], a[1][0] => a[1][1])
            }.to_not raise_error
          end
        end
        [[[:address,'1.2.3.4'],[:remote_address,'foo'],[:down,'true']]].each do |a|
          it "should accept all of :#{a[0][0]}, :#{a[1][0]}, :#{a[2][0]}" do
            expect { @class.new(:name => "#{a[0][0]}-#{a[1][0]}-#{a[2][0]}",
                                a[0][0] => a[0][1], a[1][0] => a[1][1],
                                  a[2][0] => a[2][1])
            }.to_not raise_error
          end
        end
      end
      context "static" do
        ["foo","bar.com","1.2.3.4"].each do |value|
          it "should accept address #{value}" do
            expect { @class.new(:name => "static-address", :address_type => :static,
                                :address => value)
            }.to_not raise_error
          end
        end
        ["foo..bar","1.2.3.256"].each do |value|
          it "should not accept address #{value}" do
            expect { @class.new(:name => "static-address", :address_type => :static,
                                :address => value)
            }.to raise_error(Puppet::ResourceError,
                             %r(:address entry:.*is invalid))
          end
        end
        ["foo","1.2.3.4"].each do |value|
          it "should accept remote_address #{value}" do
            expect { @class.new(:name => "static-remote_address", :address_type => :static,
                                :remote_address => value)
            }.to_not raise_error
          end
        end
        ["foo..bar","1.2.3.300"].each do |value|
          it "should not accept remote_address #{value}" do
            expect { @class.new(:name => "static-remote_address", :address_type => :static,
                                :remote_address => value)
            }.to raise_error(Puppet::ResourceError,
                             %r(:remote_address entry:.*is invalid))
          end
        end
        ["true","false"].each do |value|
          it "should accept down #{value}" do
            expect { @class.new(:name => "static-down", :address_type => :static,
                                :down => value)
            }.to_not raise_error
          end
        end
        it "should not accept seconds" do
          expect { @class.new(:name => "static-seconds", :address_type => :static,
                              :seconds => 5)
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*seconds.*static))
        end
        it "should not accept hostname" do
          expect { @class.new(:name => "static-hostname", :address_type => :static,
                              :hostname => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*hostname.*static))
        end
        it "should not accept interface_id" do
          expect { @class.new(:name => "static-interface_id", :address_type => :static,
                              :interface_id => "net0/v4test")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*interface_id.*static))
        end
        it "should not accept remote_interface_id" do
          expect { @class.new(:name => "static-remote_interface_id", :address_type => :static,
                              :remote_interface_id => "net0/v6")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_interface_id.*static))
        end
      end
      context "dhcp" do
        it "should not accept address" do
          expect { @class.new(:name => "dhcp-address", :address_type => :dhcp,
                              :address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*address.*dhcp))
        end
        it "should not accept remote_address" do
          expect { @class.new(:name => "dhcp-remote_address", :address_type => :dhcp,
                              :remote_address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_address.*dhcp))
        end
        it "should not accept down" do
          expect { @class.new(:name => "dhcp-down", :address_type => :dhcp,
                              :down => "true")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*down.*dhcp))
        end
        [5,"10","forever"].each do |value|
          it "should accept seconds #{value}" do
            expect { @class.new(:name => "dhcp-seconds", :address_type => :dhcp,
                                :seconds => value)
            }.to_not raise_error
          end
        end
        it "should accept hostname" do
          expect { @class.new(:name => "dhcp-hostname", :address_type => :dhcp,
                              :hostname => "foo")
          }.to_not raise_error
        end
        it "should not accept interface_id" do
          expect { @class.new(:name => "dhcp-interface_id", :address_type => :dhcp,
                              :interface_id => "net0/v4")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*interface_id.*dhcp))
        end
        it "should not accept remote_interface_id" do
          expect { @class.new(:name => "dhcp-remote_interface_id", :address_type => :dhcp,
                              :remote_interface_id => "net0/v4")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_interface_id.*dhcp))
        end
      end
      context "addrconf" do
        it "should not accept address" do
          expect { @class.new(:name => "addrconf-address", :address_type => :addrconf,
                              :address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*address.*addrconf))
        end
        it "should not accept remote_address" do
          expect { @class.new(:name => "addrconf-remote_address", :address_type => :addrconf,
                              :remote_address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_address.*addrconf))
        end
        it "should not accept down" do
          expect { @class.new(:name => "addrconf-down", :address_type => :addrconf,
                              :down => "true")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*down.*addrconf))
        end
        it "should not accept seconds" do
          expect { @class.new(:name => "addrconf-seconds", :address_type => :addrconf,
                              :seconds => 5)
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*seconds.*addrconf))
        end
        it "should not accept hostname" do
          expect { @class.new(:name => "addrconf-hostname", :address_type => :addrconf,
                              :hostname => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*hostname.*addrconf))
        end
        ["net0/v4","net0/v4test","net0/v6"].each do |value|
          it "should accept interface_id #{value}" do
            expect { @class.new(:name => "addrconf-interface_id", :address_type => :addrconf,
                                :interface_id => value)
            }.to_not raise_error
          end
        end
        ["net0/v4","net0/v4test","net0/v6"].each do |value|
          it "should accept remote_interface_id #{value}" do
            expect { @class.new(:name => "addrconf-remote_interface_id", :address_type => :addrconf,
                                :remote_interface_id => value)
            }.to_not raise_error
          end
        end
      end
      context "from_gz" do
        it "should not accept address" do
          expect { @class.new(:name => "from_gz-address", :address_type => :from_gz,
                              :address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*address.*from_gz))
        end
        it "should not accept remote_address" do
          expect { @class.new(:name => "from_gz-remote_address", :address_type => :from_gz,
                              :remote_address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_address.*from_gz))
        end
        it "should not accept down" do
          expect { @class.new(:name => "from_gz-down", :address_type => :from_gz,
                              :down => "true")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*down.*from_gz))
        end
        it "should not accept seconds" do
          expect { @class.new(:name => "from_gz-seconds", :address_type => :from_gz,
                              :seconds => 5)
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*seconds.*from_gz))
        end
        it "should not accept hostname" do
          expect { @class.new(:name => "from_gz-hostname", :address_type => :from_gz,
                              :hostname => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*hostname.*from_gz))
        end
        it "should not accept interface_id" do
          expect { @class.new(:name => "from_gz-interface_id", :address_type => :from_gz,
                              :interface_id => "net0/v4")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*interface_id.*from_gz))
        end
        it "should not accept remote_interface_id" do
          expect { @class.new(:name => "from_gz-remote_interface_id", :address_type => :from_gz,
                              :remote_interface_id => "net0/v4")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_interface_id.*from_gz))
        end
      end
      context "inherited" do
        it "should not accept address" do
          expect { @class.new(:name => "inherited-address", :address_type => :inherited,
                              :address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*address.*inherited))
        end
        it "should not accept remote_address" do
          expect { @class.new(:name => "inherited-remote_address", :address_type => :inherited,
                              :remote_address => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_address.*inherited))
        end
        it "should not accept down" do
          expect { @class.new(:name => "inherited-down", :address_type => :inherited,
                              :down => "true")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*down.*inherited))
        end
        it "should not accept seconds" do
          expect { @class.new(:name => "inherited-seconds", :address_type => :inherited,
                              :seconds => 5)
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*seconds.*inherited))
        end
        it "should not accept hostname" do
          expect { @class.new(:name => "inherited-hostname", :address_type => :inherited,
                              :hostname => "foo")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*hostname.*inherited))
        end
        it "should not accept interface_id" do
          expect { @class.new(:name => "inherited-interface_id", :address_type => :inherited,
                              :interface_id => "net0/v4")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*interface_id.*inherited))
        end
        it "should not accept remote_interface_id" do
          expect { @class.new(:name => "inherited-remote_interface_id", :address_type => :inherited,
                              :remote_interface_id => "net0/v4")
          }.to raise_error(Puppet::ResourceError,
                           %r(cannot specify.*remote_interface_id.*inherited))
        end
      end

    end  # address_type

    describe "for enable" do
      error_pattern = /cannot specify/m
      def validate(enab,tmp)
        @class.new(:name => @profile_name, :enable => enab, :temporary => tmp)
      end

      [ "true","false" ].each do |enable|
        context "temporary=true" do
          it "should reject enable=#{enable}" do
            expect { validate(enable,true) }.to raise_error(Puppet::ResourceError,
                                                            error_pattern)
          end
        end
        context "temporary=false" do
          it "should accept enable=#{enable}" do
            expect { validate(enable,false) }.not_to raise_error
          end
        end

        it "should reject an invalid value" do
          expect { validate("foobar",false) }.to raise_error(Puppet::ResourceError,
                                                       /Invalid value/)
        end

      end

    end  # enable

    describe "for stateful" do
      error_pattern = /stateful.*Invalid/m

      def validate(sful)
         @class.new(:name => @profile_name, :stateful => sful)
      end

      [ "yes", "no" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # stateful

    describe "for stateless" do
      error_pattern = /stateless.*Invalid/m

      def validate(sless)
         @class.new(:name => @profile_name, :stateless => sless)
      end

      [ "yes", "no" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # stateless

  end # validating values
end

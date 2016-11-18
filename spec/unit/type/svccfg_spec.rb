#!/usr/bin/env rspec
require 'spec_helper'

type_class = Puppet::Type.type(:svccfg)

describe type_class do

  it "should have :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end

  describe "when validating attributes" do
    [ :ensure, :value].each do |prop|
      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to be == :property
      end
    end
    end

  describe "when validating parameters" do

    context "ensure" do
      error_pattern = /Invalid value/m
      [ "present", "absent", "delcust" ].each do |newval|
        it "should accept a value of #{newval}" do
          expect { described_class.new(:name => "foo", :fmri => "svc:/foo", :property => "bar/baz", :value => "quux",  :ensure => newval) }.not_to raise_error
          end
      end
      [ "fake" ].each do |newval|
        it "should not accept a value of #{newval}" do
          expect { described_class.new(:name => "foo", :fmri => "svc:/foo", :property => "bar/baz", :value => "quux",  :ensure => newval) }.to raise_error(Puppet::Error, /Invalid value/)
          end
      end
    end

    context "type" do
      context "with valid value" do
        {
          # Type => [Value Array]
          :count => [ 1, "2", "345" ],
          :integer => [ 6, "7", -8, "-9" ],
          :opaque => [ "c8c83828c6bf00e3edbb9d47c4771587" ],
          :host => [ "foo.com", "1.2.3.4", "foo.com 1.2.3.4" ],
          :hostname => [ "bar.com", "baz.com quux.net" ],
          :net_address => [ "1.2.3.4", "fdf0:9a7a:4acd:9823:488a:b3c:cb69:23e0", "1.2.3.4 fdf0:9a7a:4acd:9823:488a:b3c:cb69:23e0"],
          :net_address_v4 => [ "1.2.3.4", "1.2.3.4 5.6.7.8" ],
          :net_address_v6 => [ "fdf0:9a7a:4acd:9823:488a:b3c:cb69:23e0",
            "fdf0:9a7a:4acd:9823:488a:b3c:cb69:23e0 fe80::baf6:b1ff:fe19:7507" ],
          :time => ["1464711909.667178000", "1464711909.671911000",
              "1464711909.667178000 1464711909.671911000"],
          :astring => ["/usr/bin/cloudbase-init\ --debug", "Unstable",
            "foo bar"],
          :ustring => ["IPS\ Repository\ Mirror",
              "web/_themes/pkg-block-icon.png", "foo bar"],
          :boolean => [ "true", "false" ],
          :fmri => ["svc:/system/filesystem/root","svc:/system/filesystem/root svc:/system/filesystem/usr svc:/system/filesystem/minimal"],
          :uri => ["svc:/system/filesystem/root", "mailto:foo@example.com",
            "http://oracle.com"],
        }.each_pair do |k,a|
          a.each { |v|
            it "should accept #{k} -> #{v}" do
          expect {
          described_class.new(:name => "#{k}-#{v}", :ensure => :present,
                         :fmri => "svc:/baz", :property => "foo/bar",
                         :type => k, :value => v)
        }.not_to raise_error
          end
          }
    end
      end # valid value
    context "with invalid value" do
        {
          # Type => [Value Array]
          :count => [ :a, -2 ],
          :integer => [ :a, 6.5 ],
          # :opaque => [ ],
          :host => [ "foo..com", "1.2.3.256", "1.2.3.4;echo foo | wall"],
          :hostname => [ "bar..com", "1.2.3.4;echo foo | wall"],
          :net_address => [ "1.2.3.256", "2001:db8:2",
          "1.2.3.4;echo foo | wall"],
          :net_address_v4 => [ "1.2.3.256", "1.2.3.4 5.6.7.256",
          "1.2.3.4;echo foo | wall"],
          :net_address_v6 => [ "2001:db8:2" "fdf0:9a7a:4acd:9823:488a:b3c:cb69:23e0 2001:db8:2",
          "fdf0::0;echo foo | wall"],
          :time => ["-1464711909.667178000" ],
          # :astring => [ ],
          # :ustring => [ ],
          :boolean => [ "maybe" ],
          :fmri => ["svc/system/filesystem/root","/system:/filesystem/root",
                    "svc:/valid/ish;echo foo > /etc/shadow"],
                    :uri => [ "mailto foo@example.com", "mailto:foo@example.com;echo foo" ],
        }.each_pair do |k,a|
          a.each { |v|
            it "should not accept #{k} -> #{v}" do
          expect {
          described_class.new(:name => "#{k}-#{v}", :ensure => :present,
                         :property => "foo/bar", :type => k, :value => v)
        }.to raise_error(Puppet::Error, /#{k}/)
          end
          }
    end
    end
        context "property group" do
        {
          # Property Group Types don't accept values
          :dependency => [nil],
          :framework => [nil],
          :configfile => [nil],
          :method => [nil],
          :template => [nil],
          :template_pg_pattern => [nil],
          :template_prop_pattern => [nil]
        }.each_pair { |k,a|
          a.each { |v|
            it "should accept #{k} -> <no value>" do
              expect {
          described_class.new(:name => "#{k}-#{v}", :ensure => :present,
                         :fmri => "svc:/baz", :property => "foo",
                         :type => k)
              }.not_to raise_error
                end
          }
        }
        {
          # Property Group Types don't accept values
          :dependency => ["foo"],
          :framework => ["foo"],
          :configfile => ["foo"],
          :method => ["foo"],
          :template => ["foo"],
          :template_pg_pattern => ["foo"],
          :template_prop_pattern => ["foo"]
        }.each_pair { |k,a|
          a.each { |v|
            it "should not accept type #{k} -> #{v}" do
              expect {
          described_class.new(:name => "#{k}-#{v}", :ensure => :present,
                         :fmri => "svc:/baz", :property => "foo",
                         :type => k, :value => k)
              }.to raise_error(Puppet::ResourceError, /Property groups do not take values/)
                end
          }
        }
        {
          # Property Group Types don't have /s in their properties
          :dependency => [nil],
          :framework => [nil],
          :configfile => [nil],
          :method => [nil],
          :template => [nil],
          :template_pg_pattern => [nil],
          :template_prop_pattern => [nil]
        }.each_pair { |k,a|
          a.each { |v|
            it "should not accept type #{k} when property 'foo/bar'" do
              expect {
                described_class.new(:name => "#{k}-#{v}", :ensure => :present,
                               :fmri => "svc:/baz", :property => "foo/bar",
                               :type => k)
              }.to raise_error(Puppet::ResourceError, /cannot contain/)
                end
          }
        }
      end # property group
    end
  end # validation
  end # type class

#!/usr/bin/env ruby

require 'spec_helper'
require_relative  '../../../../lib/puppet/type/pkg_publisher'
require_relative '../../../../lib/puppet/provider/pkg_publisher/solaris.rb'

describe Puppet::Type.type(:pkg_publisher).provider(:pkg_publisher) do

  let(:resource) { Puppet::Type.type(:pkg_publisher).new(
    { :name => 'mypub',
    }
  )}
  let(:provider) { described_class.new(resource) }

  context "responds to" do
    [:exists?, :build_origin, :build_flags,
      :create, :destroy ].each do |method|
      it method do is_expected.to respond_to(method) end
      end

    [:sticky, :enable, :origin, :mirror, :proxy, :searchfirst, :searchafter,
      :searchbefore, :sslkey, :sslcert].each do |method|
      it method do is_expected.to respond_to(method) end
      it "#{method}=" do is_expected.to respond_to("#{method}=") end
      end
  end


  context 'with one mirrored publisher' do
    before :each do
      described_class.stubs(:pkg).with(:publisher, "-H", "-F", "tsv").returns "solaris	true	false	true	origin	online	http://pkgserver.foobar.com/	-\nsolaris	true	false	true	mirror	online	http://pkgserver2.foobar.com	-"
    end

    it 'finds one publisher' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'parses the publisher properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => "solaris",
        :enable => "true",
        :ensure => :present,
        :mirror => ["http://pkgserver2.foobar.com"],
        :origin => ["http://pkgserver.foobar.com"],
        :proxy => nil,
        :searchafter => nil,
        :searchbefore => nil,
        :searchfirst => true,
        :sslcert => nil,
        :sslkey => nil,
        :sticky => "true"
      } )
    end
  end


  context 'with two non-mirrored publishers' do
    before :each do
      described_class.stubs(:pkg).with(:publisher, "-H", "-F", "tsv").returns "solaris	true	false	true	origin	online	http://pkgserver.foobar.com/	-\nextra	true	false	true	origin	online	http://extra.foobar.com	-"
    end

    it 'finds two publishers' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'parses the first publisher properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => "solaris",
        :enable => "true",
        :ensure => :present,
        :mirror => [],
        :origin => ["http://pkgserver.foobar.com"],
        :proxy => nil,
        :searchafter => nil,
        :searchbefore => nil,
        :searchfirst => true,
        :sslcert => nil,
        :sslkey => nil,
        :sticky => "true"
      } )
    end

    it 'parses the second publisher properly' do
      expect(described_class.instances[1].instance_variable_get("@property_hash")).to eq( {
        :name => "extra",
        :enable => "true",
        :ensure => :present,
        :mirror => [],
        :origin => ["http://extra.foobar.com"],
        :proxy => nil,
        :searchafter => "solaris",
        :searchbefore => nil,
        :searchfirst => nil,
        :sslcert => nil,
        :sslkey => nil,
        :sticky => "true"
      } )
    end
  end


end

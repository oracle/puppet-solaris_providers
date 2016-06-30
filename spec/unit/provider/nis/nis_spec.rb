#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nis).provider(:nis) do

  let(:provider) do
    @nis_class = Puppet::Type.type(:nis)
    @provider = @nis_class.provider(:nis)
    @provider.stubs(:suitable?).returns true
    described_class.new(:nis)
  end

  [:domainname, :ypservers, :securenets, :use_broadcast, :use_ypsetme].each { |method|
    it { is_expected.to respond_to(method) }
    it { is_expected.to respond_to("#{method}=".to_sym) }
  }

    it { is_expected.to respond_to(:flush) }

  xdescribe "when validating defined properties" do
    props = ""
    [Client_fmri, Domain_fmri].each do |svc|
      #props = props + `svcprop -a #{svc}`
    end

    Puppet::Type.type(:nis).validproperties.each do |field|
      pg = "config"

      it "should be able to see the #{pg}/#{field} SMF property" do
        expect(props =~ /tm_proppat_nt_#{pg}_#{field.to_s}\/name/).not_to eq(nil)
      end

    end  # validproperties
  end  # validating default values
end

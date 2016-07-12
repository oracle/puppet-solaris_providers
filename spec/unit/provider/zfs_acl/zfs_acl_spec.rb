#!/usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:zfs_acl).provider(:zfs_acl) do

  let(:resource) do
    Puppet::Type.type(:zfs_acl).new(
      :name => "/tmp/foo", :ensure => :present,
      :acl => [{:target => :everyone,
        :perms => [:read_data],
        :inheritance => [:absent],
        :perm_type => :allow}]
    )
      end

  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/bin/chmod').returns true
    FileTest.stubs(:executable?).with('/usr/bin/chmod').returns true
    FileTest.stubs(:file?).with('/usr/bin/ls').returns true
    FileTest.stubs(:executable?).with('/usr/bin/ls').returns true
    FileTest.stubs(:exists?).with('/tmp/foo').returns true
  end

  context "responds to" do
    [ :exists?, :create, :destroy, :file ].each do |method|
      it method do is_expected.to respond_to(method) end
    end
    it :acl do is_expected.to respond_to(:acl) end
    it :acl= do is_expected.to respond_to(:acl=) end
  end

  describe "parses ACL into an array of ACEs" do
    it "finds the expected number of ACEs" do
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
      expect(provider.acl.size).to eq 8
    end
    it "finds the expected content of ACEs" do
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
      expect(provider.acl).to eq YAML.load_file(my_fixture('ls_v_tmp_foo.yaml'))
    end
  end
  describe ".has_default_perms?" do
    it "false" do
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('not_default_perms.txt'))
      expect(provider.has_default_perms?).to eq false
    end
    it "true" do
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('default_perms.txt'))
      expect(provider.has_default_perms?).to eq true
    end
  end
  describe ".has_custom_perms?" do
    it "false" do
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('default_perms.txt'))
      expect(provider.has_custom_perms?).to eq false
    end
    it "user/group: true" do
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('custom_perms.txt'))
      expect(provider.has_custom_perms?).to eq true
    end
    [ "owner", "group", "everyone" ].each { |thing|
    it "#{thing}@ true" do
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture("custom_perms_#{thing}@.txt"))
      expect(provider.has_custom_perms?).to eq true
    end
    }
  end
  describe ".exists?" do
    it "returns false for non-existent file" do
      resource[:file] = "/bogus/bogus123"
      expect(provider.exists?).to eq false
    end
    it "returns true for a file" do
      resource[:file] = "/tmp/foo"
      described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
      expect(provider.exists?).to eq true
    end
  end

  describe ".create" do
    before(:each) do
    end
    context ":purge_acl = true" do
      context "set_default_perms = false" do
        before(:each) do
          resource[:set_default_perms] = :false
        end
        it "creates a simple ACL" do
          resource[:set_default_perms] = false
          described_class.expects(:chmod).with('A=everyone@:read_data::allow', '/tmp/foo')
          expect(provider.create).to eq nil
        end
        it "creates a simple user: ACL" do
          resource[:acl][0][:target]= "user:sferry"
          resource[:acl][0][:perms].push :write_data
          described_class.expects(:chmod).with('A=user:sferry:read_data/write_data::allow', '/tmp/foo')
          expect(provider.create).to eq nil
        end
        it "creates a simple multi-entry ACL" do
          resource[:acl] = [ resource[:acl][0], resource[:acl][0].dup ]
          resource[:acl][1][:target]= "user:sferry"
          resource[:acl][1][:perms].push :write_data
          described_class.expects(:chmod).with('A=user:sferry:read_data/write_data::allow,everyone@:read_data/write_data::allow', '/tmp/foo')
          expect(provider.create).to eq nil
        end
      end
      context "set_default_perms = true" do
        before(:each) do
          resource[:set_default_perms] = :true
        end
        it "creates an ACL with mixed default params" do
          resource[:acl][0][:perms].push :append_data
          # There is a better way to do this repeat execution
          described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('not_default_perms.txt'))
          described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('not_default_perms.txt'))
          described_class.expects(:chmod).with('A=group@:read_xattr/read_attributes/read_acl/synchronize::allow,owner@:read_xattr/write_xattr/read_attributes/write_attributes/read_acl/write_acl/write_owner/synchronize::allow,everyone@:read_data/append_data/read_xattr/read_attributes/read_acl/synchronize::allow', '/tmp/foo')
          expect(provider.create).to eq nil
        end
        it "creates an ACL with default and granular params" do
          resource[:acl][0][:target] = "user:sferry"
          described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('not_default_perms.txt'))
          described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('not_default_perms.txt'))
          described_class.expects(:chmod).with('A=everyone@:read_xattr/read_attributes/read_acl/synchronize::allow,group@:read_xattr/read_attributes/read_acl/synchronize::allow,owner@:read_xattr/write_xattr/read_attributes/write_attributes/read_acl/write_acl/write_owner/synchronize::allow,user:sferry:read_data::allow', '/tmp/foo')
          expect(provider.create).to eq nil
        end
      end
    end
  end
  describe ".destroy" do
    it "removes a custom ACL" do
          described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
          described_class.expects(:chmod).with('A-', '/tmp/foo')
          expect(provider.destroy).to eq nil
    end
    it "does nothing for a standard ACL" do
          described_class.expects(:ls).with("-v", "/tmp/foo").returns File.read(my_fixture('not_default_perms.txt'))
          expect(provider.destroy).to eq nil
    end
  end
end

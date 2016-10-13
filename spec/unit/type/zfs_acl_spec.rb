#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:zfs_acl) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "/tmp/foo",
      :ensure => :present,
      :acl => [
        {'target'=>'owner', 'perms'=>['full_set'], 'perm_type'=>'allow'},
        {'target'=>'everyone', 'perms'=>['write_set'], 'perm_type'=>'deny'}
    ],
    }
      end

  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { Puppet::Type.type(:zfs_acl).new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:acl) {
    params.each.collect do |param|
      Puppet::Type::ZfsAcl::Ace.new(param[:acl])
    end
  }


  let(:error_pattern) { /Invalid/ }

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end

  describe "has property" do
    [ :ensure, :acl,].each do |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    end
    end

  describe "has param" do
    [ :set_default_perms, :purge_acl,].each do |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :param
      end
    end
  end

  describe "accepts valid parameters for" do
    context "target" do
      before(:each) do
        params[:acl][0] = {
          'perms' => ['read_data'],
          'perm_type' => 'allow'
        }
      end
      %w( owner@ group@ everyone@
        owner group everyone
        user:foo group:bar
      ).each do |thing|
        it thing.inspect do
          params[:acl][0]['target'] = thing
          expect { resource }.not_to raise_error
        end
      end

    end
    context "perms" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'perm_type' => 'allow'
        }
      end
      %w(
        read_data write_data append_data read_xattr write_xattr
        execute delete_child read_attributes write_attributes
        delete read_acl write_acl write_owner synchronize
        full_set modify_set read_set write_set
      ).each do |thing|
        it thing.inspect do
          params[:acl][0]['perms']= [thing]
          expect { resource }.not_to raise_error
        end
      end

      # Check multiple perms at once
      it "accepts multiple valid options" do
        params[:acl][0]['perms']= ['read_data', 'write_data', 'append_data']
        expect { resource }.not_to raise_error
      end

      context "expands sets" do
        it "full_set" do
          params[:acl][0]['perms']= ['full_set']
          expect(resource[:acl][0].perms).to eq(["read_data",
            "write_data", "append_data", "read_xattr", "write_xattr",
            "execute", "delete_child", "read_attributes",
            "write_attributes", "delete", "read_acl", "write_acl",
            "write_owner", "synchronize"])
        end

        it "modify_set" do
          params[:acl][0]['perms']= ['modify_set']
          expect(resource[:acl][0].perms).to eq(["read_data",
            "write_data", "append_data", "read_xattr", "write_xattr",
            "execute", "delete_child", "read_attributes",
            "write_attributes", "delete", "read_acl",
            "synchronize"])
        end
        it "modify_set+" do
          params[:acl][0]['perms']= ['modify_set','write_owner']
          expect(resource[:acl][0].perms).to includes('write_owner')
        end
        it "write_set" do
          params[:acl][0]['perms']= ['write_set']
          expect(resource[:acl][0].perms).to eq(
            %w(write_data append_data write_attributes write_xattr))

        end
        it "write_set+" do
          params[:acl][0]['perms']= ['write_set','read_data']
          expect(resource[:acl][0].perms).to includes('read_data')

        end
        it "read_set" do
          params[:acl][0]['perms']= ['read_set']
          expect(resource[:acl][0].perms).to eq(
             %w(read_data read_acl read_attributes read_xattr))
        end
        it "read_set+" do
          params[:acl][0]['perms']= ['read_set','write_data']
          expect(resource[:acl][0].perms).to includes('write_data')
        end
      end
    end

    context "inheritance" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'perm_type' => 'allow',
          'perms' => ['write_set']
        }
      end

     %w(
     file_inherit dir_inherit inherit_only no_propagate absent
       ).each do |thing|
        it thing.inspect do
          params[:acl][0]['inheritance'] = [thing]
          expect { resource }.not_to raise_error
        end
      end

      # Check multiple flags at once
      it "accepts multiple valid options" do
        params[:acl][0]['inheritance'] = ['inherit_only', 'no_propagate']
        expect { resource }.not_to raise_error
      end

    end
    context "perm_type" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'inheritance' => ['no_propagate'],
          'perms' => ['write_set']
        }
      end
      %w( allow deny audit alarm ).each do |thing|
        it thing.inspect do
          params[:acl][0]['perm_type'] = thing
          expect { resource }.not_to raise_error
        end
      end
    end
    context "set_default_perms" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'perm_type' => 'allow',
          'perms' => ['write_set']
        }
      end
      %w(true false).each do |thing|
        it thing.inspect do
          params[:acl][0][:set_default_perms] = thing
          expect { resource }.not_to raise_error
        end
      end
    end
    context "purge_acl" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'perm_type' => 'allow',
          'perms' => ['write_set']
        }
      end
      %w(true false).each do |thing|
        it thing.inspect do
          params[:acl][0][:purge_acl] = thing
          expect { resource }.not_to raise_error
        end
      end
    end
  end # Valid values

  describe "rejects invalid parameters for" do
    context "target" do
      before(:each) do
        params[:acl][0] = {
          'perms' => ['read_data'],
          'perm_type' => 'allow'
        }
      end
      %w( :other bob usr:foo user: group: ).each do |thing|
        it thing.inspect do
          params[:acl][0]['target'] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end

    end
    context "perms" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'perm_type' => 'allow'
        }
      end
     %w(
        reads_data :munge foo
      ).each do |thing|
        it thing.inspect do
          params[:acl][0]['perms']= [thing]
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end

      # Check multiple perms at once
      it "rejects mixed valid/invalid options" do
        params[:acl][0]['perms']= [:bogus, 'write_data', 'append_data', :foo]
        expect { resource }.to raise_error(Puppet::Error, error_pattern)
      end
    end

    context "inheritance" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'perm_type' => 'allow',
          'perms' => ['write_set']
        }
      end

      [
        :bogus, :thing
      ].each do |thing|
        it thing.inspect do
          params[:acl][0]['inheritance'] = [thing]
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end

      # Check multiple flags at once
      it "rejects mixed valid/invalid options" do
        params[:acl][0]['inheritance'] = ['inherit_only', :bogus]
        expect { resource }.to raise_error(Puppet::Error, error_pattern)
      end

    end
    context "perm_type" do
      before(:each) do
        params[:acl][0] = {
          'target' => 'owner',
          'inheritance' => ['no_propagate'],
          'perms' => ['write_set']
        }
      end
      [ :permit, :reject ].each do |thing|
        it thing.inspect do
          params[:acl][0]['perm_type'] = thing
          expect { resource }.to raise_error(Puppet::Error, error_pattern)
        end
      end
    end
  end # Invalid values
  context "ACL array" do
    before(:each) do
      params[:acl][0] = {
        'target' => 'owner',
        'inheritance' => ['no_propagate'],
        'perms' => ['write_set'],
        'perm_type' => 'allow'
      }
      params[:acl][1] = {
        'target' => 'everyone',
        'perms' => ['read_set'],
        'perm_type' => 'allow'
      }
    end
    it "accepts valid sets" do
      expect { resource }.not_to raise_error
    end
    it "rejects mixed valid/invalid sets" do
      params[:acl][1]['target'] = "foo"
      expect { resource }.to raise_error(Puppet::Error, error_pattern)
    end
  end

  context "autorequires" do
    context "files" do
      it "does not require file when no matching resource exists" do
        file = Puppet::Type.type(:file).new(:name => "/tmp/bar")
        catalog.add_resource resource
        catalog.add_resource file
        expect(resource.autorequire.count).to eq 0
      end
      it "requires the matching file resource" do
        file = Puppet::Type.type(:file).new(:name => resource[:file])
        catalog.add_resource file
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 1
        expect(reqs[0].source).to eq file
        expect(reqs[0].target).to eq resource
      end
    end

    # This setup from puppetlabs-acl/spec/unit/type/acl_spec.rb
    context "users" do
      def test_add_user(user_name)
        user = Puppet::Type.type(:user).new(:name => user_name)
        catalog.add_resource user
        user
      end
      def test_should_set_autorequired_user(user_name)
        user = test_add_user(user_name)
        catalog.add_resource resource

        reqs = resource.autorequire
        expect(reqs.count).to eq 1
        expect(reqs[0].source).to eq user
        expect(reqs[0].target).to eq resource
      end

      def test_should_not_set_autorequired_user(user_name)
        test_add_user(user_name)
        catalog.add_resource resource

        reqs = resource.autorequire
        expect(reqs).to be_empty
      end
      it "does not require user when no matching resource exists" do
        test_should_not_set_autorequired_user("foo")
      end
      it "requires user when matching resource exists" do
        params[:acl][0]['target'] = "user:foo"
        test_should_set_autorequired_user("foo")
      end
      it "requires multiple users when matching resources exist" do
        # Add ACE entries for three users
        params[:acl][0]['target'] = "user:foo"
        params[:acl][1]['target'] = "user:bar"
        params[:acl][2] = params[:acl][1].dup
        params[:acl][2]['target'] = "user:baz"

        # Add two users to the catalog
        foo = test_add_user("foo")
        bar = test_add_user("bar")

        # Add the resource to the catalog and get requirements
        catalog.add_resource resource
        reqs = resource.autorequire

        # Check expectations
        expect(reqs.length).to eq 2
        expect(reqs[0].source).to eq foo
        expect(reqs[1].source).to eq bar
      end
    end
    context "groups" do
      def test_add_group(group_name)
        group = Puppet::Type.type('group').new(:name => group_name)
        catalog.add_resource group
        group
      end
      it "does not require group when no matching resource exists" do
        group = Puppet::Type.type('group').new(:name => "foo")
        params[:acl][0]['target'] = "group:sys"
        catalog.add_resource resource
        catalog.add_resource group
        expect(resource.autorequire.count).to eq 0
      end
      it "requires the matching group resource" do
        params[:acl][0]['target'] = "group:foo"
        group = test_add_group("foo")
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 1
        expect(reqs[0].source).to eq group
        expect(reqs[0].target).to eq resource
      end
      it "requires multiple groups when matching resources exist" do
        # Add ACE entries for three users
        params[:acl][0]['target'] = "group:foo"
        params[:acl][1]['target'] = "group:bar"
        params[:acl][2] = params[:acl][1].dup
        params[:acl][2]['target'] = "group:baz"

        # Add two groups to the catalog
        foo = test_add_group("foo")
        bar = test_add_group("bar")

        # Add the resource to the catalog and get requirements
        catalog.add_resource resource
        reqs = resource.autorequire

        # Check expectations
        expect(reqs.length).to eq 2
        expect(reqs[0].source).to eq foo
        expect(reqs[1].source).to eq bar
      end
    end
  end
end

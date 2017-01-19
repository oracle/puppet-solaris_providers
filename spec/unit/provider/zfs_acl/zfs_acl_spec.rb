require 'spec_helper'

describe Puppet::Type.type(:zfs_acl).provider(:zfs_acl) do

  let(:ace) { Puppet::Type::ZfsAcl::Ace }

  let(:params) do
    {
      :name => "/root/foo", :ensure => 'present',
      :file => "/root/foo",
      :set_default_perms => 'true',
      :acl => [{'target' => 'everyone',
        'perms' => ['read_data'],
        'inheritance' => ['absent'],
        'perm_type' => 'allow'}]
    }
      end

  let(:resource) { Puppet::Type.type(:zfs_acl).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/bin/chmod').returns true
    FileTest.stubs(:executable?).with('/usr/bin/chmod').returns true
    FileTest.stubs(:file?).with('/usr/bin/ls').returns true
    FileTest.stubs(:executable?).with('/usr/bin/ls').returns true
    FileTest.stubs(:exists?).with('/root/foo').returns true
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
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
      expect(provider.acl.size).to eq 8
    end
    it "finds the expected content of ACEs" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(
        my_fixture('ls_v_tmp_foo.txt'))
        expect(provider.acl.collect { |ace| ace.to_hash }).to eq YAML.load_file(
          my_fixture('ls_v_tmp_foo.yaml'))
    end
  end
  describe ".has_default_perms?" do
    it "true" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
      expect(provider.has_default_perms?(provider.acl)).to eq true
    end
    it "false" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('not_default_perms.txt'))
      expect(provider.has_default_perms?(provider.acl)).to eq false
    end
    it "false with perm_type = deny" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('default_perms_deny.txt'))
      expect(provider.has_default_perms?(provider.acl)).to eq false
    end
  end
  describe ".add_default_perms" do
    it "maintains custom perms" do
      before = [
        Ace.new({'target' => 'user:sferry','perms'=>['read_data'],'perm_type' => 'deny'}),
        Ace.new({'target' => 'user:sferry','perms'=>['write_data'],'perm_type' => 'allow'}),
        Ace.new({'target'=>"group@", 'perms'=>["read_xattr", "read_attributes", "read_acl", "synchronize", "write_data"], 'perm_type'=>"allow", 'inheritance'=>["absent"]}),
      ]
      after = provider.add_default_perms(before)
      expect(after.length).to eq(5)

      before.each_with_index { |ace,idx|
        expect(ace.to_h).to eq(before[idx].to_h)
      }
    end
    it "adds default perms" do
      goal = [
        Ace.new({'target'=>"owner@", 'perms'=>["read_xattr", "write_xattr", "read_attributes", "write_attributes", "read_acl", "write_acl", "write_owner", "synchronize"], 'perm_type'=>"allow", 'inheritance'=>["absent"]}),
        Ace.new({'target'=>"group@", 'perms'=>["read_xattr", "read_attributes", "read_acl", "synchronize"], 'perm_type'=>"allow", 'inheritance'=>["absent"]}),
        Ace.new({'target'=>"everyone@", 'perms'=>["read_xattr", "read_attributes", "read_acl", "synchronize"], 'perm_type'=>"allow", 'inheritance'=>["absent"]}),
      ]
      output = provider.add_default_perms([])
      expect(output.length).to eq(3)
      output.each_with_index { |ace,idx|
        expect(ace.to_h).to eq(goal[idx].to_h)
      }
    end
  end
  describe ".has_custom_perms?" do
    it "user/group: true" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('custom_perms.txt'))
      expect(provider.has_custom_perms?).to eq true
    end
    [ "owner", "group", "everyone" ].each { |thing|
      it "#{thing}@ true" do
        described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture("custom_perms_#{thing}@.txt"))
        expect(provider.has_custom_perms?).to eq true
      end
    }
    it "false" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('default_perms.txt'))
      expect(provider.has_custom_perms?).to eq false
    end
  end
  describe ".exists?" do
    it "returns false for non-existent file" do
      resource[:file] = "/bogus/bogus123"
      expect(provider.exists?).to eq false
    end
    it "returns true for a file" do
      resource[:file] = "/root/foo"
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
      expect(provider.exists?).to eq true
    end
  end

  describe ".create (file)" do
    before(:each) do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
    end
    context ":purge_acl = true" do
      context "set_default_perms = false" do
        before(:each) do
          params[:set_default_perms] = false
        end
        it "creates a simple ACL" do
          described_class.expects(:chmod).with(
            'A=everyone@:r-------------:------:allow', params[:file])
          expect(provider.create).to eq nil
        end
        it "creates a simple user: ACL" do
          params[:acl][0]['target']= "user:sferry"
          params[:acl][0]['perms'].push 'write_data'
          described_class.expects(:chmod).with(
            'A=user:sferry:rw------------:------:allow', params[:file])
          expect(provider.create).to eq nil
        end
        it "creates a simple multi-entry ACL" do
          params[:acl].push params[:acl][0].dup
          params[:acl][1]['target']= "user:sferry"
          params[:acl][1]['perms']= ['write_data']
          params[:acl][1]['perm_type']= 'allow'
          params[:acl].push params[:acl][1].dup
          params[:acl][1]['perms']= ['read_data']
          params[:acl][1]['perm_type']= 'deny'
          described_class.expects(:chmod).with(
            [
              'A=everyone@:r-------------:------:allow',
              'user:sferry:r-------------:------:deny',
              'user:sferry:-w------------:------:allow'
          ] * ",",
            params[:file])
          expect(provider.create).to eq nil
        end
      end
      context "set_default_perms = true" do
        before(:each) do
          params[:set_default_perms] = true
        end
        it "creates an ACL with mixed default params" do
          params[:acl][0]['perms'].push 'append_data'
          described_class.expects(:chmod).with(
            [
              'A=owner@:------aARWcCos:------:allow',
              'group@:------a-R-c--s:------:allow',
              'everyone@:r--p--a-R-c--s:------:allow'
          ] * ",",
              params[:file])
              expect(provider.create).to eq nil
        end
        it "creates an ACL with default and granular params" do
          params[:acl][0]['target'] = "user:sferry"
          described_class.expects(:chmod).with(
            [
              'A=user:sferry:r-------------:------:allow',
              'owner@:------aARWcCos:------:allow',
              'group@:------a-R-c--s:------:allow',
              'everyone@:------a-R-c--s:------:allow'
          ] * ",",
              params[:file])
              expect(provider.exists?)
              expect(provider.create).to eq nil
        end
      end
    end
  end #create file
  describe ".create (dir)" do
    before(:each) do
      described_class.expects(:ls).with("-d", "-v", "/root").returns File.read(my_fixture('ls_v_root.txt'))
      params[:file] = "/root"
    end
    context ":purge_acl = true" do
      context "set_default_perms = false" do
        before(:each) do
          params[:set_default_perms] = false
        end
        it "creates a simple ACL" do
          described_class.expects(:chmod).with(
            'A=everyone@:r-------------:------:allow', params[:file])
          expect(provider.create).to eq nil
        end
        it "creates a simple user: ACL" do
          params[:acl][0]['target']= "user:sferry"
          params[:acl][0]['perms'].push 'write_data'
          described_class.expects(:chmod).with(
            'A=user:sferry:rw------------:------:allow', params[:file])
          expect(provider.create).to eq nil
        end
        it "creates a simple multi-entry ACL" do
          params[:acl].push params[:acl][0].dup
          params[:acl][1]['target']= "user:sferry"
          params[:acl][1]['perms'].push 'write_data'
          described_class.expects(:chmod).with(
            ['A=everyone@:rw------------:------:allow',
              'user:sferry:rw------------:------:allow'
          ] * ",",
              params[:file])
              expect(provider.create).to eq nil
        end
      end
      context "set_default_perms = true" do
        before(:each) do
          params[:set_default_perms] = true
        end
        it "creates an ACL with mixed default params" do
          params[:acl][0]['perms'].push 'append_data'
          described_class.expects(:chmod).with(
            [
              'A=owner@:------aARWcCos:------:allow',
              'group@:------a-R-c--s:------:allow',
              'everyone@:r--p--a-R-c--s:------:allow'
          ] * ",",
            params[:file])
          expect(provider.create).to eq nil
        end
        it "creates an ACL with default and granular params" do
          params[:acl][0]['target'] = "user:sferry"
          described_class.expects(:chmod).with(
            [
              'A=user:sferry:r-------------:------:allow',
              'owner@:------aARWcCos:------:allow',
              'group@:------a-R-c--s:------:allow',
              'everyone@:------a-R-c--s:------:allow'
          ] * ",",
              params[:file])
              expect(provider.exists?)
              expect(provider.create).to eq nil
        end
      end
    end
  end
  describe ".destroy" do
    it "removes a custom ACL" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('ls_v_tmp_foo.txt'))
      described_class.expects(:chmod).with('A-', '/root/foo')
      expect(provider.destroy).to eq nil
    end
    it "does nothing for a standard ACL" do
      described_class.expects(:ls).with("-d", "-v", "/root/foo").returns File.read(my_fixture('not_default_perms.txt'))
      expect(provider.destroy).to eq nil
    end
  end
end

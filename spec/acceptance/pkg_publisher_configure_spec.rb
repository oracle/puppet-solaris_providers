require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris pkg_publisher provider' do

  # create some local repositories
  before(:all) do
    shell("pkgrepo create /tmp/puppet-repo1", :acceptable_exit_codes => 0)
    shell("pkgrepo create /tmp/puppet-repo2", :acceptable_exit_codes => 0)
    shell("pkgrepo create /tmp/puppet-repo3", :acceptable_exit_codes => 0)
    shell("pkgrepo add-publisher -s /tmp/puppet-repo1 puppet", :acceptable_exit_codes => 0)
    shell("pkgrepo add-publisher -s /tmp/puppet-repo2 puppet", :acceptable_exit_codes => 0)
    shell("pkgrepo add-publisher -s /tmp/puppet-repo3 puppet3", :acceptable_exit_codes => 0)
  end

  # manifests to add publishers
  mirror_pp = <<-EOP
    pkg_publisher {'puppet':
      ensure => present, 
      origin => 'file:///tmp/puppet-repo1',
      mirror => 'file:///tmp/puppet-repo2',
      enable => 'true',
      sticky => 'true',
      searchfirst => 'true'
    }
  EOP

  sb_pp = <<-EOP
    pkg_publisher {'puppet3':
      ensure => present, 
      origin => 'file:///tmp/puppet-repo3',
      searchbefore => 'puppet',
      enable => 'true',
      sticky => 'false'
    }
  EOP

  sa_pp = <<-EOP
    pkg_publisher {'puppet3':
      ensure => present, 
      origin => 'file:///tmp/puppet-repo3',
      searchafter => 'puppet',
      enable => 'true',
      sticky => 'false'
    }
  EOP

  dis_pp = <<-EOP
    pkg_publisher {'puppet3':
      ensure => present, 
      origin => 'file:///tmp/puppet-repo3',
      enable => 'false',
      sticky => 'false'
    }
  EOP

  rm_pp = <<-EOP
    pkg_publisher {'puppet3':
      ensure => absent, 
    }
  EOP

  context "when adding a mirrored publisher" do
    it 'should apply a manifest with no errors' do
      apply_manifest(mirror_pp, :catch_failures => true)
    end
  
    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(mirror_pp, :catch_failures => true).exit_code).to be_zero
    end
  
    it 'should correctly apply the origin value' do
      shell("pkg publisher -H -F tsv | head -1 | egrep -s '^puppet	true	false	true	origin	online	file:///tmp/puppet-repo1/	-$'", :acceptable_exit_codes => 0)
    end

    it 'should correctly apply the mirror value' do
      shell("pkg publisher -H -F tsv | head -2 | tail -1 | egrep -s '^puppet	true	false	true	mirror	online	file:///tmp/puppet-repo2/	-$'", :acceptable_exit_codes => 0)
    end
  end


  context "when adding a searchbefore publisher" do
    it 'should apply a manifest with no errors' do
      apply_manifest(sb_pp, :catch_failures => true)
    end
  
    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(sb_pp, :catch_failures => true).exit_code).to be_zero
    end
  
    it 'should correctly apply the new publisher to be first' do
      shell("pkg publisher -H -F tsv | head -1 | egrep -s '^puppet3	false	false	true	origin	online	file:///tmp/puppet-repo3/	-$'", :acceptable_exit_codes => 0)
    end
  end

  context "when adding a searchafter publisher" do
    it 'should apply a manifest with no errors' do
      apply_manifest(sa_pp, :catch_failures => true)
    end
  
    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(sa_pp, :catch_failures => true).exit_code).to be_zero
    end
  
    it 'should correctly apply the new publisher to be after' do
      shell("pkg publisher -H -F tsv | head -3 | tail -1 | egrep -s '^puppet3	false	false	true	origin	online	file:///tmp/puppet-repo3/	-$'", :acceptable_exit_codes => 0)
    end
  end

  context "when adding a disabled publisher" do
    it 'should apply a manifest with no errors' do
      apply_manifest(dis_pp, :catch_failures => true)
    end
  
    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(dis_pp, :catch_failures => true).exit_code).to be_zero
    end
  
    it 'should correctly disable the publisher' do
      shell("pkg publisher -H -F tsv | head -3 | tail -1 | egrep -s '^puppet3	false	false	false	origin	online	file:///tmp/puppet-repo3/	-$'", :acceptable_exit_codes => 0)
    end
  end

  context "when removing a publisher" do
    it 'should apply a manifest with no errors' do
      apply_manifest(rm_pp, :catch_failures => true)
    end
  
    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(rm_pp, :catch_failures => true).exit_code).to be_zero
    end
  
    it 'should correctly disable the publisher' do
      shell("pkg publisher -H -F tsv | head -3 | tail -1 | egrep -s '^puppet3'", :acceptable_exit_codes => 1)
    end
  end

  # remove the repositories 
  after(:all) do
    shell("rm -rf /tmp/puppet-repo[123]", :acceptable_exit_codes => 0)
  end
end

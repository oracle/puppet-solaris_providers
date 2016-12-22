require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris pkg_facet provider' do

  # a manifest to add a facet
  pp = <<-EOP
    pkg_facet { 'facet.version-lock.system/management/puppet':
      ensure => 'present',
      value  => 'false',
    }
  EOP

  # a manifest to remove a facet

  pp2 = <<-EOP
    pkg_facet { 'facet.version-lock.system/management/puppet':
      ensure => 'absent',
    }
  EOP


  context "when adding a facet" do
    it 'should apply a manifest with no errors' do
      apply_manifest(pp, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    it 'should correctly apply the facet value' do
      shell("pkg facet -H -F tsv | egrep -s '^facet.version-lock.system/management/puppet	False	local$'", :acceptable_exit_codes => 0)
    end
  end

  context "when removing a facet" do
    it 'should apply a manifest with no errors' do
      apply_manifest(pp2, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(pp2, :catch_failures => true).exit_code).to be_zero
    end

    it 'should correctly remove the facet value' do
      shell("pkg facet -H -F tsv | egrep -s '^facet.version-lock.system/management/puppet	False	local$'", :acceptable_exit_codes => 1)
    end
  end

end

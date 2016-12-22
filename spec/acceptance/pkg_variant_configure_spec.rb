require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris pkg_variant provider' do

  # a manifest to add a variant
  pp = <<-EOP
    pkg_variant { 'variant.foo':
      ensure => 'present',
      value  => 'bar',
    }
  EOP


  context "when adding a variant" do
    it 'should apply a manifest with no errors' do
      apply_manifest(pp, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    it 'should correctly apply the variant value' do
      shell("pkg variant -H -F tsv | egrep -s '^variant.foo	bar$'", :acceptable_exit_codes => 0)
    end
  end

end

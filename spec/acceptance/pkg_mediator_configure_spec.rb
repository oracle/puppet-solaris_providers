require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris pkg_mediator provider' do

  # a manifest to add a mediator
  pp = <<-EOP
    pkg_mediator { 'foo':
      ensure         => 'present',
      implementation => 'fooimpl',
      version => '1.0',
    }
  EOP

  # a manifest to remove a mediator
  pp2 = <<-EOP
    pkg_mediator { 'foo':
      ensure         => 'absent',
    }
  EOP


  context "when adding a mediator" do
    it 'should apply a manifest with no errors' do
      apply_manifest(pp, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end

    it 'should correctly apply the mediator value' do
      shell("pkg mediator -H -F tsv | egrep -s '^foo	local	1.0	local	fooimpl	$'", :acceptable_exit_codes => 0)
    end
  end

  context "when removing a mediator" do
    it 'should apply a manifest with no errors' do
      apply_manifest(pp2, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(pp2, :catch_failures => true).exit_code).to be_zero
    end

    it 'should correctly remove the mediator value' do
      shell("pkg mediator -H -F tsv | egrep -s '^foo	local	1.0	local	fooimpl	$'", :acceptable_exit_codes => 1)
    end
  end

end

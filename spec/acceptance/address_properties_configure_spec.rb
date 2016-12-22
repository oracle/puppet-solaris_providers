require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris address_properties provider' do

  context "when applying property changes" do
    off42_manifest = <<-EOP
      address_properties { 'lo0/v6':
        ensure     => 'present',
        properties => {'prefixlen' => '42', 
                       'transmit' => 'off'}
      }
    EOP

    it 'should apply a manifest with no errors' do
      apply_manifest(off42_manifest, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(off42_manifest, :catch_failures => true).exit_code).to be_zero
    end

    it 'should find the new values' do
      shell("ipadm show-addrprop -c -o ADDROBJ,PROPERTY,CURRENT | egrep -s '^lo0/v6:prefixlen:42$'", :acceptable_exit_codes => 0)
      shell("ipadm show-addrprop -c -o ADDROBJ,PROPERTY,CURRENT | egrep -s '^lo0/v6:transmit:off$'", :acceptable_exit_codes => 0)
    end
  end  # property changes


  context "when applying a temporary property" do
    temp_manifest = <<-EOP
      address_properties { 'lo0/v6':
        ensure     => 'present',
        properties => { 'temporary'  => 'true', 'transmit' => 'off' }
      }
    EOP

    it 'should apply the manifest with no errors' do
      apply_manifest(temp_manifest, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(temp_manifest, :catch_failures => true).exit_code).to be_zero
    end

    it 'should find the temporary value' do
      shell("ipadm show-addrprop -c -o ADDROBJ,PROPERTY,CURRENT,PERSISTENT | egrep -s '^lo0/v6:transmit:on:off$'", :acceptable_exit_codes => 0)
    end
  end # temporary property


  context "when restoring values" do
    restore_manifest = <<-EOP
      address_properties { 'lo0/v6':
        ensure     => 'present',
        properties => {'prefixlen' => '128', 
                       'transmit' => 'on'}
      }
    EOP

    it 'should apply a manifest with no errors' do
      apply_manifest(restore_manifest, :catch_failures => true)
    end

    it 'should apply the manifest again with no updates triggered' do
      expect(apply_manifest(restore_manifest, :catch_failures => true).exit_code).to be_zero
    end

    it 'should find the restored values' do
      shell("ipadm show-addrprop -c -o ADDROBJ,PROPERTY,CURRENT,PERSISTENT | egrep -s '^lo0/v6:prefixlen:128:128$'", :acceptable_exit_codes => 0)
      shell("ipadm show-addrprop -c -o ADDROBJ,PROPERTY,CURRENT,PERSISTENT | egrep -s '^lo0/v6:transmit:on:on$'", :acceptable_exit_codes => 0)
    end
  end # restore values

end

require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris address_object provider' do

  # a sample manifest to apply
  unconfigure_manifest = <<-EOP
    address_object { "lo0/v6":
      ensure => absent
    }
  EOP

  it 'should apply an unconfigure manifest with no errors' do
    apply_manifest(unconfigure_manifest, :catch_failures => true)
  end

  it 'should apply the unconfigure manifest again with no updates triggered' do
    expect(apply_manifest(unconfigure_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should not find the removed address object' do
    shell("ipadm | grep lo0/v6", :acceptable_exit_codes => 1)
  end


  configure_manifest = <<-EOP
    address_object { "lo0/v6":
      address_type => static,
      enable => true,
      ensure => present,
      address => "::1/128"
    }
  EOP

  it 'should apply a configure manifest with no errors' do
    apply_manifest(configure_manifest, :catch_failures => true)
  end

  it 'should apply the configure manifest again with no updates triggered' do
    expect(apply_manifest(configure_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should find the configured address object' do
    shell("ipadm | egrep -s lo0/v6", :acceptable_exit_codes => 0)
  end


  down_manifest = <<-EOP
    address_object { "lo0/v6":
      down => true
    }
  EOP

  it 'should apply a down manifest with no errors' do
    apply_manifest(down_manifest, :catch_failures => true)
  end

  it 'should apply the down manifest again with no updates triggered' do
    expect(apply_manifest(down_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should find the downed address object' do
    shell("ipadm | grep -s lo0/v6 | egrep -s down", :acceptable_exit_codes => 0)
  end


  up_manifest = <<-EOP
    address_object { "lo0/v6":
      down => false
    }
  EOP

  it 'should apply a up manifest with no errors' do
    apply_manifest(up_manifest, :catch_failures => true)
  end

  it 'should apply the up manifest again with no updates triggered' do
    expect(apply_manifest(up_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should find the up address object' do
    shell("ipadm | grep -s lo0/v6 | egrep -s ok", :acceptable_exit_codes => 0)
  end

end

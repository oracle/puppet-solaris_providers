require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris LDAP provider' do

  Client_fmri = "svc:/network/nis/client"
  Domain_fmri = "svc:/network/nis/domain"

  # a sample manifest to apply
  pp = <<-EOP
    nis { 'current':
      domainname                    => ['foo.com'],
      ypservers                     => ['1.2.3.4', '2.3.4.5'],
      securenets                    => { 'a.foo.com' => '1.2.3.4',
                                         'b.foo.com' => '2.3.4.5' },
      use_broadcast                 => false,
      use_ypsetme                   => false,
    }
  EOP

  # disable service so configuration doesn't get overridden by server
  [ Client_fmri, Domain_fmri ].each do
    shell("svcadm disable ldap/client", :acceptable_exit_codes => 0)
  end

  it 'should apply a manifest with no errors' do
    apply_manifest(pp, :catch_failures => true)
  end

  it 'should apply the manifest again with no updates triggered' do
    expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
  end

  it 'should correctly apply the domainname value' do
    shell("svcprop -p config/domainname #{Domain_fmri} | egrep -s '^foo.com$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the ypservers value' do
    shell("svcprop -p config/ypservers #{Domain_fmri} | egrep -s '^1.2.3.4 2.3.4.5$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the securenets value' do
    shell("svcprop -p config/securenets #{Domain_fmri} | egrep -s '^a.foo.com\\\\ 1.2.3.4 b.foo.com\\\\ 2.3.4.5$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the use_broadcast value' do
    shell("svcprop -p config/use_broadcast #{Client_fmri} | egrep -s '^false$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the use_ypsetme value' do
    shell("svcprop -p config/use_ypsetme #{Client_fmri} | egrep -s '^false$'", :acceptable_exit_codes => 0)
  end

end

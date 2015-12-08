require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris LDAP provider' do

  fmri = "ldap/client"

  # a sample manifest to apply
  pp = <<-EOP
    ldap { 'current':
      admin_bind_dn                 => ['admin_bind_dn_val'],
      admin_bind_passwd             => 'adminbindpass',
      attribute_map                 => ['map1:val', 'map2:val'],
      authentication_method         => ['tls:simple', 'simple'],
      bind_dn                       => ['dc=foo,dc=com'],
      bind_passwd                   => 'bindpass',
      bind_time_limit               => '10',
      credential_level              => 'proxy',
      enable_shadow_update          => 'false',
      follow_referrals              => 'false',
      host_certpath                 => '/var/certpath',
      objectclass_map               => ['map1:val', 'map2:val'],
      preferred_server_list         => ['a.foo.com', 'b.foo.com'],
      profile                       => 'ldap-profile',
      profile_ttl                   => '43200',
      search_base                   => 'dc=foo,dc=com',
      search_scope                  => 'one',
      search_time_limit             => '30',
      server_list                   => ['a.foo.com', 'b.foo.com'],
      service_authentication_method => ['simple', 'tls:simple'],
      service_credential_level      => 'proxy',
      service_search_descriptor     => 'passwd:dc=foo,dc=com',
    }
  EOP

  # disable service so configuration doesn't get overridden by server
  shell("svcadm disable ldap/client", :acceptable_exit_codes => 0)

  it 'should apply a manifest with no errors' do
    apply_manifest(pp, :catch_failures => true)
  end

  it 'should apply the manifest again with no updates triggered' do
    expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
  end

  it 'should correctly apply the admin_bind_dn value' do
    shell("svcprop -p cred/admin_bind_dn #{fmri} | egrep -s '^admin_bind_dn_val$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the admin_bind_passwd value' do
    shell("svcprop -p cred/admin_bind_passwd #{fmri} | egrep -s '^adminbindpass$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the attribute_map value' do
    shell("svcprop -p config/attribute_map #{fmri} | egrep -s '^map1:val map2:val$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the authentication_method value' do
    shell("svcprop -p config/authentication_method #{fmri} | egrep -s '^tls:simple simple$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the bind_dn value' do
    shell("svcprop -p cred/bind_dn #{fmri} | egrep -s '^dc=foo,dc=com$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the bind_passwd value' do
    shell("svcprop -p cred/bind_passwd #{fmri} | egrep -s '^bindpass$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the bind_time_limit value' do
    shell("svcprop -p config/bind_time_limit #{fmri} | egrep -s '^10$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the credential_level value' do
    shell("svcprop -p config/credential_level #{fmri} | egrep -s '^proxy$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the enable_shadow_update value' do
    shell("svcprop -p cred/enable_shadow_update #{fmri} | egrep -s '^false$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the follow_referrals value' do
    shell("svcprop -p config/follow_referrals #{fmri} | egrep -s '^false$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the host_certpath value' do
    shell("svcprop -p cred/host_certpath #{fmri} | egrep -s '^/var/certpath$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the objectclass_map value' do
    shell("svcprop -p config/objectclass_map #{fmri} | egrep -s '^map1:val map2:val$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the preferred_server_list value' do
    shell("svcprop -p config/preferred_server_list #{fmri} | egrep -s '^a.foo.com b.foo.com$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the profile value' do
    shell("svcprop -p config/profile #{fmri} | egrep -s '^ldap-profile$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the profile_ttl value' do
    shell("svcprop -p config/profile_ttl #{fmri} | egrep -s '^43200$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the search_base value' do
    shell("svcprop -p config/search_base #{fmri} | egrep -s '^dc=foo,dc=com$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the search_scope value' do
    shell("svcprop -p config/search_scope #{fmri} | egrep -s '^one$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the search_time_limit value' do
    shell("svcprop -p config/search_time_limit #{fmri} | egrep -s '^30$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the server_list value' do
    shell("svcprop -p config/server_list #{fmri} | egrep -s '^a.foo.com b.foo.com$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the service_authentication_method value' do
    shell("svcprop -p config/service_authentication_method #{fmri} | egrep -s '^simple tls:simple$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the service_credential_level value' do
    shell("svcprop -p config/service_credential_level #{fmri} | egrep -s '^proxy$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the service_search_descriptor value' do
    shell("svcprop -p config/service_search_descriptor #{fmri} | egrep -s '^passwd:dc=foo,dc=com$'", :acceptable_exit_codes => 0)
  end

end

require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris DNS provider' do

  fmri = "svc:/network/dns/client"

  # a sample manifest to apply
  pp = <<-EOP
    dns { 'current':
      nameserver                    => ['1.2.3.4', '2.3.4.5'],
      domain                        => 'foo.com',
      search                        => ['foo.com', 'bar.com'],
      sortlist                      => ['1.2.3.4/5', '2.3.4.5/6'],
      options                       => ['debug', 'retry:3'],
    }
  EOP

  # disable service so configuration doesn't get overridden by server
  shell("svcadm disable dns/client", :acceptable_exit_codes => 0)

  it 'should apply a manifest with no errors' do
    apply_manifest(pp, :catch_failures => true)
  end

  it 'should apply the manifest again with no updates triggered' do
    expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
  end

  it 'should correctly apply the nameserver value' do
    shell("svcprop -p config/nameserver #{fmri} | egrep -s '^1.2.3.4 2.3.4.5$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the domain value' do
    shell("svcprop -p config/domain #{fmri} | egrep -s '^foo.com$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the search value' do
    shell("svcprop -p config/search #{fmri} | egrep -s '^foo.com bar.com$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the sortlist value' do
    shell("svcprop -p config/sortlist #{fmri} | egrep -s '^1.2.3.4/5 2.3.4.5/6$'", :acceptable_exit_codes => 0)
  end

  it 'should correctly apply the options value' do
    shell("svcprop -p config/options #{fmri} | egrep -s '^debug retry:3$'", :acceptable_exit_codes => 0)
  end

end

require 'spec_helper_acceptance'
require 'pry'

describe 'Solaris zone provider' do

  # a sample zonecfg to apply

  zonecfg = <<-EOZ
    create -b
    set brand=solaris-kz
    set autoboot=true
    set autoshutdown=shutdown
    set bootargs="kz=d -k -m verbose"
    add anet
    set lower-link=auto
    set link-protection=mac-nospoof
    set mac-address=auto
    set id=0
    end
    add device
    set storage=dev:/dev/zvol/dsk/%{global-rootzpool}/VARSHARE/zones/%{zonename}/disk%{id}
    set bootpri=0
    set id=0
    end
    add capped-memory
    set physical=4G
    end
    add virtual-cpu
    set ncpus=4
    end
    add suspend
    set path=/system/zones/%{zonename}/suspend
    end 
  EOZ

  # a sample manifest to apply
  configure_manifest = <<-EOP
    zone { conzone:
      ensure => configured,
      zonecfg_export => '#{zonecfg}'
    }
  EOP

  it 'should apply a configure manifest with no errors' do
    apply_manifest(configure_manifest, :catch_failures => true)
  end

  it 'should apply the configure manifest again with no updates triggered' do
    expect(apply_manifest(configure_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should find the zone in a configured state' do
    shell("zoneadm list -cv | grep conzone | egrep -s '^   - conzone          configured  -                            solaris-kz excl  $'", :acceptable_exit_codes => 0)
  end

  # a sample manifest to apply
  uncon_manifest = <<-EOP
    zone { conzone:
      ensure => absent
    }
  EOP

  it 'should remove a configured zone with no errors' do
    apply_manifest(uncon_manifest, :catch_failures => true)
  end

  it 'should apply the removal manifest again with no updates triggered' do
    expect(apply_manifest(uncon_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should not find the zone' do
    shell("zoneadm list -cv | grep conzone", :acceptable_exit_codes => 1)
  end



  # a sample manifest to apply
  install_manifest = <<-EOP
    zone { inszone:
      ensure => installed,
      zonecfg_export => '#{zonecfg}'
    }
  EOP

  it 'should apply a configure manifest with no errors' do
    apply_manifest(install_manifest, :catch_failures => true)
  end

  it 'should apply the install manifest again with no updates triggered' do
    expect(apply_manifest(install_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should find the zone in a installed state' do
    shell("zoneadm list -cv | grep inszone | egrep -s '^   - inszone          installed   -                            solaris-kz excl  $'", :acceptable_exit_codes => 0)
  end

  # a sample manifest to apply
  unins_manifest = <<-EOP
    zone { inszone:
      ensure => absent
    }
  EOP

  it 'should remove an installed zone with no errors' do
    apply_manifest(unins_manifest, :catch_failures => true)
  end

  it 'should apply the removal manifest again with no updates triggered' do
    expect(apply_manifest(unins_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should not find the zone' do
    shell("zoneadm list -cv | grep inszone", :acceptable_exit_codes => 1)
  end


  # a sample manifest to apply
  running_manifest = <<-EOP
    zone { runzone:
      ensure => running,
      zonecfg_export => '#{zonecfg}'
    }
  EOP

  it 'should apply a configure manifest with no errors' do
    apply_manifest(running_manifest, :catch_failures => true)
  end

  it 'should apply the running manifest again with no updates triggered' do
    expect(apply_manifest(running_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should find the zone in a running state' do
    shell("zoneadm list -cv | grep runzone | egrep -s '^   [0-9] runzone          running     -                            solaris-kz excl  $'", :acceptable_exit_codes => 0)
  end

  # a sample manifest to apply
  unrun_manifest = <<-EOP
    zone { runzone:
      ensure => absent
    }
  EOP

  it 'should remove a running zone with no errors' do
    apply_manifest(unrun_manifest, :catch_failures => true)
  end

  it 'should apply the removal manifest again with no updates triggered' do
    expect(apply_manifest(unrun_manifest, :catch_failures => true).exit_code).to be_zero
  end

  it 'should not find the zone' do
    shell("zoneadm list -cv | grep runzone", :acceptable_exit_codes => 1)
  end


end

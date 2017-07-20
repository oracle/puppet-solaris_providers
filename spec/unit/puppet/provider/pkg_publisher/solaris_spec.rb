require 'spec_helper'

describe Puppet::Type.type(:pkg_publisher).provider(:solaris) do

  let(:params) do
    {
      :name => 'mpyub',
      :origin => %w[http://pkg.oracle.com/solaris/release],
      :ensure => :present,
      :proxy => [],
      :mirror => [],
      :sslkey => [],
      :sslcert => []
    }
  end
  # Fake a property hash
  let(:property_hash) do
    {
      :name => 'mpyub',
      :origin => ['http://pkg.oracle.com/solaris/release'],
      :ensure => :present,
      :proxy => [],
      :mirror => [],
      :sslkey => [],
      :sslcert => []
    }
  end
  let(:error_pattern) { /must be 0 or equal to the number of origins and mirrors/ }

  let(:resource) { Puppet::Type.type(:pkg_publisher).new(params) }
  let(:provider) do
    provider = described_class.new(resource)
    provider.instance_variable_set(:@property_hash, property_hash)
    return provider
  end



    [:exists?, :build_origin, :build_flags,
      :create, :destroy ].each do |method|
        it { is_expected.to respond_to(method) }
      end

    [:sticky, :enable, :origin, :mirror, :proxy, :searchfirst, :searchafter,
      :searchbefore, :sslkey, :sslcert].each do |method|
        it { is_expected.to respond_to(method) }
        it { is_expected.to respond_to("#{method}=") }
      end

  context ".instances" do
    before do
      described_class.stubs(:pkg).with(:publisher, "-H", "-F", "tsv").returns File.read(my_fixture('H_F_tsv.txt'))
      described_class.stubs(:pkg).with(:publisher, "-H", "-F", "tsv", ['solarisstudio', 'exa-family', 'solaris-mirror', 'solaris']).returns File.read(my_fixture('H_F_tsv_solaris___.txt'))
    end

    it 'finds four publishers' do
      expect(described_class.instances.size).to eq(4)
    end
    it 'parses the first publisher properly' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq({
        :enable => "true",
        :ensure => :present,
        :mirror => [],
        :name => "solarisstudio",
        :origin => ["https://pkg.oracle.com/solarisstudio/support"],
        :proxy => ["http://bogus.proxy"],
        :searchafter => nil,
        :searchbefore => nil,
        :searchfirst => :true,
        :sslcert => ["/var/pkg/ssl/ffe21948d584f3eb6a55f70335ef3a877d01e89a"],
        :sslkey => ["/var/pkg/ssl/4f58196a8bcf9519279cf02f8208a5617aca9984"],
        :sticky => "true",
        })
    end
    it 'parses the second publisher properly' do
      expect(described_class.instances[1].instance_variable_get("@property_hash")).to eq( {
        :enable => "true",
        :ensure => :present,
        :mirror => [],
        :name => "exa-family",
        :origin => ["https://pkg.oracle.com/solaris/exa-family"],
        :proxy => [:absent],
        :searchafter => "solarisstudio",
        :searchbefore => nil,
        :searchfirst => nil,
        :sslcert => ["/var/pkg/ssl/ffe21948d584f3eb6a55f70335ef3a877d01e89a"],
        :sslkey => ["/var/pkg/ssl/4f58196a8bcf9519279cf02f8208a5617aca9984"],
        :sticky => "true",
      } )
    end
    it 'parses the third publisher properly' do
      expect(described_class.instances[2].instance_variable_get("@property_hash")).to eq( {
        :enable => "true",
        :ensure => :present,
        :mirror => ["http://pkg.oracle.com/solaris/release"],
        :name => "solaris-mirror",
        :origin => ["file:///media/sol-12_0-119-repo/repo"],
        :proxy => [:absent, :absent],
        :searchafter => "exa-family",
        :searchbefore => nil,
        :searchfirst => nil,
        :sslcert => [:absent, :absent],
        :sslkey => [:absent, :absent],
        :sticky => "true",
      } )
    end
    it 'parses the fourth publisher properly' do
      expect(described_class.instances[3].instance_variable_get("@property_hash")).to eq( {
        :enable => "true",
        :ensure => :present,
        :mirror => [],
        :name => "solaris",
        :origin => ["file:///media/sol-12_0-119-repo/repo", "http://pkg.oracle.com/solaris/release"],
        :proxy => [:absent, "http://bogus.proxy"],
        :searchafter => "solaris-mirror",
        :searchbefore => nil,
        :searchfirst => nil,
        :sslcert => [:absent, :absent],
        :sslkey => [:absent, :absent],
        :sticky => "true",
      } )
    end
  end

  context ".batchable?" do
    it "true with no proxy, sslcert, sslkey" do
      expect(provider.batchable?).to eq(true)
    end
    [:sslkey, :sslcert].each do |key|
      it "false with #{key}" do
        params[key] << '/path/to/file'
        expect(provider.batchable?).to eq(false)
      end
    end
    it "false with proxy" do
      params[:proxy] << 'http://foo'
      expect(provider.batchable?).to eq(false)
    end
  end
  context ".destroy" do
    it "destroys" do
      described_class.expects(:pkg).with('unset-publisher', params[:name])
      expect(provider.destroy)
    end
  end

  context ".create" do
    before do
      property_hash = {}
    end
    it "simple origin" do
      params[:mirror] = []
      described_class.expects(:pkg).with('set-publisher',
      '-g', *params[:origin],
      '-G', '*', '-M', '*',
      params[:name])
      expect(provider.create)
    end
    it "simple origin + mirror" do
      params[:mirror] = %w[http://mirror]
      described_class.expects(:pkg).with('set-publisher',
      '-g', *params[:origin],
      '-m', *params[:mirror],
      '-G', '*', '-M', '*',
      params[:name])
      expect(provider.create)
    end

    context "with proxy" do
      it "simple" do
        params[:mirror] = []
        params[:proxy] = %w[http://proxy]
        described_class.expects(:pkg).with('set-publisher',
        '--proxy', *params[:proxy],
        '-g', *params[:origin],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "complex" do
        params[:mirror] = %w[http://mirror http://mirror1]
        params[:proxy] = %w[http://proxy http://proxy1 absent]
        # The first invocation
        described_class.expects(:pkg).with('set-publisher',
        '--proxy', params[:proxy][0],
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])

        described_class.expects(:pkg).with('set-publisher',
        '--proxy', params[:proxy][1],
        '-m', params[:mirror][0],
        params[:name])

        described_class.expects(:pkg).with('set-publisher',
        '-m', params[:mirror][1],
        params[:name])

        expect(provider.create)
      end
    end

    context "with sslcert" do
      it "simple" do
        params[:mirror] = []
        params[:sslcert] = %w[/path/to/file]
        described_class.expects(:pkg).with('set-publisher',
        '-c', *params[:sslcert],
        '-g', *params[:origin],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "complex" do
        params[:mirror] = %w[http://mirror http://mirror1]
        params[:sslcert] = %w[/path/to/file absent /path/to/file1]
        # The first invocation
        described_class.expects(:pkg).with('set-publisher',
        '-c', params[:sslcert][0],
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])

        described_class.expects(:pkg).with('set-publisher',
        '-m', params[:mirror][0],
        params[:name])

        described_class.expects(:pkg).with('set-publisher',
        '-c', params[:sslcert][2],
        '-m', params[:mirror][1],
        params[:name])

        expect(provider.create)
      end
    end

    context "with sslkey" do
      it "simple" do
        params[:mirror] = []
        params[:sslkey] = %w[/path/to/file]
        described_class.expects(:pkg).with('set-publisher',
        '-k', *params[:sslkey],
        '-g', *params[:origin],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "complex" do
        params[:mirror] = %w[http://mirror http://mirror1]
        params[:sslkey] = %w[absent /path/to/file /path/to/file1]
        # The first invocation
        described_class.expects(:pkg).with('set-publisher',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])

        described_class.expects(:pkg).with('set-publisher',
        '-k', params[:sslkey][1],
        '-m', params[:mirror][0],
        params[:name])

        described_class.expects(:pkg).with('set-publisher',
        '-k', params[:sslkey][2],
        '-m', params[:mirror][1],
        params[:name])

        expect(provider.create)
      end
    end

    context "with sticky" do
      it "undef" do
        params.delete(:sticky)
        described_class.expects(:pkg).with('set-publisher',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "true" do
        params[:sticky] = :true
        described_class.expects(:pkg).with('set-publisher',
        '--sticky',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "false" do
        params[:sticky] = :false
        described_class.expects(:pkg).with('set-publisher',
        '--non-sticky',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
    end
    context "with searchfirst" do
      it "undef" do
        params.delete(:searchfirst)
        described_class.expects(:pkg).with('set-publisher',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "true" do
        params[:searchfirst] = :true
        described_class.expects(:pkg).with('set-publisher',
        '--search-first',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
    end
    context "with search" do
      before do
        described_class.stubs(:pkg).with(:publisher, "-H", "-F", "tsv").returns File.read(my_fixture('H_F_tsv.txt'))
      end
      it "before" do
        params[:searchbefore] = "solaris"
        described_class.expects(:pkg).with('set-publisher',
        '--search-before', 'solaris',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "after" do
        params[:searchafter] = "solaris"
        described_class.expects(:pkg).with('set-publisher',
        '--search-after', 'solaris',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
    end

    context "with enabled" do
      it "true" do
        params[:enable] = :true
        described_class.expects(:pkg).with('set-publisher',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        expect(provider.create)
      end
      it "false" do
        params[:enable] = :false
        described_class.expects(:pkg).with('set-publisher',
        '-g', params[:origin][0],
        '-G', '*', '-M', '*',
        params[:name])
        described_class.expects(:pkg).with('set-publisher',
        '--disable',
        params[:name])
        expect(provider.create)
      end
    end
    context "mismatched count" do
      [:sslcert, :sslkey].each do |key|
        it key do
          params[key] = %w[/foo /bar /baz]
          expect{provider.create}.to raise_error(Puppet::Error, error_pattern)
        end
      end
      it "proxy" do
        params[:proxy] = %w[http://foo http://bar http://baz]
        expect{provider.create}.to raise_error(Puppet::Error, error_pattern)
      end
    end
  end

  context 'sticky=' do
    it "true" do
      described_class.expects(:pkg).with('set-publisher',
      '--sticky',
      params[:name])
      expect(provider.sticky=:true)
    end
    it "false" do
      described_class.expects(:pkg).with('set-publisher',
      '--non-sticky',
      params[:name])
      expect(provider.sticky=:false)
    end
  end
  context 'enable=' do
    it "true" do
      described_class.expects(:pkg).with('set-publisher',
      '--enable',
      params[:name])
      expect(provider.enable=:true)
    end
    it "false" do
      described_class.expects(:pkg).with('set-publisher',
      '--disable',
      params[:name])
      expect(provider.enable=:false)
    end
  end
  context 'searchfirst=' do
    it "true" do
      described_class.expects(:pkg).with('set-publisher',
      '--search-first',
      params[:name])
      expect(provider.searchfirst=:true)
    end
    it "false" do
      expect(provider.searchfirst=:false)
    end
  end
  context 'sslcert=' do
    it "[:absent]" do
      params[:sslcert] = [:absent]
      described_class.expects(:pkg).with('set-publisher',
      '-c', '',
      '-p', params[:origin][0])
      expect(provider.sslcert=params[:sslcert])
    end
    it "[one-cert]" do
      params[:sslcert] = %w[/path/to/cert]
      described_class.expects(:pkg).with('set-publisher',
      '-c', params[:sslcert][0],
      '-p', params[:origin][0])
      expect(provider.sslcert=params[:sslcert])
    end
    it "[multiple certs]" do
      params[:sslcert] = %w[/path/to/cert1 /path/to/cert2]
      params[:origin] << 'http://origin2'
      (0..1).each do |index|
        described_class.expects(:pkg).with('set-publisher',
        '-c', params[:sslcert][index],
        '-p', params[:origin][index])
      end
      expect(provider.sslcert=params[:sslcert])
    end
  end
  context 'sslkey=' do
    it "[:absent]" do
      params[:sslkey] = [:absent]
      described_class.expects(:pkg).with('set-publisher',
      '-k', '',
      '-p', params[:origin][0])
      expect(provider.sslkey=params[:sslkey])
    end
    it "[one-key]" do
      params[:sslkey] = %w[/path/to/key]
      described_class.expects(:pkg).with('set-publisher',
      '-k', params[:sslkey][0],
      '-p', params[:origin][0])
      expect(provider.sslkey=params[:sslkey])
    end
    it "[multiple keys]" do
      params[:sslkey] = %w[/path/to/key1 /path/to/key2]
      params[:origin] << 'http://origin2'
      (0..1).each do |index|
        described_class.expects(:pkg).with('set-publisher',
        '-k', params[:sslkey][index],
        '-p', params[:origin][index])
      end
      expect(provider.sslkey=params[:sslkey])
    end
  end
  context 'origin=' do
    it ".empty?" do
      params[:origin] = []
      described_class.expects(:pkg).with('set-publisher',
      '-G', '*',
      params[:name])
      expect(provider.origin=params[:origin])
    end
    it "[:absent]" do
      params[:origin] = [:absent]
      described_class.expects(:pkg).with('set-publisher',
      '-G', '*',
      params[:name])
      expect(provider.origin=params[:origin])
    end
    it "[single]" do
      property_hash[:origin] = []
      described_class.expects(:pkg).with('set-publisher',
      '-g', params[:origin][0],
      params[:name])
      expect(provider.origin=params[:origin])
    end
    it "add [multiple origins]" do
      params[:origin] += %w[http://origin2 https://origin3]
        described_class.expects(:pkg).with('set-publisher',
        '-g', params[:origin][-2],
        '-g', params[:origin][-1],
        params[:name])
      expect(provider.origin=params[:origin])
    end
    it "remove [multiple origins]" do
      property_hash[:origin] += %w[http://origin2 https://origin3]
        described_class.expects(:pkg).with('set-publisher',
        '-G', property_hash[:origin][-2],
        '-G', property_hash[:origin][-1],
        params[:name])
      expect(provider.origin=params[:origin])
    end
    it "mixed [multiple origins]" do
      property_hash[:origin] += %w[http://origin2 https://origin3]
      params[:origin] += %w[http://origin4]
        described_class.expects(:pkg).with('set-publisher',
        '-G', property_hash[:origin][-2],
        '-G', property_hash[:origin][-1],
        params[:name])
        described_class.expects(:pkg).with('set-publisher',
        '-g', params[:origin][-1],
        params[:name])
      expect(provider.origin=params[:origin])
    end
  end
  context 'mirror=' do
    it ".empty?" do
      params[:mirror] = []
      described_class.expects(:pkg).with('set-publisher',
      '-M', '*',
      params[:name])
      expect(provider.mirror=params[:mirror])
    end
    it "[:absent]" do
      params[:mirror] = [:absent]
      described_class.expects(:pkg).with('set-publisher',
      '-M', '*',
      params[:name])
      expect(provider.mirror=params[:mirror])
    end
    it "[single]" do
      params[:mirror] = %w[http://mirror1]
      property_hash[:mirror] = []
      described_class.expects(:pkg).with('set-publisher',
      '-m', params[:mirror][0],
      params[:name])
      expect(provider.mirror=params[:mirror])
    end
    it "add [multiple mirrors]" do
      property_hash[:mirror] = %w[http://mirror1]
      params[:mirror] = %w[http://mirror1 http://mirror2 https://mirror3]
        described_class.expects(:pkg).with('set-publisher',
        '-m', params[:mirror][-2],
        '-m', params[:mirror][-1],
        params[:name])
      expect(provider.mirror=params[:mirror])
    end
    it "remove [multiple mirrors]" do
      params[:mirror] = %w[http://mirror1]
      property_hash[:mirror] = %w[http://mirror1 http://mirror2 https://mirror3]
        described_class.expects(:pkg).with('set-publisher',
        '-M', property_hash[:mirror][-2],
        '-M', property_hash[:mirror][-1],
        params[:name])
      expect(provider.mirror=params[:mirror])
    end
    it "mixed [multiple mirrors]" do
      property_hash[:mirror] += %w[http://mirror2 https://mirror3]
      params[:mirror] += %w[http://mirror4]
        described_class.expects(:pkg).with('set-publisher',
        '-M', property_hash[:mirror][-2],
        '-M', property_hash[:mirror][-1],
        params[:name])
        described_class.expects(:pkg).with('set-publisher',
        '-m', params[:mirror][-1],
        params[:name])
      expect(provider.mirror=params[:mirror])
    end
  end
  context 'proxy=' do
    it ":absent" do
      params[:origin] = %w(http://a)
      params[:proxy] = [:absent]
      described_class.expects(:pkg).with('set-publisher',
      '--proxy', '', '-g', params[:origin][0],
      params[:name])
      expect(provider.proxy=params[:proxy]).to eq(params[:proxy])
    end
    it "with value" do
      params[:origin] = %w(http://a http://b)
      params[:mirror] = %w(http://c)
      params[:proxy]  = %w(http://proxy-a http://proxy-b http://proxy-c)
      combined = params[:origin] + params[:mirror]
      (0..1).each do |index|
        described_class.expects(:pkg).with('set-publisher',
        '--proxy', params[:proxy][index],
        '-g', combined[index],
        params[:name])
      end
        described_class.expects(:pkg).with('set-publisher',
        '--proxy', params[:proxy][2],
        '-m', combined[2],
        params[:name])
      expect(provider.proxy=params[:proxy]).to eq(params[:proxy])
    end
  end
  context 'searchbefore=' do
    it "sets a value" do
      described_class.expects(:pkg).with('set-publisher',
      '--search-before', 'foo',
      params[:name])
      expect(provider.searchbefore='foo').to eq('foo')
    end
  end
  context 'searchafter=' do
    it "sets a value" do
      described_class.expects(:pkg).with('set-publisher',
      '--search-after', 'foo',
      params[:name])
      expect(provider.searchafter='foo').to eq('foo')
    end
  end
end

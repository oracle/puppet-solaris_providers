require 'spec_helper'
describe Puppet::Type.type(:pkg_facet).provider(:pkg_facet) do

  let(:resource) { Puppet::Type.type(:pkg_facet).new(
     :name => 'foo',
     :ensure => :present)
  }

  let(:provider) { resource.provider }

  context "responds to" do
  [ :value, :exists?, :create, :destroy ].each do |method|
    it method do is_expected.to respond_to(method) end
  end
  end


  context 'with two facets' do
    before :each do
      described_class.stubs(:pkg).with(:facet, "-H", "-F", "tsv").returns "facet.version-lock.system/foo/bar     True    local\nfacet.version-lock.system/foo2/bar     False    local"
    end

    it 'finds two facets' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'parses the first facet' do
      expect(described_class.instances[0].instance_variable_get("@property_hash")).to eq( {
        :name => 'facet.version-lock.system/foo/bar',
        :ensure   => :present,
        :value  => "true"
      } )
    end

    it 'parses the second facet' do
      expect(described_class.instances[1].instance_variable_get("@property_hash")).to eq( {
        :name => 'facet.version-lock.system/foo2/bar',
        :ensure   => :present,
        :value  => "false"
      } )
    end

  end

end

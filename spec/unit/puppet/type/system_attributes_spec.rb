require 'spec_helper'

describe Puppet::Type.type(:system_attributes) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "/tmp/foo",
      :ensure => :present,
    }
      end

  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { Puppet::Type.type(:system_attributes).new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }

  let(:error_pattern) { /Invalid/ }

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end

  describe "has property" do
    [
      :ensure, :archive, :hidden, :readonly, :system, :appendonly,
      :nodump, :immutable, :av_modified, :av_quarantined, :nounlink, :offline,
      :sparse, :sensitive
    ].each do |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "accepts valid parameters for" do
    [
      :archive, :hidden, :readonly, :system, :appendonly,
      :nodump, :immutable, :av_modified, :av_quarantined, :nounlink, :offline,
      :sparse, :sensitive
    ].each do |prop|
      context prop do
        [:yes,:no].each { |thing|
          it "accepts #{thing} " do
            params[prop] = thing
            expect{resource}.not_to raise_error
          end
        }
      end
    end
  end

  describe "rejects invalid parameters for" do
    [
      :archive, :hidden, :readonly, :system, :appendonly,
      :nodump, :immutable, :av_modified, :av_quarantined, :nounlink, :offline,
      :sparse, :sensitive
    ].each do |prop|
      context prop do
        [:false,:maybe,1].each { |thing|
          it "rejects #{thing} " do
            params[prop] = thing
            expect{resource}.to raise_error(Puppet::Error,error_pattern)
          end
        }
      end
    end
  end # Invalid values


  context "autorequires" do
    context "files" do
      it "does not require file when no matching resource exists" do
        file = Puppet::Type.type(:file).new(:name => "/tmp/bar")
        catalog.add_resource resource
        catalog.add_resource file
        expect(resource.autorequire.count).to eq 0
      end
      it "requires the matching file resource" do
        file = Puppet::Type.type(:file).new(:name => resource[:file])
        catalog.add_resource file
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 1
        expect(reqs[0].source).to eq file
        expect(reqs[0].target).to eq resource
      end
    end
  end
end

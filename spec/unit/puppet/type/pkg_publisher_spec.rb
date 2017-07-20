require 'spec_helper'

describe Puppet::Type.type(:pkg_publisher) do

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
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:error_pattern) { /Invalid value/m }

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end

  describe "has property" do
    [ :ensure, :origin, :enable, :sticky, :searchfirst, :searchafter,
      :searchbefore, :proxy, :sslkey, :sslcert, :mirror
    ].each do |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "parameter" do
    [:ensure].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(present absent).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(online offline).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
      end
    end
    [:origin, :mirror].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(file://mydir/ https://foo/bar http://foo/bar).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(bare_string).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
        it "returns an array for a single value" do
          params[:origin] = "file://mydir"
          expect(resource[:origin]).to eq([params[:origin]])
        end
        it "trims trailing slashes" do
          params[type] = %w(file://trail/ file://notrail)
          expect(resource[type]).to eq(%w(file://trail file://notrail))
        end
      end
    end
    [:enable, :sticky].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(true false) + [true, false].each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(yes no).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
      end
    end
    [:searchfirst].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(true).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(false).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
      end
    end
    [:searchafter, :searchbefore].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(a_string).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
      end
    end
    [:proxy].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(http://foo).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
            it "<undef>" do
              params.delete(type)
              expect { resource }.not_to raise_error
            end
        end
        context "rejects" do
          %w(https://bar).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
      end
    end
    [:sslcert, :sslkey].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(/fully/specified/path).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(~/expanded/path relative/path).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
      end
    end
  end # parameters
  context "autorequire" do
    before do
      params[:sslkey] = "/foo"
      params[:sslcert] = "/bar"
    end
    context "files" do
      it "does not require file when no matching resource exists" do
        file = Puppet::Type.type(:file).new(:name => "/baz")
        catalog.add_resource resource
        catalog.add_resource file
        expect(resource.autorequire.count).to eq 0
      end
      it "requires the matching file resource" do
        sslkey = Puppet::Type.type(:file).new(:name => params[:sslkey])
        catalog.add_resource sslkey
        sslcert = Puppet::Type.type(:file).new(:name => params[:sslcert])
        catalog.add_resource sslcert
        catalog.add_resource resource
        reqs = resource.autorequire
        expect(reqs.count).to eq 2
        expect(reqs[0].source).to eq sslkey
        expect(reqs[0].target).to eq resource
        expect(reqs[1].source).to eq sslcert
        expect(reqs[1].target).to eq resource
      end
      it "does not fail if sslcert and key are nil" do
        params.delete(:sslkey)
        params.delete(:sslcert)
        file = Puppet::Type.type(:file).new(:name => "/baz")
        catalog.add_resource resource
        catalog.add_resource file
        expect(resource.autorequire.count).to eq 0
      end
    end
  end
end

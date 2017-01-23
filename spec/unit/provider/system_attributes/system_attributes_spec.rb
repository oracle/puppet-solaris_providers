require 'spec_helper'

describe Puppet::Type.type(:system_attributes).provider(:system_attributes) do

  let(:params) do
    {
      :name => "/root/foo",
      :ensure => 'present',
    }
  end

  let(:resource) { Puppet::Type.type(:system_attributes).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/bin/chmod').returns true
    FileTest.stubs(:executable?).with('/usr/bin/chmod').returns true
    FileTest.stubs(:file?).with('/usr/bin/ls').returns true
    FileTest.stubs(:executable?).with('/usr/bin/ls').returns true
    FileTest.stubs(:exists?).with('/root/foo').returns true
  end

  context "responds to" do
    [ :exists?, :create, :destroy, :flush ].each do |method|
      it method do is_expected.to respond_to(method) end
    end
  [:archive, :av_modified, :av_quarantined,
    :hidden, :readonly, :system, :appendonly,
    :nodump, :immutable, :nounlink, :offline,
    :sparse, :sensitive].each do |method|
      it method do is_expected.to respond_to(method) end
      it "#{method}=" do is_expected.to respond_to(method) end
    end
  end

  describe "#instances" do
    it "has 0 instances" do
      expect(described_class.instances.size).to eq(0)
    end
  end

  describe ".exists?" do
    it "returns false for non-existent file" do
      resource[:file] = "/bogus/bogus123"
      expect(provider.exists?).to eq false
    end
    it "returns true for a file" do
      described_class.expects(:ls).with("-/c","/root/foo").returns File.read(my_fixture('ls_c_root_foo.txt'))
      expect(provider.exists?).to eq true
    end
    it "returns false for an existing file with no attributes when :ensure == :absent" do
      params[:ensure] = :absent
      described_class.expects(:ls).with("-/c","/root/foo").returns 'foo\n{------------}\n'
      expect(provider.exists?).to eq false
    end
  end

  describe "attribute parsing" do
    it "finds the expected attributes" do
      described_class.expects(:ls).with("-/c","/root/foo").returns File.read(my_fixture('ls_c_root_foo.txt'))
      expect(provider.attributes).to eq(
        {:archive=>"yes", :hidden=>"no", :readonly=>"no", :system=>"no",
         :appendonly=>"no", :nodump=>"no", :immutable=>"no",
         :av_modified=>"yes", :av_quarantined=>"no", :nounlink=>"no",
         :offline=>"no", :sparse=>"no", :sensitive=>"no"}
      )
    end
    {
      :archive=>'A',
      :hidden=>'H',
      :readonly=>'R',
      :system=>'S',
      :appendonly=>'a',
      :nodump=>'d',
      :immutable=>'i',
      :av_modified=>'m',
      :av_quarantined=>'q',
      :nounlink=>'u',
      :offline=>'O',
      :sparse=>'s',
      :sensitive=>'T'
    }.each_pair { |key,value|
      it "maps #{value} to #{key}" do
        described_class.expects(:ls).with("-/c","/root/foo").returns "foo\n{#{value}}\n"
        _attr = provider.attributes
        expect(_attr[key]).to eq('yes')
        expect(_attr.values.count('no')).to eq(12)
      end
    }
  end

  describe "attribute setting" do
    context "default" do
      before(:each) do
        params[:strict] = 'false'
      end
      {
        :hidden=>'H',
        :readonly=>'R',
        :system=>'S',
        :appendonly=>'a',
        :nodump=>'d',
        :immutable=>'i',
        :nounlink=>'u',
        :offline=>'O',
        :sparse=>'s',
        :sensitive=>'T'
      }.each_pair { |key,value|
        it "caches #{key} change" do
          provider.send("#{key}=",'yes')
          provider.send("#{key}=",'no')
          _flush = provider.instance_variable_get(:@property_flush)
          expect(_flush[:no].include?(value))
          expect(_flush[:yes].include?(value))
        end
      }

      # Ignorable
      {
        :archive=>'A',
        :av_modified=>'m',
        :av_quarantined=>'q',
      }.each_pair { |key,value|
        it "caches ignorable #{key} change" do
          provider.send("#{key}=",'yes')
          provider.send("#{key}=",'no')
          _flush = provider.instance_variable_get(:@property_flush)
          expect(_flush[:no].include?(value)).to eq true
          expect(_flush[:yes].include?(value)).to eq true
        end
      }
    end
    context "strict" do
      before(:each) do
        params[:strict] = 'true'
      end
      # Ignorable
      {
        :archive=>'A',
        :av_modified=>'m',
        :av_quarantined=>'q',
      }.each_pair { |key,value|
        context "#{key}" do
          before(:each) do
            described_class.expects(:ls).returns "foo\n{#{value}}\n"
          end
          # There is almost certainly a more concise way to
          # do the following but params needs to be set prior
          # to setting the instance variable

          it "changes when specified in the resource" do
            provider.send("#{key}=",'yes')
            provider.send("#{key}=",'no')
            provider.instance_variable_set(
              :@property_hash, provider.attributes
            )
            _flush = provider.instance_variable_get(:@property_flush)
            expect(_flush[:no].include?(value)).to eq true
            expect(_flush[:yes].include?(value)).to eq true
          end
          it "maintains existing when absent in the resource (ignore == true)" do
            params["ignore_#{key}".intern] = 'true'
            described_class.expects(:ls).returns "foo\n{#{value}}\n"
            described_class.expects(:chmod).returns
            provider.instance_variable_set(
              :@property_hash, provider.attributes
            )
            provider.flush
            _flush = provider.instance_variable_get(:@property_flush)
            expect(_flush[:no].include?(value)).to eq false
            expect(_flush[:yes].include?(value)).to eq true
          end
          it "changes existing when absent in the resource (ignore == false)" do
            params["ignore_#{key}".intern] = 'false'
            described_class.expects(:ls).returns "foo\n{#{value}}\n"
            described_class.expects(:chmod).returns
            provider.instance_variable_set(
              :@property_hash, provider.attributes
            )
            provider.flush
            _flush = provider.instance_variable_get(:@property_flush)
            expect(_flush[:no].include?(value)).to eq true
            expect(_flush[:yes].include?(value)).to eq false
          end
        end
      }
    end

    describe ".destroy" do
      it "removes attributes" do
        described_class.expects(:chmod).with(
          "S=c", resource[:file]
        )
        expect(provider.destroy).to eq nil
      end
    end
  end
end

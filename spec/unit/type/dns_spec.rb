require 'spec_helper'

describe Puppet::Type.type(:dns) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "current",
      :domain => 'foo.com',
      :nameserver => '127.0.0.1'
    }
      end

  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:error_pattern) { / invalid/ }

  before do
    @class = described_class
    @profile_name = "current"
  end

  it "should have :name as its keyattribute" do
    expect( @class.key_attributes).to be == [:name]
  end

  describe "when validating attributes" do
    [:nameserver, :domain, :search, :sortlist, :options
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "when validating values" do
    describe "for nameserver" do
      error_pattern = /nameserver.*invalid/m

      def validate(hostname)
         @class.new(:name => @profile_name, :nameserver => hostname)
      end

      it "should reject hostnames greater than 255 characters" do
        expect { validate "aaaa." * 51 << "a"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostnames with double periods" do
        expect { validate "double..isbad.com"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostname segments larger than 63 characters" do
        expect { validate "my." << "a" * 64 << ".com"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostname segments not starting with a letter/digit" do
        expect { validate "my._invalid.hostname"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject hostname segments ending with a dash" do
        expect { validate "my.invalid-.hostname"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      ["192.168.1.256","192.168.1."].each do |ip|
        it "should reject invalid IP addresses #{ip}" do
          expect { validate ip
          }.to raise_error(Puppet::Error, error_pattern)
        end
      end

      it "should accept an array of valid values" do
        expect { validate [ "1.2.3.4", "2.3.4.5" ] }.
             not_to raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name,
                            :nameserver => "1.2.3.4")
        expect(mytype.property("nameserver").value).to be_an(Array)
      end
    end  # nameserver


    describe "for domain" do

      def validate(domain_val)
         @class.new(:name => @profile_name, :domain => domain_val)
      end

      it "should accept a value" do
        expect { validate "foo.com" }.
             not_to raise_error
      end
    end  # domain


    describe "for search" do
      def validate(search_val)
         @class.new(:name => @profile_name, :search => search_val)
      end

      it "should accept an array of valid values" do
        expect { validate [ "foo", "bar" ] }.
             not_to raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name,
                            :search => "foo")
        expect(mytype.property("search").value).to be_an(Array)
      end
    end  # search


    describe "for sortlist" do
      error_pattern = /sortlist.*invalid/m

      def validate(slist)
         @class.new(:name => @profile_name, :sortlist => slist)
      end

      it "should reject invalid IP addresses" do
        expect { validate "192.168.1.256"
             }.to raise_error(Puppet::Error, error_pattern)
        expect { validate "192.168.1."
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should accept an array of valid values" do
        expect { validate [ "1.2.3.4/5", "2.3.4.5/6" ] }.
             not_to raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name,
                            :sortlist => "1.2.3.4/5")
        expect(mytype.property("sortlist").value).to be_an(Array)
      end
    end  # sortlist

    describe "for options" do
      error_pattern = /option.*invalid/m

      def validate(op)
         @class.new(:name => @profile_name, :options => op)
      end

      it "should reject options with too many fields" do
        expect { validate "retry:1:2"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      it "should reject invalid options" do
        expect { validate "foo"
             }.to raise_error(Puppet::Error, error_pattern)
        expect { validate "bar:1"
             }.to raise_error(Puppet::Error, error_pattern)
      end

      ["debug", "rotate", "no-check-names", "inet6"
      ].each do |op|
        it "should accept #{op} option with no arguments" do
          expect { validate "#{op}" }.
               not_to raise_error
        end  # arg

        it "should reject #{op} with one argument" do
          expect { validate "#{op}:1"
               }.to raise_error(Puppet::Error, error_pattern)
        end
      end  # simple_opts

      ["ndots", "timeout", "retrans", "attempts", "retry"
      ].each do |op|
        it "should accept #{op} option with one argument" do
          expect { validate "#{op}:1" }.
               not_to raise_error
        end  # opt arg

        it "should reject #{op} with no arguments" do
          expect { validate "#{op}"
               }.to raise_error(Puppet::Error, error_pattern)
        end
      end  # arg_opts

     it "should reject arguments that won't cast to integer" do
        expect { validate "retry:a"
             }.to raise_error(Puppet::Error, error_pattern)
     end

     it "should allow an empty value to clear" do
          expect { validate "" }.not_to raise_error
     end

    end  # options

  end # validating values

  describe "parameter" do
    [:nameserver].each { |type|
      context "accepts #{type}" do
        # A bunch of examples AND a multi-value string
        %w(1.2.3.4 10.10.10.1 fe80::3e07:54ff:fe53:c704 [fe80::3e07:54ff:fe53:c704]) +
          [ "1.2.3.4 2.3.4.5" ].each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(1.2.3.256 fe80::3e07::c704).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:domain].each { |type|
      context "accepts #{type}" do
        %w(foo.com foo.bar.com).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(foo..com, "this.is;echo bad").each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:search].each { |type|
      context "accepts #{type}" do
        %w(foo.com foo.bar.com).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(foo..com ).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:sortlist].each { |type|
      context "accepts #{type}" do
        %w(1.2.3.4 1.2.3.4/255.255.255.0).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(1.2.3.256 1.2.3.4/768).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
    [:options].each { |type|
      context "accepts #{type}" do
        (%w(debug timeout:3)+[:absent]).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(fail timeout: timeout:2:3).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
  end
end

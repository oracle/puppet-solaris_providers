require 'spec_helper'

describe Puppet::Type.type(:pkg_publisher) do

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect( @class.key_attributes).to be == [:name]
  end

  describe "when validating attributes" do
    [ :ensure, :origin, :enable, :sticky, :searchfirst, :searchafter,
      :searchbefore, :proxy, :sslkey, :sslcert, :mirror
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to be == :property
      end
    end
  end

  describe "when validating values" do

    describe "for ensure" do
      error_pattern = /Invalid value/m
      def validate(ens)
         @class.new(:name => @profile_name, :ensure => ens)
      end

      [ "present", "absent" ].each do |newval|
        it "should accept a value of #{newval}" do
          expect { validate(newval) }.not_to raise_error
        end
      end

      it "should reject invalid values" do
        expect { validate "foo" }.to raise_error(Puppet::Error, error_pattern)
      end
    end  # ensure

    describe "for origin" do
      def validate(orig)
         @class.new(:name => @profile_name, :origin => orig)
      end

      it "should accept a value" do
        expect { validate "[ 'file://mydir/' ]"
             }.not_to raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name,
                            :origin => "file://mydir")
        expect(mytype.property("origin").value).to be_an(Array)
      end

      it "should trim trailing slashes from file:// URI values" do
        mytype = @class.new(:name => @profile_name,
                            :origin => ['file://trail/', 'file://notrail'])
        expect(mytype.property("origin").value).to be ==
                                       ['file://trail', 'file://notrail']
      end
    end  # origin

    describe "for enable" do
      error_pattern = /enable.*Invalid/m

      def validate(enab)
         @class.new(:name => @profile_name, :enable => enab)
      end

      [ "true", "false" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # enable

    describe "for sticky" do
      error_pattern = /sticky.*Invalid/m

      def validate(stickyval)
         @class.new(:name => @profile_name, :sticky => stickyval)
      end

      [ "true", "false" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # sticky

    describe "for searchfirst" do
      error_pattern = /searchfirst.*Invalid/m

      def validate(sf)
         @class.new(:name => @profile_name, :searchfirst => sf)
      end

      [ "true" ].each do |follow_val|
        it "should accept a value of #{follow_val}" do
          expect { validate(follow_val) }.not_to raise_error
        end
      end

      it "should reject an invalid value" do
        expect { validate("foobar") }.to raise_error(Puppet::ResourceError,
                                                       error_pattern)
      end
    end  # searchfirst

    describe "for searchafter" do
      def validate(sa)
         @class.new(:name => @profile_name, :searchafter => sa)
      end

      it "should accept a value" do
        expect { validate "foo" }.not_to raise_error
      end
    end  # searchafter

    describe "for searchbefore" do
      def validate(sb)
         @class.new(:name => @profile_name, :searchbefore => sb)
      end

      it "should accept a value" do
        expect { validate "foo" }.not_to raise_error
      end
    end  # searchbefore

    describe "for proxy" do
      def validate(pval)
         @class.new(:name => @profile_name, :proxy => pval,
         :origin => "http://bar")
      end

      it "should accept a value" do
        expect { validate "http://foo" }.not_to raise_error
      end
    end  # proxy

    describe "for sslkey" do
      def validate(skey)
         @class.new(:name => @profile_name, :sslkey => skey,
         :origin => "http://bar")
      end

      it "should accept a value" do
        expect { validate "/foo" }.not_to raise_error
      end
    end  # sslkey

    describe "for sslcert" do
      def validate(scert)
         @class.new(:name => @profile_name, :sslcert => scert,
         :origin => "http://bar")
      end

      it "should accept a value" do
        expect { validate "/foo" }.not_to raise_error
      end
    end  # sslcert

    describe "for mirror" do
      def validate(mir)
         @class.new(:name => @profile_name, :mirror => mir)
      end

      it "should accept a value" do
        expect { validate "[ 'file://mydir/' ]"
             }.not_to raise_error
      end

      it "should return an array for a single value" do
        mytype = @class.new(:name => @profile_name,
                            :mirror => "file://mydir")
        expect(mytype.property("mirror").value).to be_an(Array)
      end

      it "should trim trailing slashes from file:// URI values" do
        mytype = @class.new(:name => @profile_name,
                            :mirror => ['file://trail/', 'file://notrail'])
        expect(mytype.property("mirror").value).to be ==
                                       ['file://trail', 'file://notrail']
      end
    end  # mirror

  end # validating values
end

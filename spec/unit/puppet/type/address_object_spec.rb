require 'spec_helper'

describe Puppet::Type.type(:address_object) do

  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "net10/v4",
      :ensure => :present,
    }
  end
  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:error_pattern) { /Invalid/ }

  before do
    @class = described_class
    @profile_name = "rspec profile"
  end

  it "should have :name as its keyattribute" do
    expect(@class.key_attributes).to eq([:name])
  end

  describe "has property" do
    [ :address_type, :enable, :address, :remote_address, :down, :seconds,
      :hostname, :interface_id, :remote_interface_id, :stateful, :stateless
    ].each do |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    end
  end # validating properties

  describe "when validating parameters" do
    [ :name, :temporary
    ].each do |prop|
      it "should have a #{prop} property" do
        expect(@class.attrtype(prop)).to eq(:param)
      end
    end
  end # validating properties

  describe "parameter" do
    {
      :ensure => {
        :accepts => [ "present", "absent" ],
        :rejects => [ "foo" ],
      },
      :temporary => {
        :accepts => [ "true", "false" ],
        :rejects => [ "yes", "no" ],
      },
      :stateful => {
        :accepts => %w(yes no),
        :rejects => %w(true false foo),
      },
      :stateless => {
        :accepts => %w(yes no),
        :rejects => %w(true false foo),
      },
    }.each_pair { |target_param,cond|
      context "#{target_param}" do
        context "accepts" do
          cond[:accepts].each do |thing|
            it thing.inspect do
              params[target_param] = thing
              expect { resource }.not_to raise_error
            end
          end
        end # Accepts
        context "rejects" do
          cond[:rejects].each do |thing|
            it thing.inspect do
              params[target_param] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end # Rejects
      end
    }

    describe "address_type" do
      context "implied" do
        (
          [
            [:address,'1.2.3.4'],
            [:remote_address,'foo'],
            [:down,'true']].product(
            [[:seconds,5],[:hostname,'bar']] +
            [
              [:interface_id,'::1a:2b:3c:4d'],
              [:remote_interface_id,'::1a:2b:3c:4d']
            ]
          )
        ).each do |a|
          it "rejects :#{a[0][0]} and :#{a[1][0]}" do
            params[a[0][0]] = a[0][1]
            params[a[1][0]] = a[1][1]
            expect { resource }.to raise_error(Puppet::ResourceError,
                                               %r(incompatible property combination))
          end
        end
        (
          [
            [:address,'1.2.3.4'],
            [:remote_address,'foo'],
            [:down,'true']
          ].permutation(2).to_a +
          [
            [:seconds,5],[:hostname,'bar']].permutation(2).to_a +
          [
            [:interface_id,'::1a:2b:3c:4d'],
            [:remote_interface_id,'::1a:2b:3c:4d']
          ].permutation(2).to_a
        ).each do |a|
          it "accepts :#{a[0][0]} and :#{a[1][0]}" do
            params[a[0][0]] = a[0][1]
            params[a[1][0]] = a[1][1]
            expect { resource }.not_to raise_error
          end
        end
        [[[:address,'1.2.3.4'],[:remote_address,'foo'],[:down,'true']]].each do |a|
          it "accepts all of :#{a[0][0]}, :#{a[1][0]}, :#{a[2][0]}" do
            params[a[0][0]] = a[0][1]
            params[a[1][0]] = a[1][1]
            params[a[2][0]] = a[2][1]
            expect { resource }.not_to raise_error
          end
        end
      end

      context "static" do
        before (:each) { params[:address_type] = :static }
        {
          :address => {
            :accepts => ["foo","bar.com","1.2.3.4"],
            :rejects => ["foo..bar","1.2.3.256"],
          },
          :remote_address => {
            :accepts => ["foo","bar.com","1.2.3.4"],
            :rejects => ["foo..bar","1.2.3.256"],
          },
          :down => {
            :accepts => ["true","false"],
            :rejects => [],
          },
          :seconds => {
            :accepts => [],
            :rejects => [ "5", 10 ]
          },
          :hostname => {
            :accepts => [],
            :rejects => [ "foo.bar" ]
          },
          :interface_id => {
            :accepts => [],
            :rejects => [ "::1a:2b:3c:4d" ]
          },
          :remote_interface_id => {
            :accepts => [],
            :rejects => [ "::1a:2b:3c:4d" ] },
          :routername => {
            :accepts => [],
            :rejects => [ "1.2.3.256" ],
          },
        }.each_pair { |target_param,cond|
          context "#{target_param}" do
            context "accepts" do
              cond[:accepts].each do |thing|
                it thing.inspect do
                  params[target_param] = thing
                  expect { resource }.not_to raise_error
                end
              end
            end # Accepts
            context "rejects" do
              cond[:rejects].each do |thing|
                it thing.inspect do
                  error_pattern = %r(is invalid|cannot specify)
                  params[target_param] = thing
                  expect { resource }.to raise_error(Puppet::Error, error_pattern)
                end
              end
            end # Rejects
          end
        }
      end # end static

      context "vrrp" do
        before (:each) { params[:address_type] = :vrrp }
        {
          :routername => {
            :accepts => ["foo.com","2.3.4.5"],
            :rejects => [ "1.2.3.256" ],
          },
          :address => {
            :accepts => [ "1.2.3.4"],
            :rejects => [ "1.2.3.256" ],
          },
          :remote_address => {
            :accepts => [],
            :rejects => [ "1.2.3.4" ],
          },
          :down => {
            :accepts => [],
            :rejects => [ "true", "false" ],
          },
          :seconds => {
            :accepts => [],
            :rejects => [5,"10","forever"],
          },
          :hostname => {
            :accepts => [],
            :rejects => ["foo.com"],
          },
          :interface_id => {
            :accepts => [],
            :rejects => ["::1a:2b:3c:4d"]
          },
          :remote_interface_id => {
            :accepts => [],
            :rejects => ["::1a:2b:3c:4d"]
          },
        }.each_pair { |target_param,cond|
          context "#{target_param}" do
            context "accepts" do
              cond[:accepts].each do |thing|
                it thing.inspect do
                  params[target_param] = thing
                  expect { resource }.not_to raise_error
                end
              end
            end # Accepts
            context "rejects" do
              cond[:rejects].each do |thing|
                it thing.inspect do
                  error_pattern = %r(is invalid|cannot specify)
                  params[target_param] = thing
                  expect { resource }.to raise_error(Puppet::Error, error_pattern)
                end
              end
            end # Rejects
          end
        }
      end # End vrrp

      context "dhcp" do
        before (:each) { params[:address_type] = :dhcp }
        {
          :address => {
            :accepts => [],
            :rejects => [ "1.2.3.4" ],
          },
          :remote_address => {
            :accepts => [],
            :rejects => [ "1.2.3.4" ],
          },
          :down => {
            :accepts => [],
            :rejects => [ "true", "false" ],
          },
          :seconds => {
            :accepts => [5,"10","forever"],
            :rejects => [],
          },
          :hostname => {
            :accepts => ["foo"],
            :rejects => ["foo..com"],
          },
          :interface_id => {
            :accepts => [],
            :rejects => ["::1a:2b:3c:4d"]
          },
          :remote_interface_id => {
            :accepts => [],
            :rejects => ["::1a:2b:3c:4d"]
          },
          :routername => {
            :accepts => [],
            :rejects => [ "1.2.3.256" ],
          },
        }.each_pair { |target_param,cond|
          context "#{target_param}" do
            context "accepts" do
              cond[:accepts].each do |thing|
                it thing.inspect do
                  params[target_param] = thing
                  expect { resource }.not_to raise_error
                end
              end
            end # Accepts
            context "rejects" do
              cond[:rejects].each do |thing|
                it thing.inspect do
                  error_pattern = %r(is invalid|cannot specify)
                  params[target_param] = thing
                  expect { resource }.to raise_error(Puppet::Error, error_pattern)
                end
              end
            end # Rejects
          end
        }
      end # End dhcp
      context "addrconf" do
        before (:each) { params[:address_type] = :addrconf }
        {
          :address => {
            :accepts => [],
            :rejects => [ "1.2.3.4" ],
          },
          :remote_address => {
            :accepts => [],
            :rejects => [ "1.2.3.4" ],
          },
          :down => {
            :accepts => [],
            :rejects => [ "true", "false" ],
          },
          :seconds => {
            :accepts => [],
            :rejects => [5,"10","forever"],
          },
          :hostname => {
            :accepts => [],
            :rejects => ["foo..com"],
          },
          :interface_id => {
            :accepts => ["::1a:2b:3c:4d"],
            :rejects => [],
          },
          :remote_interface_id => {
            :accepts => ["::1a:2b:3c:4d"],
            :rejects => [],
          },
          :routername => {
            :accepts => [],
            :rejects => [ "1.2.3.256" ],
          },
        }.each_pair { |target_param,cond|
          context "#{target_param}" do
            context "accepts" do
              cond[:accepts].each do |thing|
                it thing.inspect do
                  params[target_param] = thing
                  expect { resource }.not_to raise_error
                end
              end
            end # Accepts
            context "rejects" do
              cond[:rejects].each do |thing|
                it thing.inspect do
                  error_pattern = %r(is invalid|cannot specify)
                  params[target_param] = thing
                  expect { resource }.to raise_error(Puppet::Error, error_pattern)
                end
              end
            end # Rejects
          end
        }
      end
      [:from_gz, :inherited].each { |ctxt|
        context "#{ctxt}" do
          before (:each) { params[:address_type] = ctxt }
          {
            :address => {
              :accepts => [],
              :rejects => [ "1.2.3.4" ],
            },
            :remote_address => {
              :accepts => [],
              :rejects => [ "1.2.3.4" ],
            },
            :down => {
              :accepts => [],
              :rejects => [ "true", "false" ],
            },
            :seconds => {
              :accepts => [],
              :rejects => [5,"10","forever"],
            },
            :hostname => {
              :accepts => [],
              :rejects => ["foo..com"],
            },
            :interface_id => {
              :accepts => [],
              :rejects => ["::1a:2b:3c:4d"],
            },
            :remote_interface_id => {
              :accepts => [],
              :rejects => ["::1a:2b:3c:4d"],
            },
            :routername => {
              :accepts => [],
              :rejects => [ "1.2.3.256" ],
            },
          }.each_pair { |target_param,cond|
            context "#{target_param}" do
              context "accepts" do
                cond[:accepts].each do |thing|
                  it thing.inspect do
                    params[target_param] = thing
                    expect { resource }.not_to raise_error
                  end
                end
              end # Accepts
              context "rejects" do
                cond[:rejects].each do |thing|
                  it thing.inspect do
                    error_pattern = %r(is invalid|cannot specify)
                    params[target_param] = thing
                    expect { resource }.to raise_error(Puppet::Error, error_pattern)
                  end
                end
              end # Rejects
            end
          }
        end
      }

    end  # address_type

    describe "enable" do
      error_pattern = /cannot specify/m
      [ "true","false" ].each do |enable|
        context "temporary=true" do
          before(:each) { params[:temporary] = true }
          it "rejects enable=#{enable}" do
            params[:enable] = enable
            expect{ resource }.to raise_error(Puppet::ResourceError,
                                              error_pattern)
          end
        end
        context "temporary=false" do
          before(:each) { params[:temporary] = false }
          it "accepts enable=#{enable}" do
            expect { resource }.not_to raise_error
          end
        end

        it "rejects invalid values" do
          params[:enable] = "foobar"
          expect { resource }.to raise_error(Puppet::ResourceError,
                                             /Invalid value/)
        end
      end
    end  # enable
  end # validating values
end

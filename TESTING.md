# Tips, Tricks, Lessons Learned, and Style Guide...Oh My

We will cover some of the major stumbling blocks found while getting started
writing unit tests for the oracle-solaris_provider.

# Style
* Rspec 3.4
  * Relish docs (below) provide more complete end-to-end usage examples
  * [Core](https://relishapp.com/rspec/rspec-core/v/3-4/docs)
  * [Expectations](https://relishapp.com/rspec/rspec-expectations/v/3-4/docs)
  * [Mocks](https://relishapp.com/rspec/rspec-mocks/v/3-4/docs)
* [Better Specs](http://betterspecs.org/)
* [Rspec-puppet](http://rspec-puppet.com/)
  * Rspec puppet is focused on manifest testing we are not currently delivering
    manifests in any meaningful way.
  * Documentation for rspec-puppet should be ignored for type and provider
    testing.
* Highlights
  * `expect` not `should`
  * third person present tense descriptions
    * bad: `it 'should not do thing'`
    * good: `it 'does not do thing'`
  * Prefer references not direct invocations
    * `described_class` vs `Puppet::Type.type(:my_type)`
    * `resource` vs `described_class.new`
  * Prefer fixtures for validating provider parsing vs inline data

**NOTE:** All Spec files must end in `_spec.rb` to be executed automatically
by rspec

## Major Test Types
Puppet uses two types of spec testing acceptance and unit.
* acceptance
  * Acceptance testing uses [Beaker](https://github.com/puppetlabs/beaker)
  * we will not be covering beaker at this time
* unit
  * Testing is performed locally via rspec / rake spec and remotely via
    Travis-CI
  * Tests must pass and be deemed sufficient before pull requests will be
    accepted by puppet
  * Coverage must be sufficient for puppet modules to be **Puppet Approved**
    or **Puppet Supported**
  * Our goal for is a minimum of **Puppet Approved**
  * Two types of related coverage: Type and Provider

## Unit Testing
Development process for a new Type and Provider:
Support for ilb is broken down into four types
* ilb_server
* ilb_servergroup
* ilb_healthcheck
* ilb_rule


We will be focusing on ilb_rule files are referenced directly by commit
on github.

### Type Development

I use something somewhat close to Test-Driven Development (TDD) or
Red-Green-Refactor. Sometimes I write the type specs first sometimes I write
the type first.

1. Using a combination of documentation, man pages, and command execution if
  available; properties and parameters are determined.
  1. [ilb docs](https://docs.oracle.com/cd/E23824_01/html/821-1453/gijjm.html)
  1. [ilb(1M)](http://docs.oracle.com/cd/E23824_01/html/821-1462/ilbadm-1m.html)
  1. [command output (fixture)](https://github.com/shawnferry/puppet-solaris_providers/blob/2ce743c715c209d9a87c038e4f85146abf6c9ee9/spec/fixtures/unit/provider/ilb_rule/ilb_rule/show-rule_f.txt)
1. Write the spec file
1. Run the specs, see that they fail (Red)
1. Write the type to pass the tests (Green)
1. Add the tests you missed and cleanup (Refactor)

#### Start with boilerplate-ish code
We will always start with something like this. Change the type
```ruby
#!/usr/bin/env rspec
require 'spec_helper'

describe Puppet::Type.type(:ilb_rule) do
```

Set default parameters valid for basic testing
```ruby
  # Modify params inline to tests to change the resource
  # before it is generated
  let(:params) do
    {
      :name => "rule1",
      :ensure => :present,
      :vip => '10.10.10.1',
      :protocol => 'tcp',
      :port => '80',
      :persistent => 'false',
      :lbalg => 'hash_ip',
      :topo_type => 'dsr',
      :servergroup => 'sg1',
      :hc_name => 'hc1',
      :hc_port => 'any'
    }
      end
```

This can generally be left identical in all spec files.
```ruby
  # Modify the resource inline to tests when you modeling the
  # behavior of the generated resource
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }

  let(:error_pattern) { /Invalid/ }

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to be == [:name]
  end
```

#### Enumerate properties
Array syntax evaluation reduces duplicate code.
```ruby
  describe "has property" do
    [
      :vip, :port, :protocol, # Incoming
      :lbalg, :topo_type, :proxy_src, :servergroup, # Handling Method
      :hc_name, :hc_port, # Healthcheck
      :conn_drain, :nat_timeout, :persist_timeout # Timers
    ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to be == :property
      end
    }
    end
```

#### Input Validation for each property and parameter
This syntax is a little longer than some methods but it is generally applicable
to most cases, fairly easy to read, and requires minimal modification across
items.

Use context to clarify test instead of changing variable names for simple
cases. You can define simple.

```ruby
  describe "parameter" do
    [:vip].each { |type|
      context "accepts #{type}" do
        %w(1.2.3.4 10.10.10.1 fe80::3e07:54ff:fe53:c704 [fe80::3e07:54ff:fe53:c704]).each do |thing|
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
    [:port].each { |type|
      context "accepts #{type}" do
        %w(1 80 443 https 80-90).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(-1 65536 -1-80 80-65536).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
#... more parameters elided ...
   # All these parameters have the same input values
   [:conn_drain, :nat_timeout, :persist_timeout].each { |type|
      context "accepts #{type}" do
        %w(0 20 100).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects #{type}" do
        %w(1.1 default -1).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
    }
  end
```

### Provider Development

1. A system capable of running ilb is found
  1. A simple manual configuration is deployed
  1. command output is collected into fixtures

#### Start with boilerplate code set type and provider `Puppet::Type.type(:my_type).provider(:my_provider)`
```ruby
#!/usr/bin/env ruby
require 'spec_helper'
describe Puppet::Type.type(:ilb_rule).provider(:ilb_rule) do

  let(:params) do
    {
      :name=>"nat1", :ensure=>:present,
      :servergroup=>"sg10", :persistent=>"/24", :enabled=>:true,
      :vip=>"81.0.0.10", :port=>"5000-5009", :protocol=>:tcp,
      :lbalg=>"roundrobin", :topo_type=>:nat,
      :proxy_src=>"60.0.0.101-60.0.0.104", :hc_name=>"hc1", :hc_port=>:any,
      :conn_drain=>"180", :nat_timeout=>"180", :persist_timeout=>"180"
    }
  end
  let(:resource) { Puppet::Type.type(:ilb_rule).new(params) }
  let(:provider) { described_class.new(resource) }

  before(:each) do
    FileTest.stubs(:file?).with('/usr/sbin/ilbadm').returns true
    FileTest.stubs(:executable?).with('/usr/sbin/ilbadm').returns true
  end
```
1. Set appropriate default params for testing
1. Enumerate commands which are used in the provider

#### Enumerate methods (most parameters and properties)
```ruby
  describe "responds to" do
    [:exists?, :create, :destroy, :enabled, :enabled=].each { |method|
      it { is_expected.to respond_to(method) }
    }
  end
```
* Prefer array evaluation to reduce duplicate
* This example is atypical as many methods are not tested here

#### Output parsing
Almost always this will be testing the instances method. For some providers
when instances isn't viable you will need to test a different method or methods.

Mock the data collection commana(s)d with output. See the fixture file
```ruby
  describe "#instances" do
    described_class.expects(:ilbadm).with(
      'show-rule', '-f').returns File.read(
        my_fixture('show-rule_f.txt'))
```

Call the instances method and map the parameters into an array of hashes.
`described_class.instances` could be called individually but would execute
the parsing step each time.
```ruby
      instances = described_class.instances.map { |p|
        hsh={}
        [
          :name, :ensure,
          :persistent, :enabled,
          :vip, :port, :protocol,
          :lbalg, :topo_type, :proxy_src,
          :hc_name, :hc_port,
          :conn_drain, :nat_timeout, :persist_timeout
        ].each { |fld|
          hsh[fld] = p.get(fld)
        }
        hsh
      }
```

Evaluate the results for correctness. Count of results will catch additions
or removals from your fixture.
```ruby
      it "has five(5) results" do
        expect(instances.size).to eq(5)
      end
```

Test as many of the results as needed to cover the configuration.
* instance[0] uses persistence and timeouts
* instance[2] uses IPv6 which has different parsing requirements
* instance[-2] uses IPv4 which is the expected common case
```ruby
      it "first instance is nat1" do
        expect(instances[0]).to eq(
          {:name=>"nat1", :ensure=>:present, :persistent=>"/24",
           :enabled=>:true, :vip=>"81.0.0.10", :port=>"5000-5009",
           :protocol=>:tcp, :lbalg=>"roundrobin", :topo_type=>:nat,
           :proxy_src=>"60.0.0.101-60.0.0.104", :hc_name=>"hc1",
           :hc_port=>:any, :conn_drain=>"180", :nat_timeout=>"180",
           :persist_timeout=>"180"}
        )
      end
      it "third instance is rule3 (IPv6)" do
        expect(instances[2]).to eq(
          {:name=>"rule3", :ensure=>:present, :persistent=>'false',
           :enabled=>:true, :vip=>"2003::1", :port=>"21", :protocol=>:tcp,
           :lbalg=>"roundrobin", :topo_type=>:dsr, :proxy_src=>:absent,
           :hc_name=>:absent, :hc_port=>:absent,
           :conn_drain=>:absent, :nat_timeout=>:absent,
           :persist_timeout=>:absent}
        )
      end
      it "last instance is rule5 (IPv4)" do
        expect(instances[-1]).to eq(
          {:name=>"rule5", :ensure=>:present, :persistent=>'false',
           :enabled=>:true, :vip=>"1.2.3.6", :port=>"21", :protocol=>:tcp,
           :lbalg=>"roundrobin", :topo_type=>:dsr, :proxy_src=>:absent,
           :hc_name=>:absent, :hc_port=>:absent,
           :conn_drain=>:absent, :nat_timeout=>:absent,
           :persist_timeout=>:absent}
        )
      end
  end
```

#### Specific Method Testing
Create and destroy should always be tested
```ruby
describe ".create" do
    it "creates a rule" do
```

Exercise the create method. This part was initially more confusing that it had
any right to be. We are mocking the call to the command and verifying the
arguments it receives.
```ruby
      described_class.expects(:ilbadm).with(
        'create-rule', '-e', '-p',
        '-i', 'vip=81.0.0.10,port=5000-5009,protocol=tcp',
        '-m', 'lbalg=roundrobin,type=nat,proxy-src=60.0.0.101-60.0.0.104,pmask=/24',
        '-h', 'hc-name=hc1,hc-port=any',
        '-t', 'conn-drain=180,nat-timeout=180,persist-timeout=180',
        '-o', 'servergroup=sg10', 'nat1'
      )
```

Execute the method. `provider` creates the `resource` which uses `params`
```ruby
      expect(provider.create).to eq nil
    end
  end
```

Exercise the destroy method
```ruby
  describe ".destroy" do
    it "destroys a server" do
      described_class.expects(:ilbadm).with(
        'delete-rule', resource[:name]
      )
      expect(provider.destroy).to eq nil
    end
  end
```

**Note:** command mocking uses `expects` and test use `expect` if these are
reversed you will receive unclear errors



Enable and disable methods are straight forward in this case
```ruby
  # Unlike the other setter methods enable does not delete then re-create
  describe ".enabled=" do
    # :absent sid is not vaild in normal execution
    # This is bypassing resource property fetching and calling the
    # method directly
    it "enables a server" do
      described_class.expects(:ilbadm).with('enable-rule', resource[:name])
      expect(provider.enabled=:true).to eq(:true)
    end
    it "disables a server" do
      described_class.expects(:ilbadm).with('disable-rule', resource[:name])
      expect(provider.enabled=:false).to eq(:false)
    end
  end
```

Setter methods for most if ilb_rule require more work and are implemented via
meta programming. We need to test them specially. We use an array here to
reduce code duplication.
```ruby
  [
    :persistent=,
    :vip=, :port=, :protocol=,
    :lbalg=, :topo_type=, :proxy_src=,
    :hc_name=, :hc_port=,
    :conn_drain=, :nat_timeout=, :persist_timeout=
  ].each { |method|
    describe ".#{method}" do
      it "destroys then re-creates the rule" do
```

Every call to one of these setters executes two commands on the system. It
first deletes the rule then re-creates it. There is no enforcement of ordering
here, only that both commands are executed. If anyone figures out how to get
strict ordering enforced please let me know.

A note on `create-rule`, one may notice that the invocation expectation is
identical for all methods. At this point of we are executing below any
validation of inputs. That is, we are checking only that `create-rule` and
`delete-rule` are executed. Using valid arguments here by setting
`params[parameter] = value` would needlessly complicate this step while
exercising the input validation already implemented in the type spec.
```ruby
        described_class.expects(:ilbadm).with('delete-rule', resource[:name])
        described_class.expects(:ilbadm).with(
          'create-rule', '-e', '-p',
          '-i', 'vip=81.0.0.10,port=5000-5009,protocol=tcp',
          '-m', 'lbalg=roundrobin,type=nat,proxy-src=60.0.0.101-60.0.0.104,pmask=/24',
          '-h', 'hc-name=hc1,hc-port=any',
          '-t', 'conn-drain=180,nat-timeout=180,persist-timeout=180',
          '-o', 'servergroup=sg10', 'nat1'
        )
```

Setters return the value they are given. We simply pass `foo` as the argument
and expect to get it back. 
```ruby
        # There is no validation in the setter methods only in the resource
        # creation
        expect(provider.send(method,"foo")).to eq("foo")
      end
    end
  }
```

 Advanced Topics
### Short cuts and Debugging with Pry
* install gems
  * pry
  * pry-rescue
* Set breakpoints with `bindings.pry`
  * Assuming you have written the type already run
    `Puppet::Type.type(:my_type).validproperties` and collect the list
    of parameters as an array you can copy and paste as a starting point

## References
* [puppet-solaris_providers @ 2ce743c](https://github.com/shawnferry/puppet-solaris_providers/tree/2ce743c715c209d9a87c038e4f85146abf6c9ee9)
* [spec/unit/type/ilb_rule_spec.rb] (https://github.com/shawnferry/puppet-solaris_providers/blob/2ce743c715c209d9a87c038e4f85146abf6c9ee9/spec/unit/type/ilb_rule_spec.rb)
* [spec/unit/provider/ilb_rule/ilb_rule_spec.rb](https://github.com/shawnferry/puppet-solaris_providers/blob/2ce743c715c209d9a87c038e4f85146abf6c9ee9/spec/unit/provider/ilb_rule/ilb_rule_spec.rb)
* [lib/puppet/type/ilb_rule.rb](https://github.com/shawnferry/puppet-solaris_providers/blob/2ce743c715c209d9a87c038e4f85146abf6c9ee9/lib/puppet/type/ilb_rule.rb)
* [lib/puppet/provider/ilb_rule/solaris.rb](https://github.com/shawnferry/puppet-solaris_providers/blob/2ce743c715c209d9a87c038e4f85146abf6c9ee9/lib/puppet/provider/ilb_rule/solaris.rb)
* [spec/fixtures/unit/provider/ilb_rule/ilb_rule/show-rule_f.txt](https://github.com/shawnferry/puppet-solaris_providers/blob/2ce743c715c209d9a87c038e4f85146abf6c9ee9/spec/fixtures/unit/provider/ilb_rule/ilb_rule/show-rule_f.txt)

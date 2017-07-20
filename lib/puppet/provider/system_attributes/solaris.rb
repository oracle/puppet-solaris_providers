#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Puppet::Type.type(:system_attributes).provide(:solaris) do
  desc "Provider for management of file system attributes for Oracle Solaris"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :chmod => '/usr/bin/chmod', :ls => '/usr/bin/ls'

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
    @property_flush[:no] = []
    @property_flush[:yes] = []
    @short_prop = {
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
    }
  end

  def exists?
    # return true immediately if we have already set :ensure
    return true if @property_hash[:ensure] == :present

    # Collect attributes from the file
    _attr = attributes

    # If the file exists it will always be "present"
    # return false if :ensure == :absent AND
    # no attributes are set
    return false if @resource[:ensure] == :absent &&
                    _attr.count('yes').zero?

    # Because we don't actually implement instances
    # populate the property_hash here
    @property_hash[:ensure] = :present
    @property_hash.merge!(_attr)
    return true
  rescue Puppet::ExecutionFailure
    # The file does not exist
    @property_hash[:ensure] = :absent
    return false
  end

  def attributes
    attr=Hash.new('no')
    ls('-/c', @resource[:file]).each_line.
      each_with_index do |line,idx|
      # Use only the second line
      next unless idx==1
      attr[:archive]        =  (line.index('A') ? 'yes': 'no')
      attr[:hidden]         =  (line.index('H') ? 'yes': 'no')
      attr[:readonly]       =  (line.index('R') ? 'yes': 'no')
      attr[:system]         =  (line.index('S') ? 'yes': 'no')
      attr[:appendonly]     =  (line.index('a') ? 'yes': 'no')
      attr[:nodump]         =  (line.index('d') ? 'yes': 'no')
      attr[:immutable]      =  (line.index('i') ? 'yes': 'no')
      attr[:av_modified]    =  (line.index('m') ? 'yes': 'no')
      attr[:av_quarantined] =  (line.index('q') ? 'yes': 'no')
      attr[:nounlink]       =  (line.index('u') ? 'yes': 'no')
      attr[:offline]        =  (line.index('O') ? 'yes': 'no')
      attr[:sparse]         =  (line.index('s') ? 'yes': 'no')
      attr[:sensitive]      =  (line.index('T') ? 'yes': 'no')
    end
    return attr
  end

  def self.instances
    # We don't attempt to fetch all files to read their ACLs
    # but we need to define instances for puppet resource
    []
  end

  def create
    @property_flush[:ensure] = :present
    return nil
  end

  def destroy
    @property_flush[:ensure] = :absent
    # Removes all attributes from the file
    chmod("S=c", @resource[:file])
  end

  def flush
    if @resource[:strict] == 'true'
      # change/collect ignorable attributes
      self.archive=@resource[:archive]
      self.av_modified=@resource[:av_modified]
      self.av_quarantined=@resource[:av_quarantined]

      chmod("S=c#{@property_flush[:yes].uniq.join}", @resource[:name])
    else
      unless @property_flush[:yes].empty?
        chmod("S+c#{@property_flush[:yes].uniq.join}", @resource[:name])
      end
      unless @property_flush[:no].empty?
        chmod("S-c#{@property_flush[:no].uniq.join}", @resource[:name])
      end
    end
    @property_hash.merge!(attributes)
  end

  # Ignorable
  [:archive, :av_modified, :av_quarantined].each do |prop|
    define_method("#{prop}=") do |should|
      # If prop is set in the resource use it
      if should == 'no'
        @property_flush[:no].push(@short_prop[prop])
      elsif should == 'yes'
        @property_flush[:yes].push(@short_prop[prop])
      elsif @resource[:strict] == 'true'
        # we are operating strict and the property
        # is not set in the resource

        if @resource["ignore_#{prop}".intern] == 'true'
          # Re-enter providing the current value
          self.send("#{prop}=",@property_hash[prop])
        else
          # Attribute is not set in resource, clear it
          self.send("#{prop}=",'no')
        end
      end
    end
  end

  [
    :hidden, :readonly, :system, :appendonly,
    :nodump, :immutable, :nounlink, :offline,
    :sparse, :sensitive
  ].each do |prop|
    define_method("#{prop}=") do |should|
      if should == 'no'
        @property_flush[:no].push(@short_prop[prop])
      elsif should == 'yes'
        @property_flush[:yes].push(@short_prop[prop])
      end
      @property_hash[prop] = should
    end
  end
end

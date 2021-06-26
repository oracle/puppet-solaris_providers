#
# Copyright (c) 2013, 2015, Oracle and/or its affiliates. All rights reserved.
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

Puppet::Type.type(:pkg_publisher).provide(:solaris) do
  desc "Provider for Solaris publishers"
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11']
  commands :pkg => '/usr/bin/pkg'

  mk_resource_methods

  def self.instances
    publishers = {}
    publisher_order = []
    pkg(:publisher, "-H", "-F", "tsv").split("\n").collect do |line|
      name, sticky, _syspub, enabled, type, _status, origin, proxy = line.split

      # strip off any trailing "/" characters
      unless origin.to_s.strip.empty?
        if origin.end_with?("/")
          origin = origin[0..-2]
        end
      end

      unless publishers.key?(name)
        # create a new hash entry for this publisher
        publishers[name] = {
          'sticky' => sticky,
          'enable' => enabled,
          'proxy' => Array[],
          'origin' => Array[],
          'mirror' => Array[],
          'sslkey' => Array[],
          'sslcert' => Array[],
        }
      end

      if type.eql? "mirror"
        publishers[name]["mirror"] << origin
      else
        publishers[name]["origin"] << origin
      end

      # proxy is per-origin/mirror
      publishers[name]["proxy"].push(proxy == '-' ? :absent : proxy)

      # set the order of the publishers
      if not publisher_order.include?("name")
        publisher_order.push name
      end
      index = publisher_order.index(name)
      if index.zero?
        publishers[name]["searchfirst"] = :true
        publishers[name]["searchafter"] = nil
      else
        publishers[name]["searchfirst"] = nil
        publishers[name]["searchafter"] = publisher_order[index-1]
      end
    end

    __pub = ""
    pkg(:publisher, "-H", "-F", "tsv", publishers.keys).split("\n")
      .each do |line|

      field,value = line.strip.split(': ',2)
      case field
      when %r{publisher}i
        __pub = value
      when %r{SSL Key}i
         publishers[__pub]["sslkey"].push(value == 'None' ? :absent : value)
      when %r{SSL Cert}i
         publishers[__pub]["sslcert"].push(value == 'None' ? :absent : value)
      end
    end

    # create new entries for the system
    publishers.keys.collect do |publisher|
      new(:name => publisher,
          :ensure => :present,
          :sticky => publishers[publisher]["sticky"],
          :enable => publishers[publisher]["enable"],
          :origin => publishers[publisher]["origin"],
          :mirror => publishers[publisher]["mirror"],
          :proxy => publishers[publisher]["proxy"],
          :searchfirst => publishers[publisher]["searchfirst"],
          :searchafter => publishers[publisher]["searchafter"],
          :searchbefore => nil,
          :sslkey => publishers[publisher]["sslkey"],
          :sslcert => publishers[publisher]["sslcert"])
    end
  end

  def self.prefetch(resources)
    # pull the instances on the system
    publishers = instances

    # set the provider for the resource to set the property_hash
    resources.keys.each do |name|
      if provider = publishers.find{ |publisher| publisher.name == name}
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def is_origin?(uri)
    @resource[:origin].index(uri) ? true : false
  end

  def build_origin(index=-1)
    origins = []

    if index == -1
      # add all the origins from the manifest
      unless @resource[:origin].nil?
        @resource[:origin].each do |o|
          origins << "-g" << o
        end
      end
      # add all the mirrors from the manifest
      unless @resource[:mirror].nil?
        @resource[:mirror].each do |m|
          origins << "-m" << m
        end
      end
    else
      combined = @resource[:origin] + @resource[:mirror]
      origins << (is_origin?(combined[index]) ? '-g' : '-m')
      origins << combined[index]
    end

    # For batchable (-1) and the first entry (0)
    # remove all the existing origins and mirrors
    if index < 1
      origins << '-G' << '*'
      origins << '-M' << '*'
    end

    origins
  end

  def build_flags(index=-1)
    flags = []

    # For the first entry or if batahcable set all the top level flags
    if index < 1
      if searchfirst = @resource[:searchfirst] and searchfirst != ""
        if searchfirst == :true
          flags << "--search-first"
        end
      end

      if sticky = @resource[:sticky] and sticky != nil
        if sticky == :true
          flags << "--sticky"
        elsif sticky == :false
          flags << "--non-sticky"
        end
      end

      if searchafter = @resource[:searchafter] and searchafter != ""
        if pkg(:publisher, "-H", "-F", "tsv").split("\n").detect \
          { |line| line.split()[0] == searchafter }
          flags << "--search-after" << searchafter
        else
          Puppet.warning "Publisher #{searchafter} not found.  " \
          "Skipping --search-after argument"
        end
      end

      if searchbefore = @resource[:searchbefore] and searchbefore != ""
        if pkg(:publisher, "-H", "-F", "tsv").split("\n").detect \
          { |line| line.split()[0] == searchbefore }
          flags << "--search-before" << searchbefore
        else
          Puppet.warning "Publisher #{searchbefore} not found.  " \
          "Skipping --search-before argument"
        end
      end
    end

    # If this is batched use the values for the first array element
    index = (index < 1 ? 0 : index )
    if (value = @resource[:proxy][index]) && value != :absent
      flags << "--proxy" << value
    end

    if (value = @resource[:sslkey][index]) && value != :absent
      flags << "-k" << value
    end

    if (value = @resource[:sslcert][index]) && value != :absent
      flags << "-c" << value
    end
    flags
  end

  # property setters
  def sticky=(value)
    if value == :true
      pkg("set-publisher", "--sticky", @resource[:name])
    else
      pkg("set-publisher", "--non-sticky", @resource[:name])
    end
    value
  end

  def enable=(value)
    if value == :true
      pkg("set-publisher", "--enable", @resource[:name])
    else
      pkg("set-publisher", "--disable", @resource[:name])
    end
    value
  end

  def searchfirst=(value)
    if value == :true
      pkg("set-publisher", "--search-first", @resource[:name])
    end
    value
  end

  def searchbefore=(value)
    pkg("set-publisher", "--search-before", value, @resource[:name])
    value
  end

  def searchafter=(value)
    pkg("set-publisher", "--search-after", value, @resource[:name])
    value
  end

  def proxy=(array)
    combined = @resource[:origin] + @resource[:mirror]
    array.each_with_index do |value,idx|
      value = value == :absent ? '' : value
      pkg("set-publisher", "--proxy", value,
      (is_origin?(combined[idx]) ? '-g' : '-m'), combined[idx],
      @resource[:name])
    end
    array
  end

  def sslkey=(array)
    # Unset value appears to be the empty string. However, if pkg cannot
    # connect to the publisher after modification the change is rejected
    combined = @resource[:origin] + @resource[:mirror]
    array.each_with_index do |value,idx|
      value = value == :absent ? '' : value
      pkg("set-publisher", "-k", value, '-p', combined[idx])
    end
    array
  end

  def sslcert=(array)
    # Unset value appears to be the empty string. However, if pkg cannot
    # connect to the publisher after modification the change is rejected
    combined = @resource[:origin] + @resource[:mirror]
    array.each_with_index do |value,idx|
      value = value == :absent ? '' : value
      pkg("set-publisher", "-c", value, '-p', combined[idx])
    end
    array
  end

  def batchable?
    # publishers with multiple origins / mirrors can use different proxies
    # and ssl certs/keys per-URI if values are provided and non-uniform
    # each origin will be created individually
    if @resource[:proxy].empty? &&
       @resource[:sslcert].empty? &&
       @resource[:sslkey].empty?
      true
    else
      false
    end
  end

  # required puppet functions
  def create
    if batchable?
      pkg("set-publisher", *build_flags, *build_origin, @resource[:name])
    else
      (0...(@resource[:origin] + @resource[:mirror]).length).each do |index|
        pkg("set-publisher", *build_flags(index), *build_origin(index), @resource[:name])
      end
    end

    # pkg(5) does not allow for a new publisher to be set with the disabled
    # flag, so check for it after setting the publisher
    if enable = @resource[:enable] and enable != nil
      if enable == :false
        pkg("set-publisher", "--disable", @resource[:name])
      end
    end
  end

  def mirror=(array)
    if array.empty? || array == [:absent]
      pkg("set-publisher", '-M', '*', @resource[:name])
    else
      add_list = array - mirror
      remove_list = mirror - array
      unless add_list.empty?
        pkg("set-publisher", *(%w[-m].product(add_list).flatten),
        @resource[:name])
      end
      unless remove_list.empty?
        pkg("set-publisher", *(%w[-M].product(remove_list).flatten),
        @resource[:name])
      end
    end
    @property_hash[:mirror] = array
  end

  def origin=(array)
    if array.empty? || array == [:absent]
      pkg("set-publisher", '-G', '*', @resource[:name])
    else
      add_list = array - origin
      remove_list = origin - array
      unless add_list.empty?
        pkg("set-publisher", *(%w[-g].product(add_list).flatten),
        @resource[:name])
      end
      unless remove_list.empty?
        pkg("set-publisher", *(%w[-G].product(remove_list).flatten),
        @resource[:name])
      end
    end
    @property_hash[:origin] = array
  end

  def destroy
    pkg("unset-publisher", @resource[:name])
  end
end

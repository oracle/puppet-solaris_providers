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

Puppet::Type.type(:ilb_rule).provide(:ilb_rule) do
  @doc = "Provider to manage Solaris Integrated Load Balancer (ILB) rule configuration."
  confine :operatingsystem => [:solaris]
  defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  commands :ilbadm => '/usr/sbin/ilbadm'

  mk_resource_methods

  def self.instances
    rules=Hash.new { |h,k| h[k] = {} }
    _currrule = ""

    ilbadm("show-rule", "-f").each_line do |line|
      field, value = line.strip.tr(' ','').split(":",2)
      field = field.downcase.tr('-','_')

      # Skip unset values
      unless field == 'pmask'
        next if value == '--'
      end

      # Process
      case field
      when 'rulename'
        _currrule = value
        rules[_currrule] = {
          :ensure => :present,
          :name => value,
        }
        next
      when 'status'
        if value == 'E'
          rules[_currrule][:enabled] = :true
        elsif value == 'D'
          rules[_currrule][:enabled] = :false
        end
        next
      when /timeout|drain/
        # Skip default timers
        next if value == '0'
      when 'servers'
        # servers are managed via ilb_server
        next
      when 'type'
        field = :topo_type
        value = value.downcase.intern
      when 'protocol', 'lbagl'
        value = value.downcase.intern
      when 'pmask'
        rules[_currrule][:persistent] =
          if value == '--'
            'false'
          else
            value
          end
        next
      when 'hc_port'
        # Support 'any' and 'all' keywords
        unless value =~ /^\d+$/
          value = value.downcase.intern
        end
      end


      # Collect remaining/munged values
      rules[_currrule][field.intern] = value
    end

    # Return the array of rule resources
    return rules.each_value.collect { |hsh| new(hsh) }
  end

  def self.prefetch(resources)
    _instances = instances
    resources.keys.each do |name|
      if provider = _instances.find { |_resource| _resource.name == name }
        resources[name].provider = provider
      end
    end
  end

  def enabled=(value)
    # Use property sid, not resource. User cannot specify sid
    if value == :true
      ilbadm("enable-rule", @resource[:name])
    elsif value == :false
      ilbadm("disable-rule", @resource[:name])
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def i_args
    # There will always be -i args
    _args = [:vip, :port, :protocol].each.collect do |field|
      @resource[field] ? "#{field}=#{@resource[field]}" : next
    end
    return ["-i",_args.compact.join(',')]
  end

  def m_args
    # There will always be -m args
    _args = [:lbalg, :proxy_src].each.collect do |field|
      @resource[field] ?
        "#{field.to_s.tr('_','-')}=#{@resource[field]}" :
        next
    end

    _args.insert(1,"type=#{@resource[:topo_type]}")
    if @resource[:persistent] && @resource[:persistent].match(%r(^/\d+$))
      _args.push "pmask=#{@resource[:persistent]}"
    end

    return ["-m",_args.compact.join(',')]
  end

  def h_args
    # There will sometimes be -h args
    _args = [:hc_name,:hc_port].each.collect do |field|
      @resource[field] ? "#{field.to_s.tr('_','-')}=#{@resource[field]}" : next
    end
    unless _args.compact.empty?
      return ["-h",_args.compact.join(',')]
    else
      return nil
    end
  end

  def t_args
    # There will sometimes be -t args
    _args = [:conn_drain,:nat_timeout,:persist_timeout].each.collect do |field|
      @resource[field] ? "#{field.to_s.tr('_','-')}=#{@resource[field]}" : next
    end
    unless _args.compact.empty?
      return ["-t",_args.compact.join(',')]
    else
      return nil
    end
  end

  def create
    #ilbadm create-rule [-e] [-p] -i vip=value,port=value[,protocol=value]
    #  -m lbalg=value,type=value[,proxy-src=ip-range][,pmask=mask]
    #  [-h hc-name=value[,hc-port=value]]
    #  [-t [conn-drain=N][,nat-timeout=N],[persist-timeout=N]]
    #  -o servergroup=value name

    # Build up args, stirctly speaking this could be done less stepwise
    # but it is even uglier
    _args = ["create-rule", "-e"]
    unless [:false,:absent,'false'].include?(@resource[:persistent])
      _args.push('-p')
    end
    _args.push(i_args, m_args, h_args, t_args)
    _args.push('-o', "servergroup=#{@resource[:servergroup]}")

    ilbadm(*_args.flatten.compact, @resource[:name])

    nil
  end

  def destroy
    ilbadm("delete-rule", @resource[:name])
  end

  # Most setter methods need to destroy/create instead of updating
  [
    :persistent,
    :vip, :port, :protocol,
    :lbalg, :topo_type, :proxy_src,
    :hc_name, :hc_port,
    :conn_drain, :nat_timeout, :persist_timeout
  ].each do |method|
    define_method("#{method}=") do |should|
      destroy
      create
      @property_hash[method] = should
    end
  end
end

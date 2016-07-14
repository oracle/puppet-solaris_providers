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

class Puppet::Type::ZfsAcl

  class Ace < Hash
  end

  # Collect Values Utilation and munging
  class Ace::Util
  @default_perms =
    {
      'owner' => [ 'read_xattr', 'write_xattr', 'read_attributes',
        'write_attributes', 'read_acl', 'write_acl',
        'write_owner', 'synchronize' ],
      'group' => [ 'read_xattr', 'read_attributes', 'read_acl', 'synchronize' ],
      'everyone' => [ 'read_xattr', 'read_attributes', 'read_acl',
          'synchronize' ],
    }
    @perms = %w(
        read_data write_data append_data read_xattr write_xattr
        execute delete_child read_attributes write_attributes
        delete read_acl write_acl write_owner synchronize
        absent
    )
    @dir_perms = %w( list_directory add_subdirectory add_file )
    @read_set = %w(read_data read_acl read_attributes read_xattr)
    @write_set = %w(write_data append_data write_attributes write_xattr)
    @target = %w( owner@ group@ everyone@ owner group everyone )
    @target_patterns = [ /^user:.+/, /^group:.+/ ]
    @perm_sets = %w( full_set modify_set read_set write_set )
    @inheritance = %w( file_inherit dir_inherit inherit_only no_propagate absent )
    @perm_type = %w( allow deny audit alarm )
    class << self
      attr_reader :perms, :target, :target_patterns, :perm_sets, :inheritance,
        :perm_type, :default_perms, :write_set, :read_set
    end
    def self.all_perms
      @perms + @perm_sets + @dir_perms
    end

    def self.compact_perms(value)
      # Use compact format for comparisons and actual application
      # Otherwise the difference between files and directories is
      # problematic

      cperms=Array.new(14).fill('-')
      value.each { |perm|
        # ordering isn't strictly important but is probably useful visually
        # for the end user rwxpdDaARWcCos
        case perm
        when 'read_data','list_directory'
          cperms[0] = :r
        when 'write_data','add_file'
          cperms[1] = :w
        when 'execute'
          cperms[2] = :x
        when 'append_data','add_subdirectory'
          cperms[3] = :p
        when 'delete'
          cperms[4] = :d
        when 'delete_child'
          cperms[5] = :D
        when 'read_attributes'
          cperms[6] = :a
        when 'write_attributes'
          cperms[7] = :A
        when 'read_xattr'
          cperms[8] = :R
        when 'write_xattr'
          cperms[9] = :W
        when 'read_acl'
          cperms[10] = :c
        when 'write_acl'
          cperms[11] = :C
        when 'write_owner'
          cperms[12] = :o
        when 'synchronize'
          cperms[13] = :s
        end
      }
      cperms
    end
    def self.compact_inh(value)
      cinh=Array.new(6).fill('-')
      value.each { |inh|
        # There are six positions...
        case inh
        when 'file_inherit'
          cinh[0] = :f
        when 'dir_inherit'
          cinh[1] = :d
        when 'inherit_only'
          cinh[2] = :i
        when 'no_propagate'
          cinh[3] = :n
        end
      }
     cinh
    end
  end

  # ACE is an access control entry
  class Ace < Hash
    attr_reader :provider
    def initialize(hash,resource=[])
      if hash.kind_of?(Hash)
        # do nothing, we expect a hash
      elsif hash.kind_of?(String)
        hash = self.split_ace(hash)
      else
        raise Puppet::Error, "Invalid input #{hash.class}:#{hash}"
      end

      hash.dup.each_pair { |k,v|
        hash.delete(k)
        hash[k.intern] = v
      }

      @hash=hash
      @provider = (resource[:provider] rescue nil)
      @hash[:perm_type].freeze

      # Munge values
      case @hash[:target]
      when /:/
        # do nothing
      when 'everyone', 'group', 'owner'
        # allow the string but convert to ...@ syntax
        @hash[:target] << '@'
      end
      # Once this is set freeze it
      @hash[:target].freeze

      if @hash[:perms].include?('full_set')
        @hash[:perms] << Ace::Util.perms
        @hash[:perms] = (@hash[:perms].flatten - %w(full_set absent)).uniq
      end

      if @hash[:perms].include?('modify_set')
        @hash[:perms] << Ace::Util.perms - %w(write_acl write_owner)
        @hash[:perms] = (@hash[:perms].flatten - %w(modify_set absent)).uniq
      end

      if @hash[:perms].include?('read_set')
        @hash[:perms] << Ace::Util.read_set
        @hash[:perms] = (@hash[:perms].flatten - ['read_set']).uniq
      end

      if @hash[:perms].include?('write_set')
        @hash[:perms] << Ace::Util.write_set
        @hash[:perms] = (@hash[:perms].flatten - ['write_set']).uniq
      end

      @hash[:inheritance] ||= ['absent']

      super(@hash)
    end


    # This is a class method used to generate the hash from the
    # raw acl output from ls
    def self.split_ace(ace)
      # The number of fields from split in the output is variable
      # from 3 - 5
      # target'perms':[inheritance:]perm_type

      hsh = { 'target' => "",
        'perms' => [],
        'inheritance' => [],
        'perm_type' => "" }

      fields = ace.split(":")

      # The last field is always the type
      hsh['perm_type'] = fields.pop

      # The first one or two fields define the target
      if %w(user group groupsid usersid sid).include?(fields[0])
        hsh['target'] = fields.slice!(0,2).join(":")
      else
        hsh['target'] = fields.shift
      end

      # The next field is perms even if it is empty
      hsh['perms'] = fields.shift.split("/")
      # It does appear possible to define an ACE with only inheritance
      # I'm not sure that has any practical application
      hsh['perms'].push('absent') if hsh['perms'].empty?

      # If there is a field here it is inheritance
      unless fields.empty?
        hsh['inheritance'] = fields.shift.split("/")
      else
        hsh['inheritance'].push('absent')
      end

      # There should never be any fields left over
      fail "Did not process all ACE fields: #{fields}" unless fields.empty?

      hsh
    end


    # otherwise we just get {} back
    def to_hash
      @hash
    end
    alias :to_h :to_hash
    alias :should :to_hash

    # Only create a hash from ace values
    def hash
      @hash[:perm_type].hash ^
      @hash[:perms].hash ^
      @hash[:inheritance].hash ^
      @hash[:target].hash
    end

    # Act like an object automatically and allow dot access
    def method_missing(sym)
        @hash[sym]
    end

    # Because we modify the set of perms if we are adding defaults
    def perms=(value)
      @hash[:perms] = value
    end

    # Act like a hash
    def [](key)
      if key == "provider"
        return @provider
      end
      @hash[key]
    end

    # Act like a hash
    def []=(key,arg)
      @hash[key] = arg
    end

    def to_s
      # All fields even can be provided even if perms or inheritance
      # are empty
      _str = "%s:%s:%s:%s" % [
        target,
        Ace::Util.compact_perms(perms) * "",
        Ace::Util.compact_inh(inheritance) * "",
        perm_type
      ]
    end

    # The following methods: keys, values, [](key) make
    # `puppet resource afs_acl somelocation` believe that
    # this is actually a Hash and can pull the values
    # from this object.
    def keys
      @hash.keys
    end

    def values
      @hash.values
    end

    # Return only ACE keys in the order they are found in an
    # ACE entry
    def inspect
      return_value = [:target, :perms, :inheritance, :perm_type].collect do |key|
        key_value = @hash[key]
        if key_value.is_a? Array
          "#{key} => #{key_value}\n"
        else
          "#{key} => '#{key_value}'"
        end
      end.join(', ')

      "\n { #{return_value} }"
    end
  end
end

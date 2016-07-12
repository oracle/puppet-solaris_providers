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
        list_directory add_file add_subdirectory absent
    )
    @target = %w( owner@ group@ everyone@ owner group everyone )
    @target_patterns = [ /^user:.+/, /^group:.+/ ]
    @perm_sets = %w( full_set modify_set read_set write_set )
    @inheritance = %w( file_inherit dir_inherit inherit_only no_propagate absent )
    @perm_type = %w( allow deny audit alarm )
    class << self
      attr_reader :perms, :target, :target_patterns, :perm_sets, :inheritance,
        :perm_type, :default_perms
    end
    def self.all_perms
      @perms + @perm_sets
    end
  end

  # ACE is an access control entry
  class Ace < Hash
    def initialize(hash,provider=nil)
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
      @hash['provider'] = provider
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
        @hash[:perms] = (@hash[:perms] + Ace::Util.perms).uniq
        @hash[:perms] = @hash[:perms] - %w(full_set absent)
      end

      if @hash[:perms].include?('modify_set')
        @hash[:perms] = (@hash[:perms] +
                         (Ace::Util.perms - ['write_acl', 'write_owner'])
                        ).uniq
                        @hash[:perms] = @hash[:perms] - %w(modify_set absent)
      end

      if @hash[:perms].include?('read_set')
        @hash[:perms] = (@hash[:perms] +
                         %w(read_data read_acl read_attributes
                       read_xattr)).uniq
        @hash[:perms] = @hash[:perms] - ['read_set']
      end
      if @hash[:perms].include?('write_set')
        @hash[:perms] = (@hash[:perms] +
                         %w(write_data append_data write_attributes
               write_xattr)).uniq
        @hash[:perms] = @hash[:perms] - ['write_set']
      end

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
        perms_to_s,
        inheritance_to_s,
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
      hash = @hash
      return_value = [:target, :perms, :inheritance, :perm_type].collect do |key|
        key_value = hash[key]
        if key_value.is_a? Array
          "#{key} => #{key_value}\n"
        else
          "#{key} => '#{key_value}'"
        end
      end.join(', ')

      "\n { #{return_value} }"
    end

    private

    def perms_to_s
      perms.index('absent') ? "" :  perms * "/"
    end

    def inheritance_to_s
      ace['inheritance'].index('absent') ? "" :  ace['inheritance'] * "/" rescue ""
    end

  end
end

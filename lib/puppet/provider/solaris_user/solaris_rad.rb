# === Description
#
# This provider uses the Rest-API for the Solaris Remote Administration
# Daemon.
#
# === Authors
#
# Manuel Zach <mzach-oss@zach.st>
#
# === Copyright
#
# Copyright 2015 Manuel Zach.
#

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'mzachh', 'rad', 'restclient.rb'))

# The following hash, helps to map the differences between Puppet and RAD
# TODO: Evaluate if proper bindings have an advantage

# <RAD Name>                <Puppet>              <RAD userChangedField>      <Rad type>  <Rad default value>
$rad_mapping = {
  "username"          =>  [ :name,                nil,                        'string',   'no default'  ],
  "userID"            =>  [ :uid,                 'uidChanged',               'integer',  'no default'  ],
  "groupID"           =>  [ :gid,                 'gidChanged',               'integer',  'no default'  ],
  "description"       =>  [ :comment,             'descChanged',              'string',   nil           ],
  "homeDirectory"     =>  [ :home,                'homedirChanged',           'string',   nil           ],
  "defaultShell"      =>  [ :shell,               'defShellChanged',          'string',   nil           ],
  "min"               =>  [ :min,                 'minChanged',               'integer',  -1            ],
  "max"               =>  [ :max,                 'maxChanged',               'integer',  -1            ],
  "warn"              =>  [ :warn,                'warnChanged',              'integer',  -1            ],
  "expire"            =>  [ :expire,              'expireChanged',            'string',   nil           ],
  "lockAfterRetries"  =>  [ :lock_after_retries,  'lockAfterRetriesChanged',  'string',   nil           ],
  "alwaysAuditFlags"  =>  [ :always_audit_flags,  'alwaysAuditChanged',       'string',   nil           ],
  "neverAuditFlags"   =>  [ :never_audit_flags,   'neverAuditChanged',        'string',   nil           ],
  "type"              =>  [ :type,                'typeChanged',              'string',   nil           ],
  "defaultProj"       =>  [ :default_proj,        'defaultProjChanged',       'string',   nil           ],
  "minLabel"          =>  [ :min_label,           'minLabelChanged',          'string',   nil           ],
  "roleAuth"          =>  [ :role_auth,           'roleAuthChanged',          'string',   nil           ],
  "idleCmd"           =>  [ :idle_cmd,            'idleCmdChanged',           'string',   nil           ],
  "idleTime"          =>  [ :idle_time,           'idleTimeChanged',          'string',   nil           ],
  "roles"             =>  [ :roles,               'rolesChanged',             'string',   nil           ],
  "profiles"          =>  [ :profiles,            'profilesChanged',          'string',   nil           ],
  "authProfiles"      =>  [ :auth_profiles,       'authProfilesChanged',      'string',   nil           ],
  "auths"             =>  [ :auths,               'authsChanged',             'string',   nil           ],
  "limitPriv"         =>  [ :limit_priv,          'limitPrivChanged',         'string',   nil           ],
  "groups"            =>  [ :groups,              'groupsChanged',            'string',   nil           ],
  "inactive"          =>  [ :inactive,            nil,                        'integer',  -1            ],
}

def to_puppet(ruby_hash)
  puppet_hash = ruby_hash

  # Set data type
  puppet_hash.each do |k,v|
    if $rad_mapping.has_key?(k) and $rad_mapping[k][2]=='integer'
      puppet_hash[k] = v.to_s
    end
  end

  # Rename keys to Puppet key names
  $rad_mapping.each do |k,v| 
    puppet_key = v[0]
    if puppet_hash.has_key?(k)
      puppet_hash[puppet_key] = puppet_hash[k]
      puppet_hash.delete(k)
    end
  end

  puppet_hash[:ensure] = :present
  puppet_hash
end

def from_puppet(puppet_hash)
  ruby_hash = puppet_hash

  # Rename Puppet key to RAD key
  $rad_mapping.each do |k,v| 
    puppet_key = v[0]
    if ruby_hash.has_key?(puppet_key)
      ruby_hash[k] = ruby_hash[puppet_key]
      ruby_hash.delete(puppet_key)
    end
  end

  # Set correct default value
  ruby_hash.keys.each do |k|
    if ruby_hash[k] == ""
      if $rad_mapping.has_key?(k)
        ruby_hash[k] = $rad_mapping[k][3]
      else
        ruby_hash[k] = nil
      end
    end
  end

  # Set RAD data type
  ruby_hash.each do |k,v|
    if $rad_mapping.has_key?(k) and $rad_mapping[k][2]=='integer'
      ruby_hash[k] = v.to_i
    end
  end

  # Remove non-RAD attributes
  ruby_hash.keys.each do |k|
    if not $rad_mapping.keys.include?(k)
      ruby_hash.delete(k)
    end
  end

  # Add missing RAD attributes
  $rad_mapping.each do |k,v|
    default_value = v[3]
    if not ruby_hash.keys.include?(k) and default_value!=nil
      ruby_hash[k] = default_value
    end
  end

  ruby_hash
end

def flush_user(user_hash)
  if @property_flush[:ensure] == :absent
    delete_user(@property_hash[:name])
    return
  end

  if @property_flush[:ensure] == :present
    add_user(resource.to_hash)
    return
  end

  url = "/api/com.oracle.solaris.rad.usermgr/1.0/UserMgr/_rad_method/modifyUser"
  user_hash = from_puppet(@property_hash)

  # Build "changeFields" hash
  changedFields = {}
  $rad_mapping.each do |k,v|
    puppet_key = v[0]
    radChanged_key = v[1]
    if radChanged_key!=nil 
      if @property_changed.include?(puppet_key)
        changedFields[radChanged_key] = true
      else
        changedFields[radChanged_key] = false
      end
    end
  end

  response = Puppetx::Mzachh::Rad::Restclient.put( "default", url, { "user" => user_hash, "changeFields" => changedFields })
  if response['status'] == 'success'
    to_puppet(response['payload'])
  else
    nil
  end
end

def delete_user(username)
  url = "/api/com.oracle.solaris.rad.usermgr/1.0/UserMgr/_rad_method/deleteUser"
  Puppetx::Mzachh::Rad::Restclient.put("default", url, { "username" => username })
end

def add_user(user_puppet)
  url = "/api/com.oracle.solaris.rad.usermgr/1.0/UserMgr/_rad_method/addUser"
  user = from_puppet(user_puppet)
  Puppetx::Mzachh::Rad::Restclient.put("default", url, { "user" => user, "password" => "###DUMMYPASSWORD###" })
  warn("WARNING: Known Default password set, change it e.g. with the \"user\" resource type")
end

Puppet::Type.type(:solaris_user).provide(
  :solaris_rad
  ) do
    desc "Provider for managing user accounts with Solaris RAD"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
    @property_changed = []
  end

  def self.instances
    url = "/api/com.oracle.solaris.rad.usermgr/1.0/UserMgr/users/"
    payload =  Puppetx::Mzachh::Rad::Restclient.get(url)['payload']
    payload.collect do |user|
      user_puppet = to_puppet(user)
      new(user_puppet)
    end
  end

  def self.prefetch(resources)
    users = instances
    resources.keys.each do |name|
      if provider = users.find{ |user| user.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  # Overwrite set fuction to track changed properties
  [resource_type.validproperties, resource_type.parameters].flatten.each do |attr|
    attr = attr.intern
    next if attr == :name
    define_method(attr.to_s + "=") do |val|
      @property_hash[attr] = val
      @property_changed.push(attr)
    end
  end

  def flush
    flushed_user = flush_user(@property_hash)
    if flushed_user != nil
      @property_hash = flushed_user
    end
  end

end

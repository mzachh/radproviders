# === Description
#
# This provider uses the Rest-API for the Solaris Remote Administration
# Daemon. It is based on the original Puppet ZFS provider.
# See: https://github.com/puppetlabs/puppet/blob/master/lib/puppet/provider/zfs/zfs.rb
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

def lookup_filesystem(filesystem)
  filesystem_url = "localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/#{escape_name(filesystem)}"
  if ( Puppetx::Mzachh::Rad::Restclient.get(filesystem_url) != false )
    true
  else
    false
  end
end

def get_property(filesystem, property)
  url = "localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/#{escape_name(filesystem)}/_rad_method/get_props"
  Puppetx::Mzachh::Rad::Restclient.put(url,{"props" => [{"name" => property}]})['payload'][0]['value'].strip()
end

def set_property(filesystem, property, value)
  url = "localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/#{escape_name(filesystem)}/_rad_method/set_props"
  Puppetx::Mzachh::Rad::Restclient.put(url,{"props" => [{"name" => property, "value" => value}]})
end

def list_allfilesystems()
  url = "localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/" 
  payload =  Puppetx::Mzachh::Rad::Restclient.get(url)['payload'].collect{|x| x['href']}.collect{|x| x.split('/')[-1]}.collect{|x| unescape_name(x)}.sort
end

def create_filesystem()
  filesystem = @resource[:name]
  parent_filesystem = filesystem.split("/")[0..-2].join("/")
  filesystem_url = "localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/#{escape_name(parent_filesystem)}/_rad_method/create_filesystem"
  all_args = {"name" => filesystem, "props" => add_properties }
  response = Puppetx::Mzachh::Rad::Restclient.put(filesystem_url, all_args)
end

def destroy_filesystem()
  filesystem = @resource[:name]
  filesystem_url = "localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/#{escape_name(filesystem)}/_rad_method/destroy"
  response = Puppetx::Mzachh::Rad::Restclient.put(filesystem_url,{})
end

def escape_name(name)
  name.gsub("/","%2F")
end

def unescape_name(name)
  name.gsub("%2F","/")
end

Puppet::Type.type(:zfs).provide(
  :solaris_rad
  ) do
    desc "Provider for managing ZFS with RAD"
    confine :operatingsystem => [:solaris]
    defaultfor :osfamily => :solaris, :kernelrelease => ['5.11', '5.12']
  
  Puppetx::Mzachh::Rad::Restclient.auth()

  def self.instances
    list_allfilesystems.collect do |name|
      new({:name => name, :ensure => :present})
    end
  end

  def add_properties
    properties = []
    Puppet::Type.type(:zfs).validproperties.each do |property|
      next if property == :ensure
      if value = @resource[property] and value != ""
        properties.push({"name" => property, "value" => value})
      end
    end
    properties
  end

  def create
    create_filesystem()
  end

  def destroy
    destroy_filesystem()
  end

  def exists?
    lookup_filesystem(@resource[:name])
  end

  ZFSRAD_PARAMETER_UNSET_OR_NOT_AVAILABLE = '-'
  # http://docs.oracle.com/cd/E19963-01/html/821-1448/gbscy.html
  # shareiscsi (added in build 120) was removed from S11 build 136
  # aclmode was removed from S11 in build 139 but it may have been added back
  # http://webcache.googleusercontent.com/search?q=cache:-p74K0DVsdwJ:developers.slashdot.org/story/11/11/09/2343258/solaris-11-released+&cd=13
  [:aclmode, :shareiscsi].each do |field|
    # The zfs commands use the property value '-' to indicate that the
    # property is not set. We make use of this value to indicate that the
    # property is not set since it is not avaliable. Conversely, if these
    # properties are attempted to be unset, and resulted in an error, our
    # best bet is to catch the exception and continue.
    define_method(field) do
      begin
        get_property(@resource[:name],field.to_s)
      rescue
        ZFSRAD_PARAMETER_UNSET_OR_NOT_AVAILABLE
      end
    end
    define_method(field.to_s + "=") do |should|
      begin
        set_property(@resource[:name],field.to_s,should.to_s)
      rescue
      end
    end
  end

  [:aclinherit, :atime, :canmount, :checksum,
   :compression, :copies, :dedup, :devices, :exec, :logbias,
   :mountpoint, :nbmand,  :primarycache, :quota, :readonly,
   :recordsize, :refquota, :refreservation, :reservation,
   :secondarycache, :setuid, :sharenfs, :sharesmb,
   :snapdir, :version, :volsize, :vscan, :xattr, :zoned].each do |field|
    define_method(field) do
      begin
        get_property(@resource[:name],field.to_s)
      rescue
        ZFSRAD_PARAMETER_UNSET_OR_NOT_AVAILABLE
      end
    end

    define_method(field.to_s + "=") do |should|
      set_property(@resource[:name],field.to_s,should.to_s)
    end
  end
end

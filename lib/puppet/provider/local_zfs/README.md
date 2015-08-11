## Provider: `local_zfs`

This Puppet module contains an alternative provider for the ZFS type. This provider uses the Solaris Remote Administration Daemon (RAD).

**The provider is currently just an experiment to test RAD and not well tested. This provider was the base for the remote_zfs provider.**

## Requirements
You need at least Solaris 11.3 beta, because this is the first version with the Rest-API for RAD.

## Installation

- pkg install puppet
- pkg install gcc
- gem install rest-client
- Add support for unix sockets to rest-client, see https://github.com/rest-client/rest-client/issues/271
- Fix http-cookie to work with unix sockets: https://github.com/sparklemotion/http-cookie/issues/7
- Copy "radproviders" to your Puppet modules directory. E.g. on Solaris 11.3 beta: /etc/puppet/modules/
- Configure root password in "radproviders/lib/puppet_x/mzachh/rad/restclient.rb"

## Usage

The provider should be used automatically whenever you use the ZFS-type. You can also force the usage of the alternative provider by setting "provider => solaris_rad":

    zfs { 'rpool/test':
        ensure      => 'present',
        mountpoint  => "/test",
        provider    => "solaris_rad"
    }

To see the REST-API calls you can use the debug mode:

    # puppet apply --debug newfs.pp
    ...
    Debug: REST API Calling GET: localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/rpool%2Ftest
    Debug: REST API Calling PUT: localhost/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/rpool/_rad_method/create_filesystem
    Debug: REST API Calling arguments: {
    "name": "rpool/test",
    "props": [
      {
        "name": "mountpoint",
        "value": "/test"
      }
      ]
    }
    Debug: REST API response: {
          "status": "success",
          "payload": {
                  "href": "/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/_rad_reference/1793"
          }
    }
    Notice: /Stage[main]/Main/Zfs[rpool/test]/ensure: created
    ...

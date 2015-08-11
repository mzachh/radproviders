## Provider: `remote_zfs`

This Puppet provider manages ZFS filesystems on remote and local servers. The provider uses the REST-API of the Solaris Remote Administration Daemon (RAD).

## Requirements
You need at least Solaris 11.3 beta, because this is the first version with the REST-API for RAD.

## Installation

- pkg install puppet
- pkg install gcc
- gem install rest-client
- Copy "radproviders" to your Puppet modules directory. E.g. on Solaris 11.3 beta: /etc/puppet/modules/

## Configuration
- Configure RAD remote service. TODO: Add details.
- Configure connections and credentials:

File:  "radproviders/lib/puppet_x/mzachh/rad/rad_config.json"

    {
      "default" : "localhost",
      "connections" : {
        "localhost" : {
          "address" : "https://127.0.0.1:12303",
          "verify_ssl" : "false",
          "auth" : {
            "username": "zfsadmin1",
            "password": "<password1>",
            "scheme": "pam",
            "preserve": true,
            "timeout": -1
            }
        },
        "fileserver" : {
          "address" : "https://fileserver.example.com:12303",
          "verify_ssl" : "false",
          "auth" : {
            "username": "zfsadmin2",
            "password": "<password2>",
            "scheme": "pam",
            "preserve": true,
            "timeout": -1
            }
        }
      }
    }

## Usage

The provider has in general the same type definition like the standard Puppet `zfs` provider

    remote_zfs { 'rpool/project1/video':
        ensure      => present,
        mountpoint  => "/mnt/project1/video",
        compression => "on"
    }

In this form the default ZFS server is used. A non-default server can be used by encoding the connection name into the resource name:

    remote_zfs { 'fileserver#rpool/project1/video':
        ensure      => present,
        mountpoint  => "/mnt/project1/video",
        compression => "on"
    }

To see the REST-API calls you can use the debug mode:

    # puppet apply --debug newfs.pp
    ...
    Debug: REST API Calling GET: https://127.0.0.1:12303/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/rpool%2Fproject1%2Fvideo
    Debug: REST API Calling PUT: https://127.0.0.1:12303/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/rpool%2Fproject1/_rad_method/create_filesystem
    Debug: REST API Calling arguments: {
      "name": "rpool/project1/video",
      "props": [
        {
          "name": "compression",
          "value": "on"
        },
        {
          "name": "mountpoint",
          "value": "/mnt/project1/video"
        }
      ]
    }
    Debug: REST API response: {
            "status": "success",
            "payload": {
                    "href": "/api/com.oracle.solaris.rad.zfsmgr/1.0/ZfsDataset/_rad_reference/1793"
            }
    }
    Notice: /Stage[main]/Main/Remote_zfs[rpool/project1/video]/ensure: created
    ...

## Extended example

The following example shows how you can create a remote ZFS filesystem and mount it with NFS. A non-root user is used, because it is likely not wanted to store the root password of the file servers on every client server.

On ZFS server `fileserver`:

    # useradd zfsadmin1
    # passwd zfsadmin1 (set a password)
    # mkdir /mnt/project1
    # chown -R zfsadmin1 /mnt/project1
    # zfs create rpool/project1
    # zfs allow zfsadmin1 compression,create,destroy,mount,mountpoint,share,recordsize,logbias,sharenfs rpool/project1

On the client server configure the credentials of `zfsadmin1` and use the following Puppet manifest:

    remote_zfs {'fileserver#rpool/project1/video':
      ensure => present,
      compression => "on",
      recordsize => "1M",
      logbias => "throughput",
      sharenfs => "on",
      mountpoint => "/mnt/project1/video"
    }

    mount { "/mnt/video":
      require => Remote_zfs['fileserver#rpool/project1/video'],
      device  => "fileserver:/mnt/project1/video",
      fstype  => "nfs",
      ensure  => "mounted",
      options => "-",
      atboot  => false
    }

Output:

    # puppet apply create_share.pp
    Notice: /Stage[main]/Main/Remote_zfs[fileserver#rpool/project1/video]/ensure: created
    Notice: /Stage[main]/Main/Mount[/mnt/video]/ensure: ensure changed 'unmounted' to 'mounted'

## TODO
- Finish documentation
- Test verify_ssl=true

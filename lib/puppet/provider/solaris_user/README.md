## Provider: `solaris_user`

This Puppet provider manages user accounts on Solaris. The provider uses the REST-API of the Solaris Remote Administration Daemon (RAD).

## Requirements
You need at least Solaris 11.3, because this is the first version with the REST-API for RAD.

## Installation

- pkg install puppet
- pkg install gcc
- gem install rest-client
- Copy "radproviders" to your Puppet modules directory. E.g. on Solaris 11.3 beta: /etc/puppet/modules/

## Configuration
- Configure [RAD remote service](https://community.oracle.com/docs/DOC-918902).
- Configure "default" connection and credentials:

File:  "radproviders/lib/puppet_x/mzachh/rad/rad_config.json"

    {
      "default" : "localhost",
      "connections" : {
        "localhost" : {
          "address" : "https://127.0.0.1:12303",
          "verify_ssl" : "false",
          "auth" : {
            "username": "admin1",
            "password": "<password1>",
            "scheme": "pam",
            "preserve": true,
            "timeout": -1
            }
        }
      }
    }

## Usage

The provider has in general the same type definition like the standard Puppet `user` provider

    solaris_user { 'mzach':
      ensure        => 'present',
      comment       => 'Manuel',
      gid           => '10',
      groups        => ['other'],
      home          => '/export/home/mzach/',
      profiles      => ['All'],
      shell         => '/usr/bin/bash',
      uid           => '300',
    }

To see the REST-API calls you can use the debug mode:

    # puppet apply --debug manager-user.pp
    ...
    Notice: /Stage[main]/Main/Solaris_user[mzach]/comment: comment changed 'Manuel' to 'Admin'
    Debug: REST API Calling PUT: https://127.0.0.1:12303/api/com.oracle.solaris.rad.usermgr/1.0/UserMgr/_rad_method/modifyUser
    Debug: REST API Calling arguments: {
      "user": {
        "username": "mzach",
        "userID": 300,
        "groupID": 10,
        "description": "Admin",
        "homeDirectory": "/export/home/mzach/",
        "defaultShell": "/usr/bin/bash",
        "min": -1,
        "max": -1,
        "warn": -1,
        "expire": null,
        "lockAfterRetries": null,
        "alwaysAuditFlags": null,
        "neverAuditFlags": null,
        "type": null,
        "defaultProj": null,
        "minLabel": null,
        "roleAuth": null,
        "idleCmd": null,
        "idleTime": null,
        "roles": null,
        "profiles": [
          "All"
        ],
        "authProfiles": null,
        "auths": null,
        "limitPriv": null,
        "groups": [
          "other"
        ],
        "inactive": -1
      },
      "changeFields": {
        "uidChanged": false,
        "gidChanged": false,
        "descChanged": true,
        "homedirChanged": false,
        "defShellChanged": false,
        "minChanged": false,
        "maxChanged": false,
        ...
    Debug: REST API response: {
            "status": "success",
            "payload": {
                    "username": "mzach",
                    "userID": 300,
                    "groupID": 10,
                    ...


    ...

## Restrictions

The current UserMgr API has several restrictions therefore I only recommend the usage for non-productive use cases, e.g.:

- During user creation a known password is set, you should change that password quickly e.g. with the `user` Puppet type.
- Changing the user ID number is not possible.
- Sometimes the user creation results in a HTTP 500 error.

For the API issues, bug reports at Oracle were opened.

## See also

- Man page: usermgr(3RAD) - Details of UserMgr RAD API

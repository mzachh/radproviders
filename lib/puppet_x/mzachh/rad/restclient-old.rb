# === Description
#
# Helper methods for using the RAD Rest-API.
#
# === Authors
#
# Manuel Zach <mzach-oss@zach.st>
#
# === Copyright
#
# Copyright 2015 Manuel Zach.
#

require 'rest_client'
require 'json'
require 'puppetx'

module Puppetx::Mzachh
  module Puppetx::Mzachh::Rad
    class Puppetx::Mzachh::Rad::Restclient
    
      @@auth_cookie = ""
    
      def self.get(url)
        not_found = false
        begin
          RestClient.socket = '/system/volatile/rad/radsocket-http'
          Puppet.debug "REST API Calling GET: #{url}" 
          response = RestClient.get(
            url,
            {:cookies => @@auth_cookie}
          )
          Puppet.debug "REST API response: #{response.to_str}" 
        rescue RestClient::ResourceNotFound 
          not_found = true
        rescue Exception => e
          Puppet.err "REST API error: #{e.inspect}" 
        end
    
        if not_found
          false
        elsif response.code == 200
          JSON.parse(response)
        else
          raise(Exception, "REST API wrong http status code: #{response.code}\n#{response.to_str}")
        end
      end
    
    
      def self.auth()
    
        auth_json = '{
          "username": "root", 
          "password": "newroot1", 
          "scheme": "pam", 
          "preserve": true, 
          "timeout": -1
        }'
    
        Puppet.debug "Start authentication ..." 
        RestClient.socket = '/system/volatile/rad/radsocket-http'
        auth_response = RestClient.post('localhost/api/com.oracle.solaris.rad.authentication/1.0/Session', auth_json, :content_type => :json, :accept => :json)
        if auth_response.code == 201
          Puppet.debug "Authentication successful"
        else
          Puppet.debug "Authentication failed"
        end
        @@auth_cookie = auth_response.cookies
      end
    
      def self.put(url, args)
        begin
          RestClient.socket = '/system/volatile/rad/radsocket-http'
          args_json = JSON.unparse(args)
          Puppet.debug "REST API Calling PUT: #{url}" 
          Puppet.debug "REST API Calling arguments: #{JSON.pretty_generate(args)}" 
          response = RestClient.put(
            url,
            args_json,
            {:content_type => :json, :accept => :json, :cookies => @@auth_cookie}
          )
          Puppet.debug "REST API response: #{response.to_str}" 
    
        rescue Exception => e
          Puppet.err "REST API error: #{e.inspect}" 
        end
    
        unless response.code == 200
          raise(Exception, "REST API wrong http status code: #{response.code}\n#{response.to_str}")
        end
        JSON.parse(response)
      end
    end
  end
end

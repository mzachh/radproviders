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
    
      @@auth_cookie = {}
      @@config = {}

      def self.get(server_identifier="default", url)
        not_found = false
        server_identifier, rad_address, verify_ssl = self.init_call(server_identifier)

        begin
          Puppet.debug "REST API Calling GET: #{rad_address}#{url}" 
          rad =  RestClient::Resource.new("#{rad_address}#{url}", :verify_ssl => verify_ssl )
          response = rad.get(:cookies => @@auth_cookie[server_identifier])
          Puppet.debug "REST API response: #{response.to_str}" 
        rescue RestClient::ResourceNotFound 
          not_found = true
        rescue Exception => e
          raise(Exception, "\nREST API error: #{e.inspect}") 
        end
    
        if not_found
          false
        elsif response.code == 200
          JSON.parse(response)
        else
          raise(Exception, "REST API wrong http status code: #{response.code}\n#{response.to_str}")
        end
      end
    
      def self.put(server_identifier="default", url, args)
        server_identifier, rad_address, verify_ssl = self.init_call(server_identifier)
        begin
          args_json = JSON.unparse(args)
          Puppet.debug "REST API Calling PUT: #{rad_address}#{url}" 
          Puppet.debug "REST API Calling arguments: #{JSON.pretty_generate(args)}" 
          rad =  RestClient::Resource.new("#{rad_address}#{url}", :verify_ssl => verify_ssl)
          response = rad.put(args_json, :content_type => :json, :accept => :json, :cookies => @@auth_cookie[server_identifier])
          Puppet.debug "REST API response: #{response.to_str}" 
    
        rescue Exception => e
          raise(Exception, "\nREST API error: #{e.inspect}") 
        end
    
        unless response.code == 200
          raise(Exception, "\nREST API wrong http status code: #{response.code}\n#{response.to_str}")
        end
        JSON.parse(response)
      end

      def self.init_call(server_identifier)

        if @@config == {}
          Puppet.debug "Loading configuration ..."
          config_file = File.read(File.dirname(__FILE__)+"/rad_config.json")
          @@config = JSON.parse(config_file)
          Puppet.debug "Loading configuration successful"
        end
 
        if server_identifier=="default"
          server_identifier = "#{@@config['default']}"
        end

        if not @@config['connections'].has_key?(server_identifier)
          raise(Exception, "No configuration for #{server_identifier} in #{config_file} available")
        end

        rad_address = "#{@@config['connections'][server_identifier]['address']}"
        verify_ssl = "#{@@config['connections'][server_identifier]['verify_ssl']}" == "true"

        if not @@auth_cookie.has_key?(server_identifier)
    
          Puppet.debug "Start authentication ..." 
          auth_json = JSON.unparse(@@config['connections'][server_identifier]['auth'])
          rad =  RestClient::Resource.new("#{rad_address}/api/com.oracle.solaris.rad.authentication/1.0/Session", :verify_ssl => verify_ssl)
          auth_response = rad.post(auth_json, :content_type => :json, :accept => :json)

          if auth_response.code == 201
            Puppet.debug "Authentication successful"
          else
            Puppet.debug "Authentication failed"
          end
          @@auth_cookie[server_identifier] = auth_response.cookies
        end
        [server_identifier, rad_address, verify_ssl]
      end
    
    end
  end
end

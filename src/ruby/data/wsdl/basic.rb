#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 VMWare
#
# Test wsdl
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "action/command"
require "action/runcommand"
require "action/block"
require "action/verify"
require "model"
require "#{mypath}/install/utils"
begin
  require "savon"
  hasSavon = true
rescue LoadError
  hasSavon = false
end

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test wsdl API"

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [

  if hasSavon
  [
    v(cb("admin get_version_info") do
      mUri = Utils::getClientURIInfo
      client = Savon::Client.new do
        # /tmp/vvv/com/zimbra/soap/ZimbraService.wsdl
        wsdl.document = mUri[:mode] + '://' + mUri[:target] + ':' + mUri[:port] + '/service/wsdl/ZimbraAdminService.wsdl'
      end
      Savon.env_namespace = :soap
      client.http.auth.ssl.verify_mode = :none
      Savon.log = false
      HTTPI.log = false
      #x =client.wsdl.soap_actions
      client.request :auth_request.to_s.camelcase, :xmlns => 'urn:zimbraAdmin' do
        soap.body = {:name => 'admin',:password => 'test123'}
      end
      client.request :get_version_info_request.to_s.camelcase, :xmlns => 'urn:zimbraAdmin'
    end) do |mcaller, data|
      #puts YAML.dump(data.body)
      mcaller.pass = !data.http_error? &&
                     !(response = data.body[:get_version_info_response]).nil? &&
                     response[:@xmlns] == 'urn:zimbraAdmin' &&
                     response.has_key?(:info) &&
                     !response[:info][:@platform].nil? &&
                     !response[:info][:@host].nil? &&
                     (major = response[:info][:@majorversion]) =~ /\d+/ &&
                     (minor = response[:info][:@minorversion]) =~ /\d+/ &&
                     (micro = response[:info][:@microversion]) =~ /\d+/ &&
                     (kindOf = response[:info][:@type]) =~ /(NETWORK|FOSS)/ &&
                     response[:info][:@version] =~ /#{major}\.#{minor}\.#{micro}.*#{kindOf}/
    end,
    
    v(cb("account auth_request") do
      mUri = Utils::getClientURIInfo
      client = Savon::Client.new do
        wsdl.document = mUri[:mode] + '://' + mUri[:target] + ':' + mUri[:port] + '/service/wsdl/ZimbraUserService.wsdl'
      end
      Savon.env_namespace = :soap
      client.http.auth.ssl.verify_mode = :none
      Savon.log = false
      HTTPI.log = false
      client.request :auth_request.to_s.camelcase, :xmlns => 'urn:zimbraAccount' do
        soap.body = {:account => 'admin',:password => Model::DEFAULTPASSWORD}
      end
    end) do |mcaller, data|
      mcaller.pass = !data.http_error? &&
                     !(response = data.body[:auth_response]).nil? &&
                     response[:@xmlns] == 'urn:zimbraAccount' &&
                     response.has_key?(:auth_token) &&
                     response[:auth_token] =~ /[\da-f_]+/ &&
                     response.has_key?(:lifetime) &&
                     response[:lifetime] =~ /\d+/
                     response.has_key?(:skin) &&
                     response[:skin] == 'serenity'
    end
  ]
  end,

]

#
# Tear Down
#

current.teardown = [

]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
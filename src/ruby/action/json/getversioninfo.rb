#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end

require "model"
require 'model/user'
require 'model/json/getversioninforequest'
require 'json'
require 'action/json/command'

 
module Action::Json
  class GetVersionInfo < Action::Json::Command
    def initialize(admin, chost=Model::Host.new(Model::Servers.getServersRunning("mailbox").first))
      super(Model::Json::GetVersionInfoRequest.new(admin), chost, 7071, 'https')
    end
    
    def run
      res = super
      if res[0] == 0
        [0, Hash[*res[1]['Body']['GetVersionInfoResponse']['info'].flatten]]
      else
        res
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
    # Unit test cases for Proxy
    class GetVersionTest < Test::Unit::TestCase     
      def testNoArgument 
        user = Model::User.new("admin@testdomain", '123456')
        user.token = 'mytoken'
        user.sessionid = 'myid'
        testObject = Action::Json::GetVersionInfo.new(user)
        restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
        assert(restore['data']['Body'].has_key?('GetVersionInfoRequest'))
        assert(restore['data']['Body']['GetVersionInfoRequest']['_jsns'] == 'urn:zimbraAdmin')
        assert(restore['data']['Header']['context']['id'] == user.sessionid)
        assert(restore['data']['Header']['context']['authToken'] == user.token)
      end      
    end   
end
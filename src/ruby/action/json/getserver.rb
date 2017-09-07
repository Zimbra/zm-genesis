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
  #$:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end

require "model"
require 'model/user'
#require 'model/json/request'
require 'model/json/getserverrequest'
require 'json'
require 'action/json/command'

 
module Action::Json
  class GetServer < Action::Json::Command
    def initialize(admin, chost=Model::Host.new(Model::Servers.getServersRunning("mailbox").first))
      super(Model::Json::GetServerRequest.new(admin, chost.to_str), chost, 7071, 'https')
    end
    
    def run
      res = super
      if res[0] == 0
        [0, Server.new(Hash[*res[1]['Body']['GetServerResponse']['server'].flatten])]
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
    class GetServerTest < Test::Unit::TestCase     
      def testNoArgument 
        user = Model::User.new("testme@testdomain", '123456')
        user.token = 'mytoken'
        user.sessionid = 'myid'
        testObject = Action::Json::GetServer.new(user, 'server')
        puts YAML.dump(testObject.to_json)
        restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
        assert(restore['data']['Body']['GetServerRequest']['server']['_content'] == 'server')
      end      
    end   
end
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
require 'model/json/getcertrequest'
require 'json'
require 'action/json/command'

 
module Action::Json
  class Certificates < Hash
    def initialize(h)
      super
      h.each_pair {|k,v| self[k] = v}
    end
  
    def subject(type)
      self.has_key?(type) ? Hash[*self[type]['subject'].flatten]['_content'].strip : nil
    end
    
    def issuer(type)
      self.has_key?(type) ? Hash[*self[type]['issuer'].flatten]['_content'].strip : nil
    end
  end
  
  class GetCertificates < Action::Json::Command
    def initialize(admin, cid, chost = Model::Host.new(Model::Servers.getServersRunning("mailbox").first))
      super(Model::Json::GetCertRequest.new(admin, cid), chost, 7071, 'https')
    end
    
    def run
      res = super
      if res[0] == 0
        [0, Certificates.new(Hash[*res[1]['Body']['GetCertResponse']['cert'].collect {|w| [w['type'], w]}.flatten])]
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
    # Unit test cases for Proxy
    class GetCertTest < Test::Unit::TestCase     
      def testNoArgument 
        user = Model::User.new("testme@testdomain", '123456')
        user.token = 'mytoken'
        user.sessionid = 'myid'
        testObject = Action::Json::GetCertificates.new(user, "serverId")
        puts YAML.dump(testObject.to_json)
        restore = JSON.parse(testObject.to_json.gsub(/\"json_class\":\"[^\"]*\",?/,''))
        assert(restore['data']['Body']['GetCertRequest']['server'] == 'serverId')
      end      
    end   
end
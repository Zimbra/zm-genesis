#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Zimbra
#
# Part of the command class structure. (??)
# Service class for PreAuth authentication testing
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require 'openssl'
require 'base64'
require 'model/testbed'
require 'action/zmprov'
 
 
module Action # :nodoc

  class PreAuth
    
    @@preAuthKey = nil
    
    def self.preAuthKey=(newkey)
      @@preAuthKey = newkey
    end

    def self.preAuthKey
      @@preAuthKey
    end
    
    def self.reset
      @@preAuthKey = nil
    end
    
    def self.genPreAuthKey(domain)
      @@preAuthKey = ZMProv.new('gdpak', '-f', domain.to_s).run[1].match(/^preAuthKey: (.*)$/)[1]
      
      return @@preAuthKey
    end
    
    def self.constructURL(account, params={})
      byvalue = (params[:by] or 'name')
      expires = (params[:expires] or '0')
      timestamp = (params[:timestamp] or (Time.now.to_i * 1000).to_s)
      domain = (params[:domain] or Model::TARGETHOST)
      preauth = computePreAuth(account, byvalue, expires, timestamp, domain)
      url = "/service/preauth?account=#{account}&by=#{byvalue}&expires=#{expires}&timestamp=#{timestamp}&preauth=#{preauth}"
      return url
    end
    
  private
  
    def self.computePreAuth(account, byvalue, expires, timestamp, domain)
      sign = ([] << account << byvalue << expires << timestamp).join('|')
      self.genPreAuthKey(domain) until @@preAuthKey
      preAuth = OpenSSL::HMAC.hexdigest('sha1', @@preAuthKey, sign)
      
      return preAuth
    end
    
  end

end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test cases for 
    class PreAuthTest < Test::Unit::TestCase
      def testGenPreAuthKey
        testObject = Action::PreAuth.genPreAuthKey(Model::TARGETHOST)
        assert(testObject.class == String && !testObject.match(/\s/))
      end
      def testConstructURLdefault
        testObject = Action::PreAuth.constructURL('test@' + Model::TARGETHOST)
        assert(testObject.class == String && !testObject.match(/\s/))
        assert(testObject.match(/^\/service\/preauth\?account=test@.*expires.*timestamp.*preauth/))
      end
      def testComputePreAuth
        account = 'test@' + Model::TARGETHOST
        timestamp = (Time.now.to_i * 1000).to_s
        testObject = Action::PreAuth.computePreAuth(account, 'name', '0',
                                   timestamp, Model::TARGETHOST)
        testObject2 = ZMProv.new('gdpa', Model::TARGETHOST, account, 'name',
                                 timestamp, '0').run[1].match(/^preauth: (.*)$/)[1]
        assert(testObject == testObject2)
      end
    end
  end
end


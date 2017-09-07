#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby'))
end
require 'action/command'
require 'net/http'
require 'uri'
 
module Action # :nodoc
  #
  #  Create a zimbra desktop account
  #
  module Zmdesktop
    
    class CreateAccount < Action::Command
     
      def initialize(pAccount = nil, pEmail = nil, pHost = nil, pPassword = 'test123', pSyncFreq = 300)
        super() 
        @mAccount = pAccount
        @mEmail = pEmail 
        @mHost = pHost
        @mPassword = pPassword
        @mSyncFreq = pSyncFreq
        @url = 'http://localhost:7633/zimbra/desktop/zmail.jsp' 
      end
  
      def run
        super()  
        res = Net::HTTP.post_form(URI.parse(@url), 
          { 'verb' => 'add',
            'accountName' => @mAccount,
            'email' => @mEmail,
            'password' => @mPassword,
            'host' => @mHost,
            'port' => 80,
            'syncFreqSecs' => 300
          }
        ) 
        res.to_str
      rescue => e
        self.to_str + "\n" + e.to_yaml  
      end    
      
      def to_str 
        "Action::Zmdesktop::CreateDesktopAccount mail #{@mEmail} host #{@mHost}"
      end  
    end 
  end
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action::Zmdesktop
    # Unit test cases for Install
    class InstallTest < Test::Unit::TestCase     
      def testRun
        test = CreateAccount.new('one','two', 'three','four')
        puts test.run
      end 
    end
  end
end
 
  


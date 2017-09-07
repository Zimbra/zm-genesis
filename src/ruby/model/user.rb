#!/usr/bin/ruby -w
#
# = action/untar.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This implements user data model
# 
#require 'json'




if($0 == __FILE__) 
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end 
require 'net/imap'

module Model # :nodoc 
  class Name < String
    def to_jh
      {
        'account' => {'json_class' => self.class.name, "_content" => self.to_s, 'by' => 'name'}
      }
    end
    
    def to_json(*a)
      to_jh.to_json(*a) 
    end
    
    def self.json_create(o) 
      new(*o['_content']) rescue nil
    end
  end
  
  class Password < String
    
    def to_jh
      {
        'password' => { 'json_class' => self.class.name, "_content" => self.to_s }
      }   
    end
    
    def to_json(*a)
      to_jh.to_json(*a) 
    end
    
    def self.json_create(o) 
      new(*o['_content']) rescue nil
    end
    
  end
  
  class User
    attr_accessor :token, :sessionid
    def initialize(pname = nil, ppassword = nil, token = nil, sessionid = nil)
      self.name = pname.class == Name ? pname : Name.new(pname)
      if ppassword
        self.password = ppassword.class == Password ? ppassword : Password.new(ppassword)
      end
      self.token = token
      self.sessionid = sessionid 
    end
    
    def name
      @name
    end
    
    def name=(data)
      @name = Name.new(data) rescue nil
    end
    
    def password
      @password
    end
    
    def password=(data)
      @password = Password.new(data) rescue nil
    end
    
    def to_jh
      password.to_jh.merge(name.to_jh).merge( {'json_class' => self.class.name})
    end
    
    def to_json(*a)
      #puts to_jh.to_json(*a)
      to_jh.to_json(*a)
    end
    
    def self.json_create(o) 
      new(Hash[*o['account'].flatten]['_content'], Hash[*o['password'].flatten]['_content']) rescue nil
    end
    
    def to_str
      self.name
    end  
    
    def to_s
      to_str
    end       
  end
  
  class ImapUser < User
    #imap user has a host
    #has a connection state
    attr_accessor :host, :state
    attr_reader :state 
    
    def initialize(*rest)
      super(*rest)
      self.state = :disconnect
      @imapHandler = nil 
    end
    
    def connectImap
      raise "No host information" if host.nil?  
      @imapHandler = Net::IMAP.new(host, *host.imap)    
      self.state = :connected 
    end
    
    def imapHandler
      connectImap unless @imapHandler
      connectImap if (state == :disconnect)
      @imapHandler
    end 
  end
  
  class YahooImapUser < ImapUser
    def imapHandler
      mImap = super
      if (state != :login)
        mImap.login(name, password)
        self.state = :login
      end
      mImap
    end
  end
end

if $0 == __FILE__
  require 'test/unit'  
  require 'yaml'
  require 'model/env'
  
  module Model
    # Unit test cases for SendMail
    class UserTest < Test::Unit::TestCase  
      
      def generateTestObject
        testObject = Model::ImapUser.new("hi", "testme") 
        testHost =  Model::Host.new('imap', 'mail.yahoo.com', false)
        testObject.host = testHost
        testObject
      end
      
      def testRun         
        testObject = Model::ImapUser.new("hi", "testme") 
        assert(testObject.password == "testme") 
      end
      
      def testConnectImapNil
        testObject = Model::ImapUser.new("hi", "testme") 
        assert_raise RuntimeError do
        testObject.connectImap
        end
      end
      
      def testConnectImap
        testObject = generateTestObject 
        testObject.connectImap
        assert(testObject.state = :connected)
      end
      
      def testImapHandler
        testObject = generateTestObject
        testObject.imapHandler 
        assert(testObject.imapHandler == testObject.imapHandler)
      end
      
      def testYahooImapHandler
        testObject = Model::YahooImapUser.new("zimbraone@ymail.com", "test123") 
        testHost =  Model::Host.new('imap', 'mail.yahoo.com', false)
        testObject.host = testHost
        #testObject.imapHandler
        #puts YAML.dump(testObject)
      end
    end
    
  end
end
 
  


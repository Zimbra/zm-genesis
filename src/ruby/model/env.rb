#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This implements test enviornment data model
# 
if($0 == __FILE__)
    mydata = File.expand_path(__FILE__).reverse.sub(/.*?ledom/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
require 'model/user'
 


module Model # :nodoc
  
  #
  # Host class
  #
  class Host
    IMAP = 143
    IMAPSSL = 993
    POP = 110
    POPSSL = 995
    
    attr_accessor :name, :domain, :architecture, :proxy, :imap, :pop, :ip    
    def initialize(name = nil, domain = nil, imapSSL = true)
      self.name = name     
      self.domain = domain
      self.proxy = true #proxy is mandatory component now, changed it to true 
      self.ip = nil
      if(imapSSL)
        self.imap = [IMAPSSL, true]
      else
        self.imap = [IMAP, false]
      end
      self.pop = [POP, false]
    end
    
    def cUser(name = nil, password = nil)
      user = self.domain.cUser(name)
      user.name = user.name.gsub(self.domain, self.name + '.' + self.domain)
      user.password = password if password
      user 
    end
    
    def ==(value)
      result = false
      begin
        result = (self.domain == value.domain) && (self.name == value.name)
      rescue
      end
      result
    end
    
    def to_str  
      if(self.domain != nil)      
        self.name + '.' + self.domain
      else
        self.name
      end
    end   
    
    def to_s
      to_str
    end
      
  end  
  
  #
  # Domain class
  #
  class Domain
    attr_accessor :name   
    
    def initialize(name = nil)
      self.name = name     
    end
    
    def cUser(name = nil)
      User.new(name+ '@'+ self.name)
    end
    
    def to_str
      self.name
    end
    
    def to_s
      to_str
    end
    
    def ==(value)
      result = false
      begin
        result = (!value.nil? && self.name == value.name)
      rescue => e
        puts e
        puts e.backtrace.join("\n")
      end
      result
    end
         
  end   
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Model
    # Unit test cases for SendMail
    class HostTest < Test::Unit::TestCase     
      def testRun         
        testObject = Model::Host.new("hi") 
        puts "I am " + testObject   
      end  
      
      def testCreateuser
        puts Model::Host.new("hi", Model::Domain.new("zimbra.com")).cUser("testtwo") 
      end
      
      def testEqual
        testObject = Model::Host.new("one")
        testObjectTwo = Model::Host.new("one")
        assert(testObject == testObjectTwo)
      end
      
      def testNotEqual
        testObject = Model::Host.new("one")
        testObjectTwo = Model::Host.new("two")
        assert(testObject != testObjectTwo)
      end
    end
    
    class DomainTest < Test::Unit::TestCase     
      def testRun         
        testObject = Model::Domain.new("hi") 
        puts testObject
      end  
      
      def testNotEqual
        testObject = Model::Domain.new("one")
        testObjectTwo = Model::Domain.new("two")
        assert(testObject != testObjectTwo)
      end
      
      def testEqual
        testObject = Model::Domain.new("one")
        testObjectTwo = Model::Domain.new("one")
        assert(testObject == testObjectTwo)
      end
      
      def testCreateuser
        puts Model::Domain.new("zimbra.com").cUser("teston")
      end

      def testCreateSpecialCharacter
        puts "special"
        puts Model::Domain.new("zimbra.com").cUser("sdfs$23423")
      end
    end
  end
end
 
  


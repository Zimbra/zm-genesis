#!/usr/bin/ruby -w
#
# = action/runcommand.rb
#
# Copyright (c) 2005,2006 Zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end 
require 'model/testbed'
require 'action/command' 
require 'action/system'
require 'action/stafsystem' 
 
module Action # :nodoc 
  #
  # Perform zmbackup action.  This will invoke some zmbackup with some argument
  # from http server
  #
  class RunCommand < Action::Command   
  
    #
    #  Create an object.
    # 
    def initialize(*arguments)
      super()
      host = Model::CLIENTHOST
      host = arguments.pop if arguments.last.instance_of?(Model::Host)
      if(host.to_s == Model::TARGETHOST.to_s)
        @runner = System.new(*arguments)
      else 
        @runner = StafSystem.new(host.to_s, *arguments)
      end  
    end
    
    def run
      @runner.run
    end
    
    def to_str
      @runner.to_str
    end 
    
    def method_missing(name, *args)      
      @runner.__send__(name, *args)
    end   
   
  end   

  class RunCommandOn < Action::RunCommand   
  
    def initialize(host=Model::TARGETHOST, *arguments)
      super(*arguments)
      if host.instance_of?(String) && (host == Model::CLIENTHOST.name || host == Model::CLIENTHOST.to_s)|| 
         (host.instance_of?(Model::Host) && host.to_s == Model::CLIENTHOST.to_s)
        @runner = System.new(*arguments)
      else 
        @runner = StafSystem.new(host, *arguments)
      end  
    end
  end
  
  class RunCommandOnMta < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("mta").first)
      end
      super(*arguments)
    end
  end
  
  class RunCommandOnMailbox < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("mailbox").first)
      end
      super(*arguments)
    end
  end
  
  class RunCommandOnLdap < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("ldap").first)
      end
      super(*arguments)
    end
  end    
  
  class RunCommandOnProxy < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        # "imapproxy" - legacy service name up to Helix
        host = Model::Servers.getServersRunning("proxy").first || Model::Servers.getServersRunning("imapproxy").first
        arguments << Model::Host.new(host)
      end
      super(*arguments)
    end
  end
  
  class RunCommandOnMemcached < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("memcached").first)
      end
      super(*arguments)
    end
  end
  
  class RunCommandOnAntispam < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("antispam").first)
      end
      super(*arguments)
    end
  end
  
  class RunCommandOnAntivirus < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("antivirus").first)
      end
      super(*arguments)
    end
  end
  
  class RunCommandOnSpell < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("spell").first)
      end
      super(*arguments)
    end
  end
  
  class RunCommandOnConvertd < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("convertd").first)
      end
      super(*arguments)
    end
  end

  class RunCommandOnLogger < Action::RunCommand
    def initialize(*arguments)
      unless arguments.last.is_a?(Model::Host)
        arguments << Model::Host.new(Model::Servers.getServersRunning("logger").first)
      end
      super(*arguments)
    end
  end  
  
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMBackup object
    class RunCommandTest < Test::Unit::TestCase    
      def testRun         
        testObject = Action::RunCommand.new('ls','root')
        testObject.run 
        assert(testObject.exitstatus == 0)
      end 
      
      def testTimeout
        testObject = Action::RunCommand.new('ls','root')
        assert(testObject.timeOut == 60)
      end
    end
  end
end


 
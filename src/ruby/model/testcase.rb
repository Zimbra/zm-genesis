#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#
# This is testcase data model.  It contains information about a particular test case
# 
module Model
require "action/filedelta"

  class TestCase
  
    private_class_method :new
    @@current = nil
    attr_reader :setup, :action, :description, :teardown, :verify, :monitor, :skip
    attr_writer :setup, :action, :description, :teardown, :verify, :monitor, :skip    
    def TestCase.instance
      unless @@current
        @@current = new
        @@current.defaultSetup
      end       
      @@current
    end
    
    def initialize
      @setup = @action = @description = @teardown = @verify = @monitor = @skip = nil
    end
    
    def defaultSetup
      #@monitor = [Action::FileDelta.new,  Action::FileDelta.new('/var/log/mailbox.log')]
      # Action::FileDelta.new('/opt/zimbra/tomcat/logs/catalina.out')] #default monitor
      @monitor = []
    end
  end
end

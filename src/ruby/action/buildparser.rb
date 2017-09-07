#!/bin/env ruby
#
# = action/untar.rb
#
# Copyright (c) 2007 zimbra
#
# Written & maintained by Virgil Stamatoiu
#
# Documented by Virgil Stamatoiu
#
# Part of the command class structure.  This implements the build name parser
# 
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require 'singleton'
require 'action/command'
require 'action/clean'
 

module Action # :nodoc
  #
  #  Retrieve the build info of the latest build(from /opt/zimbra/.update_history).
  #
  class BuildParser < Action::RunCommand
    include Singleton
    attr :baseBuildId, false
    attr :targetBuildId, false
    attr :timestamp, false
    #
    # Objection creation
    # 
    def initialize(filename = '.update_history')
      super("cat", 'root', File.join(Command::ZIMBRAPATH,filename))
      @filename = filename
      @tokens = {}
      run
    end
     
    #
    # Execute  action
    # filename is stored inside @@filename at object initilization time 
    def run 
      begin
        iResult = super[1]    		 
        if(iResult =~ /Data\s+:/)
          iResult = (iResult)[/Data\s+:(.*?)\s*\}/m, 1]
        end     
    	#iResult = iResult.split.compact[0].split('|').slice(-1)[/\d{14}.*/]
    	iResult = iResult.split.compact[0].split('|')
    	@targetBuildId = iResult.slice(-1)
    	@timestamp = targetBuildId[/\d{14}.*/]
    	@baseBuildId = iResult.length == 1 ? @targetBuildId : iResult.slice(-2)
    	[0, iResult.join('|')]
	    rescue
	      [1, 'Unknown']
	    end
	  end
   
   def buildLabel()
     mObject = RunCommand.new('wget', 'root', '--no-proxy', '-O', '-',
                              "http://zre-matrix.eng.vmware.com/cgi-bin/build/builds.cgi?" + 
                              "branchSelect=" + @targetBuildId[/(.*)_#{@timestamp}/, 1].split('_').last +
                              "&archSelect=" + @targetBuildId[/zcs_(.*)_[^_]+_#{@timestamp}/, 1] +
                              "&typeSelect=" + @timestamp.split('_').last +
                              '&statusSelect=Released&oldSortBy=Build&sortBy=Build')
     mObject.timeOut = 300
     mResult = mObject.run
     iResult = mResult[1].split(/\n/).select {|w| w =~ /#{@timestamp}/}.select {|w| w =~ /#{@targetBuildId[/zcs_(.*)_[^_]+_#{@timestamp}/, 1]}</} rescue nil
     return '' if iResult.nil?
     # released  = logs</A></TD><TD NOWRAP COLSPAN=1>7.1.3_GA</TD><TD NOWRAP COLSPAN=1><A HREF
     # nreleased = logs</A></TD><TD NOWRAP COLSPAN=1>DAILY_DEBUG</TD>...
     #             logs</A></TD><TD NOWRAP COLSPAN=1>&nbsp</TD>...
     iResult.first[/logs<\/A><\/TD><[^>]+>([^<]+)/, 1] rescue ''
   end
    
    def to_str
      "Action:buildparser file:#{@filename}"
    end   
  end  
end
 
if $0 == __FILE__
  require 'test/unit'
  
  module Action  
    # Unit test cases for Untar
    class BuildParserTest < Test::Unit::TestCase
    
        # Basic execution"     
        def testRun()
          #testObject = Action::BuildParser.new(File::join('/tmp/history'))
          #testObject.run
          #testDir = "Cookies"        
          File.delete('/tmp/history')
          [0, 'TBD']
        end
        
        def testTOS
          testObject = Action::BuildParser.new
          puts testObject
        end        
          
    end
  end
end


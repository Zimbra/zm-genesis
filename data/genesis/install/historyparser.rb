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

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/zmprov"
require "action/buildparser"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = ".install_history parser"

#include Action 

module Action # :nodoc
class HistoryParser < Action::RunCommandOn
    attr :baseVersion, false
    attr :targetVersion, false
    attr :timestamp, false
    attr :id, false
    attr :doc, false
    attr :platform, 'false'
    #
    # Objection creation
    #
    def initialize(host = Model::TARGETHOST, filename = '.install_history')
      super(host, "cat", 'root', File.join(Command::ZIMBRAPATH,filename))
      @filename = filename
      @tokens = {}
    end
     
    #
    # Execute  action
    # filename is stored inside @@filename at object initilization time 
    def run
      mResult = super()
      begin         
        if mResult[1] =~ /Data\s+:/
          mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        @doc = mResult[1].split(/\n+/)
        iResult = Hash[*mResult[1].split(/\n/).select {|w| w =~ /\bzimbra-core(-|_).*/}.collect {|w| w.split(/\s+/).slice(1, 2)}.flatten]
        @baseVersion = iResult['INSTALLED'][/zimbra-core(-|_)(\d+(\.\d+){1,2}[^.]*)_\d+\./, 2]
        @targetVersion = iResult.has_key?('UPGRADED') ? iResult['UPGRADED'][/zimbra-core(-|_)(\d+(\.\d+){1,2}[^.]*)_\d+\./, 2] : @baseVersion
        @timestamp = (iResult.has_key?('UPGRADED') ? iResult['UPGRADED'] : iResult['INSTALLED'])[/(\d{14}).*/, 1]
        @id = mResult[1].split(/\n/).select {|w| w=~ /.*\s+zimbra-core.*/}[-1][/.*zimbra-core(-|_)(.*)\.[^.]+$/, 2]
        @platform = iResult['INSTALLED'][/.*zimbra-core.*_\d{3,}\.([^-]+)(-\d{14}\..*rpm|\.pkg|_[^.]+\.deb)/, 1]
        [0, iResult.values.join('|')]
      rescue
        [1, 'Unknown']
      end
    end    
    
    def isUpgrade
      @doc.select {|w| w =~ /\d+:\s+CONFIG SESSION COMPLETE/}.length > 1
    end
    
    def to_str
      "Action:HistoryParser file:#{@filename}"
    end   
  end

end
#
# Setup
#
current.setup = [
   
] 

#
# Execution
#


current.action = [

]
    	

#
# Tear Down
#
current.teardown = [         
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
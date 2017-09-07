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
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/runcommand"
require "action/verify"
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "mail server jars check"

include Action
include Model


#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#
current.action = [ 
  v(cb("zmailbox cache default") do
    DumpMaxCachedMessages = 
             "import com.zimbra.client.ZMailbox;\n" +
             "public class ZMailboxCheck {\n" +
             "  public static void main(String [] args) {\n" +
             "     System.out.println(\\\"MAX_NUM_CACHED_MESSAGES|\\\" + ZMailbox.MAX_NUM_CACHED_MESSAGES);\n" +
             "  };\n" +
             "}"
    mObject = RunCommand.new('echo', 'root', "-e", "\"#{DumpMaxCachedMessages}\" > /tmp/ZMailboxCheck.java")
    mResult = mObject.run
    mObject = RunCommand.new('cd /tmp; javac', 'zimbra', 
                             '-cp /opt/zimbra/lib/jars/zimbraclient.jar', 'ZMailboxCheck.java')
    mResult = mObject.run
    mObject = RunCommand.new('zmjava ', Command::ZIMBRAUSER, 
                             '-cp /tmp', 'ZMailboxCheck')
    mResult = mObject.run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && 
      data[1][/.*MAX_NUM_CACHED_MESSAGES\|(\d+)/m,1] == ZMLocal.new('zmailbox_message_cachesize').run
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'MAX_NUM_CACHED_MESSAGES' => {"IS" => data[1][/.*MAX_NUM_CACHED_MESSAGES\|(\d+)/m,1],
                                                       "SB" => ZMLocal.new('zmailbox_message_cachesize').run}}
    end
  end,
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
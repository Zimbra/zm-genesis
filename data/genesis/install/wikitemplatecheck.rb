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
require "fileutils" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Wiki templates test"

include Action 


expected = '5.0.33'
@suffix = "notdef"
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("Wiki templates check", 600) do
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','mysql'), Command::ZIMBRAUSER,
                              '--database=zimbra', '--skip-column-names',
                              '--execute="select name, path from volume"')
    #mResult = mObject.run
    iResult = mObject.run[1]    		 
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
    end
    storePath = iResult[/message.*\s+(\S+)$/, 1]
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin', 'zmprov'), Command::ZIMBRAUSER,
                             'gcf', 'zimbraNotebookAccount')
    iResult = mObject.run[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
    end
    wikiAccount = iResult[/zimbraNotebookAccount:\s+(\S+)$/, 1]
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','mysql'), Command::ZIMBRAUSER,
                              '--skip-column-names',
                              '--execute="show databases"')
    iResult = mObject.run[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
    end
    iResult = iResult.select {|w| w=~ /^\s*mboxgroup/}.collect {|y| y.strip()}
    mboxes = []
    iResult.each {
      |mbox|
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','mysql'), Command::ZIMBRAUSER,
                               "--skip-column-names",
                               "--database=#{mbox}",
                               '--execute="select mailbox_id, index_id, mod_metadata, name from mail_item where metadata regexp \"' +
                                "#{wikiAccount}\\\"" + "\"")
      iResult = mObject.run[1]
      mboxes += iResult.split("\n") if iResult != ''
    }
    mResult = []
    if mboxes.empty?
      mResult << ['wiki', "No templates found", "/opt/zimbra/wiki/Template/..."]
    else
      dbWikiTemplates = []
      mboxes.each do
        |line|
        (id, index, meta, name) = line.split(' ')
        t1 = storePath + '/0/' + id + '/msg/0/' + index + '-' + meta + '.msg'
        t2 = '/opt/zimbra/wiki/Template/' + name
        t2 += '.wiki' if name !~ /\.gif$/
        dbWikiTemplates << File.basename(t2)
        #puts "t1=#{t1}, t2=#{t2}." 
        begin
          if !FileUtils.cmp(t1, t2)
            mResult << [name, "old version", t2]
          end
        rescue
          mResult << [name, "error #{$!}", t2]
        end 
      end
      mObject = RunCommand.new('ls', Command::ZIMBRAUSER, '-1', '/opt/zimbra/wiki/Template')
      iResult = mObject.run[1]    		 
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      iResult = iResult.split("\n")
      if !(iResult - dbWikiTemplates).empty?
        (iResult - dbWikiTemplates).each { |y|
          mResult << [y, "Missing from DB", "/opt/zimbra/wiki/Template/#{y}"]
        }
      end
    end
    mResult
  end) do |mcaller, data|
    mcaller.pass = data.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Wiki templates check' => {}}
      data.each {|w|
        mcaller.badones['Wiki templates check'][w[0]] = {"IS"=>w[1], "SB"=>w[2]}
      }
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

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
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser"
require "#{mypath}/install/configparser"
require "#{mypath}/install/historyparser"
require "action/zmcontrol"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmcontrol test"

include Action 

(mCfg = ConfigParser.new).run

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  mCfg.getServersRunning('.*').map do |x|
    v(cb("zmcontrol check") do
      timestamp = BuildParser.instance.timestamp
      mObject = Action::RunCommand.new("/bin/cat", "root", "/tmp/install.out." + timestamp, Model::Host.new(x))
      mResult = mObject.run
      # retrieve the #of status requests
      mResult[1] = if RUBY_VERSION =~ /1\.8\.\d+/
                     require 'iconv'
                     Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(mResult[1])[/(((Host #{x}(\n\t[^\n]+)+)\n)+)/m, 1]
                   else
                     mObject.run[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''})
                   end
      mResult[1] = mResult[1][/(((Host #{x}(\n\t[^\n]+)+)\n)+)/m, 1].split(/\n/)
      mResult
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].select {|w| w =~ /Host/}.size == 1
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - zmcontrol status check' => {"IS" => data[1], "SB" => '1 status check'}}
      end
    end
  end,
  
  mCfg.getServersRunning('.*').map do |x|
    v(cb("package check") do
      expected = []
      mHost = mCfg.doc.get_elements('//host').select {|w| w.attributes['name'] == x || w.elements['zimbrahost'].attributes['name'] == x}.first rescue nil
      next [1, expected, expected] if mHost.nil? #Shouldn't get here
      mHost.each_element("package") {|e| expected << e.attributes['name'][/zimbra-(.*)/, 1]}
      (history = HistoryParser.new(Model::Host.new(x))).run
      expected << 'antispam' if expected.include?('mta')
      expected << 'antivirus' if expected.include?('mta') && !history.isUpgrade()
      mResult = ZMControl.new('status', Model::Host.new(x)).run
      res = mResult[1].split(/\n/).collect {|w| w.chomp.strip.split()}
      [0, expected, res]
    end) do |mcaller, data|
      #for now always add antispam and antivirus only on installations
      #(history = HistoryParser.new(Model::Host.new(x))).run
      #data[1] << 'antispam'
      #data[1] << 'antivirus' if !history.isUpgrade()
      aliases = {'store' => 'mailbox',
                 'proxy' => 'imapproxy'}
      aliases.default='none'
      errs = data[1].select do |w|
               w !~ /(apache|cluster)/
             end.select do |w|
               (w !~ /(convertd|archiving)/) or (BuildParser.instance.targetBuildId !~ /_FOSS/i)
             end.select do |w|
               !(data[2].include?([w, 'Running']) || data[2].include?([aliases[w], 'Running']))
             end
      mcaller.pass = data[0] == 0 && errs.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        diffs = {}
        errs.each do |w|
          key = aliases.has_key?(w) ? aliases[w] : w
          if data[2].flatten.include?(key)
            msg = data[2].select {|s| s[0] == key}.collect {|s| s[1]}.first
          else
            msg = 'missing'
          end
          diffs[key] = {"SB"=>'Running', "IS"=>msg}
        end
        mcaller.badones = {x + ' - package check' => diffs}
      end
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
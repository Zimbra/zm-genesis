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
require "action/zmprov"
require "action/zmlocalconfig"
require "#{mypath}/install/configparser"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()

include Action 

(mCfg = ConfigParser.new).run
webserver = ZMLocal.new('mailboxd_server').run
webserver = RunCommandOn.new(mCfg.getServersRunning('store').first, File.join(Command::ZIMBRAPATH,'bin', 'zmlocalconfig'), Command::ZIMBRAUSER,
                             '-m', 'nokey', 'mailboxd_server').run[1].chomp
current.description = "#{webserver}.xml test"

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  mCfg.getServersRunning('store').map do |x|
  [
    v(cb("#{webserver}.xml test") do
      data = RunCommandOn.new(x, "/bin/cat", "root", File.join(Command::ZIMBRAPATH, webserver, "etc", webserver + '.xml')).run
      result = data[1]
      doc = Document.new result.slice(result.index('<?xml version'), result.index('</Configure>') - result.index('<?xml version') + '</Configure>'.length)
      res = {}
      exitCode = 1
      doc.root.elements.each('New') do |e|
        next if e.attributes['class'] != 'org.eclipse.jetty.util.ssl.SslContextFactory'
        exitCode = 0
        id = e.attributes['id']
        res[id] = {}
        e.elements.each do |param|
          res[id].merge!({param.attributes['name'] => param.text}) if !param.has_elements?
          next if param.elements['Array'].nil?
          val = []
          param.elements.each('Array/Item') {|w| val.push(w.text)}
          res[id].merge!({param.attributes['name'] => val})
        end
      end
      [exitCode, res]
    end) do |mcaller, data|
      #mObject = ZMProv.new('gcf', 'zimbraSSLExcludeCipherSuites')
      mObject = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin', 'zmprov'), Command::ZIMBRAUSER,
                                 'gcf', 'zimbraSSLExcludeCipherSuites')
      mResult = mObject.run
      expected = mResult[1].split(/\n/).select {|w| w=~ /zimbraSSLExcludeCipherSuites:/}.collect {|w| w[/zimbraSSLExcludeCipherSuites:\s+(\S+)/, 1]}
      mcaller.pass = data[0] == 0 && 
                     data[1].keys.select {|k| !data[1][k].has_key?('ExcludeCipherSuites')}.empty? &&
                     data[1].keys.select {|k| data[1][k]['ExcludeCipherSuites'].sort != expected.sort}.empty? &&
                     data[1].keys.select {|k| data[1][k].has_key?('allowRenegotiate')}.empty?
    end,
  ]
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
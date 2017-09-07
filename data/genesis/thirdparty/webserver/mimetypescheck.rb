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
require "#{mypath}/install/configparser"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Mime types test"

include Action 


expected = {'dmg' => 'application/octet-stream',
           }

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
  mCfg.getServersRunning('store').map do  |x|
    v(RunCommand.new("/bin/cat", "root", f = File.join(Command::ZIMBRAPATH, "jetty", "etc", "webdefault.xml"), Model::Host.new(x))) do |mcaller, data|
        result = data[1]
        startIndex = -1
        endIndex = -1
        index = 0
        result.split(/\n/).each {|line|
          if line[/<?xml version/]
            startIndex = index
          elsif line[/<\/web-app>/]
            endIndex = index + 1
            break
          end
          index += 1
        }
        doc = Document.new result.slice(result.index('<?xml version'), result.index('</web-app>') - result.index('<?xml version') + '</web-app>'.length)
        reality = {}
        doc.elements.each("/web-app/mime-mapping") {
          |mimeType|
          extension = mimeType.elements["extension"].text
          type = mimeType.elements["mime-type"].text
          reality[extension] = type #if expected.has_key?(extension)
        }
        mcaller.pass = data[0] == 0 && expected.keys.select {|w|  expected[w] != reality[w]}.empty?
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.suppressDump("Suppressed - #{f} can be very large") 
          msgs = {}
          expected.keys.each do |extension| 
            v = reality.has_key?(extension) ? reality[extension] : "Missing"
            msgs[extension] = {"IS"=>"#{v}", "SB"=>"#{expected[extension]}"}
          end
          mcaller.badones = {x + ' - mime types check' => msgs}
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
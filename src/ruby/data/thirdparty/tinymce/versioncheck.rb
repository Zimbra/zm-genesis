#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2014 Zimbra, Inc.
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "tinymce version test"

include Action 

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(RunCommand.new('cat', Command::ZIMBRAUSER,
                   File.join(Command::ZIMBRAPATH, 'jetty', 'webapps', 'zimbra', 'js', 'ajax', '3rdparty', 'tinymce', 'tinymce.js'))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].split(/\n/).first[/\/\/\s+(\S+)\s/, 1] == OSL::LegalApproved['tinymce']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'tinymce version' => {"IS" => data[1].split(/\n/).first, "SB" => OSL::LegalApproved['tinymce']}}
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

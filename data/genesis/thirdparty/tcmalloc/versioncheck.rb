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
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "tcmalloc version test"

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

  v(RunCommand.new(File.join( 'strings ' , Command::ZIMBRACOMMON, 'lib/libtcmalloc_minimal.so'),
                        Command::ZIMBRAUSER, '| grep gperftools')) do |mcaller, data|
      result = data[1][/gperftools(\s+\d+.*)/,1]
        mResult = result.strip
#puts data[1][/.*\s(\d.\d)/]

      mcaller.pass = data[0] == 0 && mResult == OSL::LegalApproved['gperftools']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'tcmalloc version' => {"IS" => mResult, "SB" => OSL::LegalApproved['gperftools']}}
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

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
require "action/buildparser"
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Java version test"

include Action


#expected = {'MACOSX' => '1.6.0_([12][6-9])',
#            'other' => Model::TARGETHOST.architecture == 11 ? '1.6.0_33' : '1.7.0_11'}
#
# Setup
#
current.setup = [

]
#
# Execution
#

 current.action = [

  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmjava'),
                            Command::ZIMBRAUSER,'-version', '2>&1')) do |mcaller, data|
    #result = data[1].split(/\n/).select {|w| w =~ /(java|openjdk) version/}[0].chomp.split(/\"/)[-1]
    result = data[1][/OpenJDK Runtime Environment \(build ([^\)]+)\)/, 1]
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      id = 'MACOSX'
    else
      id = 'other'
    end
    mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['openjdk'] || ['1.8.0_74-zimbra-b02']

    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'java version' => {"IS" => result, "SB" => OSL::LegalApproved['openjdk']}}
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

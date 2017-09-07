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
require "action/runcommand" 


module Action # :nodoc
  
  class ZMLocalconfig < Action::RunCommand

  #
  #  Create a zmlocalconfig object.
  #

    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmlocalconfig'), ZIMBRAUSER, *arguments)
    end
  end

  class ZMLocal < Action::RunCommand

    #
    #  Create a zmlocalconfig object.
    #

    def initialize(*arguments)
      host = nil
      if arguments[0].kind_of? Model::Host
        host = arguments.shift
      else
        host = Model::TARGETHOST
      end
      super(File.join(ZIMBRAPATH,'bin','zmlocalconfig'), ZIMBRAUSER, '-s', '-m', 'nokey', *arguments.push(host))
    end

    def run
      data = super
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      iResult.chomp
    end
  end
  
end


if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
    # Unit test cases for Proxy
    class ZMLocalTest < Test::Unit::TestCase     
      def testNoArgument 
        testOne = ZMLocal.new('testme')
        assert(testOne.to_str =~ /\/opt\/zimbra\/bin\/zmlocalconfig -m nokey testme/)
      end      
    end   
end
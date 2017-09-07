#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#

#
# Test basic zmpython command
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end
require "action/command"
require "action/verify"
require "action/zmpython"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmpython"

jython_version = '2.5.2'
#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [

  v(ZMPython.new('-h')) do |mcaller,data|
    usage =  [Regexp.escape('usage: jython [option] ... [-c cmd | -m mod | file | -] [arg] ...'),
              Regexp.escape('Options and arguments:'),
              Regexp.escape('-c cmd   : program passed in as string (terminates option list)'),
              Regexp.escape("Dprop=v : Set the property `prop' to value `v'"),
              Regexp.escape('-C codec : Use a different codec when reading from the console.'),
              Regexp.escape('-h       : print this help message and exit (also --help)'),
              Regexp.escape('-i       : inspect interactively after running script'),
              Regexp.escape('           and force prompts, even if stdin does not appear to be a terminal'),
              Regexp.escape('-jar jar : program read from __run__.py in jar file'),
              Regexp.escape('-m mod   : run library module as a script (terminates option list)'),
              Regexp.escape('-Q arg   : division options: -Qold (default), -Qwarn, -Qwarnall, -Qnew'),
              Regexp.escape("-S       : don't imply 'import site' on initialization"),
              Regexp.escape('-u       : unbuffered binary stdout and stderr'),
              Regexp.escape('-v       : verbose (trace import statements)'),
              Regexp.escape('-V       : print the Python version number and exit (also --version)'),
              Regexp.escape('-W arg   : warning control (arg is action:message:category:module:lineno)'),
              Regexp.escape('file     : program read from script file'),
              Regexp.escape('-        : program read from stdin (default; interactive mode if a tty)'),
              Regexp.escape('arg ...  : arguments passed to program in sys.argv[1:]'),
              Regexp.escape('Other environment variables:'),
              Regexp.escape("JYTHONPATH: ':'-separated list of directories prefixed to the default module"),
              Regexp.escape('            search path.  The result is sys.path.'),
             ]
    mcaller.pass = data[0] == 0 &&
                   (lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}).size == usage.size &&
                   lines.select {|w| w !~ /#{usage.join('|')}/}.empty?
  end,
  
  v(ZMPython.new('-V')) do |mcaller,data|
    result = data[1][/Jython\s(\d.*)+/,1]
	mcaller.pass = (data[0] == 0 && result == jython_version)
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Jython version' => {"IS"=>result, "SB"=>jython_version}}
    end
  end,
  
  v(ZMPython.new('-c',"\"import tempfile;print tempfile.gettempdir()\"")) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('/tmp')
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

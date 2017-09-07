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
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
require 'model/testbed'

module Action # :nodoc

  STAF = if(not (RUBY_PLATFORM =~ /win32/ || RUBY_PLATFORM =~ /mingw32/ ))
    #ENV['DYLD_LIBRARY_PATH']='/usr/local/lib:/usr/lib:/usr/local/staf/lib:/Library/staf/lib'
    File.join('/usr','local','staf','bin','staf')
    #File.join('/Library','staf','bin','STAF')
  else
    File.join('C:','STAF','bin','staf')
    #File.join('C:','devtools','STAF','bin','STAF')
  end

  class StafSystem < Action::Command
    @@hostHash = Hash.new

    #
    #  Create a System object.
    #
    attr_reader :response, :exitstatus

    def initialize(targetHost, programName, context = nil, *arguments)
      super()
      @encoding = nil
      @arguments = arguments.delete_if {|w| @encoding = w if w.kind_of? Encoding}
      @programName = programName
      @context = context || Command::ZIMBRAUSER
      @response = nil
      @exitstatus = 0
      @su = nil
      @targethost = targetHost || Model::TARGETHOST

      if(@@hostHash.key?(@targethost))
        platform = @@hostHash[@targethost]
      else
        platform = `#{Action::STAF} #{@targethost} var get system var STAF/Config/OS/Name`
        @@hostHash[@targethost] = platform
      end

      if(not (platform =~ /^win/i))
        @su = "#{Action::STAF} #{@targethost} PROCESS START SHELL COMMAND "+
              "\"/bin/su - #{@context} -c "
      else
        @su = "#{Action::STAF} #{@targethost} PROCESS START SHELL COMMAND \""
      end
    end

    #
    #  Perform execution
    #
    def run
      processed_arg = @arguments.map do |x|
        if( (x.class == Proc) || (x.class == Method))
          x.call
        else
          x
        end
      end.map do |y|
        begin
          y.gsub!(/\\/) { |s| '\\\\'}
          y.gsub!(/"/) { |s| '\\'+s }
          y.gsub(/(\{)/) { |s| '^'+s}
        rescue
          y
        end
      end

      commandLine = @su + "'#{@programName} #{processed_arg.join(' ')}'\""+
        " WAIT RETURNSTDOUT RETURNSTDERR"
      puts commandLine if $DEBUG
      f = IO.popen(commandLine)
      result = f.read
      f.close_read
      begin
        resultA = parseData(result)
      rescue
        resultA = [nil, nil]
      end
      @exitstatus = getReturnCode(result).to_i
      #@response = result
      @response = getReturnData(resultA[0])
      [@exitstatus, @response, getReturnData(resultA[1])]
    end

    def parseData(data)
      return nil if data.nil?
      result = @encoding.nil? ? data: data.force_encoding(@encoding)
      begin
        result = data[/Files\s+:\s+\[\s+(.*\})\s+\]\s+\}/m,1].split(/\s*\}\s+\{\s+/m)
      rescue
        puts YAML.dump(data)
        puts "======"
        puts YAML.dump(data[/Files.*?\[(.*?)^\s+\]\n/m, 1])
        puts "======"
        puts YAML.dump(data[/Files.*?\[(.*?)^\s+\]\n/m, 1][/\{(.*)\}/m,1])
      end
      return result
    end

    def getReturnCode(data)
      return nil if data.nil?
      return data[/Return Code:\s+(.*?)\s/m,1]
    end

    def getReturnData(data)
      return "" if data.nil?
      return data[/Data\s+:\s*(.*)/m,1]
      #return data[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end

    def to_str
      processed_arg = @arguments.map { |x|
        if( (x.class == Proc) || (x.class == Method))
          x.call
        else
          x
        end
      }
      "Action:#{@programName} #{processed_arg.join(' ')}"
    end

    def to_s
      to_str
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  module Action
    #
    # Unit test case for GetBuild object
    class SystemTest < Test::Unit::TestCase

      def testTimeOut
        testObject = Action::StafSystem.new(Model::TARGETHOST, '/opt/zimbra/bin/zmcontrol','zimbra','status')
        puts testObject.timeOut
      end
      def testCreate
        testObject = Action::StafSystem.new(Model::TARGETHOST, '/opt/zimbra/bin/zmcontrol','zimbra','status')
        testObject.run
      end

      def testParse
        testObject = Action::StafSystem.new(Model::TARGETHOST, '/opt/zimbra/bin/zmcontrol','zimbra','status')
        data = <<DATA
Response
--------
{
  Return Code: 0
  Key        : <None>
  Files      : [
    {
      Return Code: 0
      Data       : Host qa04.lab.zimbra.com
	antispam                Running
	antivirus               Running
	ldap                    Running
	logger                  Running
	mailbox                 Running
	mta                     Running
	spell                   Running

    }
    {
      Return Code: 0
      Data       : weird
    }
  ]
}
DATA
        puts YAML.dump(testObject.parseData(data))
#        puts testObject.getReturnCode(resultA[0])
#        puts testObject.getReturnData(resultA[0])
      end
    end
  end
end



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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "xerces xml version test"

include Action 


class FileExtractor < Action::Command
  attr :archive, false
  attr :file, false
  attr :tmpdir, false
  #
  # Objection creation
  # 
  def initialize(filename = File.join('lib', 'jars', 'lucene*.jar'))
    super()
    @file = ''
    @archive = filename
    @tmpdir = '/tmp/tmpextr'
  end
   
  #
  # Execute  action
  # filename is stored inside @archive at object initilization time 
  def run 
    begin
      mResult = RunCommand.new('/bin/ls', Command::ZIMBRAUSER, @archive).run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
      end
      mResult[1] = mResult[1].strip.chomp
      return mResult if mResult[0] != 0
      crtArchive = mResult[1]
      mResult = RunCommand.new("mkdir -p #{@tmpdir}; cd #{@tmpdir}; ", Command::ZIMBRAUSER, 'jar','-xvf', 
                               File.join(Command::ZIMBRAPATH, crtArchive), @file).run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
      end
      if mResult[1] == nil
        mResult[0] += 1 
        mResult[1] = "File #{@file} missing from archive #{@archive}[#{crtArchive}]"
      end
      if mResult[0] != 0
        RunCommand.new('/bin/rm', Command::ZIMBRAUSER, '-rf', @tmpdir).run
        return mResult 
      end
      mResult[1] = mResult[1].strip.chomp
      result = extract() 
      mResult = RunCommand.new('/bin/rm', Command::ZIMBRAUSER, '-rf', @tmpdir).run
      [0, result]
    rescue
      [1, 'Unknown']
    end
  end
  
  def extract()
    mResult = RunCommand.new("cd #{@tmpdir}; /bin/cat", Command::ZIMBRAUSER, @file).run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    mResult[1] = mResult[1].strip.chomp
    return mResult[1]
  end
  
  def to_str
    "Action:FileExtractor archive:#{@archive}, version file:#{@file}"
  end   
end

class StringExtractor < FileExtractor

  def initialize(pattern)
    super(File.join('lib', 'jars', 'xercesImp*.jar'))
    @file = 'org/apache/xerces/impl/XMLScanner.class'
    @archive = File.join('lib', 'jars', 'xercesImp*.jar')
    @pattern = pattern
  end
  
  def extract()
    mResult = RunCommand.new("cd #{@tmpdir}; /usr/bin/strings", Command::ZIMBRAUSER, '-', @file).run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    mResult[1] = mResult[1].strip.chomp
    return mResult[1][/#{@pattern}/]
  end
end

expected = '2.9.1'
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zmjava'), Command::ZIMBRAUSER,
                   'org.apache.xerces.impl.Version')) do |mcaller, data|
    result = data[1][/Xerces-J\s+([^\s]+).*/, 1]
    mcaller.pass = data[0] == 0 && result =~ /#{expected}/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'xerces version' => {"IS"=>result, "SB"=>expected}}
    end
  end,
  
  v(cb("XMLScanner patch check") do
    mObject = StringExtractor.new('InvalidCharInSystemID')
    mResult = mObject.run
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] != nil
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'XMLScanner patch check' => {"SB" => 'InvalidCharInSystemID found',
                                                      "IS" => "exit code #{data[0]}, pattern match #{data[1] == nil ? 'none' : data[1]}"}}
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
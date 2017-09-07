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
# check that sleepycat is in Perl BDB run path
# find /opt/zimbra/zimbramon/ -name "Berkeley*.so" -print -exec ldd '{}' \; | grep sleepycat

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
current.description = "Perl run path test"

include Action 

mArchitecture = BuildParser.instance.targetBuildId[/zcs_([^_]+(_64)?)_/, 1]
expected = Regexp.new(".*/opt/zimbra/common/lib/libdb-..*")
extension = '.so'
cmd = 'ldd'


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

=begin
current.action = [       
  
  v(cb("BDB runpath test") do 
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      extension = '.bundle'
      cmd = 'otool -L'
    end
    mObject = RunCommand.new('find', Command::ZIMBRAUSER, File.join(Command::ZIMBRAPATH,'zimbramon'),
                             '-name', "BerkeleyDB*#{extension}", '-print', '|',
                             'xargs', cmd)
    result = mObject.run[1]
    if !result.split(/\n/).select {|w| w =~ /.*#{expected}.*/}.empty?
      [0, expected]
    else
      mObject = RunCommand.new('find', Command::ZIMBRAUSER, File.join(Command::ZIMBRAPATH,'zimbramon'),
                               '-name', "BerkeleyDB*#{extension}", '-print')
      iResult = mObject.run[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      if iResult.empty?
        [1, ["BerkeleyDB*#{extension}", "Not found", "Found"]]
      else
        lib = iResult
        mObject = RunCommand.new(cmd, Command::ZIMBRAUSER, lib)
        iResult = mObject.run[1]
        if(iResult =~ /Data\s+:/)
          iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
        end
        if iResult.split(/\n/).select {|w| w =~ /.*#{expected}.*/}.empty?
          [1, ["#{cmd} #{lib}", iResult, ".*#{expected}.*"]]
        end
      end
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'BDB run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
    end
  end,
  
  v(cb("zimbramon runpath test") do 
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      extension = '.bundle'
      cmd = 'otool -L'
    end
    except = ['SSLeay', 'DB_File', 'BerkeleyDB', 'RSA', 'LDAPapi', 'Random']
    libPath = File.join(Command::ZIMBRAPATH,'zimbramon', 'lib')
    mObject = RunCommand.new('find', Command::ZIMBRAUSER, libPath,
                             '-name', "\"*#{extension}\"",
                             "-a -path \"*auto*\"",
                             '-print')
    iResult = mObject.run[1]
    next([1, {"find *#{extension} in #{libPath}" => ['No perl precompiled libs found', 'Existing libs']}]) if iResult.split(/\n/).select {|w| w =~ /.*#{Regexp.compile(libPath)}.*/}.empty?
    expected = %r/#{Command::ZIMBRAPATH}(#{File::SEPARATOR}(mariadb|openssl|zeromq)(-[^\/]+)*)?#{File::SEPARATOR}lib#{File::SEPARATOR}.*/
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
    end
    exitCode = 0
    res = {}
    libs = iResult.split(/\n/).select {|w| w=~ /#{Regexp.compile(Command::ZIMBRAPATH)}/}.collect {|w| w.chomp.strip}
    #libs = ['/opt/zimbra/zimbramon/lib/darwin-thread-multi-2level/auto/Digest/SHA1/SHA1.bundle']
    libs.each do |lib|
      next if !except.select {|w| lib =~ /#{w}/}.empty?
      mObject = RunCommand.new(cmd, Command::ZIMBRAUSER, lib)
      iResult = mObject.run[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      iResult = iResult.split(/\n/).select {|w| w !~ /#{Regexp.compile(lib)}/}
      next if (iResult = iResult.select {|w| w =~ /#{Regexp.compile(Command::ZIMBRAPATH)}/}).empty?
      next if iResult.select {|w| w !~ /#{expected}/}.empty?
      exitCode += 1
      res[lib] = [iResult.select {|w| w !~ /#{expected}/}.collect {|w| w.chomp.strip}.join(" "), expected.source]
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      messages = {}
      data[1].each_pair do |k,v|
        messages[k] = {"IS"=>v[0], "SB" => v[1]}
      end
      mcaller.badones = {'zimbramon run path test' => messages}
    end
  end,
]
=end


=begin
 current.action = [

  v(cb("BerkeleyDB runpath test") do
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      extension = '.dylib'
      cmd = 'otool -L'
    end
    mObject = RunCommand.new(cmd, Command::ZIMBRAUSER,
                             File.join(Command::ZIMBRACOMMON,'lib', 'perl5', 'x86_64-linux-gnu-thread-multi', 'auto', 'BerkeleyDB', "BerkeleyDB#{extension}"))
    mResult = mObject.run[1]
#puts mResult
    if !mResult.split(/\n/).select {|w| w =~ /\s*#{expected}\s+.*/}.empty?
      [0, mResult[/\s*#{expected}\s+.*/]]
    else
      if(mResult =~ /Data\s+:/)
        mResult = (mResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      [1, ["ldd " + File.join(Command::ZIMBRACOMMON,'lib', 'perl5', 'x86_64-linux-gnu-thread-multi', 'auto', 'BerkeleyDB', "BerkeleyDB#{extension}"),
           mResult[/.*libdb-..*$/], expected.source]]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'BerkeleyDB run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
    end
  end,

 ]
=end


current.action = [

  v(cb("BerkeleyDB runpath test") do

    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      extension = '.dylib'
      cmd = 'otool -L'
    end
if mArchitecture =~ /UBUNTU/

    mObject = RunCommand.new(cmd, Command::ZIMBRAUSER,
                             File.join(Command::ZIMBRACOMMON,'lib', 'perl5', 'x86_64-linux-gnu-thread-multi', 'auto', 'BerkeleyDB', "BerkeleyDB#{extension}"))
    mResult = mObject.run[1]
    if !mResult.split(/\n/).select {|w| w =~ /\s*#{expected}\s+.*/}.empty?
      [0, mResult[/\s*#{expected}\s+.*/]]
    else
      if(mResult =~ /Data\s+:/)
        mResult = (mResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      [1, ["ldd " + File.join(Command::ZIMBRACOMMON,'lib', 'perl5', 'x86_64-linux-gnu-thread-multi', 'auto', 'BerkeleyDB', "BerkeleyDB#{extension}"),
           mResult[/.*libdb-..*$/], expected.source]]
    end

else
  mObject = RunCommand.new(cmd, Command::ZIMBRAUSER,
                             File.join(Command::ZIMBRACOMMON,'lib', 'perl5', 'x86_64-linux-thread-multi', 'auto', 'BerkeleyDB', "BerkeleyDB#{extension}"))
    mResult = mObject.run[1]
    if !mResult.split(/\n/).select {|w| w =~ /\s*#{expected}\s+.*/}.empty?
      [0, mResult[/\s*#{expected}\s+.*/]]
    else
      if(mResult =~ /Data\s+:/)
        mResult = (mResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      [1, ["ldd " + File.join(Command::ZIMBRACOMMON,'lib', 'perl5', 'x86_64-linux-gnu-thread-multi', 'auto', 'BerkeleyDB', "BerkeleyDB#{extension}"),
           mResult[/.*libdb-..*$/], expected.source]]
    end




end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'BerkeleyDB run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
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
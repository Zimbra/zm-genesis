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
require "action/zmsoap"
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Open source licenses test"

soapServer = ZMProv.new('gas', 'mailbox').run[1].split(/\n/).first
expectedVer = ZMSoap.new('-z', '-t', 'admin', '-u', "https://#{soapServer}:7071/service/admin/soap", 'GetVersionInfoRequest').run[1][/\bversion=\W(.*)\D\d+\.(NETWORK|FOSS)/, 1]
expectedVer.gsub!(/_BETA\d+/,' GA')

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
  v(RunCommand.new("/bin/ls", "root", "-1", File::join(Command::ZIMBRAPATH, 'docs', 'open_source_license*.txt'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).size == 2
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'open_source_license*.txt' => {"SB" => "2", "IS" => data[1].split(/\n/).join(', ')}}
    end
  end,
  
  v(RunCommand.new("cat", "root", File::join(Command::ZIMBRAPATH, 'docs', 'open_source_licenses.txt'), Encoding::UTF_8)) do |mcaller, data|
    #data[1] = if RUBY_VERSION =~ /1\.8\.\d+/
    #            require 'iconv'
    #            Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(data[1])
    #          else
    #            data[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '??'})
    #          end
    mcaller.pass = data[0] == 0 && !(legal = data[1][/^Zimbra Collaboration Suite\s+(.*)\n/, 1]).nil? &&
                   legal =~ /\d+(\.\d+){2}(\s+|_)GA/ && expectedVer == legal
                   
                   #&& #=~ /#{legal.gsub(/\s+/, '_')}/ &&
                   #!(tags = data[1].split(/\n/).select {|w| w =~ /^\s*>>>\s+/}.select {|w| w !~ /License/i}).empty? &&
                   #(versions = tags.collect {|w| w[/\s*>>>\s+(\S+)/, 1]}).size == versions.uniq.size * 2
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
      mcaller.badones = {'open_source_licenses.txt mismatch' => {"SB" => "open_source_licenses.txt, version #{expectedVer}", "IS" => data[1].split(/\n/)[0..5]}}
    end
  end,
  
  v(RunCommand.new("cat", "root", File::join(Command::ZIMBRAPATH, 'docs', 'open_source_licenses_zcs-windows.txt'), Encoding::UTF_8)) do |mcaller, data|
    #data[1] = if RUBY_VERSION =~ /1\.8\.\d+/
    #            require 'iconv'
    #            Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(data[1])
    #          else
    #            data[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '??'})
    #          end
    mcaller.pass = data[0] == 0 && !(legal = data[1][/^Zimbra Windows Components\s+([^\n]+)$/, 1]).nil? &&
                   legal =~ /\d+(\.\d+){2}\s+GA/ && expectedVer =~ /#{legal[/(\S+)/, 1]}/ &&
                   !(tags = data[1].split(/\n/).select {|w| w =~ /^\s*>>>\s+/}.select {|w| w !~ /License/i}).empty? &&
                   (versions = tags.collect {|w| w[/\s*>>>\s+(\S+)/, 1]}).size == versions.uniq.size * 2
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
      mcaller.badones = {'open_source_license_zcs-windows.txt mismatch' => {"SB" => "open_source_license_zcs-windows.txt, version #{expectedVer}", "IS" => data[1].split(/\n/)[0..5]}}
    end
  end,
  
  ['.uninstall', ''].map do |x|
    v(cb("ASCII test") do
      mResult = RunCommand.new('find', 'root', File.join(Command::ZIMBRAPATH, x, 'docs'),
                               "\\( -name \"*license*.txt\" -or -name \"*eula*.txt\" \\)", '-print', '|xargs', 'grep', "--color='auto'", '-P', '-n', '"[\x80-\xFF]"', Encoding::UTF_8).run
    end) do |mcaller, data|
      #data[1] = if RUBY_VERSION =~ /1\.8\.\d+/
      #            require 'iconv'
      #            Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(data[1])
      #          else
      #            data[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '??'})
      #          end
      mcaller.pass = data[0] != 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'ASCII check' => {"SB" => "ASCII only", "IS" => data[1]}}
      end
    end
  end,
  
  RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, 'docs', '*PL.txt')).run[1].split(/\n/).map do |x|
    v(cb("ASCII test") do
      mResult = RunCommand.new('grep', 'root', "--color='auto'", '-P', '-n', '"[\x80-\xFF]"', Encoding::UTF_8, x).run
    end) do |mcaller, data|
      #data[1] = if RUBY_VERSION =~ /1\.8\.\d+/
      #            require 'iconv'
      #            Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(data[1])
      #          else
      #            data[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '??'})
      #          end
      mcaller.pass = data[0] != 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' ASCII check' => {"SB" => "ASCII only", "IS" => data[1]}}
      end
    end
  end,

  OSL::LegalApproved.keys.map do |x|
    v(OSLHelper.licenseValidation(x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == true
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {"#{x} check" => {"SB" => OSL::LegalApproved[x], "IS" => data[2]}}
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
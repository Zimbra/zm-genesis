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
require "action/oslicense.rb"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "nginx basic test"

include Action 


options = ['--http-log-path',
           '--error-log-path',
           '--http-client-body-temp-path',
           '--http-proxy-temp-path',
           '--http-fastcgi-temp-path']
skipIt = true

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("nginx config test") do
    mObject = ConfigParser.new()
    mResult = mObject.run
    hasPackage = begin
      mObject.isPackageInstalled('zimbra-proxy')
    rescue
      false
    end
    next [1, skipIt] if !hasPackage
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'common', 'sbin', 'nginx'),
                   Command::ZIMBRAUSER,'-V')
    mResult = mObject.run
  end) do |mcaller, data|
    verExtractor = %r/nginx version:\s+nginx\/(\S+)/
    pathMatcher = %r/#{Command::ZIMBRAPATH}#{File::SEPARATOR}(log|data#{File::SEPARATOR}tmp).*/
    res = Hash[*data[1][/configure arguments:\s+(.*)/, 1].split().select{|w| w =~ /\S+=\S+/}.collect {|w| w.split(/\s*=\s*/)}.flatten] if data[0] == 0
    mcaller.pass = data[0] == 0 && data[1][/#{verExtractor}/, 1] == OSL::LegalApproved['nginx'] &&
                   options.collect {|w| (!res.has_key?(w) || res[w] !~ /#{pathMatcher}/) ? '1' : ''}.join(" ").strip == ''
    mcaller.pass = true if data[1] == skipIt
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msg = if data[0] != 0
              {File.join(Command::ZIMBRAPATH,'nginx', 'sbin', 'nginx') + " -V exit code" => {"IS"=>data[0], "SB"=>'Success'}}
            else
              ver = data[1][/#{verExtractor}/, 1]
              mres = {}
              if ver != OSL::LegalApproved['nginx']
                mres['nginx version'] = {"IS"=>ver, "SB"=>OSL::LegalApproved['nginx']}
              end
              options.collect do |w|
                if !res.has_key?(w)
                  mres[w] = {"IS"=> 'Missing', "SB" => pathMatcher.source}
                else
                  mres[w] = {"IS" => res[w], "SB" => pathMatcher.source} if res[w] !~ /#{pathMatcher}/
                end
              end
              mres
            end
      mcaller.badones = {'nginx config check' => msg.reject {|k, v| !v}}
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

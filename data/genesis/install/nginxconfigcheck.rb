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
require "action/zmprov"
require "action/buildparser"
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "nginx config check"

include Action 

 

#
# Setup
#
current.setup = [
   
] 

expected = {
            'zimbraReverseProxyLookupTarget' => 'FALSE'
            }
sexpected = {}

extension = 'so'
hasProxySomewhere = false
pcrePat = Regexp.new(%r/.*libpcre\.#{extension}\.\d+ => .*\/libpcre\.#{extension}\.\d+.*/)
cmd = 'ldd'
#
# Execution
#

current.action = [
  v(cb("server config check") do
    
    exitCode = 0
    res = {}
    
    #Find out if proxy is installed somewhere 
    mObject = ZMProv.new('gas', 'imapproxy')
    data = mObject.run
    if(data[1] =~ /Data\s+:/)
        data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    hasProxySomewhere = !data[1].nil? && !data[1][/\W+/m].nil?
    mObject = ZMProv.new('gas')
    data = mObject.run
    if(data[1] =~ /Data\s+:/)
        data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    data[1].split(/\n/).collect {|line| line.split(/:\s+/)[-1].chomp}.each do |server|
      sexpected[server] = expected.dup
      sexpected[server]['zimbraReverseProxyLookupTarget'] = 'FALSE'
      mObject = ZMProv.new('gs', server)
      data = mObject.run
      exitCode += data[0]
      if(data[1] =~ /Data\s+:/)
        data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      # Verification logic
      # a) if the system is mailstore and if there is proxy enabled anywhere in the system, it is a lookup target
      # b) false otherwise
      #expected['zimbraReverseProxyLookupTarget'] = 'TRUE' if (data[1] =~ /\s*zimbraServiceEnabled:\s+mailbox.*/ && hasProxySomewhere) 
      #### b is not true anymore, on single node with mbs, is TRUE regardless of proxy being enabled somewhere

      sexpected[server]['zimbraReverseProxyLookupTarget'] = 'TRUE' if data[1] =~ /\s*zimbraServiceEnabled:\s+mailbox.*/ 
      res[server] = {}
      sexpected[server].each_key do |key|
        res[server][key] = 'NOTFOUND' if data[1] == nil
        if data[0] == 0
          mResult = data[1][/\s*#{key}:\s+(.*)$/, 1]
        end
        if mResult == nil || mResult == ""
          res[server][key] = 'NOTFOUND'
        else
          res[server][key] = mResult
        end
	  end
	end
	[exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].keys.select {|s| data[1][s] != sexpected[s]}.empty?
  	if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        tmp = {}
        data[1].each_key do |s|
          tmp[s] = {}
          sb = sexpected[s]
          sb.keys.select {|k| sb[k] != data[1][s][k]}.collect do |k|
            tmp[s][k] = {"IS" => data[1][s][k], "SB" => sb[k]}
          end
        end
        tmp.delete_if {|k, v| v.empty?}
        mcaller.badones = {'server config check' => tmp}
  	end
  end,
  
  v(cb("nginx runpath test") do 
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      #extension = '.dylib'
      #cmd = 'otool -L'
      [0, "Skip on MACOSX - #{BuildParser.instance.targetBuildId}"]
    else
      cli = File.join(Command::ZIMBRAPATH,'nginx', 'sbin', 'nginx')
      mObject = RunCommand.new('find', Command::ZIMBRAUSER, cli)
      mResult = mObject.run
      if mResult[0] != 0
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s+(.*?)\s*\}/m, 1]
        end
        [0, mResult[1]]
      else
        mObject = RunCommand.new(cmd, Command::ZIMBRAUSER, cli)
        mResult = mObject.run[1]
        #puts mResult
        if !mResult.split(/\n/).select {|w| w =~ /\s*#{pcrePat}\s+.*/}.empty?
          [0, mResult[/\s*#{pcrePat}\s+.*/]]
        else
          if(mResult =~ /Data\s+:/)
            mResult = mResult[/Data\s+:\s+(.*?)\s*\}/m, 1]
          end
          [1, ["ldd " + cli, 
               mResult, pcrePat.source]]
        end
      end
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'nginx run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
    end
  end,

  v(cb("nginx account test") do 
    ldapPassword = ZMLocal.new('zimbra_ldap_password').run
    url = ZMLocal.new('ldap_url').run.split(/\s+/)[-1]
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'common', 'bin', 'ldapsearch'), Command::ZIMBRAUSER,
                             '-LLL',
                             '-H', url,
                             '-x', '-w', ldapPassword,
                             '-D', 'uid=zimbra,cn=admins,cn=zimbra',
                             '-b', 'uid=zmnginx,cn=appaccts,cn=zimbra',
                             'zimbraIsAdminAccount')
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = (mResult[1])[/Data\s+:\s+(.*?)\s*\}/m, 1]
    end
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraIsAdminAccount:\s+TRUE$/i
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'nginx account test' => {'zimbraIsAdminAccount' => {"IS"=>data[1].chomp.split()[-1], "SB"=>'TRUE'}}}
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
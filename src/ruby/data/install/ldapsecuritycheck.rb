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
# 1) check that ldapadd with malformed objectClasses attribute
#    does not crash slapd
# 2) check that "ldapsearch -x -h hostname 'objectClass=*'"
#    is rejected

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser"
#require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap security test"

include Action 


ldapUrls = []
ldif = ['dn: cn=zimbra\\\nobjectClasses: top\\\ndescription: Zimbra Systems Application Data\\\ncn: zimbra\\\nstructuralObjectClasses: organizationalRole\\\n\\\n',
        'dn: uid=test5,ou=SONST,ou=people,dc=kip.uni-heidelberg,dc=de\\\nobjectClasses: top\\\n\\\n'
       ]

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#


ldif1 = "dn: cn=zimbra\nobjectClasses: top\ndescription: Zimbra Systems Application Data\ncn: zimbra\nstructuralObjectClass: organizationalRole\n\n"
#echo ldif1 | ldapadd -H ldapUrl -x -w ldapPassword -D uid=zimbra,cn=admins,cn=zimbra
#if ldap down, fail, restart ldap
ldif2 = "dn: uid=test5,ou=SONST,ou=people,dc=kip.uni-heidelberg,dc=de\nobjectClasses: top\n\n"
#echo -e ldif2 | ldapadd -H ldap://qaxx.liquidsys.com:389 -x -w passwd -D uid=zimbra,cn=admins,cn=zimbra
#if ldap down, fail, restart ldap
#else success
current.action = [       
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'ldap_url')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    ldapUrl = data[1]
    if(ldapUrl =~ /Data\s+:/)
      ldapUrl = ldapUrl[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    ldapUrls = ldapUrl.chomp.split(/\n/)
    mcaller.pass = data[0] == 0 && ldapUrls != [] 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap_url' => {"IS"=>ldapUrl, "SB"=>"Defined"}}
    end
  end,
  
  #OpenLDAP crashes at a null pointer dereference during the processing of
  #modrdn call with maliciously formed destination rdn string.
  #No authentication is required to trigger this vulnerability.
  v(cb("ldapmodrdn crash test", 300) do
    exitCode = 0 
    result = {}
    ldapUrls.each do |url|
      restartNeeded = false
      host = Model::Host.new(url[/\/\/([^:\.]+)/, 1], Model::TARGETHOST.domain)
      mResult = RunCommandOn.new(host, 'zmlocalconfig', Command::ZIMBRAUSER, '-s -m nokey zimbra_ldap_password').run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      pwd = mResult[1].chomp
      ['dc=something,dc=anything dc=', 'cn=something,dc=anything cn=#80'].each do |dnrdn|
        mObject = RunCommandOn.new(host, File.join(Command::ZIMBRAPATH, 'openldap', 'bin', 'ldapmodrdn'), Command::ZIMBRAUSER,
                                 '-H', url,
                                 '-x', '-w', pwd,
                                 '-D', 'uid=zimbra,cn=admins,cn=zimbra',
                                 dnrdn)
        mResult = mObject.run
        iResult = mResult[1]
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
        end
        #sleep 20
        mObject = RunCommandOn.new(host, File.join(Command::ZIMBRAPATH, 'bin', 'ldap'), Command::ZIMBRAUSER,
                                   'status');
        mResult = mObject.run
        if mResult[1] !~ /slapd running/
           exitCode += 1
           restartNeeded = true
           mObject = RunCommandOn.new(host, File.join(Command::ZIMBRAPATH, 'bin', 'ldap'), Command::ZIMBRAUSER, 'start').run
           if(mResult[1] =~ /Data\s+:/)
             mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
           end
           msg = "#{mResult[1]} after running ldapmodrdn " + dnrdn
           if result.has_key?(host)
             result[host].push(msg)
           else
             result[host] = [msg]
           end
        end
      end
      mObject = RunCommandOn.new(host, File.join(Command::ZIMBRAPATH, 'bin', 'zmcontrol stop; zmcontrol start'), Command::ZIMBRAUSER).run if restartNeeded
      break if exitCode != 0
    end
    #result.delete_if {|k,v| v == nil}
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #&& data[1].select { |w| w[2] == nil}.empty?
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data[1].each_pair {|k, v| msgs.merge!({k.to_s => {"IS" => "slapd crash - " + v.join(' '), "SB" => 'slapd running'}})}
      mcaller.badones = {'ldapmodrdn crash check' => msgs}
    end
  end,
  
  v(cb("ldapadd crash test", 300) do
    exitCode = 0 
    result = ""
    ldif.each do |obj|
      ldapUrls.each do |url|
        host = Model::Host.new(url[/\/\/([^:\.]+)/, 1], Model::TARGETHOST.domain)
        mResult = RunCommandOn.new(host, 'zmlocalconfig', Command::ZIMBRAUSER, '-s -m nokey zimbra_ldap_password').run
        if(mResult[1] =~ /Data\s+:/)
          mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
        end
        pwd = mResult[1].chomp
        mObject = RunCommandOn.new(host, "echo -e \"#{obj}\" | " + File.join(Command::ZIMBRAPATH, 'openldap', 'bin', 'ldapadd'), Command::ZIMBRAUSER,
                                 '-H', url,
                                 '-x', '-w', pwd,
                                 '-D', 'uid=zimbra,cn=admins,cn=zimbra')
        mResult = mObject.run
        iResult = mResult[1]
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
        end
        sleep 20
        mObject = RunCommandOn.new(host, File.join(Command::ZIMBRAPATH, 'bin', 'ldap'), Command::ZIMBRAUSER,
                                   'status');
        mResult = mObject.run
        if mResult[1] !~ /slapd running/
           exitCode = 1
           mObject = RunCommandOn.new(host, File.join(Command::ZIMBRAPATH, 'bin', 'zmcontrol stop; zmcontrol start'), Command::ZIMBRAUSER).run;
           result = "(#{mResult[1][/.*process/]}) while adding " + obj
           break
        end
      end
      break if exitCode != 0
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #&& data[1].select { |w| w[2] == nil}.empty?
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap crash check' => {"IS"=>"slapd crashed" + data[1], "SB"=>'slapd running'}}
    end
  end,
  
  #ldapsearch -x -h "qa14.liquidsys.com"  'objectClass=*'
  v(cb("ldap search anonymous bind test") do
    result = []
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zmlocalconfig'), Command::ZIMBRAUSER,
                             '-s', '-m nokey', 'ldap_url')
    mResult = mObject.run
    iResult = mResult[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    ldapHosts = iResult.split(/\s+/).collect {|w| w[/ldaps?:\/\/(.*):.*/,1]}
    ldapHosts.each do |host|
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'ldapsearch'), Command::ZIMBRAUSER,
                               '-h', host,
                               '-x', 'objectClass=*')
      mResult = mObject.run
      result << [mResult[0], host, mResult[1][/.*#\s+(numEntries: .*)/,1]]
    end
    result
  end) do |mcaller, data|
    mcaller.pass = data.select {|w| w[0] == 0 && w[2] != nil}.empty? ^ (BuildParser.instance.baseBuildId =~ /FRANK(LIN)?/)
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      errs = {}
      data.each do |err|
        if err[0] != 0
          errs[err[1] + " - ldapsearch exit code"] = {"IS"=>err[0], "SB"=>'0'}
        else
          if err[2] != nil
            next if BuildParser.instance.baseBuildId =~ /FRANK(LIN)?/
            errs[err[1]] = {"IS"=>err[2], "SB"=>'connection refused'}
          else
            next if BuildParser.instance.baseBuildId !~ /FRANK(LIN)?/
            errs[err[1]] = {"IS"=>'connection refused', "SB"=>'connection allowed'}
          end
        end
        mcaller.badones = {'ldapsearch anonymous bind check' => errs}
      end
    end
  end,
  
  #ITS 5580
  #echo "0000000: ffff ff00 8441 4243 44" | xxd -r -  /tmp/packet
  #nc localhost 389 < packet
  #if ldap stopped, fail, restart zimbra
  v(cb("BER Decoding Remote DoS Vulnerability test",600) do
    result = [0, {}]
    mObject = RunCommand.new('echo', 'root',
                             '"0000000: ffff ff00 8441 4243 44"',
                             '| xxd -r - /tmp/packet')
    mResult = mObject.run
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zmlocalconfig'), Command::ZIMBRAUSER,
                             '-s', '-m nokey', 'ldap_url')
    mResult = mObject.run
    iResult = mResult[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    ldapHosts = iResult.split(/\s+/).collect {|w| w[/ldaps?:\/\/(.*)/,1].gsub(/:/, ' ')}
    ldapHosts.each do |host|
      mObject = RunCommand.new('nc', 'root', host, '<', '/tmp/packet')
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmcontrol'), Command::ZIMBRAUSER, 'status')
      mResult = mObject.run
      if mResult[0] != 0
        if(mResult[1] =~ /Data\s+:/)
           mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
        end
        tmp = mResult[1][/\s*(ldap\s+Stopped)/, 1]
        if tmp == nil
          result[1][host.split(/ /)[0]] = mResult[1]
        else
          result[0] += mResult[0]
          result[1][host.split(/ /)[0]] = tmp
          RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmcontrol'), Command::ZIMBRAUSER, 'stop').run
          RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmcontrol'), Command::ZIMBRAUSER, 'start').run
        end
      end
    end
    result
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #data.select {|w| w[0] == 0}.empty? || mObject.baseBuildId =~ /FRANK(LIN)?/
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      #mcaller.badones = {'BER Decoding Remote DoS Vulnerability' => {}}
      errmsg = {}
      data[1].each_pair do |host, err|
        errmsg[host] = {"IS"=>err, "SB"=>'ldap Running'}
      end
      mcaller.badones = {'BER Decoding Remote DoS Vulnerability' => errmsg}
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
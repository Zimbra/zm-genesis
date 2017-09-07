#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
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
require "action/zmcontrol"
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require "action/zmamavisd"
require "model/deployment"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server permission check" 
printOption = '-exec stat'
if(Model::TARGETHOST.architecture == 1  || #MACOSX
  Model::TARGETHOST.architecture == 9  || #MACOSXx86
  Model::TARGETHOST.architecture == 39 || #MACOSXx86_10.5
  Model::TARGETHOST.architecture == 52 || #MACOSXx86_10.6
  Model::TARGETHOST.architecture == 66)   #MACOSXx86_10.7
  printOption += ' -f '
else
  printOption += ' -c '
end
printOption += '"%N user:%U,group:%G,permissions:%A" {} \;'


include Action 

(mConfig = ConfigParser.new()).run
def isExecutable?(file)
  mObject = Action::RunCommand.new('file','root', file[/([^`'"]*)/, 1])
  mResult = mObject.run
  return false if mResult[0] != 0 ||
                  mResult[1] !~ /\sexecutable\s/
  true
end
 
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  # Get a list of executables   
  v(cb("Owner check") do
    users = "! -user zimbra ! -user root"
    users += " ! -user postfix" if ZMProv.new('gas', 'mta').run[1].include?(Utils::zimbraHostname)
    mObject = Action::RunCommand.new('find','root', Command::ZIMBRAPATH + File::SEPARATOR, 
                                     "#{users} ! -path \"*uninstall*\" #{printOption}").run  
  end) do |mcaller, data|
    mcaller.pass = !data[1].include?('/opt/zimbra') && data[0] == 0
  end,  
  
  v(cb("Zimbra Ownership Check") do 
    mResult = Action::RunCommand.new('find','root', Command::ZIMBRAPATH + File::SEPARATOR, 
                                     "! -user root",
                                     ['*uninstall*',
                                      '*\/zimbra\/jetty*emma*',
                                     ].collect {|w| "-a ! -path \"#{w}\""}.join(" "),
                                     "-name \"*.jar\"",
                                     printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[1].split(/\n/).select {|w| w !~ /user:zimbra/}.empty? && data[0] == 0
  end,  
  
  v(cb("Zimbra User Permission Check") do
    mObject = Action::RunCommand.new('find','root', Command::ZIMBRAPATH + File::SEPARATOR, 
                                     "-user zimbra -perm +002 -type f",
                                     "-a ! -path \"*uninstall*\"",
                                     "-a ! -path \"*\/zimbra\/jetty*emma*\"",
                                     "-a ! -path \"*\/zimbra\/jetty*\.em\"",
                                     printOption).run 
    [ 
     '/opt/zimbra/\.bash_history',
     '.*?catalina.out',
     '/opt/zimbra/data/tmp.*-rw-rw-rw',
     ].each do |x| 
      mObject[1].gsub!(Regexp.new(x),'')
    end
    mObject
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('/opt/zimbra')
  end,  
  
  v(cb("Root User Permission Check") do
    mResult = Action::RunCommand.new('find','root', Command::ZIMBRAPATH + File::SEPARATOR, 
                                     "-user root -perm +002",
                                     "! -type l",
                                     "-a ! -type d",
                                     "-a ! -path \"*uninstall*\"",
                                     "-a ! -path \"*tcmalloc*\"",
                                     "-a ! -path \"*postfix*\"",
                                     "-a ! -path \"*#{Command::ZIMBRAPATH}\/data\/ldap\/state\/run\/ldapi\"",
                                     "-a ! -path \"*zimbra\/data\/tmp*\"",
                                     printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    ['/opt/zimbra//?\.update_history.*$',  
    ].each do |x| 
      mResult[1].gsub!(Regexp.new(x),'')
    end
    mResult
  end) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && !data[1].include?('/opt/zimbra') 
  end,   
 
  v(cb("zimbra.log Permission Check") do
    mResult = Action::RunCommand.new('find','root', '/var/log/', 
      "-user zimbra -group zimbra ! -perm 644",
      " -type f",
      printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mResult
  end) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && !data[1].include?('zimbra.log')
  end,
  
  v(cb("install.log Permission Check") do
    next [0, '-rw-------'] if Utils::isAppliance
    mObject = RunCommand.new("/bin/ls", 'root', '-rtl', '/tmp/install.log.*')
    iResult = mObject.run
    if(iResult[1] =~ /Data\s+:/)
      iResult[1] = (iResult[1])[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    iResult[1] = iResult[1].split("\n").last if iResult[0] == 0
    iResult
  end) do |mcaller, data| 
    expected = '-rw-------'
    if(Model::TARGETHOST.architecture == 1 ||
       Model::TARGETHOST.architecture == 9 ||
       Model::TARGETHOST.architecture == 39 ||
       Model::TARGETHOST.architecture == 66)
      mcaller.pass = true
    else
      mcaller.pass = data[0] == 0 && data[1].include?(expected)
    end
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {data[1].split.last + ' permissions' => {"IS"=>data[1].split.first, "SB"=>expected}}
    end
  end,
  
  if mConfig.isPackageInstalled('zimbra-mta') && mConfig.getServersRunning('octopus').empty?
  [
    v(cb("Spamassassin Ownership Check") do
      mObject = Action::RunCommand.new('find','root', File::join(Command::ZIMBRAPATH, 'data', 'spamassassin'), 
        "! -user zimbra",
        printOption).run
      mObject
    end) do |mcaller, data| 
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    v(cb("/var/spamassassin Permission Check") do
      mObject = Action::RunCommand.new('ls','root', '-ld', File::join(File::SEPARATOR, 'var', 'spamassassin')).run
      mObject
    end) do |mcaller, data|
      mcaller.pass = data[1][/#{Regexp.new("drwx.*(\s+#{Command::ZIMBRAUSER}){2}.*/var/spamassassin")}/] ||
                     !ZMProv.new('gas', 'antispam').run[1].include?(Utils::zimbraHostname)
    end,
  ]
  end,
  
  v(cb("SSL ownership check") do
    mResult = Action::RunCommand.new('find','root', File.join(Command::ZIMBRAPATH, 'ssl', ''), 
                                     '! -user', Command::ZIMBRAUSER,
                                     "-name \"*\"",
                                     printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mResult
  end) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
    
  v(cb("SSL permission check") do
    mResult = Action::RunCommand.new('find','root', File.join(Command::ZIMBRAPATH, 'ssl', ''), 
                                     '-perm +022', "-name \"*\"",
                                     printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mResult
  end) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,  
  
  v(cb("Exec Permission Check") do
    mResult = Action::RunCommand.new('find','root', Command::ZIMBRAPATH + File::SEPARATOR,
                                     #'-executable',
                                     '! -perm -555',
                                     "-path \"*[/s]bin/*\"",
                                     "-type f",
                                     "! -name \"*envvars*\"",
                                     printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select {|w| isExecutable?(w.split.first)}.empty?
  end,

  v(cb("Jetty Ownership Check") do
    mResult = Action::RunCommand.new('find','root', File.join(Command::ZIMBRAPATH, 'jetty', 'work'), 
                                     "! -user zimbra",
                                     "-name \"*\"",
                                     printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mResult
  end) do |mcaller, data|
    store = Model::Deployment.getServersRunning('store')
    expected = 'No such file or directory'
    expected = 'start_\d+.properties' if store.include?(Model::TARGETHOST.to_s)
    mcaller.pass = data[1].chomp.split(/\n/).select {|w| w !~ /#{expected}/}.empty?
  end,
  
  v(cb("data/tmp Permission Check") do
    mObject = RunCommand.new("/bin/ls", 'root', '-l', File.join(Command::ZIMBRAPATH, 'data'))
    mResult = mObject.run
  end) do |mcaller, data| 
    expected = 'drwxrwxrw'
    mcaller.pass = data[0] == 0 && !data[1].split(/\n/).select {|w| w =~ /#{expected}.*\stmp\s*$/}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'data/tmp permissions' => {"IS"=>data[1].split(/\n/).select{|w| w =~ /\stmp\s*$/}.first, "SB"=>expected}}
    end
  end,
  
  v(cb("fd.csv perms check") do
    ZMStatctl.new('rotate').run
    mResult = Action::RunCommand.new('find','root', File.join(Command::ZIMBRAPATH, 'zmstat'), 
                                     "! -user root", "-name fd.csv", printOption).run
    mResult[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(File.join(Command::ZIMBRAPATH, 'zmstat', 'fd.csv')) 
  end,
  
  v(Action::RunCommand.new('find','root', File.join(Command::ZIMBRAPATH, 'conf', 'attrs'), 
                           "-user #{Command::ZIMBRAUSER}",
                           '-perm 444',
                           "-name zimbra-attrs.xml",
                           printOption)) do |mcaller, data|
    data[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "'"})
    mcaller.pass = data[0] == 0 && data[1].include?( File.join(Command::ZIMBRAPATH, 'conf', 'attrs', 'zimbra-attrs.xml')) 
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

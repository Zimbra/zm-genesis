#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
#
# Test basic zmproxyconfgen command
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmproxyconfgen"
require "action/zmamavisd"
require 'model/deployment'


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmproxyconfgen"
includeDir = 'test_confgen'
templateDir = Command::ZIMBRAPATH+'/conf/nginx/templates'


#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  if Model::Deployment.getServersRunning('proxy').include?(Model::TARGETHOST.to_s)
    [
      RunCommand.new('/bin/rm','root','-rf',Command::ZIMBRAPATH+'/conf/'+includeDir),
      RunCommand.new('/bin/rm','root','-rf','/tmp/testTemplates' ),
      RunCommand.new('/bin/rm','root','-rf',templateDir+'/testTemplates' ),

      RunCommand.new('/bin/mkdir', Command::ZIMBRAUSER, Command::ZIMBRAPATH+'/conf/'+includeDir),
      RunCommand.new('/bin/mkdir', Command::ZIMBRAUSER, Command::ZIMBRAPATH+'/conf/'+includeDir+'/testprefix'),
      RunCommand.new('/bin/mkdir', Command::ZIMBRAUSER, '/tmp/testTemplates'),
      RunCommand.new('/bin/mkdir', Command::ZIMBRAUSER, templateDir),

      RunCommand.new('/bin/cp', Command::ZIMBRAUSER, '-R', templateDir+'/*','/tmp/testTemplates/'),
      
      v(RunCommand.new('/bin/mv', Command::ZIMBRAUSER, '/tmp/testTemplates',templateDir)) do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,


      v(ZMProxyconfgen.new('-h')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?('usage: ProxyConfGen')
      end,

      v(ZMProxyconfgen.new('--help')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?('usage: ProxyConfGen')
      end,

      v(cb("description test") do
        mResult = ZMProxyconfgen.new('-D').run
        next mResult if mResult[0] != 0
        cfg = mResult[1][/(\n\s+NGINX Keyword.*)/m, 1].split(/\n\s+NGINX\s+/m)
        cfg.shift
        res = Hash.new({})
        cfg.each do |crt|
          key = crt[/Keyword:\s+([^\n]+)\n/, 1]
          res[key] = {}
          crt.split(/\n/).slice(1..-1).each do |line|
            name, val = line.split(/:\s+/)
            res[key][name] = val
          end
        end
        [mResult[0], res]
      end) do |mcaller, data|
        expected = {'memcache.:servers' => {'Description' => "List of known memcache servers (i.e. servers having memcached service enabled)"}}
        mcaller.pass = data[0] == 0 && (errs = expected.keys.select{ |w| !(expected[w].values - data[1][w].values).empty?}.collect{|w| [w, expected[w], data[1][w]]}).empty?
      end,
        
      v(ZMProxyconfgen.new('-i',includeDir,'-n')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir)
      end,

      v(cb("Verify",600)do
        RunCommand.new('/bin/ls', Command::ZIMBRAUSER, includeDir+'/*').run
      end)do |mcaller,data|
        mcaller.pass = data[0] != 0 && data[1].include?('No such file or directory')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--dry-run ')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir)
      end,

      v(cb("Verify",600)do
        data = RunCommand.new('/bin/ls', Command::ZIMBRAUSER, includeDir+'/*').run
      end)do |mcaller,data|
        mcaller.pass = data[0] != 0 && data[1].include?('No such file or directory')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--dry-run ','-p','xxxx.xxx')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('xxxx.xxx')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--dry-run ','--prefix','xxxx.xxx')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('test')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--dry-run ','-P','testTemplates/nginx.conf')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--dry-run ','--template-prefix','testTemplates/nginx.conf')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--dry-run ','-t','/opt/zimbra/conf/nginx/templates/testTemplates/')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'-n','--templatedir','/opt/zimbra/conf/nginx/templates/testTemplates/')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'-n','-w','/tmp/')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Cannot read configuration directory')
      end,


    ##  Bug 33505
    ##  v(ZMProxyconfgen.new('-i',includeDir,'-p','nnginx.conf','-t','/opt/zimbra/conf/nginx/templates/testTemplates/','-n')) do |mcaller, data|
    ##    mcaller.pass = (data[0] == 0) && data[1].include?(includeDir) && data[1].include?('xxxx.xxx')
    ##  end,
    ##
    ##  v(ZMProxyconfgen.new('-i',includeDir,'--prefix','xxxx.xxx')) do |mcaller, data|
    ##    mcaller.pass = (data[0] == 1) && data[1].include?(includeDir) && data[1].include?('xxxx.xxx.template does not exist')
    ##  end,

      v(ZMProxyconfgen.new()) do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,

      v(ZMProxyconfgen.new('-i',includeDir)) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir)
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'-P','testTemplates/nginx.conf')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--template-prefix','testTemplates/nginx.conf')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'-t','/opt/zimbra/conf/nginx/templates/testTemplates/')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--templatedir','/opt/zimbra/conf/nginx/templates/testTemplates/')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'-w','/tmp/')) do |mcaller, data|
        mcaller.pass = data[0] == 1 && data[1].include?('Cannot read configuration directory')
      end,

      # repeat for -v
       v(ZMProxyconfgen.new('-i',includeDir,'-P','testTemplates/nginx.conf','-v')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')&& data[1].include?('DEBUG')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--template-prefix','testTemplates/nginx.conf','-v')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')&& data[1].include?('DEBUG')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'-t','/opt/zimbra/conf/nginx/templates/testTemplates/','-v')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')&& data[1].include?('DEBUG')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'--templatedir','/opt/zimbra/conf/nginx/templates/testTemplates/','-v')) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?(includeDir) && data[1].include?('testTemplates')&& data[1].include?('DEBUG')
      end,

      v(ZMProxyconfgen.new('-i',includeDir,'-w','/tmp/','-v')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Cannot read configuration directory') && data[1].include?('DEBUG')
      end,

      v(ZMProxyconfgen.new('-s',Model::TARGETHOST.to_s)) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?('Loading server object:')
      end,

      v(ZMProxyconfgen.new('-i','/wrong-path')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Error')
      end,

      v(ZMProxyconfgen.new('-i','/wrong-path','-P','Templates/nginx.conf')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Error')
      end,

      v(ZMProxyconfgen.new('-p','anything')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Error')
      end,

      v(ZMProxyconfgen.new('-s','anything')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Make sure the server specified with -s exists')
      end,

      v(ZMProxyconfgen.new('-anything')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Unrecognized option: -anything')
      end,

      v(ZMProxyconfgen.new('--anything')) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1].include?('Unrecognized option: --anything')
      end,

      ZMProv.new('ms', Model::TARGETHOST,'zimbraReverseProxyLookupTarget', 'FALSE') do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,

      ZMProxyctl.new('restart')do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,

      v(ZMProxyconfgen.new('-s',Model::TARGETHOST.to_s)) do |mcaller, data|
        mcaller.pass = data[0] == 0 && data[1].include?('WARN: No available nginx lookup handlers could be found') \
                                    && data[1].include?('WARN: Configuration is not valid because no route lookup handlers exist, or because no HTTP/HTTPS upstream servers were found') \
                                    && data[1].include?('WARN: Please ensure that the output of \'zmprov garpu/garpb\' returns at least one entry')
      end,

      ZMProv.new('ms', Model::TARGETHOST,'zimbraReverseProxyLookupTarget', 'TRUE')do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,

      ZMProxyctl.new('restart')do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,
        
      v(RunCommand.new(ZMProxyconfgen.new.to_str.gsub(/Action:/, '').gsub(/libexec/, 'bin'))) do |mcaller, data|
        mcaller.pass = data[0] != 0 && data[1]  =~ /No such file or directory/
      end,
    ]
  end
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

#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
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
require "action/buildparser"
require 'action/zmprov'
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
require "action/zmamavisd"
require 'net/http'
require 'net/https'
require 'uri'
require "model/deployment"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Security test"

include Action 


ldapUrls = []
disableAntivirusRequired = false
mConfig = ConfigParser.new()
mConfig.run

def getDefaultDomain()
  mResult = ZMProv.new('gcf', 'zimbraDefaultDomainName').run
  if(mResult[1] =~ /Data\s+:/)
    mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
  end
  mResult[1].chomp.split(/:\s*/)[1]
end
mUri = Utils::getClientURIInfo

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

 
current.action = [ 
  v(cb("soap XXE attack test", 300) do
    exitCode = 0 
    result = {}
    soapPost = '<?xml version=\\\"1.0\\\" encoding=\\\"utf-8\\\"?>\n' +
                  '<!DOCTYPE foo [<!ENTITY xxe SYSTEM \\\"file:///opt/zimbra/.ssh/authorized_keys\\\">]>\n' +
                  '  <soap:Envelope xmlns:soap=\\\"http://www.w3.org/2003/05/soap-envelope\\\">\n' +
                  '    <soap:Header><context xmlns=\\\"urn:zimbra\\\">\n' +
                  '      <userAgent xmlns=\\\"\\\" name=\\\"ZimbraWebClient - FF3.0 (Win)\\\" version=\\\"6.0.0_BETA2_1547.UBUNTU8\\\"/>\n' +
                  '      <session xmlns=\\\"\\\" id=\\\"1117\\\"/>\n' +
                  '      <notify xmlns=\\\"\\\" seq=\\\"8\\\"/>\n' +
                  '      <account xmlns=\\\"\\\" by=\\\"name\\\">&xxe;</account>\n' +
                  '      <format xmlns=\\\"\\\" type=\\\"js\\\"/></context>\n' +
                  '    </soap:Header>\n' +
                  '    <soap:Body>\n' +
                  '      <NoOpRequest xmlns=\\\"urn:zimbraMail\\\"/>\n' +
                  '    </soap:Body>\n' +
                  '  </soap:Envelope>\n'
    mObject = RunCommand.new('echo', '-e', "\"#{soapPost}\"", '> /tmp/soap.txt')
    mResult = mObject.run
    mObject = ConfigParser.new()
    mResult = mObject.run
    servers = mObject.getServersRunning('store')
    servers.each do |host|
      mResult = RunCommandOn.new(host, 'wget', Command::ZIMBRAUSER,
                                  '-S', '-d',
                                  "http://#{host}/service/soap",
                                  '--post-file=/tmp/soap.txt').run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      if mResult[1] =~ /command=.*\/opt\/zimbra\/libexec\/zmrcd.* ssh-dss/
        exitCode += 1
        result[host] = mResult[1]
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #&& data[1].select { |w| w[2] == nil}.empty?
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data[1].each_pair do |k,v|
        msgs[k] = {"IS" => v, "SB" => 'no ssh key'}
      end
      mcaller.badones = {'soap xxe attack check' => msgs}
    end
  end,

  v(cb("dav attack test", 300) do
    exitCode = 0 
    result = {}
    data = "<?xml version=\"1.0\" encoding=\"utf-8\"?>" +
              "<!DOCTYPE foo [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]>" +
              "<x0:propfind xmlns:x0=\"DAV:\">" +
              "  <x0:prop>" +
              "    <x1:getctag xmlns:x1=\"http://calendarserver.org/ns/\"></x1:getctag>" +
              "    <x0:displayname></x0:displayname>" +
              "    <x0:ordering></x0:ordering>" +
              "    <x2:calendar-description xmlns:x2=\"urn:ietf:params:xml:ns:caldav\"></x2:calendar-description>" +
              "    <x3:calendar-color xmlns:x3=\"http://apple.com/ns/ical/\"></x3:calendar-color>" +
              "    <x3:calendar-order xmlns:x3=\"http://apple.com/ns/ical/\"></x3:calendar-order>" +
              "    <x0:resourcetype></x0:resourcetype>" +
              "    <x2:calendar-free-busy-set xmlns:x2=\"urn:ietf:params:xml:ns:caldav\"></x2:calendar-free-busy-set>" +
              "  </x0:prop>" +
              "</x0:propfind>"
    admin = "admin@" + getDefaultDomain()
    mObject = ConfigParser.new()
    mResult = mObject.run
    modeAttr = 'zimbraMailMode'
    portSuffix = 'Port'
    murlAttr = 'zimbraMailURL'
    servers = mObject.getServersRunning('proxy')
    if !servers.empty?
      modeAttr = 'zimbraReverseProxyMailMode'
      portSuffix = 'ProxyPort'
    end
    #portAttr = 'zimbraMailPort'
    #murlAttr = 'zimbraMailURL'
    servers = mObject.getServersRunning('store') if mObject.getServersRunning('proxy').empty?
    servers.each do |host|
      mode = ZMProv.new('gs', host, modeAttr).run[1][/#{modeAttr}:\s+(\S+)/, 1]
      portAttr = 'zimbraMail' + (mode == 'http' ? '' : 'SSL') + portSuffix
      port = ZMProv.new('gs', host, portAttr).run[1][/#{portAttr}:\s+(\S+)/, 1]
      conn = Net::HTTP.new(host, port)
      conn.use_ssl = true if mode != 'http'
      conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
      begin
        conn.start do |http|
          req = Net::HTTP::Propfind.new("/dav/#{admin}/Calendar")
          req.basic_auth 'admin', 'test123'
          response = http.request(req, data)
          if response.body =~ /command=.*\/opt\/zimbra\/libexec\/zmrcd.* ssh-dss/
            exitCode += 1
            result[host] = response.body
          end
        end
      rescue StandardError
        false 
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 #&& data[1].select { |w| w[2] == nil}.empty?
    if (not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data[1].each_pair do |k,v|
        msgs[k] = {"IS" => v, "SB" => 'no ssh key'}
      end
      mcaller.badones = {'dav attack check' => msgs}
    end
  end,
  
  v(cb("Enable Zimbra antivirus",300) do
    exitCode = 0
    res = ''
    mObject = ZMLocal.new('zimbra_server_hostname')
    server = mObject.run
    next[0, 'Skipping - non cluster only'] if mConfig.isClustered(server)
    mResult = ZMProv.new('gs', server).run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
    end
    config = mResult[1].chomp
    eservices = config.split(/\n/).select {|w| w =~ /^zimbraServiceEnabled:\s+.*$/}.collect {|w| w[/zimbraServiceEnabled:\s+(.*)\s*$/, 1]}
    next([0, 'Skipping - antivirus already enabled']) if eservices.include?('antivirus')
    iservices = config.split(/\n/).select {|w| w =~ /zimbraServiceInstalled:\s+.*$/}.collect {|w| w[/zimbraServiceInstalled:\s+(.*)\s*$/, 1]}
    next([0, 'antivirus is not installed']) if !iservices.include?('antivirus')
    disableAntivirusRequired = true
    cmd = ['+zimbraServiceEnabled', 'antivirus']
    mResult = ZMProv.new('ms', server, *cmd).run
    if mResult[0] != 0
      exitCode += 1 
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      res += mResult[1] + '\n'
    end
    mResult = ZMMtactl.new('reload').run
    if mResult[0] != 0
      exitCode += 1 
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      res += mResult[1] + '\n'
    end
    mResult = ZMAntivirusctl.new('restart').run
    if mResult[0] != 0
      exitCode += 1 
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      res += mResult[1] + '\n'
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Enable Zimbra antivirus' => {"IS" => data[1], "SB" => "Success"}}
    end
  end,
  
  #bug 52947
  #Clam AV has a service attached to port TCP/3310 which accepts commands
  # without authentication. One such command is "SHUTDOWN";
  # this command instructs the Clam AV service to terminate.

  Model::Deployment.getServersRunning('mta').map do |host|
    v(cb("clamav denial of service test", 300) do
      case mArchitecture = BuildParser.instance.targetBuildId[/zcs_([^_]+(_64)?)_/, 1]
        when 'SuSEES10', 'SLES10_64', 'SLES11_64' then mCmd = 'netcat'
        else mCmd = 'nc'
      end
      mPort = '3310'
      exitCode = 0 
      result = nil
      ### TODO enable service if disabled - upgrades
      mHost = Model::Host.new(host)
      mObject = RunCommandOn.new(mHost, 'echo', 'root', "\"SHUTDOWN\"", '|',
                                 mCmd, '-v', host, mPort)
      mResult = mObject.run
      if mResult[1] !~ /Connection refused/
        exitCode = 1
        result = mResult[1].chomp.strip
        mResult = RunCommandOn.new(mHost, 'zmantivirusctl', Command::ZIMBRAUSER,
                                   'start').run
      end
      [exitCode, result]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if (not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {host + ' - clamav denial of service test' => {"IS" => data[1], "SB" => 'Connection refused'}}
      end
    end
  end,
  
  ['AjxKeys', 'AjxMsg', 'AjxTemplateMsg', 'I18nMsg', 
   'ZabMsg', 'ZaMsg', 'ZbMsg', 'ZhKeys', 'ZhMsg',
   'ZmKeys', 'ZmMsg', 'ZMsg', 'ZmSMS', 'ZtMsg', 'whatever'].map do |x|
    ['carbon', 'foo'].map do |y|
      v(cb('skin vulnerability check') do
        #mUri = Utils::getClientURIInfo
        mUrl = File.join(mUri[:mode] + '://' + mUri[:target] + ':' + mUri[:port],
                         'res', x + '.js?skin=../../../../../../../../../../../../../../../../etc/passwd%00' + y)
        mResult = RunCommand.new("wget", "root", "--no-proxy", '-O', '-' ,'--no-check-certificate', '"' + mUrl + '"').run
        mResult << mUrl
      end) do |mcaller, data|
        mcaller.pass = data[0] != 0 || data[1] !~ /zimbra=.*::\/opt\/zimbra:\/bin\/bash/
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.suppressDump("Suppress dump, the result has #{data[1].split(/\n/).size} lines")
          mcaller.badones = {'URL vulnerability: ' + data.last => {"IS" => data[1].split(/\n/).select {|w| w =~ /a\./}[-10, 10], "SB" => 'no access'}}
        end
      end
    end
  end,
  
  ['login'].map do |x|
    v(cb('jsp vulnerability check') do
      mUrl = File.join(mUri[:mode] + '://' + mUri[:target] + ':' + mUri[:port], 'public', x + '.jsp/')
      url = URI.parse(mUrl)
      req = Net::HTTP::Get.new(url.path)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if url.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      [begin
         http.start{|x| x.request(req)}
       rescue StandardError => e
         e
       end, mUrl]
    end) do |mcaller, data|
      mcaller.pass = data[0].kind_of?(Errno::ECONNREFUSED) ||
                     data[0].kind_of?(Net::HTTPNotFound)  || data[0].body.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.suppressDump("Suppress dump, the result has #{data[0].body.split(/\n/).size} lines")
        mcaller.badones = {'jsp vulnerability: ' + data.last => {"IS" => data[0].message, "SB" => 'not found or empty'}}
      end
    end
  end,
    
  mConfig.getServersRunning('store').map do |x|
  [
    if ZMProv.new('gs', x, 'zimbraMailMode').run[1] !~  /.*\shttp\n/
    [
      v(RunCommand.new('staf', 'root', Model::TARGETHOST.to_s, 'fs', 'copy', 'file', File.join(Model::DATAPATH, 'security', f = 'evil.xml'),
                       'tofile', File.join(Command::ZIMBRAPATH, 'jetty', 'webapps', 'zimbra', 'downloads', f), 'tomachine', Model::Host.new(x).to_s))  do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,
        
      v(RunCommand.new('staf', 'root', Model::TARGETHOST.to_s, 'fs', 'copy', 'file', File.join(Model::DATAPATH, 'security', f = 'soap.xml'),
                           'tofile', File.join(Command::ZIMBRAPATH, 'jetty', 'webapps', 'zimbra', 'downloads', f), 'tomachine', Model::Host.new(x).to_s))  do |mcaller, data|
        mcaller.pass = data[0] == 0
      end,
      
      v(cb('evil test') do
        mPort = ZMProv.new('gs', x, attr = 'zimbraMailSSLPort').run[1][/#{attr}:\s+(\S+)/, 1]
        RunCommand.new('wget', 'root', '-S', '-d', '--no-check-certificate',
                       "--post-file=#{File.join(Command::ZIMBRAPATH, 'jetty', 'webapps', 'zimbra', 'downloads', f)}",
                       "https://#{x}:#{mPort}/service/soap/", '2>&1', h = Model::Host.new(x)).run
      end) do |mcaller, data|
        data[1].encode!('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => "??"})
        mcaller.pass = data[1] !~ /zimbra:x:\d+:\d+::#{Command::ZIMBRAPATH}:\/bin\/bash/ &&
                       data[1] =~ /service.PARSE_ERROR/
      end
    ]
    end
  ]
  end,

  v(cb("Disable Zimbra antivirus",300) do
    next([0, 'Skipping - disable antivirus not needed']) if !disableAntivirusRequired
    exitCode = 0
    res = ''
    mObject = ZMLocal.new('zimbra_server_hostname')
    server = mObject.run
    next([0, 'Skipping - non cluster only']) if mConfig.isClustered(server)
    mResult = ZMProv.new('gs', server).run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
    end
    config = mResult[1].chomp
    eservices = config.split(/\n/).select {|w| w =~ /^zimbraServiceEnabled:\s+.*$/}.collect {|w| w[/zimbraServiceEnabled:\s+(.*)\s*$/, 1]}
    next([0, 'Skipping - antivirus already disabled']) if !eservices.include?('antivirus')
    iservices = config.split(/\n/).select {|w| w =~ /zimbraServiceInstalled:\s+.*$/}.collect {|w| w[/zimbraServiceInstalled:\s+(.*)\s*$/, 1]}
    next([0, 'antivirus is not installed']) if !iservices.include?('antivirus')
    cmd = ['-zimbraServiceEnabled', 'antivirus']
    mResult = ZMProv.new('ms', server, *cmd).run
    if mResult[0] != 0
      exitCode += 1 
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      res += mResult[1] + '\n'
    end
    mResult = ZMMtactl.new('reload').run
    if mResult[0] != 0
      exitCode += 1 
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      res += mResult[1] + '\n'
    end
    mResult = ZMAntivirusctl.new('restart').run
    if mResult[0] != 0
      exitCode += 1 
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      res += mResult[1] + '\n'
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Disable Zimbra antivirus' => {"IS" => data[1], "SB" => "Success"}}
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
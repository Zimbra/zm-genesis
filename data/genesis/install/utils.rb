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

require "action/runcommand" 
require "action/zmlocalconfig"
require "action/zmprov"
require 'model/user'
require 'rexml/document'
include REXML

include Action

module Utils # :nodoc
  class Test < Proc
    attr :descr, false
    def initialize(descr, &bloc)
      super()
      @descr = descr
    end
    
    def to_str
      @descr
    end
  end
  
  def Utils::zimbraHostname(host = Model::TARGETHOST)
    ZMLocal.new(host, 'zimbra_server_hostname').run
  end
  
  def Utils::upgradeHistory()
    mObject = RunCommand.new('/bin/cat', 'root', File.join(Command::ZIMBRAPATH, '.install_history'))
    data = mObject.run()
    return [] if data[0] != 0
    data[1].split(/\n/).collect {|w| w[/((INSTALLED|UPGRADED)\s+zimbra-core[_-].*)$/, 1]}.compact
  end
  
  def Utils::isUpgradeFrom(release)
    !upgradeHistory.slice(0..-2).select {|w| w =~ /#{Regexp.compile(release)}/}.empty?
  end
  
  def Utils::isUpgrade()
    mObject = RunCommand.new('/bin/cat', 'root', File.join(Command::ZIMBRAPATH, '.install_history'))
    data = mObject.run()
    return false if data[0] != 0
    !data[1].split(/\n/).collect {|w| w[/UPGRADED\s+zimbra-core[_-](.*)$/, 1]}.compact.empty?
  end
  
  def Utils::zimbraDefaultDomain()
    ZMProv.new('gcf', 'zimbraDefaultDomainName').run[1][/zimbraDefaultDomainName:\s+(\S+)/, 1]
  end
  
  def Utils::setLC(host, name, newValue, currentValue = '', prefix = Provision::LCPrefix)
    val = "preupgradeValue=#{newValue}restoreValue=#{currentValue}"
    mResult = RunCommandOn.new(host, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                               '-e', [prefix, name].join('_').downcase + "=\"" + val + "\"").run
    if mResult[0] != 0
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
    end
    mResult
  end
  
  def Utils::getLC(host, name, prefix = Provision::LCPrefix)
    mResult = ZMLocal.new(host, [prefix, name].join('_').downcase).run
    return [0, ['Missing', '']] if mResult !~ /preupgradeValue=(.*)restoreValue=(.*)/
    [0, /preupgradeValue=(.*)restoreValue=(.*)/.match(mResult)[-2,2]]
  end
  
  def Utils::isAppliance
    (RunCommand.new("/bin/ls","root","-l", File.join('/opt','zcs-installer', 'log', 'appliance_configure.log')).run.first rescue 2) == 0
  end
  
  def Utils::applianceVersion
    RunCommand.new("dpkg", "root", "-l", 'zimbra-installer').run[1][/zimbra-installer\s+(\S+)/, 1] rescue nil
  end
  
  def Utils::getAdmins
    mResult = ZMProv.new('-l', 'gaaa').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = (mResult[1])[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    mResult[1].split(/\n/).collect {|w| Model::User.new(w, Model::DEFAULTPASSWORD)}
  end
  
  def Utils::getClientURIInfo
    proxy = ZMProv.new('gas', 'proxy').run[1].split(/\n/)
    store = ZMProv.new('gas', 'mailbox').run[1].split(/\n/)
    target = store.include?(Model::TARGETHOST.to_s) ? Model::TARGETHOST : Model::Host.new(store.first[/(.*)\.#{Model::TestDomain}/, 1], Model::TestDomain)
    target = (proxy.empty? || proxy.include?(Model::TARGETHOST.to_s)) ? Model::TARGETHOST : Model::Host.new(proxy.first[/(.*)\.#{Model::TestDomain}/, 1], Model::TestDomain)
    modeAttr = 'zimbraReverseProxyMailMode'
    portAttr = 'ProxyPort'
    if proxy.empty?
      modeAttr = 'zimbraMailMode'
      portAttr = 'Port'
    end
    mode = ZMProv.new('gs', target, modeAttr).run[1].chomp[/#{modeAttr}:\s+(\S+)/, 1]
    portAttr = 'zimbraMail' + (mode == 'http' ? '' : 'SSL') + portAttr
    port = ZMProv.new('gs', target, portAttr).run[1].chomp[/#{portAttr}:\s+(\S+)/, 1]
    if mode !~ /http/
      mode = 'http' + (port =~ /443/ ? 's' : '')
    end
    {:target => target, :mode => mode, :port => port}
  end
  
  def releaseName(stamp, branch, os)
    mResult = RunCommand.new("wget", "root", "--no-proxy", '-O', '-',
                             '--no-check-certificate', '--progress=dot', '-e', 'dot_bytes=10M',
                             'http://zre-matrix.eng.vmware.com/cgi-bin/build/builds.cgi' +
                             "?branchSelect=#{branch}" +
                             "&archSelect=#{os}&typeSelect=#{(t = stamp[/(NETWORK|FOSS)/, 1]).nil? ? 'all' : t}" +
                             "&statusSelect=all&oldSortBy=Build&sortBy=Build").run
    return nil if mResult[0] != 0
    res = mResult[1].split(/\n/).collect {|w| w[/.*?#{stamp}.*?#{branch}.*?#{os}.*?logs<\/A><\/TD><TD[^>]+>([^<]*)<\/TD>.*?/, 1]}.compact
    #!res.first[/.*_[GQ]A$/].nil?
    res.first == '&nbsp' ? nil : res.first
  end

end


if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
  # Unit test cases for Proxy
  class UtilsTest < Test::Unit::TestCase     
    def testOne 
      test = Utils::Test.new('testone') {|w| w == true}
      assert(test.to_str == 'testone')
      assert(test.call(true))
      assert(!test.call(false))
    end
    def testTwo
      test = Utils::Test.new('testtwo') {|x, y| x == y}
      assert(test.call(true, true))
      assert(!test.call(true, false))
    end
  end   
end

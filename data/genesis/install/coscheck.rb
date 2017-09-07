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
require "#{mypath}/install/attributeparser"
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "COS test"

include Action
include Model

def expectedTimezone
  return 'America/Pacific' if Utils::isAppliance
  mObject = ConfigParser.new()
  mObject.run
  res = nil
  mObject.doc.elements.each("//option") {
    |option|
    if option.attributes['name'] == 'zimbraPrefTimeZoneName'
      res = option.text.chomp.strip
      return res
    end
    res
  }
end

def getAllowedDomains(host, filename)
  res = []
  mObject = RunCommandOn.new(host, 'cat', Command::ZIMBRAUSER, filename)
  iResult = mObject.run[1]
  doc = Document.new iResult.slice(iResult.index('<zimletConfig'), iResult.index('</zimletConfig>') - iResult.index('<zimletConfig') + '</zimletConfig>'.length)
  doc.each_element_with_attribute('name', 'allowedDomains', 0, '//property') do |prop|
    res = prop.text.split(/\s*,\s*/)
  end
  res
end

(mCfg = ConfigParser.new).run
existing = {}
expected = {}

(mCosDefault = AttributeParser.new('cos')).run
exceptions = {'cn' => Utils::Test.new('default') {|sb, is| is[0] =~ /default\b/},
              'description' => Utils::Test.new('some text') {|sb, is| true},
              'zimbraBatchedIndexingSize' => Utils::Test.new('1 if customized, else 20 on upgrade') do |sb, is|
                                               mObject = ConfigParser.new()
                                               mResult = mObject.run
                                               next is[0] =~ /Missing\b/ if mResult[0] != 0
                                               mCmd = mObject.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'cos', 'zimbraBatchedIndexingSize')
                                               if mCmd != false
                                                 is[0] == mCmd.split(/\s/)[-1]
                                               else
                                                 if Utils::isUpgradeFrom('5.0.[012]_')
                                                   is[0] == 'Missing'
                                                 else
                                                   is[0] == '20'
                                                 end
                                               end
                                             end,
              'zimbraContactAutoCompleteEmailFields' => Utils::Test.new('[workEmail1,workEmail2,workEmail3] only on upgrade from 6.0.5+') do |sb, is|
                                                          if Utils::isUpgradeFrom('5.0.\d+') || Utils::isUpgradeFrom('6.0.[0-5]_')
                                                            diff = ['workEmail1', 'workEmail2', 'workEmail3']
                                                          else
                                                            diff = []
                                                          end
                                                          islist = is[0].split(/\s*,\s*/)
                                                          sblist = sb[0].split(/\s*,\s*/)
                                                          sblist - islist == diff && islist - sblist == []
                                                        end,
              'zimbraFeatureBriefcasesEnabled' => Utils::Test.new('FALSE on install, preserve on upgrade') do |sb, is|
                                                    if Utils::isUpgradeFrom('((6|7)(\.\d){2}|8\.0\.0_BETA[1-4])')
                                                      is[0] == 'TRUE'
                                                    else
                                                      is[0] == 'FALSE'
                                                    end
                                                  end,
              'zimbraFeatureInstantNotify' => Utils::Test.new('Off') {|sb, is| true},
              'zimbraFeatureMobilePolicyEnabled' => Utils::Test.new('FALSE on upgrade from FRANK[LIN]') do |sb, is|
                                                      if Utils::isUpgradeFrom('4.\d') || Utils::isUpgradeFrom('5.\d')
                                                        is[0] == 'FALSE'
                                                      else
                                                        is[0] == 'TRUE'
                                                      end
                                                    end,
              'zimbraFeatureNotebookEnabled' => Utils::Test.new('FALSE if appliance, TRUE otherwise') do |sb, is|
                                                  Utils::isAppliance ? is[0] == 'FALSE' : is[0] == 'TRUE'
                                                end,
              'zimbraFeatureReadReceiptsEnabled' => Utils::Test.new('FALSE on upgrade from FRANK[LIN]') do |sb, is|
                                                      if Utils::isUpgradeFrom('4.\d') || Utils::isUpgradeFrom('5.\d')
                                                        is[0] == 'FALSE'
                                                      else
                                                        is[0] == 'TRUE'
                                                      end
                                                    end,
              'zimbraFeatureSocialExternalEnabled' => Utils::Test.new('TRUE or FALSE') do |sb, is|
                                                        mCmd = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'cos', 'zimbraFeatureSocialExternalEnabled')
                                                        if mCmd != false
                                                          is[0] == mCmd[/zimbraFeatureSocialExternalEnabled\s+(TRUE|FALSE)\s+/, 1]
                                                        else
                                                          is[0] == sb[0]
                                                        end
                                                      end,
              'zimbraFeatureWebSearchEnabled' => Utils::Test.new('TRUE or Missing') {|sb, is| is[0] =~ /(TRUE|Missing)/},
              'zimbraFeatureVoiceChangePinEnabled' => Utils::Test.new('TRUE on upgrade from 5.0.19+|6.0.2+') do |sb, is|
                                                        if Utils::isUpgradeFrom('6.0.[01]_')
                                                          is[0] == 'Missing'
                                                        else
                                                          is[0] == 'TRUE'
                                                        end
                                                      end,
              'zimbraFeatureSocialExternalURL' => Utils::Test.new('TRUE or FALSE') do |sb, is|
                                                    mCmd = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'cos', 'zimbraFeatureSocialExternalEnabled')
                                                    if mCmd != false
                                                      is[0] == mCmd[/zimbraFeatureSocialExternalURL\s+(\S+)\s*/, 1]
                                                    else
                                                      is[0] == 'Missing'
                                                    end
                                                  end,
              'zimbraId' => Utils::Test.new("id") {|sb, is| is[0] !~ /Missing/},
              'zimbraMailHostPool' => Utils::Test.new("objectid") {|sb, is| is[0] !~ /Missing/},
              'zimbraMailSignatureMaxLength' => Utils::Test.new("10240(default) on install, 1024 on upgrade") do |sb, is|
                                                  if Utils::isUpgradeFrom('5.0.\d+') || Utils::isUpgradeFrom('6.0.0_BETA1')
                                                    is[0] =="1024"
                                                  else
                                                    false
                                                  end
                                                end,
              'zimbraMailThreadingAlgorithm' => Utils::Test.new("#{mCosDefault.attributes['zimbraMailThreadingAlgorithm']['default']} on install, #{mCosDefault.upgradeValue('zimbraMailThreadingAlgorithm').first} on upgrade") do |sb, is|
                                                  if !Utils::isUpgrade || Utils::isUpgradeFrom('8.0.0_BETA1')
                                                    is[0] == sb[0]
                                                  else
                                                    #(mObject = AttributeParser.new('cos')).run
                                                    is[0] == mCosDefault.upgradeValue('zimbraMailThreadingAlgorithm').first
                                                  end
                                                end,
              'zimbraMobileForceSamsungProtocol25' => Utils::Test.new("FALSE on install, TRUE on upgrade from 8.5") do |sb, is|
                                                        if Utils::isUpgradeFrom('(7\.\d+|8\.0)\.\d+')
                                                          is[0] == 'TRUE'
                                                        else
                                                          is[0] == sb[0]
                                                        end
                                                      end,
              'zimbraMobilePolicyMaxEmailAgeFilter' => Utils::Test.new("2 on upgrades from <8.5.0_BETA2, 5 otherwise") do |sb, is|
                                                         if Utils::isUpgrade && Utils::isUpgradeFrom('([78].[0-2].\d+|8.5.0_BETA1)')
                                                           is[0] == '2'
                                                         else
                                                           is[0] == sb[0]
                                                         end
                                                       end,
              'zimbraMobilePolicyMaxCalendarAgeFilter' => Utils::Test.new("4 on upgrades from <8.5.0_BETA2, 5 otherwise") do |sb, is|
                                                            if Utils::isUpgrade && Utils::isUpgradeFrom('([78].[0-2].\d+|8.5.0_BETA1)')
                                                              is[0] == '4'
                                                            else
                                                              is[0] == sb[0]
                                                            end
                                                          end,
              'zimbraMobilePolicyRequireStorageCardEncryption' => Utils::Test.new('FALSE on install, preserve on upgrade') do |sb, is|
                                                                    if Utils::isUpgradeFrom('(7|8)(\.\d){2}')
                                                                      is[0] == 'TRUE'
                                                                    else
                                                                      is[0] == sb[0]
                                                                    end
                                                                  end,
              'zimbraPrefCalendarReminderSendEmail' => Utils::Test.new("FALSE on install/upgrade from 7.1.3+, else TRUE") do |sb, is|
                                                         if !Utils::isUpgrade() || Utils::isUpgradeFrom('7.1.([3-9]|1\d)')
                                                           is[0] == 'FALSE'
                                                         else
                                                           is[0] == 'TRUE'
                                                         end
                                                       end,
              'zimbraPrefComposeFormat' => Utils::Test.new("html on 9.x+ install, text on upgrades from pre 9.0") do |sb, is|
                                                         if !Utils::isUpgrade() || Utils::isUpgradeFrom('(7|8)(\.\d+){2}')
                                                           is[0] == 'text'
                                                         else
                                                           is[0] == 'html'
                                                         end
                                                       end,
              'zimbraPrefForwardIncludeOriginalText' => Utils::Test.new("includeBodyAndHeaders on install/upgrade from 6.0.6+") do |sb, is|
                                                          if !Utils::isUpgrade() || Utils::isUpgradeFrom('6.0.([6-9]|\d{2})_')
                                                            is[0] =~ /includeBodyAndHeaders/
                                                          else
                                                            is[0] =~ /includeBody/
                                                          end
                                                        end,
              'zimbraPrefMailDefaultCharset' => Utils::Test.new("default = Missing, UTF-8 on upgrade") do |sb, is|
                                                  if !Utils::isUpgrade() || Utils::isUpgradeFrom('5.0.1[6-9]') || !Utils::isUpgradeFrom('6.0.0_BETA1')
                                                    is[0] =~ /Missing/
                                                  else
                                                    is[0] =~ /UTF-8/
                                                  end
                                                end,
              'zimbraPrefMailSendReadReceipts' => Utils::Test.new("prompt on 8.5 install else never") do |sb, is|
                                                    if Utils::isUpgradeFrom('(7\.\d+|8\.0)\.\d+')   # !Utils::isUpgrade() || Utils::isUpgradeFrom('6.0.([6-9]|\d{2})_')
                                                      is[0].chomp == 'never'
                                                    else
                                                      is[0].chomp == 'prompt'
                                                    end
                                                  end,
              'zimbraPrefReplyIncludeOriginalText' => Utils::Test.new("includeBodyAndHeaders on install/upgrade from 6.0.6+") do |sb, is|
                                                  if !Utils::isUpgrade() || Utils::isUpgradeFrom('6.0.([6-9]|\d{2})_')
                                                    is[0] =~ /includeBodyAndHeaders/
                                                  else
                                                    is[0] =~ /includeBody/
                                                  end
                                                end,
              'zimbraPrefForwardReplyInOriginalFormat' => Utils::Test.new("default = TRUE, FALSE on upgrade from 8.0.0_BETA1 and prior") do |sb, is|
                                                            if Utils::isUpgradeFrom('(6|7|8).(0|1|2).\d+_(BETA1)*')
                                                              is[0] == 'FALSE'
                                                            else
                                                              is[0] == 'TRUE'
                                                            end
                                                          end,
              'zimbraPrefSkin' => Utils::Test.new('appliance => sand, installation => ' + ((res = ZMProv.new('gc', 'default', 'zimbraPrefSkin').run[1][/zimbraPrefSkin:\s+(\S+)/, 1]).nil?? 'not found' : res)) do |sb, is|
                                    next true if Utils::isUpgrade
                                    next is[0] == 'sand' if Utils::isAppliance
                                    #sb[0] = 'beach' if Utils::isUpgrade && Utils::isUpgradeFrom('[56]\.0\.\d+_')
                                    #sb[0] = 'carbon' if Utils::isUpgrade && Utils::isUpgradeFrom('7\.\d+\.\d+_')
                                    is[0] == sb[0]
                                  end,
              'zimbraPrefSpellIgnoreWord' => Utils::Test.new("blog") do |sb, is|
                                                        if !Utils::isUpgrade() || !Utils::isUpgradeFrom('(5.0.\d+|6.0.[0-7])_')
                                                          is[0] == 'blog'
                                                        else
                                                          is[0] == 'Missing'
                                                        end
                                                      end,
              'zimbraPrefStandardClientAccessilbityMode' => Utils::Test.new('Missing in 5.0.9') {|sb, is| is[0] =~ /Missing/},
              'zimbraPrefTimeZoneId' => Utils::Test.new("#{expectedTimezone()}") {|sb, is| true},
              'zimbraProxyAllowedDomains' => Utils::Test.new("domain list") do |sb, is|
                                               if Utils::isAppliance
                                                 stores = [Utils::zimbraHostname]
                                               else
                                                 mObject = ConfigParser.new()
                                                 mResult = mObject.run
                                                 stores = mObject.getServersRunning('store')
                                               end
                                               next is[0] =~ /Missing/ if !stores
                                               allowedDomains = []
                                               host = stores[0]
                                               testDomain = Domain.new(Utils::zimbraHostname[/[^.]+\.(.*)/, 1])
                                               myHost = Host.new(host[/(.*)\.#{testDomain}/, 1], testDomain)
                                               mObject = RunCommandOn.new(myHost, 'find', Command::ZIMBRAUSER,
                                                                          File.join(Command::ZIMBRAPATH, 'zimlets-deployed'),
                                                                          '-name', 'config_template.xml', '-print')
                                               mResult = mObject.run
                                               templates = mResult[1].split(/\n/).select {|w| w =~ /.*\.xml/}.collect {|w| w[/(\/opt\/zimbra.*xml)/, 1]}
                                               templates.each do |template|
                                                 allowedDomains += getAllowedDomains(myHost, template)
                                               end
                                               allowedDomains = ['Missing'] if allowedDomains == []
                                               is.sort == allowedDomains.sort
                                             end,
              'zimbraZimletAvailableZimlets' => Utils::Test.new("zimlet list") do |sb, is|
                                                  is.select {|w| (w !~ /com_zimbra_/) || (w =~ /\+com_zimbra_click/)}.empty?
                                                end,
             }
exceptions.default = Utils::Test.new("default = Missing") {|sb, is| is[0] =~ /Missing/ && sb[0] =~ /Skip - no default/}
applianceDefaults = {'zimbraFeatureNotebookEnabled' => ['FALSE']}

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  v(cb("Cos defaults test") do
    expected = mCosDefault.attributes
    applianceDefaults.each_pair {|k, v| expected[k]['default'] = v} if Utils::isAppliance
    exitCode = 0
    result = {}
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                             'gc', 'default')
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    if data[0] != 0
      [data[0], iResult]
    else
      existing = {}
      toks = nil
      iResult.split(/\n/).each do |line|
        next if line =~ /^#/
        if line =~ /^\S+:\s+.*/
          if toks != nil
            existing[toks[0]] = [] if !existing.has_key? toks[0]
            existing[toks[0]] << toks[1].chomp
          end
          toks = line.split(/:\s+/, 2)
        else
          toks[1] += line
        end
      end
      expected = expected.delete_if {|k,v| !mCosDefault.attributes[k]['deprecatedSince'].nil?}
      existing[toks[0]] = [] if !existing.has_key? toks[0]
      existing[toks[0]] << toks[1].chomp
      existing.default = ['Missing']
      iResult = {}
      expected.each_key do |key|
        iResult[key] = existing[key] #if expected[key] != ["Skip - no default"]
      end
      [exitCode, iResult]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].keys().select do |w|
                     data[1][w].sort != expected[w]['default'].sort
                   end.select do |w|
                     !(exceptions[w].call(expected[w]['default'], data[1][w]))
                   end.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Cos defaults test' => {}}
      if data[0] != 0
        mcaller.badones['Cos defaults test'] = {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}
      else
        expectedKeys = expected.keys
        realityKeys = data[1].keys
        unexpectedKeys = realityKeys - expectedKeys
        commonKeys = realityKeys - unexpectedKeys
        missingKeys = expectedKeys - realityKeys
        mResult = {}
        realityKeys.select do |w|
          (data[1][w] & expected[w]['default']).size != expected[w]['default'].size
        end.select do |w|
          data[1][w] != expected[w]['default']
        end.select do |w|
          !(exceptions[w].call(expected[w]['default'], data[1][w]))
        end.each do |w|
          mResult[w] = {"IS" => data[1][w].join(","),
                        "SB" => if exceptions.has_key?(w)
                                  exceptions[w].to_str
                                else
                                  expected[w]['default'].join(",")
                                end}
        end
        missingKeys.select do |w|
          expected[w] != ["Skip - no default"]
        end.each {|w| mResult[w] = {"IS" => "missing", "SB" => expected[w]['default'].join(",")}}
        mcaller.badones['Cos defaults test'] = mResult
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
#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/preUpgrade/setIdentities.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# Set identities with values from zimbra-attrs.xml
# and check that upgrade preserves them
#


exitCode = 0

#allNames = ('bits', 'machine', 'OS', 'build', 'branch',
#                'baseBuild', 'targetBuild');

require 'getoptlong'
require 'rexml/document'
include REXML

options = {}

opts = GetoptLong.new(
      [ '--bits', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--machine', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--OS', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--build', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--branch', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--baseBuild', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--targetBuild', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--logLevel', GetoptLong::REQUIRED_ARGUMENT ]
    )

opts.each do |opt, arg|
    options[opt.gsub(/--/, "")] = arg
end

#print opts.get(), options['baseBuild']

puts "Start " + File.basename($0) + "..."

attrsXml = '/opt/zimbra/conf/attrs/zimbra-attrs.xml'
params = ""
identities = {}
if FileTest.exists?(attrsXml)
   file = File.open(attrsXml, "r")
   doc = Document.new file
   doc.elements.each("/attrs/attr") {
      |attr|
      next if !attr.attributes.has_key?("optionalIn")
      next if attr.attributes.has_key?("deprecatedSince")
      next if !attr.attributes["optionalIn"].include? "identity"
      msg = "n=#{attr.attributes['name']} tpye=#{attr.attributes['type']}"
      if attr.elements["defaultCOSValue"]
         defaultVal = attr.elements["defaultCOSValue"].text
         msg += " df=#{defaultVal}\""
         if attr.attributes['type']  == 'boolean'
            val = 'TRUE'
            val = 'FALSE' if defaultVal == "TRUE"
            identities["identity_#{attr.attributes['name']}_#{val}"] = "#{attr.attributes['name']} #{val}"
         elsif attr.attributes['type'] == 'enum'
            values = attr.attributes['value'].split(',')
            nondef = values - [defaultVal]
            val = nondef[0].gsub(/\$/, "\\\$")
            identities["identity_#{attr.attributes['name']}_#{val}"] = "#{attr.attributes['name']} \'#{val}\'"
         else
            puts "skip #{msg}"
            next
         end
      end
   }
end

#else get attrs from conf/zimbra.ldif
# = `su - zimbra -c "zmprov cid acct identity_aname_avalue #{params} 2>&1"`
acctName = "identityTestAccount"
admin = `su - zimbra -c "/opt/zimbra/bin/zmprov -l gaa" | grep '^admin@'`
domain = admin.chomp!.split('@')[1]
account = "#{acctName}@#{domain}"
identitySupported = `su - zimbra -c "/opt/zimbra/bin/zmprov gid admin"`
if ($?>>8) != 0
   puts "identity not supported"
   #deprecated
   #parms = "zimbraPrefForwardReplyInOriginalFormat TRUE"
   parms += " zimbraPrefComposeFormat html"
   parms += " zimbraPrefForwardIncludeOriginalText includeAsAttachment"
   parms += " zimbraPrefReplyIncludeOriginalText includeAsAttachment"
   acctId = `su - zimbra -c "/opt/zimbra/bin/zmprov ca #{account} test123 #{parms} 2>&1"`
   if ($?>>8) != 0
      puts "error cannot create account #{account} exit code:" + ($?>>8).to_s
      exitCode += 1
   end
   puts "End " + File.basename($0) + "\n"
   exit exitCode
end

acctId = `su - zimbra -c "/opt/zimbra/bin/zmprov ca #{account} test123 2>&1"`
if ($?>>8) != 0
   puts "error cannot create account #{account} exit code:" + ($?>>8).to_s
   exitCode += 1
else
   identities.each_key {
      |key|
      res = `su - zimbra -c "/opt/zimbra/bin/zmprov cid #{account} #{key} #{identities[key]} 2>&1"`
      if ($?>>8) != 0
         puts "error cannot create #{account} identity #{key} exit code:" + ($?>>8).to_s
         exitCode += 1
      end
      #modify DEFAULT identity
      res = `su - zimbra -c "/opt/zimbra/bin/zmprov mid #{account} DEFAULT #{identities[key]} 2>&1"`
      if ($?>>8) != 0
         puts "error cannot modify #{account} identity DEFAULT exit code:" + ($?>>8).to_s
         exitCode += 1
      end

   }
end

puts "End " + File.basename($0) + "\n"

exit exitCode

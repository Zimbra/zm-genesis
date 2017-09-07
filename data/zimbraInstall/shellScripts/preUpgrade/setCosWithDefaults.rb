#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/preUpgrade/setCosWithDefaults.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# Set a new cos with all default values from zimbra-attrs.xml
# 
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
      [ '--targetBuild', GetoptLong::REQUIRED_ARGUMENT ]
    )

opts.each do |opt, arg|
    options[opt.gsub(/--/, "")] = arg
end

#print opts.get(), options['baseBuild']

puts "Start " + File.basename($0) + "..."

attrsXml = '/opt/zimbra/conf/attrs/zimbra-attrs.xml'
params = ""
if FileTest.exists?(attrsXml)
   file = File.open(attrsXml, "r")
   doc = Document.new file
   doc.elements.each("/attrs/attr") {
      |attr|
      next if !attr.elements["defaultCOSValue"]
      next if attr.attributes.has_key?("deprecatedSince")
      defaultVal = "\'" + attr.elements["defaultCOSValue"].text + "\'"
      defaultVal.gsub!(/\$/, "\\\$")
      attrName = attr.attributes["name"]
      params += " " + attrName + " " + defaultVal
   }
end
#else get attrs from conf/zimbra.ldif
cosId = `su - zimbra -c "/opt/zimbra/bin/zmprov cc newCosWithDefaults #{params} 2>&1"`
if ($?>>8) != 0
   puts "error executing \"zmprov cc newCosWithDefaults #{params}\" exit code:" + ($?>>8).to_s
   if options['logLevel'] == 'debug'
      puts "result = #{coses}"
   end
   exitCode += 1
else
   puts "cos newCosWithDefaults created"
end

puts "End " + File.basename($0) + "\n"

exit exitCode

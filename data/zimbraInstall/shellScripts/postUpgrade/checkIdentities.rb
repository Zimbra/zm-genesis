#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/postUpgrade/checkIdentities.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# Check that identity prefs were preserved by upgrade
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
if 0 == 1
if FileTest.exists?(attrsXml)
   file = File.open(attrsXml, "r")
   doc = Document.new file
   doc.elements.each("/attrs/attr") {
      |attr|
      next if !attr.attributes.has_key?("optionalIn")
      next if !attr.attributes["optionalIn"].include? "identity"
      msg = "n=#{attr.attributes['name']} tpye=#{attr.attributes['type']}"
      if attr.attributes.has_key?("value")
         msg += " v=#{attr.attributes['value']}"
      end
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
      puts "xxx #{msg}"
   }
end
end

acctName = "identityTestAccount"
account = "#{acctName}"
reality = {}
res = `su - zimbra -c "zmprov gid #{account} 2>&1"`
if ($?>>8) != 0
   puts "error cannot retrieve #{account} identities exit code:" + ($?>>8).to_s
   if options['logLevel'] == 'debug'
      puts "result = #{res}"
   end
   exitCode += 1
else
   name = ''
   res.each {
      |line|
      if line =~ /^# name/
         name = line.split(' ').last
         reality[name] = {}
      elsif line.chop! !~ /^\s+$/
#         if reality.has_key?(name)
#            reality[name].push(line)
#         else
#            reality[name] = [line]
#         end
         toks = line.split(": ")
         reality[name][toks[0]] = toks[1]
      end
   }
   if reality.empty?
      exitCode += 1
      puts "error no identities available"
   else
      reality.each_key {
         |name|
         expected = name.split('_')
         if expected[0] == 'DEFAULT'
            puts "check DEFAULT"
            expect = {'zimbraPrefForwardReplyFormat' => 'same',
                      'zimbraPrefForwardIncludeOriginalText' => 'includeAsAttachment',
                      'zimbraPrefReplyIncludeOriginalText' => 'includeAsAttachment'}
            expect['zimbraPrefForwardReplyFormat'] = 'html' if options['baseBuild'].split('_')[-3].upcase >= 'FRANK'
            expect.each_key {
               |key|
               msg = ""
               crt = "Missing"
               crt = reality[name][key] if reality[name].has_key?(key)
               if expect[key] != crt
                  msg += "error "
                  exitCode += 1
               end
               puts "#{msg}identity #{name} #{key} SB:#{expect[key]} IS:#{crt}."
            }
         else
            msg = ""
            if reality[name][expected[1]] != expected[2]
               msg += "error "
               exitCode += 1
            end
            puts "#{msg}identity #{name} #{expected[1]} SB:#{expected[2]} IS:#{reality[name][expected[1]]}."
         end
      }
   end
end

#reality.each_key {
#   |key|
#   puts "key=#{key}, v=" + reality.to_s + "."
#}
#      res = `su - zimbra -c "zmprov cid #{account} #{key} #{identities[key]} 2>&1"`
#      if ($?>>8) != 0
#         puts "error cannot create #{account} identity #{key} exit code:" + ($?>>8).to_s
#         exitCode += 1
#      end
#   }
#end

puts "End " + File.basename($0) + "\n"

exit exitCode

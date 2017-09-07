#!/bin/ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
#
# Setup system for cobertura
#
COBERTDIR = '/var/tmp/cobertura-1.9.1'
list = %w(/opt/zimbra/lib/ext-common /opt/zimbra/jetty/webapps/service/WEB-INF)
list = list + %w(/opt/zimbra/jetty/webapps/zimbra/WEB-INF/lib /opt/zimbra/jetty/common/lib)
 
clist = list.map do |x|
   ['cp '+File.join(COBERTDIR, 'cobertura.jar')+" #{x}",
    #"cd #{x};find "+ x.to_s + " -name 'zim*.jar' | xargs #{File.join(COBERTDIR, 'cobertura-instrument.sh')}"
   ]
end
puts `cd /opt/zimbra/log;find /opt/zimbra/jetty -follow -name 'zimbra*jar' | xargs /var/tmp/cobertura-1.9.1/cobertura-instrument.sh`
#puts `cd /opt/zimbra;find /opt/zimbra/lib -follow -name 'zimbra*jar' | xargs /var/tmp/cobertura-1.9.1/cobertura-instrument.sh`
clist.flatten.each do |x|
  puts x
  result = `#{x} 2>&1 `
  puts result
end
puts `sed -i.bak 's#^CP=#CP=${ZMROOT}/lib/jars/cobertura.jar${PATHSEP}#' /opt/zimbra/bin/zmlocalconfig`
puts `/opt/zimbra/libexec/zmfixperms`
puts `find /opt/zimbra -name 'cober*.ser' -exec chown zimbra:zimbra {} \\;`
puts `find /opt/zimbra -name 'cober*.ser' -exec chmod u+w {} \\;`
#now the directory has to be writable by zimbra
#list.each do |x|
#  puts `chmod go+rwx #{x}`
#  puts `chmod u+w #{File.join(x,'cobertura.ser')}`
#  puts `chown zimbra:zimbra #{File.join(x, 'cobertura.ser')}`
#end
# channel lock is in /opt/zimbra
puts `chmod go+rwx /opt/zimbra /opt/zimbra/log`


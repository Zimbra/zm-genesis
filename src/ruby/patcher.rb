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
# patch perdition
#!/bin/env ruby
branch, os = ARGV
url = "http://zqa-tms.eng.vmware.com/files/patch/#{branch}/#{os}/perdition-1.17.1.1z.tgz"
puts `wget #{url}`
puts `tar -C /opt/zimbra -xzf ./perdition-1.17.1.1z.tgz`
puts `su - zimbra -c 'zmcontrol stop'`
puts `chown zimbra:zimbra /opt/zimbra/perdition-1.17.1.1z`
puts `rm /opt/zimbra/perdition`
puts `ln -s /opt/zimbra/perdition-1.17.1.1z /opt/zimbra/perdition`
puts `su - zimbra -c 'zmcontrol start'`

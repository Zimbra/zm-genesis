#!/usr/bin/env ruby
#
# pushing resolv.conf to all the system
require 'ping'
require 'yaml'

data = <<EOF
domain eng.vmware.com
search eng.vmware.com vmware.com
nameserver	10.137.244.7
nameserver	10.132.71.1
nameserver	10.132.71.2
EOF

1.upto(450) do |x|
  hostName = "zqa-%03i.eng.vmware.com"%x
  if(Ping.pingecho(hostName))
    command = 'ssh root@%s "cat /etc/resolv.conf"'%hostName
    puts command
    result =  `#{command}`
    if (result !~ /10.137.244.7/ && result =~ /nameserver/)
      puts "%s needs modification"%hostName
      `echo "#{data}" > /tmp/hi.txt`
      copy = "scp /tmp/hi.txt root@%s:/etc/resolv.conf"%hostName
      `#{copy}`
    end
  end
end

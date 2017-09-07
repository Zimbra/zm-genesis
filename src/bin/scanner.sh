#!/bin/bash
#
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# scan dogfood/catfood logs for errors
#
rm -f /data/syslogs/mailresult.txt
for i in dogfood.zimbra.com catfood.zimbra.com
do
   mkdir -p /data/syslogs/$i
   rsync zimbra@$i:/opt/zimbra/log/* /data/syslogs/$i
   rm -f /data/syslogs/$i/sync.log
   echo -e "==$i=======\n mailbox.log\n" > /data/syslogs/$i/mailme.txt
   egrep '( ERROR | FATAL )' /data/syslogs/$i/mailbox.log* | egrep -v 'lastConvId=-1' | sort -u -k 8  >> /data/syslogs/$i/mailme.txt
   egrep '(OutOfMem|StackOverflowError|TOO_MANY_HOPS)' /data/syslogs/$i/mailbox.log* >> /data/syslogs/$i/mailme.txt
   echo -e "\n nginx.log\n" >> /data/syslogs/$i/mailme.txt
   egrep -v '\[(info|notice)\]' /data/syslogs/$i/nginx.log >> /data/syslogs/$i/mailme.txt
   cat /data/syslogs/$i/mailme.txt >> /data/syslogs/mailresult.txt
done
cat - /data/syslogs/mailresult.txt << EOF | sendmail -t
to:qa-automation@zimbra.com
from:qa23@lab.zimbra.com
subject: Operation Logs Scan
Do NOT REPLY; AUTO GENERATED


EOF

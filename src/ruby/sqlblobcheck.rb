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
# Check the difference between mysql entries and blob on the system
#
# Usage.  run on the system as zimbra
# 
require 'set'
require 'getoptlong'

opts = GetoptLong.new(
  ['--brief', '-b', GetoptLong::NO_ARGUMENT],
  ['--filter', '-f', GetoptLong::REQUIRED_ARGUMENT]
)

filter = nil;
brief = false;

opts.each do |opt, arg|
  case opt
    when '--brief'
      brief = true
    when '--filter'
      filter = arg
  end
end

mailboxStatement = if filter
  "mysql -N -s -e \"select id, group_id, account_id, comment from zimbra.mailbox where comment like \'%#{filter}%\';\""
else
  "mysql -N -s -e 'select id, group_id, account_id, comment from zimbra.mailbox;'"
end    
mresult =  `#{mailboxStatement}`
#puts mresult

def getBlobDB(mailGroup, mailID)
  statement = "mysql -N -s -e 'select id, type, index_id, blob_digest, subject, mod_content from mboxgroup#{mailGroup}.mail_item where mailbox_id = #{mailID} and "+
  "index_id is NOT NULL and blob_digest like \"%=\"'"
  `#{statement}`.split(/\n/)
end

def getBlob(mailID)
  storage = '/opt/zimbra/store/0'
  mPath  = File.join(storage, mailID)
  statement = "ls -R #{mPath} | grep '\\\.msg' | sort -n --field-separator=- -u"
  if(File.exist?(mPath))
   `#{statement}`.split(/\n/)
  else
    []
  end
end


def getDetailDiffs(dbList, blobList)
  setOne = Set.new(dbList.map { |x| x.split(/\t/)[2].to_i })
  setTwo = Set.new(blobList.map { |x|  x.split(/\./)[0].split(/-/)[0].to_i })
  missingFromBlob = setOne - setTwo
  missingFromDB = setTwo - setOne
  [missingFromBlob.to_a.sort, missingFromDB.to_a.sort]
end

hasError = 0
mresult.split(/\n/).each do |x|
 mArray = x.chomp.split(/\t/)
 dbList = getBlobDB(mArray[1], mArray[0])
 blobList = getBlob(mArray[0])
 puts "#{mArray[3]}" unless brief
 if(dbList.size != blobList.size)
    hasError = 1
    puts "-- #{mArray[3]} #{mArray[0]} has corruption database entries #{dbList.size} blob entries #{blobList.size}"
    missA, missB = getDetailDiffs(dbList, blobList)
    puts "-- Missing from Blob #{missA.size} Missing from DB #{missB.size}"
    if(missA.size < 200)
      puts "-- Missing blobs #{missA.join(', ')}"
    else
      puts "-- Missing blobs information supressed"
    end
    if(missB.size < 200)
      puts "-- Missing DB #{missB.join(', ')}"
    else
      puts "-- Missing DB information supressed"
    end
    missA.each do |x|
       statement = "mysql -e 'select * from mboxgroup#{mArray[1]}.mail_item where mailbox_id = #{mArray[0]} and id = #{x}'"
       puts `#{statement}`
    end
    puts
 end
 
end
exit hasError

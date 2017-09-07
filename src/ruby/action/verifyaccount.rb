#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
#
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?ybur/,"").reverse; $:.unshift(File.join(mydata, 'ruby')) 
end
   
require 'set'
require 'action/runcommand' 
require 'action/stafsystem'
require 'tempfile'
require 'model/testbed'


module Action # :nodoc
  
  
  # Verify the data consistency of the account
  #
  # Current it does
  # 1) Check consistency between mysql and blob
  class VerifyAccount < Action::Command
    def initialize(pFilter = nil) 
      super()
      @filter = pFilter 
      @mailboxStatement = "-N -s -e \"select id, group_id, account_id, comment from zimbra.mailbox where comment like \\\"%#{@filter}%\\\"; \"" #single quote escape doesn't work
      self.timeOut = 4800
    end 
    
    # Get list of blob entries from mysql database
    def getBlobDB(mailGroup, mailID)
      statement = "-N -s -e \"select id, type, index_id, blob_digest, subject, mod_content from mboxgroup#{mailGroup}.mail_item where mailbox_id = #{mailID} and "+
      "index_id is NOT NULL and blob_digest like \\\"%=\\\"\"" #single quote escape doesn't work
      #`#{statement}`.split(/\n/)
      RunCommand.new('mysql', ZIMBRAUSER, statement).run[1].split(/\n/) rescue []
    end
    
    # Get list of blob entries from the disk drive
    def getBlob(mailID)
      storage = '/opt/zimbra/store/0' #TODO get the correct storage location
      mPath  = File.join(storage, mailID.to_s)
      statement = "ls -R #{mPath} | egrep '.msg$' | sort -n -t- -u"
      if(File.exist?(mPath)) 
        RunCommand.new(statement).run[1].split(/\n/).find_all {|x| x =~ /msg$/ } rescue []
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
    
    def run
      mResult = RunCommand.new('mysql', ZIMBRAUSER, @mailboxStatement).run[1] rescue [] 
      hasError = 0
      mReturns = []
      mResult.split(/\n/).each do |x|
        mArray = x.chomp.split(/\t/)
        dbList = getBlobDB(mArray[1], mArray[0])
        blobList = getBlob(mArray[0]) 
        if(dbList.size != blobList.size)
          hasError = 1
          mReturns <<  "-- #{mArray[3]} #{mArray[0]} has corruption database entries #{dbList.size} blob entries #{blobList.size}"
          missA, missB = getDetailDiffs(dbList, blobList)
          mReturns <<  "-- Missing from Blob #{missA.size} Missing from DB #{missB.size}"
          if(missA.size < 200)
            mReturns <<  "-- Missing blobs #{missA.join(', ')}"
          else
            mReturns <<  "-- Missing blobs information supressed"
          end
          if(missB.size < 200)
            mReturns <<  "-- Missing DB #{missB.join(', ')}"
          else
            mReturns <<  "-- Missing DB information supressed"
          end          
          statement = " -e \"select * from mboxgroup#{mArray[1]}.mail_item where mailbox_id = #{mArray[0]} and id IN (#{missA.join(', ')})\""         
          mReturns << begin RunCommand.new('mysql', ZIMBRAUSER, statement).run[1] rescue "" end        
        end 
      end
      return [hasError, mReturns]
    end
    
    
    def to_str
      "Action: VerifyAccount #{@prefix} 0 #{@finish} #{@domain}"
    end
  end
  
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMProv object
    class VerifyAccountTest < Test::Unit::TestCase
      def testGetBlobDB
        testObject = Action::VerifyAccount.new('ca '+ Model::TARGETHOST.cUser('remote2')+ ' zimbra') 
        assert(testObject.getBlobDB(1, 1).size > 0)
        assert(testObject.getBlobDB(1,1000).size == 0)    
      end
      
      def testGetBlob
        testObject = Action::VerifyAccount.new('ca '+ Model::TARGETHOST.cUser('remote2')+ ' zimbra') 
        assert(testObject.getBlob('1').size > 0)
        
      end
      
      def testRun
        testObject = Action::VerifyAccount.new('admin')
        assert(testObject.run.first == 0) 
      end
      
      
    end
  end
end

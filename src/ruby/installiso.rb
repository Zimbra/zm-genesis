#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
#
#  This script will kick off iso installation based on few assumption
#  #1 100 GB disk capacity, main hd is scsi device 0
#  #2 HD will be ereased prior to installation
#  #3 ISO will placed on IDE:0
# 2006 Zimbra
require 'getoptlong'
require 'yaml'

def getOptions
   [
     ['-h', GetoptLong::NO_ARGUMENT],
     ['-i', GetoptLong::REQUIRED_ARGUMENT],
     ['-s', GetoptLong::REQUIRED_ARGUMENT],
   ]
end

def helpMessage
   [
    'Kick off rpath ISO install',
    '-h help Message',
    '-s server',
    '-i iso'].each do |x|
      puts x
   end
end


def getSetting
   vminstance = iso = nil
   GetoptLong.new(*getOptions).each do | opt, arg|
      case opt
         when '-h' then
            helpMessage
         when '-s' then
            vminstance = arg
         when '-i' then
            iso = arg
      end
   end
   return vminstance, iso
end

@cashInstance = nil
def getInstanceHash
   if(@cashInstance.nil?)
      tArray = `vmware-cmd -l 2>/dev/null `.split(/\n/).map do |x|
         x = x.chomp
         [File.split(x)[0], x]
      end.flatten
      @cashInstance = Hash[*tArray]
   end
   @cashInstance
end

def isValidInstance(mInstance) 
   return false if mInstance.nil?
   # Trim last few /// if exists
   mInstance = mInstance.sub(/\/+$/,'')
   getInstanceHash.has_key?(mInstance)
end

def isValidIso(mIso)
   return false if mIso.nil?
   return false if not (File.exist?(mIso) && File.file?(mIso))
   `file #{mIso}`.upcase.include?('ISO')
end

def stopVirtual(mInstance)
   mInstance = mInstance.sub(/\/+$/,'')
   `vmware-cmd '#{getInstanceHash[mInstance]}' stop hard 2>/dev/null`
end

def startVirtual(mInstance)
   mInstance = mInstance.sub(/\/+$/,'')
   `vmware-cmd '#{getInstanceHash[mInstance]}' start 2>/dev/null`
end

def gethdvmfileName(mInstance)
   `vmware-cmd  '#{getInstanceHash[mInstance]}' getconfig scsi0:0.fileName 2>/dev/null`.sub(/^.*?=\s+/,'').chomp
end

def setISO(mInstance, nISO)
   mdata = []
   File.open(getInstanceHash[mInstance]).each { |line|
      mdata.push line if not line.include?("ide")
   }
   mdata = mdata + [
     "ide0:0.present = \"TRUE\"\n",
     "ide0:0.fileName = \"#{nISO}\"\n",
     "ide0:0.deviceType = \"cdrom-image\"\n"
   ]
   mOutFile = File.new(getInstanceHash[mInstance],"w")
   mOutFile.puts mdata
   mOutFile.close
   puts mdata 
 end

def eraseHD(mInstance)
  Dir.glob(File.join(mInstance,'*.vmdk')) do |x|
    File.unlink(x)
  end 
end

def createHD(mInstance, mHDFileName)
   puts `vmware-vdiskmanager -c -s 100.0Gb -a lsilogic -t 1 '#{File.join(mInstance, mHDFileName)}'`
end

vminstance, iso = getSetting.map { |x| File.expand_path(x) }
# Make sure argument is valid
if(isValidInstance(vminstance) &&  isValidIso(iso))
   # Shut down virtual machine
   stopVirtual(vminstance)
   # Reformat harddrive
   eraseHD(vminstance)
   createHD(vminstance, gethdvmfileName(vminstance))
   # Reset CDrom to point to iso
   setISO(vminstance, iso)
   # Boot
   startVirtual(vminstance)
else
   puts "Illegal argument #{vminstance} #{iso}"
   helpMessage
end

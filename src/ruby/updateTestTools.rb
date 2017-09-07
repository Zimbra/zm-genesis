#!/bin/env ruby
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# This script updates various test tools on QA00
#
require 'getoptlong'
require 'yaml'

opts = GetoptLong.new(
   [ '--help', '-h', GetoptLong::NO_ARGUMENT],
   [ '--filter', '-f', GetoptLong::REQUIRED_ARGUMENT ]
)

filter = nil

opts.each do |opt, arg|
   case opt
      when '--help'
           puts "--help  -h: This help"
           puts "--filter -f: Filter term" 
           exit
      when '--filter'
           filter = arg
   end
end

workList = [
   ['genesis', 'genesis.tgz', {'GNR-603' => 'TestToolsGNR603Genesis'}],
   ['mapivalidator','mapidata.tgz'],
   ['pstvalidator','pstdata.tgz'],
   ['soapvalidator','soapdata.tgz'],
   ['zimbraInstall','upgrade.tgz'],
   #['staf','stafstax.tgz', {'FRANK' => 'TestToolsMain', 'FRANK_TOI' => 'TestToolsMain'}],
   ['staf','stafstax.tgz', {'FRANK_TOI' => 'TestToolsMain'}],
   ['QTP', 'qtp.tgz', {'FRANK_TOI' => 'TestToolsFrankTOI'}],
   ['zimbraperf',['perfdata.tgz', 'perfcore.tgz'], {'main' => 'ZimbraPerfMain', 'FRANKLIN' => 'ZimbraPerfMain'}],
   ['zdesktopvalidator', 'zdesktop.tgz'],
   ['SelNG', 'selng.tgz']
]

#filter
workList = workList.map do |x|
   if(filter.nil? || x.first =~ /#{filter}/ )
      x
   else
      nil
   end
end.compact

workList.each do |x|
  puts "Erease #{x[0]}"
  `rm -r -f /opt/qa/#{x[0]}`
  puts "Untar #{x[1]}"
  if ((x.size > 2) && x[2].key?('main'))
    antdirectory = x[2]['main']
  else
    antdirectory = 'TestToolsMain'
  end
  anttarballa = x[1]
  anttarballa = [anttarballa] if anttarballa.class != Array
  
  anttarballa.each do |anttarball| 
    if(x[0] != 'staf')
      `tar -C /opt/qa/ -xzf /opt/qa/anthill/publishDir/#{antdirectory}/#{anttarball}`
    else
       `mkdir -p /opt/qa/#{x[0]}`
      `tar -C /opt/qa/#{x[0]} -xzf /opt/qa/anthill/publishDir/#{antdirectory}/#{anttarball}`
    end
  end
end

# Branch unrolling
branchMap = { 'main' => 'TestToolsMain' ,  'FRANKLIN' => 'TestToolsFranklin', 'GNR-603' => 'TestToolsMain'} #GNR-603 is not symboic linked because genesis exception

branchMap.each_pair do |key, value|
   workList.each do |x|
      puts "Erease #{key}/#{x[0]}"
      `rm -r -f /opt/qa/#{key}/#{x[0]}`
      if(x[0] != 'staf')
         `mkdir -p /opt/qa/#{key}`
      else
         `mkdir -p /opt/qa/#{key}/#{x[0]}`
      end
      
      anttarballa = x[1]
      anttarballa = [anttarballa] if anttarballa.class != Array
      
      antdirectory = value
      # check to see if particular tool has overwrite
      if ((x.size > 2) && x[2].key?(key))
         antdirectory = x[2][key]
      end
      anttarballa.each do |anttarball| 
        puts "Untar #{key}/#{anttarball} from #{antdirectory}"
        # package for staf stax is a bit different, temporary patch
        if(x[0] != 'staf')
          `nice tar -C /opt/qa/#{key} -xzf /opt/qa/anthill/publishDir/#{antdirectory}/#{anttarball}`
        else
          `nice tar -C /opt/qa/#{key}/#{x[0]} -xzf /opt/qa/anthill/publishDir/#{antdirectory}/#{anttarball}`
        end
      end
      `chmod -R ugo+w /opt/qa/#{key}`
   end
end

# Update STAF STAX
`tar -C /usr/local/staf/services/lib -xzf /opt/qa/anthill/publishDir/TestToolsMain/stafstax.tgz`


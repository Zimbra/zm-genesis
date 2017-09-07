#!/usr/bin/ruby -d
#
# Tai-Sheng Hwang
# Copyright (C) 2005 zimbra
#
# Short script to validate the files
#
fileList = Dir.glob(File.join("C:","corruption", "*")) 
fileList.each do |file|
  begin
    next if File.directory?(file)
    puts "New file #{file}"
    
    f = File.new(file, "r") 
    f = f.binmode
    dataSegment = 0
    myerror = false
    while(not f.eof and not myerror)
      mnumber = f.getc
      1.upto(3) { |i|
	if(not f.eof)	
		mnumber = f.getc * 256 ** i + mnumber
	end
      }     
      #puts "Segment #{dataSegment} Length #{mnumber}"
      dataSegment += 1
      if(mnumber == 0)
        puts "File #{file} Segment #{dataSegment} Zero length, data corruption"   
        myerror = true
        next     
      end
      data = ''
      while((data.length < mnumber) and not f.eof)
	      data = data + f.read(mnumber - data.length)
      end          
      if(data.length != mnumber)
        puts "File #{file} Segment #{dataSegment} #{data.length} #{mnumber} size corruption"    
        data = data.unpack('H*').join("-")	 
        puts data
        myerror = true
      else 
        #puts "File #{file} Segment #{dataSegment} #{data.length}"         
        #data = data.unpack('H*').join("-")	 
        #puts data
      end
    end
  rescue => exception
    puts "Igore #{exception} for file #{file}"  
  end
end

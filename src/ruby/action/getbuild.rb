#!/usr/bin/ruby -w
#
# = action/getbuild.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This will get a build from the build server
#
#!/usr/bin/ruby -w
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
 
require 'action/command'
require 'net/http' 
module Action # :nodoc

  #
  # Perform getbuild operation.  This class will fetch a patciular zimbra build
  # from http server
  #
  class GetBuild < Action::Command
  
    #
    #  Create a getbuild object.  The build server address is hard coded
    #  to http://zre-matrix.eng.vmware.com:80/main/builds
    #  === Example
    #  GetBuild() get latest build tar ball put in on current directory      
    def initialize(version = nil, retrieve = true, destination = nil, os = 'RHEL4', branch = 'main', bit = 'NETWORK')
      super()
      @version = version
      @retrieve = retrieve
      @filename = 'zcs.tgz'
      @destination = destination || Dir.getwd
      @urlString = "zre-matrix.eng.vmware.com"
      @port = 80
      @tries = 5
      @interval = 60 
      @os = os
      @branch = branch
      @bit = bit
    end
    
    #
    #  Perform execution
    #
    def run
      urlString = '/' << ["links", @os, @branch].join('/') << '/' 
      Net::HTTP.start(@urlString,@port) { |http| 
        response = nil
        (0..@tries).each do |i| 
          response = http.get(urlString)
          break if (response.code == '200')
          puts "Error #{response.code} Sleeping #{@interval}"
          $stdout.flush
          sleep @interval
        end 
        raise "retrievefailure" if (response.code != '200')      
        if(@retrieve && response.code == '200')
          destination = File.join(@destination, @filename)           
          a = open(destination,'w')        
          a.binmode          
          @version = get_latest(response.body) if @version == nil
          #tgz_name = pick_tgz_name(http, File.join(urlString, @version, 'ZimbraBuild'))
          puts @version
          #puts tgz_name
          http.request_get(File.join(urlString, @version, 'ZimbraBuild', 'i386' ,'zcs.tgz')) { |res|
            if(res.code != '200')
              a.close
              File.unlink(destination)
              raise "retrievefailure"
            end
            res.read_body { |segment| a.write(segment) } 
          }           
          a.close
        end
      }      
    end
    
    def pick_tgz_name(http, url)    
      result = http.get(url)
      return nil if result.code != '200' 
      result.body.select do |x|
        x.include?('.tgz')
      end.map do |y| 
        y.scan(/href="(.*?\.tgz)/).pop
      end 
    end
    
    def get_latest(dataArray)
      dataArray.select do |y|
        y.include?(@bit)    
      end.map do |z|
        z.scan(/\d+_#{@bit}/).pop   
      end.sort[-1]
    end
    
    def to_str
      "Action:getbuild host:#{@urlString} port:#{@port} version:#{@version}"
    end
  end 
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for GetBuild object
    class GetBuildTest < Test::Unit::TestCase
      def testRun
        testObject = Action::GetBuild.new('20050912140101_NETWORK')
        testObject.run
      end 
      
      def testgetLatest
        testObject = Action::GetBuild.new
        
        testArray = [ 'garbage',
        '<tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="20050823180101_NETWORK/">20050823180101_NETWORK/</a></td><td align="right">11-Sep-2005 08:41  </td><td align="right">  - </td></tr>',
        '<tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="20050825160101_NETWORK/">20050825160101_NETWORK/</a></td><td align="right">11-Sep-2005 08:41  </td><td align="right">  - </td></tr>',
        '<tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="20050906120101_NETWORK/">20050906120101_NETWORK/</a></td><td align="right">11-Sep-2005 08:40  </td><td align="right">  - </td></tr>',
        '<tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="20050906165315_NETWORK/">20050906165315_NETWORK/</a></td><td align="right">11-Sep-2005 08:40  </td><td align="right">  - </td></tr>',
        '<tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="20050911162838_NETWORK/">20050911162838_NETWORK/</a></td><td align="right">11-Sep-2005 16:33  </td><td align="right">  - </td></tr>'] 
        assert(testObject.get_latest(testArray) == '20050911162838_NETWORK', 'get latest logic test') 
      end
      
      def stestTGZ
        testObject = Action::GetBuild.new
         Net::HTTP.start( "build.lab.zimbra.com", 8000) { |http|
           url = '/' << ["links","RHEL4","main", "20050911162838_NETWORK", "ZimbraBuild"].join('/') << '/' 
           result = testObject.pick_tgz_name(http, url)
           puts result
         }
      end
    end
  end
end


 

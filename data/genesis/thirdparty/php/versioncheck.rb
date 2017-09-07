#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/zmprov"
require "action/verify"
require 'model/user'
require 'net/http'
require "#{mypath}/install/configparser"
require "action/oslicense"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "php version test"
content = '<html>\n' +
          '   <head>\n' +
          '      <title>PHP Test</title>\n' +
	        '      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">\n' +
          '    </head>\n' +
          '    <body><p><?php echo phpversion(); ?></p></body>\n' +
          '</html>'
hostname = 'UNDEF'


include Action 

(mCfg = ConfigParser.new).run

#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#
current.action = [
  mCfg.getServersRunning('apache').map do |x|
    v(cb("php version check", 180) do
      mObject = RunCommand.new('echo', 'root', '-e', "\"#{content}\" > /opt/zimbra/data/httpd/htdocs/version.php", Model::Host.new(x))
      mResult = mObject.run
      port = '7780'
      url = URI.parse("http://#{x}:7780/version.php")
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      if !res.kind_of?(Net::HTTPOK)
        res = [1, 'error - ' + res.body]
      else
        res = res.body[/<p>(.*)<\/p>/, 1]
      end
      [0, res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == OSL::LegalApproved['php'] 
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - php version test' => {"IS" => data[1], "SB" => OSL::LegalApproved['php']}}
      end
    end
  end,

]

#
# Tear Down
#
current.teardown = [      
 
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
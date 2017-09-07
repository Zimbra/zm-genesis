#
# Simple script to help oauth testing
#
#  do read README.TXT on zimbra oauth to see how it works
#
gem 'oauth'
require 'oauth/consumer'
require 'yaml'
require 'oauth/signature/plaintext'
require 'oauth/signature/rsa/sha1'

consumer=OAuth::Consumer.new "AVff2raXvhMUxFnif06g", 
                             "u0zg77R1bQqbzutAusJYmTxqeUpWVt7U2TjWlzbVZkA",
                              {
                               :signature_method => 'PLAINTEXT',
                               :site=>"http://zqa-061.eng.vmware.com", 
                               :request_token_path => "/service/extension/oauth/req_token",
                               :authorize_path =>     "/service/extension/oauth/authorization",
                               :access_token_path =>  "/service/extension/oauth/access_token"
                              }

request_token = consumer.get_request_token
puts YAML.dump(request_token.authorize_url)
puts "giveme access token"
at = gets.chomp
puts "hi"
puts at
access_token = request_token.get_access_token(:oauth_verifier => at)
puts YAML.dump(access_token)
# restart zimbra server here to check if everything persists
puts "press enter"
gets.chomp
response = access_token.get("/service/home/testme@zqa-061.eng.vmware.com/inbox.rss")
puts YAML.dump(response)

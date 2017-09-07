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
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
  
require 'action/soap/clientauthhandler.rb'
require 'action/soap/getfolder.rb'
require 'action/soap/login.rb'
 

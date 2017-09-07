#!/bin/env python
#
# Simple script to fetch latest build from the server
# 
# Bill Hwang
#
# Underlying library is much more future riched.  However those are not needed
# at this moment
#
# This script will be enhanced later to have automatic install capability
#
from action import *

if __name__ == '__main__':    
 
    runScript = [getbuild.GetBuild(), untar.Untar(), install.Install()]       
    print "Start running automatic installation"
    for item in runScript:
        item.run()   



 
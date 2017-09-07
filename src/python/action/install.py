#!/bin/env python
#
#
# Library module that actually unroll the build
#
import command #IGNORE:W0403
import unittest
import os

class Install(command.Command): #IGNORE:R0903
    def __init__(self, confFile = 'current.conf'):
        super(Untar, self).__init__()
        self.fileName = filename
        self.commandLine = 'install.sh '         
        
    def run(self):
        executionString = " ".join([self.commandLine, self.fileName])
        os.system(executionString)
 
        
class TestUntar(unittest.TestCase):
    def testInstall(self):
        pass
    
if __name__ == '__main__':
    unittest.main()  
#!/bin/env python
#
#
# Library module that actually unroll the build
#
import command #IGNORE:W0403
import unittest
import os

class Untar(command.Command): #IGNORE:R0903
    def __init__(self, filename = 'zimbramail.tgz'):
        super(Untar, self).__init__()
        self.fileName = filename
        self.commandLine = 'tar -xvzf'         
        
    def run(self):
        executionString = " ".join([self.commandLine, self.fileName])
        os.system(executionString)
 
        
class TestUntar(unittest.TestCase):
    def testUnroll(self):
        runMe = Untar('\\'.join(['testdata', 'cookie.tgz']))
        runMe.run() 
    
if __name__ == '__main__':
    unittest.main()  
        
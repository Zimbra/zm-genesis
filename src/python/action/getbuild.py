import urllib
import urllib2
import unittest
import re
import os

from command import Command #IGNORE:W0403 

class GetBuild(Command):
    
    def __init__(self, version = 'latest', retrieve = True, destination = None):
        super(GetBuild, self).__init__()
        self.version = version       
        self.retrieve = retrieve
        self.filename = 'zimbramail.tgz'
        if(destination == None):
            self.destination = os.getcwd()
        else:
            self.destination = destination
        self.urlString = "http://build.zimbra.com:8000/main/builds"
        self.response = None
        self.buildList = None
    
    def run(self):
        urlstring = "/".join([self.urlString, self.version])         
        self.response = urllib2.urlopen(urlstring)       
        if(self.retrieve == True):              
            urllib.urlretrieve("/".join([urlstring, self.filename])
            , "/".join([self.destination, self.filename])) 
        
    def getLiveList(self):
        urlString = "http://build.zimbra.com:8000/main/index.html"
        response = urllib2.urlopen(urlString)
        line = response.readline()
        pattern = re.compile('<A HREF="builds/(\d*?)"')
        self.buildList = [];
        while(line):             
            match = pattern.match(line)
            if(match != None):
                self.buildList.append(match.group(1))
            line = response.readline()
        response.close()
        return self.buildList
    
    def getVersion(self):
        urlstring = "/".join([self.urlString, self.version]) 
        response = urllib2.urlopen(urlstring)        
        line = response.readline()
        pattern = re.compile('zimbra-core-(.*?)\.i386')
        version = None
        while(line):                         
            match = pattern.search(line)
            if(match != None):
                version = match.group(1)                 
                break
            line = response.readline()
        return version
 
class GetBuildTest(unittest.TestCase): #IGNORE:R0904
    
    def testExecuteDefault(self):
        build = GetBuild()
        build.retrieve = False
        try:
            build.run()
            #print build.response.read()
        except urllib2.HTTPError, inst: 
            failemessage = "Default fetch test failure %s"% inst
            self.fail(failemessage)
            
    def testRetrieveDefault(self):
        build = GetBuild()
        try:
            build.run()
            #print build.response.read()
        except urllib2.HTTPError, inst: 
            failemessage = "Default fetch test failure %s"% inst
            self.fail(failemessage)        
            
    def testExecuteNotFound(self):
        build = GetBuild("dummy", False)
        try:
            build.run()
            print build.response.read()
            self.fail("No exception raised on bogus url link %s"% 
                build.urlString)
        except urllib2.HTTPError: #IGNORE:W0704
            pass
        except:
            self.fail("Non http error exception raised")
            raise            
    
    def testNonDefault(self):
        build = GetBuild()
        mylist = build.getLiveList()
        if(len(mylist) == 0):
            self.fail("No build to conduct the test")
        else:
            build.version = mylist[0]
            build.retrieve = False
            try:
                build.run()
            except urllib2.HTTPError, inst:
                failemessage = "test Nondefault failure %s"% inst
                self.fail(failemessage)

    def testNonDefaultRetrieve(self):
        build = GetBuild()
        mylist = build.getLiveList() 
        if(len(mylist) == 0):
            self.fail("No build to conduct the test")
        else:
            build.version = mylist[0]
            build.retrieve = True
            build.destination = 'C:\\' 
            
            try:
                os.remove('C:\\'+'zimbramail.tgz')            
            except OSError: #IGNORE:W0704
                pass
                
            try:
                build.run()
                self.assertEqual(os.path.isfile('C:\\'+'zimbramail.tgz'), True, 
                "File is not being written")
                os.remove('C:\\'+'zimbramail.tgz')                
            except urllib2.HTTPError, inst:
                failemessage = "test Nondefault failure %s"% inst
                self.fail(failemessage)
                
    def testGetVersion(self):
        build = GetBuild() 
        self.assertNotEqual(build.getVersion(), None, "Version Fetch Failure")
    
   
if __name__ == '__main__':
    unittest.main()     
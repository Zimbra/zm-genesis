import unittest

class Config(object):
    """
    Place holder for different configuration in the system
    """
    def __init__(self):
        """
        Initialization routine
        """
        self.archiveName = None        
        self.reload()        
    
    def reload(self):
        self.archiveName = "zimbramail.tgz" #Name of the archive file 
        
class ConfigTest(unittest.TestCase):
    """
    Test initialization, basic test
    """
    def testCreateMe(self):
        testOne = Config()
        self.assertNotEqual(testOne, None)
        
if __name__ == '__main__':
    unittest.main()  
        
        
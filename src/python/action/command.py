import unittest

class Command(object):
    """
    A base class for command object
    """
    
    def __init__(self):
        """
        Initialization method
        """
        pass
    
    def run(self):
        """
        Run particular command
        """
        pass

class CommandTest(unittest.TestCase):
    def testInit(self):
        testObject = Command()         
        
    def testRun(self):
        " Run command "
        testObject = Command()
        testObject.run()

if __name__ == '__main__':
    unittest.main()
# [ COPYRIGHT CLASE HERE]
import unittest
from . import Entity
from . import Location
from . import Strings

class ProcessTestSuite(unittest.TestCase):
    def test_name_and_location(self):
        """Function is working fine when given a name and a location."""
        result = Strings.Process("", Location.NAME)
        self.assertNotEqual(result, "")

    def test_empty_name(self):
        """Function is working fine when a given name is empty."""
        result = Strings.Process("", Location.NAME)
        self.assertNotEqual(result, "")


    def test_empty_location(self):
        """Function is working fine when a given location is empty."""
        result = Strings.Process(Entity.NAME, "")
        self.assertNotEqual(result, "")


    def test_empty_name_and_location(self):
        """Function is working fine when a given name and a given location are both empty."""
        result = Strings.Process("", "")
        self.assertEqual(result, "")

if __name__ == '__main__':
    unittest.main()

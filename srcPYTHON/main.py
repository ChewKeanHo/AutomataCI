__copyright__ = """
    Copyright <YEAR> <NAME>

    [ LICENSE_NOTICE_HERE ]
"""
__license__ = "[ LICENSE_SPDX_ID_HERE ]"
################################################################################
import sys
from libs.Sample import Entity
from libs.Sample import Location
from libs.Sample import Strings

def main() -> int:
    print("Hello " + Strings.Process(Entity.NAME, Location.NAME))
    return 0


if __name__ == '__main__':
    sys.exit(main())

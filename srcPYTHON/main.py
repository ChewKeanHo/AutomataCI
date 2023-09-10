__copyright__ = """
    Copyright <YEAR> <NAME>

    [ LICENSE_NOTICE_HERE ]
"""
__license__ = "[ LICENSE_SPDX_ID_HERE ]"
################################################################################
import sys
from Libs.Sample import Entity
from Libs.Sample import Location
from Libs.Sample import Strings

def main() -> int:
    print("Hello " + Strings.Process(Entity.NAME, Location.NAME))
    return 0


if __name__ == '__main__':
    sys.exit(main())

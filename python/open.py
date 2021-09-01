__author__  = "Silvano Furlan"
__date__    = "4july2021"
__python__  = "python3"

"""
### open.py ###
---------------
Open up a communication with the stDAQ
and return the firmware version.
"""

import stdaq

daq = stdaq.STDAQ('COM9') # open the communication

[pkg,rel,sub] = daq.version()

print("\n stDAQ version: ({}) r.{}.{}\n".format(pkg,rel,sub))

del daq # close the communication

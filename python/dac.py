__author__  = "Silvano Furlan"
__date__    = "4july2021"
__python__  = "python3"

"""
### dac.py ###
---------------
Generate a triangular wave from the dac on pin PA4,
sweeping 0 to 3.3V, with incremental steps of 10mV.
"""

import stdaq
from time import sleep

daq = stdaq.STDAQ('COM9') # open the communication

daq.set_dac(4095)
daq.enable_dac()

step = 12
taps = 341
periods = 10

for i in range(2*taps*periods):
    value = abs(step*((i%(2*taps))-taps))
    daq.set_dac(value)
    sleep(0.001)

del daq # close the communication

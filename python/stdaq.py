__author__  = "Silvano Furlan"
__date__    = "4july2021"
__python__  = "python3"
__version__ = "1.0.0"

"""
### stdaq.py ###
----------------
class for the stDAQ python API

"""

import serial
import struct

class STDAQ:
    
    def __init__(self, comport, verbose=True):
        # open the COM port to read/write data to the stDAQ
            
        self.ser = serial.Serial(comport,9600,timeout=0.1)
            
        while (self.ser.readline() != b''): 
            pass
        
        if (self.ser.is_open == True):
            [self.package,self.revision,self.subrevision] = self.version()
            if (verbose):
                print("\n!> Connected to stDAQ: ({}) ver.{}.{}".format(self.package,self.revision,self.subrevision))
        else:
            print("\n!> Connection NOT successful!\n")
            self.ser.write("s{}".format(struct.pack('<BBB',3,1,0)))
            self.ser.write("a{}".format(struct.pack('<BB',0,10)))
            rx = self.ser.read(20)
            
        pass
        
    def version(self):
        # get the version of the stDAQ firmware
        
        self.ser.write("vn".encode('utf-8'))
        package = self.ser.readline()
        
        self.ser.write("vr".encode('utf-8'))
        rev = self.ser.read(1)
        revision = struct.unpack('<B',rev)[0]
        sub = self.ser.read(1)
        subrevision = struct.unpack('<B',sub)[0]
        
        return [package[0:-1],revision,subrevision]
    
    def set_adc(self, channelsequence, clockdivision):
        # set the ADC channels for the acquisition with stdaq
        # channelsequence is an array of max 16 entries with value ranging from [0-16]
        # with the exclusion of 4 and 8, which is not available on stdaq (NUCLEO-F413ZH)
        # repetition of the same value is possible inside channelsequence
        # i.e: channelsequence = [0,0,1,1,0,5,6,15,16];
        # where 0 = channel 0, 1 = channel 1, .... 16 = temperature sensor
        # clockdivision is a value in [0-9] corresponding to a division of the 1MHz
        # reference clock into 0 = 1MHz, 1 = 500KHz, 2 = 250KHz, 3 = 125KHz, ...
        
        nch = len(channelsequence);
        if (nch>16):
            printf("\n!> Sequence MUST be max. 16!")
            return
        
        if ((4 in channelsequence) | (8 in channelsequence)):
            printf("\n!> Channel 4 and 8 in the sequence are NOT supported on NUCLEO-F413ZH!")
            return
        
        if (clockdivision < 0 | clockdivision > 9):
            printf("\n!> Clock division must be between [0-9]!")
            return
        
        #if (self.write("t{}".format(struct.pack('<B',clockdivision+48)) != 2):
        #    printf("\n!> Write to clockdivision is NOT successfull!")
        #    return
        
        seq = "s{}".format(struct.pack('<BB',clockdivision,nch))
        for i in range(nch):
            seq = seq + "{}".format(struct.pack('<B',channelsequence[i]))
            
        if (self.ser.write(seq) != 3+nch):
            printf("\n!> Write to channelsequence is NOT successfull!")
            return
        
    def get_adc(self, channelsequence, numsamplesperchannel):
        # acquisition of the values from the ADC channels with stdaq
        # numsamplesperchannel is the number of samples per channel returned by the acquisition
        # samples is an array of [numchannels x numsamplesperchannel] with the 12bits ADC values
        # scaled to 0-3.3V. For the temperature channel, the value is returned already scaled in Celsius.
        # NOTE: the stdaq MUST BE first set with stdaq_set_adc() and channelsequence MUST BE the same.
    
        nch = len(channelsequence)
        nrx = 2*nch*numsamplesperchannel
        samples = []
        
        nhi = int(numsamplesperchannel/256) #floor
        nlo = numsamplesperchannel%256
        
        msg = "a{}".format(struct.pack('<BB',nhi,nlo))
        if (self.ser.write(msg) != 3):      # start acquisition
            printf("\n!> Acquisition NOT started!")
            return samples
        
        adc = []
        for i in range(numsamplesperchannel):
            rx = self.ser.read(2*nch)
            for j in range(len(rx)):
                adc = [adc,struct.unpack('<B',rx(j))[0]]
                
        # format sample in 16 bits half-words
        factor = 3.3/4096.0
        for i in range(nch):
            ch = []
            for j in range(numsamplesperchannel):
                a = j*nch*2+i*2
                ch = [ch, (adc[a]+256*adc[a+1])*factor]
            samples = [samples, ch]
            
        # Temp_Celsius = (Vsense-V25) / avg_slope + 25
        # V25 = 0.76 V
        # avg_slope = 2.5 mV/C
        if (16 in channelsequence):
            tempidx = [i for i, e in enumerate(channelsequence) if e == 16]
            for k in range(len(tempidx)):
                for t in range(numsamplesperchannel):
                    samples[k][t] = (samples[k][t] - 0.76)/0.0025 + 25
                    
        return samples
    
    
    def set_dac(self, value):
        # set the DAC1 value to the desired output
        # value is a 12bit value [0-4095]
        
        if (value<0 or value>4095):
            print("\n!> Value is out of boundary [0-4095]!")
            return
    
        nhi = int(value/256) #floor
        nlo = value%256
        
        msg = "d{}".format(struct.pack('<BB',nhi,nlo))
        if (self.ser.write(msg) != 3):
            print("\n!> DAC value NOT set!")
            return
        
    def enable_dac(self):
        # enable DAC 
        if (self.ser.write("de".encode('utf-8')) != 2):
            print("\n!> DAC NOT enabled!")
            return
        pass
    
    def disable_dac(self):
        # disable DAC 
        if (self.ser.write("dd".encode('utf-8')) != 2):
            print("\n!> DAC NOT disabled!")
            return
        pass
    
    def get_gpio(self, pin):
        # get the value from the register of the input pin
        if (pin < 0 & pin > 3):
            print("\n!> input pin must be PE[0-3]!")
            return
        
        msg = "gg{}".format(struct.pack('<BB',pin,0))
        if (self.ser.write(msg) == 4):
            ret = self.ser.read(1)
            value = struct.unpack('<B',ret)[0]
        else:
            print("\n!> GPIO input NOT gotten!")
            value = -1
        
        return value
        
    def set_gpio(self, pin, value):
        # set the GPIO pin to [0,1] output value
        if (value != 0 & value != 1):
            print("\n!> input value must be [0,1]!")
            return
        if (pin < 0 | pin > 7):
            print("\n!> input pin must be PD[0-7]!")
            return
        
        msg = "gs{}".format(struct.pack('<BB',pin,value))
        if (self.ser.write(msg) != 4):
            print("\n!> GPIO output NOT set!")
            return
        
    def toggle_gpio(self, pin):
        # toggle the status of a gpio output
        if (pin < 0 | pin > 7):
            print("\n!> input pin must be [0-7]!")
            return
        
        msg = "gt{}".format(struct.pack('<BB',pin,0))
        if (self.ser.write(msg) != 4):
            print("\n!> GPIO output NOT toggled!")
            return
        
    def toggle_led(self, ledcolor):
        # toggle the led color
        if (ledcolor=='r'): # toggle red
            if (self.write("lr") != 2):
                print("\n!> LED NOT toggled!")
                return
        elif (ledcolor=='g'): # toggle green
            if (self.write("lg") != 2):
                print("\n!> LED NOT toggled!")
                return
        elif (ledcolor=='b'): # toggle blue
            if (self.write("lb") != 2):
                print("\n!> LED NOT toggled!")
                return
        else:
            printf("\n!> Color NOT recognized; must be [r,g,b]!")
            return
        
    def set_pwm(self):
        pass
    
    def enable_pwm(self):
        pass
    
    def disable_pwm(self):
        pass
    
    def read_i2c(self, i2c_address, reg_address, num_bytes):
        # Read from the I2C in standard mode 100 kHz non-strech clock
        # i2c_address: is a 7-bit address [0-127]
        # reg_address: is the address of the register for a memory address size of 8 bits
        # num_bytes: number of bytes, maximum read of 32 bytes
        # rx: is an array with the returned values
        # len: is the length of the array (if -1, means no output available)
        
        out = []
        
        if (num_bytes > 32):
            print("\n!> the argument num_bytes can be of maximum 32 bytes!")
            return [out,-1]
        
        if (i2c_address > 127):
            print("\n!> the I2C address MUST be a 7-bit address!")
            return [out,-1]
        
        if (reg_address > 255):
            print("\n!> the register address MUST be a 8-bit address!")
            return [out,-1]
        
        msg = "ir{}".format(struct.pack('<BBB',i2c_address,reg_address,num_bytes))
        if (self.ser.write(msg) != 5):
            print("\n !> I2C read command NOT sent sucessfully!")
            return [out,-1]
        else:
            rx = self.read(num_bytes)
            for i in range(len(rx)):
                out = [out,struct.unpack('<B',rx(i))[0]]
            
            return [out,len(out)]
        
    def write_i2c(self, i2c_address, reg_address, data):
        # Write to the I2C in standard mode 100 kHz non-strech clock
        # i2c_address: is a 7-bit address [0-127]
        # reg_address: is the address of the register for a memory address size of 8 bits
        # data: array with data where each entry must be < 256 and maximum length of 32 entries
            
        # check data array
        tx_size = len(data);
        
        if (data>=256 | tx_size>32):
            print("\n !> data MUST have numerical entries [0-255] and a max. length of 32!")
            return
        
        if (i2c_address > 127):
            print("\n!> the I2C address MUST be a 7-bit address!")
            return 
        
        if (reg_address > 255):
            print("\n!> the register address MUST be a 8-bit address!")
            return
        
        msg = "iw{}".format(struct.pack('<BBB',i2c_address,reg_address,tx_size))
        for i in range(len(data)):
            msg = msg + "{}".format(struct.pack('<B',data[i]))
            
        if (self.ser.write(msg) != 5+tx_size):
            print("\n !> I2C write command NOT sent sucessfully!")
            return
    
    def __del__(self):
        # on class delete
        self.ser.close()
    

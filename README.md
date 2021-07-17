# stDAQ
![stDAQ_logo](docs/img/stDAQ_logo.png)

## An Affordable Data Acquisition System with an ST-Nucleo board and Scilab/Python interface

### Description

stDAQ transforms an ST-NUCLEO board into an easy programmable and versatile data acquisition system.
Environments like Scilab or Python running on a PC can be used to interact and program the stDAQ data acquisition. 
In the current version, the following peripherals are programmable on the ST NUCLEO-F413ZH board:
- 1x 12 bits ADC with 14 multiplexed channels
- 1x 12 bits DAC
- 8x GPIO pins
- 3x LEDs (RGB)
- 1x timer (t.b.d.)
- 1x PWM (t.b.d.)
- 1x I2C interface (t.b.d.)

More details about the programming, performance evaluation and the installation are available in the PDF reference manual, in the /docs/refman folder.

### Requirements & installation

We are using the ST NUCLEO-F413ZH board, which can be bought here <a href="https://www.digikey.com/en/products/detail/stmicroelectronics/NUCLEO-F413ZH/6559189"> NUCLEO-F413ZH</a> for about 20$.
The NUCLEO-F413ZH board needs to be flushed with the binary file provided in the nucleo folder, see instruction in reference manual.
Install <a href="https://www.scilab.org/"> Scilab </a>, launch it and run the scilab/runme.sci script to load the stDAQ library into the environment (currently tested only with v6.0.2 on Windows 8.1).


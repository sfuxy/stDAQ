// Author: S.Furlan
// Date: 3 July 2021

exec loader.sce;

function out = stdaq_open( port ) 

    out = call("stdaq_open",...
        port,1,"c",...
        "out",...
        [1,1],2,"i");
    
    if (out<0) then
         mprintf("\n !> %s port not found!\n",port);
    else 
        mprintf("\n !> %s port open!\n",port);
    end
    
endfunction

//function out = stdaq_read( rx_length )
function [rx,len] = stdaq_read( rx_length )
    /*
    out = call("stdaq_read",...
        "out",...
        [1,1],1,"i");
    */
    if (rx_length>256) then
        rx_length = 256;
    end
    [rx,len] = call("stdaq_read",...
        rx_length,1,"i",...
        "out",...
        [1,rx_length],2,"i",...
        [1,1],3,"i");
    
endfunction

function out = stdaq_write( tx_buffer, tx_length )

    if (tx_length > 64) 
        mprintf("\n !> tx_length MUST be <= 64!");
        out = -1;
        return;
    end
    
    out = call("stdaq_write",...
        tx_length,1,"i",...
        tx_buffer,2,"i",...
        "out",...
        [1,1],3,"i");

    //tx_buffer,2,"c",...

endfunction

function stdaq_close( )
    // close the VCOM port to the stdaq
    call("stdaq_close");
    
endfunction

function [package,revision,subrevision] = stdaq_version()
    // returns the version information of the current stDAQ firmware
    if (stdaq_write(ascii(['v','n']),2)>=0) then
        [rx,len] = stdaq_read(256);
        package = ascii(rx(1:len));
    end
    if (stdaq_write(ascii(['v','r']),2)>=0) then
        [rx, len] = stdaq_read(256);
        revision = rx(1);
        subrevision = rx(2);
    end
endfunction
    
function stdaq_set_adc( channelsequence, clockdivision )
    // set the ADC channels for the acquisition with stdaq
    // channelsequence is an array of max 16 entries with value ranging from [0-16]
    // with the exclusion of 4 and 8, which is not available on stdaq (NUCLEO-F413ZH)
    // repetition of the same value is possible inside channelsequence
    // i.e: channelsequence = [0,0,1,1,0,5,6,15,16];
    // where 0 = channel 0, 1 = channel 1, .... 16 = temperature sensor
    // clockdivision is a value in [0-9] corresponding to a division of the 1MHz
    // reference clock into 0 = 1MHz, 1 = 500KHz, 2 = 250KHz, 3 = 125KHz, ...
    
    nch = length(channelsequence);
    if (nch>16) then
        mprintf("\n!> Sequence MUST be max. 16!");
        return;
    end
    if (length(find((channelsequence==4)||(channelsequence==8)))>0) then
        mprintf("\n!> Channel 8 in the sequence is NOT supported on NUCLEO-F413ZH!");
        return;
    end
    if (clockdivision<0 || clockdivision>9) then
        mprintf("\n!> Clock division must be between [0-9]!");
        return;
    end
    if (stdaq_write([ascii('t'),clockdivision+48],2)<0) then
    //if (stdaq_write(msprintf("t%c",char(clockdivision+48)),2)<0) then
        mprintf("\n!> Write to clockdivision is NOT successfull!");
        return;
    end

    //seq = msprintf("s%c",char(nch+96));
    //for i=1:nch
    //    seq = msprintf("%s%c",seq,char(channelsequence(i)+97));
    //end
    seq = [ascii('s'),nch+96,channelsequence+97];
    if (stdaq_write(seq,2+nch)<0) then
        mprintf("\n!> Write to channelsequence is NOT successfull!");
        return;
    end
    
endfunction

function samples = stdaq_get_adc( channelsequence, numsamplesperchannel )
    // acquisition of the values from the ADC channels with stdaq
    // numsamplesperchannel is the number of samples per channel returned by the acquisition
    // samples is an array of [numchannels x numsamplesperchannel] with the 12bits ADC values
    // scaled to 0-3.3V. For the temperature channel, the value is returned already scaled in Celsius.
    // NOTE: the stdaq MUST BE first set with stdaq_set_adc() and channelsequence MUST BE the same.
    
    nch = length(channelsequence);
    nrx = 2*nch*numsamplesperchannel;
    adc = zeros(1,nrx); 
    
    nhi = floor(numsamplesperchannel/256);
    nlo = pmodulo(numsamplesperchannel,256);
    
    //if (stdaq_write(msprintf("a%c%c",char(nhi),char(nlo)),3)<0) then // start acquisition
    if (stdaq_write([ascii('a'),nhi,nlo],3)<0) then // start acquisition
        mprintf("\n!> Acquisition NOT started!");
        return;
    end 
    
    inc = 1;
    adc = zeros(1,nrx);
    while (nrx>0) // till acqisition is over
        [rx,len] = stdaq_read(256);
        /*
        if (nrx/256 > 0) then 
            [rx,len] = stdaq_read(256);
        else
            [rx,len] = stdaq_read(pmodulo(nrx,256));
        end
        */
        
        if (len>0) then
            adc(1,inc:(inc+len-1)) = rx(1:len);
            inc = inc + len;
            nrx = nrx - len;
            //mprintf("%d",nrx);
        end
    end
    
    
    // format samples
    samples = zeros(numsamplesperchannel,nch);
    for i=1:numsamplesperchannel
        for j=1:nch
           samples(i,j) = adc(1,(i-1)*nch*2+(j-1)*2+1)+256*adc(1,(i-1)*nch*2+j*2); 
        end
    end
    
    samples = samples/4096*3.3;
    
    // if TEMPERATURE_SENSOR then
    // Temp_Celsius = (Vsense-V25) / avg_slope + 25;
    // V25 = 0.76 V
    // avg_slope = 2.5 mV/C
    tempidx = find(channelsequence==16);
    if (~isempty(tempidx)) then 
        samples(:,tempidx) = (samples(:,tempidx)-0.76)/0.0025 + 25;
    end
    
    
endfunction

function stdaq_set_dac(value)
    // set the DAC1 value to the desired output
    // value is a 12bit value [0-4095]
    
    if (value<0 || value>4095) then
        mprintf("\n!> Value is out of boundary [0-4095]!");
        return;
    end
    
    nhi = floor(value/256);
    nlo = pmodulo(value,256);
    
    if (stdaq_write([ascii('d'),nhi,nlo],3)<0) then
        mprintf("\n!> DAC value NOT set!");
        return;
    end
    
    //sleep(1); // max. refresh limit
endfunction

function stdaq_enable_dac()
    // enable DAC 
    if (stdaq_write(ascii(['d','e']),2)<0) then
        mprintf("\n!> DAC NOT enabled!");
        return;
    end
endfunction

function stdaq_disable_dac()
    // disable DAC 
    if (stdaq_write(ascii(['d','d']),2)<0) then
        mprintf("\n!> DAC NOT disabled!");
        return;
    end
endfunction

function value = stdaq_get_gpio(pin)
    // get the value from the register of the input pin
    if (pin<0 && pin>3) then
        mprintf("\n!> input pin must be PE[0-3]!");
        return;
    end
    if (stdaq_write([ascii('g'),ascii('g'),pin,0],4)>=0) then
        [rx,len] = stdaq_read(1);
        value = rx(1);
    else
        mprintf("\n!> GPIO input NOT gotten!");
    end 
endfunction

function stdaq_set_gpio(pin, value)
    // set the GPIO pin to [0,1] output value
    if (value~=0 && value~=1) then
        mprintf("\n!> input value must be [0,1]!");
        return;
    end
    if (pin<0 && pin>7) then
        mprintf("\n!> input pin must be PD[0-7]!");
        return;
    end
    if (stdaq_write([ascii('g'),ascii('s'),pin,value],4)<0) then
        mprintf("\n!> GPIO output NOT set!");
        return;
    end
endfunction

function stdaq_toggle_gpio(pin)
    // toggle the status of a gpio output
    if (pin<0 && pin>7) then
        mprintf("\n!> input pin must be [0-7]!");
        return;
    end
    if (stdaq_write([ascii('g'),ascii('t'),pin,0],4)<0) then
        mprintf("\n!> GPIO output NOT toggled!");
        return;
    end
endfunction

function stdaq_toggle_led(ledcolor)
    // toggle the led color
    if (ledcolor=='r') then // toggle red
        if (stdaq_write(ascii(['l','r']),2)<0) then
            mprintf("\n!> LED NOT toggled!");
            return;
        end
    elseif (ledcolor=='g') then // toggle green
        if (stdaq_write(ascii(['l','g']),2)<0) then
            mprintf("\n!> LED NOT toggled!");
            return;
        end  
    elseif (ledcolor=='b') then // toggle blue
        if (stdaq_write(ascii(['l','b']),2)<0) then
            mprintf("\n!> LED NOT toggled!");
            return;
        end   
    else
        mprintf("\n!> Color NOT recognized; must be [r,g,b]!");
        return;    
    end
endfunction

function stdaq_set_pwm()
endfunction

function stdaq_start_pwm()
endfunction

function stdaq_stop_pwm()
endfunction

function stdaq_set_timer()
endfunction

function stdaq_start_timer()
endfunction

function stdaq_stop_timer()
endfunction

function stdaq_set_i2c()
endfunction

function stdaq_read_i2c()
endfunction

function stdaq_write_i2c()
endfunction

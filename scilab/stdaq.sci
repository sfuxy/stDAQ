// Author: S.Furlan
// Date: 3 July 2021

exec loader.sce;

global tim_params;
tim_params = [-1,-1;-1,-1;-1,-1];

function out = stdaq_open( port ) 

    global tim_params;
    out = call("stdaq_open",...
        port,1,"c",...
        "out",...
        [1,1],2,"i");
    
    if (out<0) then
         mprintf("\n !> %s port not found!\n",port);
    else 
        mprintf("\n !> %s port open!\n",port);
        tim_params = [-1,-1;-1,-1;-1,-1];
        // warm-up ADC
        //stdaq_write(ascii(['t','3']),2) // set sampling freq. = 125 KHz
        //stdaq_write([ascii('s'),3,ascii(['d','a','b','c','d'])],7); // set sampling freq. 125kHz & ch0-ch3
        stdaq_write([ascii('s'),3,4,0,1,2,3],7); 
       // sleep(10);
        //stdaq_write(ascii(['s','d','b','b','c','d']),6) 
        sleep(10);
        stdaq_write([ascii('a'),0,10],3); // start acquisition with 8224 repeatitions
        sleep(10);
        [rx,len] = stdaq_read(256);
        
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
        mprintf("\n!> Channel 4 and 8 in the sequence are NOT supported on NUCLEO-F413ZH!");
        return;
    end
    if (clockdivision<0 || clockdivision>9) then
        mprintf("\n!> Clock division must be between [0-9]!");
        return;
    end
    /*
    if (stdaq_write([ascii('t'),clockdivision+48],2)<0) then
    //if (stdaq_write(msprintf("t%c",char(clockdivision+48)),2)<0) then
        mprintf("\n!> Write to clockdivision is NOT successfull!");
        return;
    end */

    //seq = msprintf("s%c",char(nch+96));
    //for i=1:nch
    //    seq = msprintf("%s%c",seq,char(channelsequence(i)+97));
    //end
    //seq = [ascii('s'),clockdivision+48,nch+96,channelsequence+97];
    seq = [ascii('s'),clockdivision,nch,channelsequence];
    if (stdaq_write(seq,3+nch)<0) then
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
    //adc = zeros(1,nrx); 
    samples = [];
    
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
        //sleep(1);
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
            //mprintf("%d ",nrx);
        end
    end
    
    //samples = 0;
    
    // format samples
    samples = zeros(numsamplesperchannel,nch);
    for i=1:numsamplesperchannel
        for j=1:nch
           //a = (i-1)*nch*2+(j-1)*2+1;
           b = (i-1)*nch*2+j*2;
           samples(i,j) = adc(1,b-1)+256*adc(1,b); 
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
        value = -1;
    end 
endfunction

function stdaq_set_gpio(pin, value)
    // set the GPIO pin to [0,1] output value
    if (value~=0 && value~=1) then
        mprintf("\n!> input value must be [0,1]!");
        return;
    end
    if (pin<0 || pin>7) then
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
    if (pin<0 || pin>7) then
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

function stdaq_set_pwm(pwm,duty,rate,params)
    // set the PWM timer 
    // pwm: is the PWM number [1-3]
    // rate: is the frequency of the PWM expressed in Hertz
    // duty: is the duty cycle expressed in percentage [0-100]
    // params: is a two entries array [tim_presc,tim_period] used to bypass the automotic period guess, with both entries in [1-65336]
    // 
    // Usage examples:
    //   stdaq_set_pwm(1,50,100) => to set tim9 to 100Hz rate and 50% duty
    //   stdaq_set_pwm(2,duty=10) => to change tim11 duty cycle to 10%
    //   stdaq_set_pwm(3,duty=20.5,params=[6400,200]) => set tim13 to 75Hz rate and duty cycle to 20.5%
    
    apb_tim_clk = 96000000;
    
    global tim_params;
    
    if ~isdef("pwm","l") then
        mprintf("\n!> PWM timer not set!");
        return;
    end
    
    if (pwm<1 || pwm>3) then
        mprintf("\n!> PWM timer must be a value in [1-3]!");
    end
    
    if isdef("duty","l") then
        if (duty<0 || duty > 100) then
            mprintf("\n!> Duty cycle must be a value in [0-100]!");
            return;
        end
        if isdef("rate","l") then 
            
            //tim_presc = (apb_tim_clk/clk)-1;
            //tim_period =
            //tmp = apb_tim_clk/rate;
            
            // Automatic period guess
            c = [0;-1]; // objective terms: find the logmax of x2 which means to maximize the PWM resolution
            lb = [1/65336;1];
            ub = [1;65336];
            Aeq = [apb_tim_clk,-rate];
            beq = [0];
            [xopt,fopt,exitflag,iter,yopt] = karmarkar(Aeq,beq,c,[],[],[],[],[],[],[],lb,ub);
    
            tim_presc = round(1/xopt(1)) - 1;
            tim_period = round(xopt(2)) - 1;
            tim_pulse = round(duty/100*(tim_period+1));
            
            mprintf("\n PWM automatic parameters generation:");
            mprintf("\n prescaler = %d",tim_presc);
            mprintf("\n period = %d",tim_period);
            mprintf("\n pulse = %d",tim_pulse);
            
            // update global tim_params variable
            tim_params(pwm,:) = [tim_presc,tim_period];
            
            val = [pwm,floor(tim_presc/256),pmodulo(tim_presc,256),floor(tim_period/256),pmodulo(tim_period,256),floor(tim_pulse/256),pmodulo(tim_pulse,256)];
    
            if (stdaq_write([ascii('x'),ascii('s'),val],9)<0) then
                mprintf("\n!> PWM values NOT set!");
                return;
            end
            
        elseif isdef("params","l") then
            
            if (or(params>65336) || or(params<1)) then
                mprintf("\n!> params must have values in [1-65336]!");
                return;
            end 
            
            tim_presc = params(1) - 1;
            tim_period = params(2) - 1;
            tim_pulse = round(duty/100*(tim_period+1));
            
            // update global tim_params variable
            tim_params(pwm,:) = [tim_presc,tim_period];
            
            val = [pwm,floor(tim_presc/256),pmodulo(tim_presc,256),floor(tim_period/256),pmodulo(tim_period,256),floor(tim_pulse/256),pmodulo(tim_pulse,256)];
    
            if (stdaq_write([ascii('x'),ascii('s'),val],9)<0) then
                mprintf("\n!> PWM values NOT set!");
                return;
            end
            
        else 
            // just update the duty cycle ONLY if the period was previously set 
            if (or(tim_params(pwm,:)>0)) then
            
                tim_presc = tim_params(pwm,1) - 1;
                tim_period = tim_params(pwm,2) - 1;
                tim_pulse = round(duty/100*(tim_period+1));

                val = [pwm,0,0,0,0,floor(tim_pulse/256),pmodulo(tim_pulse,256)];
    
                if (stdaq_write([ascii('x'),ascii('x'),val],9)<0) then
                    mprintf("\n!> PWM duty cycle NOT set!");
                    return;
                end
            
            else
                mprintf("\n!> PWM period was NOT previosly set!");
                return;
            end 
        end
    else 
        mprintf("\n!> Duty was NOT defined!");
    end
    
endfunction

function stdaq_enable_pwm(pwm)
    // Enable the PWM tim, where tim can be either [1,2,3]. 
    if (pwm<1 || pwm>3) then
        mprintf("\n!> PWM timer must be a value in [1-3]!");
        return;
    end
    if (stdaq_write([ascii('x'),ascii('e'),pwm],3)<0) then
        mprintf("\n!> PWM%d NOT enabled!",pwm);
        return;
    end
endfunction

function stdaq_disable_pwm(pwm)
    // Enable the PWM tim, where tim can be either [1,2,3]. 
    if (pwm<1 || pwm>3) then
        mprintf("\n!> PWM timer must be a value in [1-3]!");
        return;
    end
    if (stdaq_write([ascii('x'),ascii('d'),pwm],3)<0) then
        mprintf("\n!> PWM%d NOT disabled!",pwm);
        return;
    end
endfunction

function [rx,len] = stdaq_read_i2c(i2c_address, reg_address, num_bytes)
    // Read from the I2C in standard mode 100 kHz non-strech clock
    // i2c_address: is a 7-bit address [0-127]
    // reg_address: is the address of the register for a memory address size of 8 bits
    // num_bytes: number of bytes, maximum read of 32 bytes
    // rx: is an array with the returned values
    // len: is the length of the array (if -1, means no output available)
    
    rx = [];
    len = -1;
    
    if (num_bytes > 32) then
        mprintf("\n!> the argument num_bytes can be of maximum 32 bytes!");
        return;
    end
    if (i2c_address > 127) then
        mprintf("\n!> the I2C address MUST be a 7-bit address!");
        return;
    end
    if (reg_address > 255) then
        mprintf("\n!> the register address MUST be a 8-bit address!");
        return;
    end
    if (stdaq_write([ascii('i'),ascii('r'),i2c_address,reg_address,num_bytes],5)<0) then
        mprintf("\n !> I2C read command NOT sent sucessfully!");
        return;
    else
        [rx,len] = stdaq_read(num_bytes);
    end
    
endfunction

function stdaq_write_i2c(i2c_address, reg_address, data)
    // Write to the I2C in standard mode 100 kHz non-strech clock
    // i2c_address: is a 7-bit address [0-127]
    // reg_address: is the address of the register for a memory address size of 8 bits
    // data: array with data where each entry must be < 256 and maximum length of 32 entries
    
    // check data array
    tx_size = length(data);
    if ((data>=256) || tx_size>32) then
        mprintf("\n !> data MUST have numerical entries [0-255] and a max. length of 32!");
        return;
    end
    if (i2c_address > 127) then
        mprintf("\n!> the I2C address MUST be a 7-bit address!");
        return;
    end
    if (reg_address > 255) then
        mprintf("\n!> the register address MUST be a 8-bit address!");
        return;
    end
    if (stdaq_write([ascii('i'),ascii('w'),i2c_address,reg_address,tx_size,data],(5+tx_size))<0) then
        mprintf("\n !> I2C write command NOT sent sucessfully!");
        return;
    end
endfunction

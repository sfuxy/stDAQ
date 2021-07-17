// Example for stdaq_set_dac() as from the Reference Manual in docs/refman

stdaq_open("COM0");
stdaq_set_dac(4059);
stdaq_enable_dac();
step = 12; taps = 34; periods = 10;
for i=1:(2*taps*periods)
    value = abs(step*(pmodulo(i,2*taps)-taps));
    stdaq_set_dac(value);
end
stdaq_disable_dac();
stdaq_close();

// Example for stdaq_toggle_gpio() as from the Reference Manual in docs/refman

stdaq_open("COM0");
tags = 100;
for i=1:tags
    stdaq_toggle_gpio(0);
    sleep(1);
end
stdaq_close();

// Example for stdaq_get_adc() as from the Reference Manual in docs/refman

stdaq_open("COM0");
chseq = [0]; // [ch0]
clkdiv = 0; // 1 MHz
stdaq_set_adc(chseq,clkdiv);
stdaq_set_dac(0);
stdaq_enable_dac();
tapsperperiod = 20; periods = 10; out = [];
value = floor(2047.5*(1 + sin(2*%pi*(1:tapsperperiod*periods)/tapsperperiod)));
for i=1:(tapsperperiod*periods)
    stdaq_set_dac(value(i));
    sleep(1);
    samples = stdaq_get_adc(chseq,1);
    out = [out, samples];
end
figure; plot(1:length(out),out);

// Example for stdaq_set_pwm() as from the Reference Manual in docs/refman

stdaq_open("COM0");
pwm = 1;
duty = 20; // 20% duty cycle
rate = 50; // 50 Hz
stdaq_set_pwm(pwm,duty,rate);
stdaq_enable_pwm(pwm);
sleep(100); // wait 100 msec.
duty = 50; // 50% duty cycle
stdaq_set_pwm(pwm,duty);
sleep(100); // wait 100 msec.
stdaq_disable_pwm(pwm);
stdaq_close();

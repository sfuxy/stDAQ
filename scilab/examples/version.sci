// Example for stdaq_version() as from the Reference Manual in docs/refman

if (stdaq_open("COM0")>=0) then
    [pkg,rel,sub] = stdaq_version();
    mprintf("\n stDAQ version: (%s) r.%d.%d",pkg,rel,sub);
    stdaq_close();
end

// Author: S.Furlan
// Date: 3 July 2021

// RunMe: run to link the functions

ilib_for_link(["stdaq_open","stdaq_set","stdaq_read","stdaq_write","stdaq_close"],"stdaq.c",[],"c");

exec('stdaq.sci',-1);

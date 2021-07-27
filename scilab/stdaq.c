// Uses Windows API serial port functions to send and receive data to STDAQ
// ilib_for_link("stdaq_open","stdaq.c",[],"c");
// ilib_for_link(["stdaq_open","stdaq_set","stdaq_read","stdaq_write","stdaq_close"],"stdaq.c",[],"c");

#include <stdio.h>
#include <stdint.h>
#include <windows.h>
#include <string.h>

static HANDLE daq_port;

void print_error(const char * context)
{
    DWORD error_code = GetLastError();
    char buffer[256];
    DWORD size = FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL, error_code, MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US), buffer, sizeof(buffer), NULL);
    if (size == 0) {buffer[0] = 0;}
    fprintf(stderr, "%s: %s\n", context, buffer);
}

// Opens the specified serial port, configures its timeouts and sets its baud rate.
HANDLE open_serial_port(const char * device, uint32_t baud_rate)
{
    HANDLE port = CreateFileA(device, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (port == INVALID_HANDLE_VALUE) 
    {
        print_error(device);
        return INVALID_HANDLE_VALUE;
    }
    
    // flush away any bytes previously read or written
    BOOL success = FlushFileBuffers(port);
    if (!success)
    {
        print_error("Failed to flush serial port");
        CloseHandle(port);
        return INVALID_HANDLE_VALUE;
    }
    
    // configure read and write operations to time out after 1 ms //100 ms.
    COMMTIMEOUTS timeouts = {0};
    timeouts.ReadIntervalTimeout            = 0;
    timeouts.ReadTotalTimeoutConstant       = 1; // 100
    timeouts.ReadTotalTimeoutMultiplier     = 0;
    timeouts.WriteTotalTimeoutConstant      = 1; // 100
    timeouts.WriteTotalTimeoutMultiplier    = 0;
    
    success = SetCommTimeouts(port, &timeouts);
    if (!success)
    {
        print_error("Failed to set serial timeouts");
        CloseHandle(port);
        return INVALID_HANDLE_VALUE;
    }
    
    // set the baud rate and other options
    DCB state = {0};
    state.DCBlength = sizeof(DCB);
    state.BaudRate = baud_rate;
    state.ByteSize = 8;
    state.Parity = NOPARITY;
    state.StopBits = ONESTOPBIT;
    
    success = SetCommState(port, &state);
    if (!success) 
    {
        print_error("Failed to set serial settings");
        CloseHandle(port);
        return INVALID_HANDLE_VALUE;
    }
    
    return port;
}

// writes bytes to the serial port
int write_port(HANDLE port, uint8_t * buffer, size_t size)
{
    DWORD written;
    BOOL success = WriteFile(port, buffer, size, &written, NULL);
    if (!success) 
    {
        print_error("Failed to write to port");
        return -1;
    }
    if (written != size)
    {
        print_error("Failed to write all bytes to port");
        return -1;
    }
    //return 0;
    return written;
}

// reads bytes from the serial port 
// returns after all the desired bytes have been read, or if there is a timeout or other error.
// returns the number of bytes successfully read into the buffer, or -1 if there was an error reading.
SSIZE_T read_port(HANDLE port, uint8_t * buffer, size_t size)
{
    DWORD received;
    BOOL success = ReadFile(port, buffer, size, &received, NULL);
    if (!success)
    {
        print_error("Failed to read from port");
        return -1;
    }
    return received;
}

void stdaq_open(char * device, int * out)
{
    
    uint32_t baud_rate = 9600;
    //printf("here");
    
    daq_port = open_serial_port(device, baud_rate);
    if (daq_port == INVALID_HANDLE_VALUE) {*out = -1;}
    else *out = 0;
    
    
}

void stdaq_set()
{
    
}

static uint8_t buffer_read[256];

//void stdaq_read(int * received)
void stdaq_read(int * length, int * rx_buffer, int * received)
{
    //uint8_t buffer[10];
    //int length = sizeof(buffer);
    //char * buffer = (char *) malloc(sizeof(char)*length);
    //uint8_t buffer_read[256];
    //int length = sizeof(buffer);
    int ii;
    *received = (int) read_port(daq_port, buffer_read, *length);
    //memcpy(rx_buffer,buffer,*length);
    for(ii=0;ii<*received;ii++) rx_buffer[ii] = (int) buffer_read[ii];
}


//void stdaq_write(int * length, char * tx_buffer, int * written)
void stdaq_write(int * length, int * tx_buffer, int * written)
{
	int i;
	uint8_t * tx8 = (uint8_t *) malloc((*length) * sizeof(uint8_t));
	for (i=0;i<*length;i++) tx8[i] = (uint8_t) tx_buffer[i];
    //*written = (int) write_port(daq_port, (uint8_t*) tx_buffer, *length);
	*written = (int) write_port(daq_port, tx8, *length);
	free(tx8);
}

void stdaq_close()
{
    CloseHandle(daq_port);
}


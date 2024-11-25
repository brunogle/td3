#ifndef HANDLER_H
#define HANDLER_H

#include "buffer.h"

#define DISPLAY_DRIVER "/dev/chatlog_lcd"

void display_interface(sh_mem_buffer_t * buffer);

#endif
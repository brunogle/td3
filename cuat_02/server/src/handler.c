#include <stdio.h>

#include <unistd.h>

#include "handler.h"
#include "buffer.h"
#include <string.h>


void handler_proc(event_buffer_t * buffer){



    char lcd_text[80];

    int f = open("/dev/lcd", O_WRONLY);

    int position = 0;

    int prev_message_idx = -1;

    while(1){

        //

        if(buffer->web_to_dev_write_idx != prev_message_idx){

            int last_message_idx = buffer->web_to_dev_write_idx;

            int first_message_idx = last_message_idx - DISPLAY_HEIGHT;
            if(first_message_idx < 0){
                first_message_idx = first_message_idx + BUFFER_SIZE;
            }

            printf("%d %d\n", last_message_idx, first_message_idx);

            int message_idx = first_message_idx;
            char lcd_str[80];

            int row = 0;
            while(message_idx != last_message_idx){
                strncpy(&lcd_str[row*DISPLAY_WIDTH], buffer->web_to_dev_shm[message_idx].message, DISPLAY_WIDTH);
                message_idx++;
                if(message_idx >= BUFFER_SIZE){
                    message_idx = 0;
                }
                row++;
            }

            for(int i = 0; i < 80; i++)
                if(lcd_str[i] == 0){
                    lcd_str[i] = ' ';
                }

            write(f, lcd_str, 80);

            prev_message_idx = buffer->web_to_dev_write_idx;
        }

        sleep(0.1);

    }
}
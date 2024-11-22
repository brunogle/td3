#include <stdio.h>

#include <unistd.h>

#include "handler.h"
#include "buffer.h"
#include <string.h>


void handler_proc(event_buffer_t * buffer){



    char lcd_text[DISPLAY_LEN];

    while(1){

        sleep(1);

        int f = open("/dev/chatlog_lcd", O_WRONLY);
        
        if(f == -1){
            printf("Failed to open HD44780 driver\n");
            continue; 
        }

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

                int message_idx = first_message_idx;
                char lcd_str[DISPLAY_LEN];

                int row = 0;
                while(message_idx != last_message_idx){
                    strncpy(&lcd_str[row*DISPLAY_WIDTH], buffer->web_to_dev_shm[message_idx].message, DISPLAY_WIDTH);
                    message_idx++;
                    if(message_idx >= BUFFER_SIZE){
                        message_idx = 0;
                    }
                    row++;
                }

                for(int i = 0; i < DISPLAY_LEN; i++)
                    if(lcd_str[i] == 0){
                        lcd_str[i] = ' ';
                    }

                if(write(f, lcd_str, DISPLAY_LEN) == -1){
                    printf("ERROR: Write to LCD failed\n");
                    break;
                }

                prev_message_idx = buffer->web_to_dev_write_idx;
            }

            sleep(0.1);

        }

    }

}
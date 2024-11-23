#include <stdio.h>

#include <unistd.h>

#include "handler.h"
#include "buffer.h"
#include <string.h>
#include <stdlib.h>
#include <sys/ipc.h>
#include <sys/shm.h>

int position = 0;

void update_display(int f, event_buffer_t *buffer){
    char lcd_str[DISPLAY_LEN];
        memset(lcd_str, 0, DISPLAY_LEN);
        int row = 0;

        for(int row = 3; row >= 0; row--){
            int message_idx = buffer->web_to_dev_write_idx + row - 4 - buffer->position;

            if(message_idx < 0)
                message_idx += BUFFER_SIZE;

            strncpy(&lcd_str[(row)*DISPLAY_WIDTH], buffer->web_to_dev_shm[message_idx].message, DISPLAY_WIDTH);

        }

        for(int i = 0; i < DISPLAY_LEN; i++)
            if(lcd_str[i] == 0){
                lcd_str[i] = ' ';
            }

        if(write(f, lcd_str, DISPLAY_LEN) == -1){
            printf("ERROR: Write to LCD failed\n");
        }
}

void handler_proc(event_buffer_t *buffer)
{

    char lcd_text[DISPLAY_LEN];

    /* Proceso parent */
    char recv_buffer[20];




    int pid = fork();
    if (pid < 0) {
        perror("ERROR: fork failed\n");
        exit(EXIT_FAILURE);
    }
    else if(pid == 0){
        
        int f = open("/dev/chatlog_lcd", O_RDWR);
        
        while(1){
            int bytes_read = read(f, recv_buffer, sizeof(recv_buffer) - 1);
            //read_web_to_dev(buffer, 0);
            if (bytes_read == -1)
            {
                perror("Failed to read from device");
                close(f);
            }

            recv_buffer[bytes_read] = '\0'; // Null-terminate the string
            if (strcmp(recv_buffer, "up\n") == 0)
            {
                printf("up\n");
                if((buffer->position < BUFFER_SIZE - 4) && (buffer->position + 4 < buffer->fill_size)){
                //printf("%d < %d\n", position + 4, buffer->fill_size);
                buffer->position++;
                update_display(f, buffer);
                }

            }
            else if (strcmp(recv_buffer, "down\n") == 0)
            {
                printf("down\n");
                if(buffer->position > 0){
                    buffer->position--;
                }
                update_display(f, buffer);
            }
            else
            {
                printf("ERROR: unkown message received from driver\n");
            }
        }
    }
    else{
        /*
        Proceso parent*/
    }


    while (1)
    {

        // sleep(1);

        int position = 0;

        int bytes_read = 0;
        int f = open("/dev/chatlog_lcd", O_RDWR);
        int prev_idx = -1;

        while (1)
        {
            if(buffer->web_to_dev_write_idx != prev_idx){

                if(buffer->position != 0)
                    buffer->position += buffer->web_to_dev_write_idx - prev_idx;

                update_display(f, buffer);

                prev_idx = buffer->web_to_dev_write_idx;

            }

            usleep(100000);
        }
    }
}
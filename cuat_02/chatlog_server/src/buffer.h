#ifndef BUFFER_H
#define BUFFER_H

#include <netinet/in.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>  
#include <unistd.h>
#include <semaphore.h>

#define DISPLAY_WIDTH 20
#define DISPLAY_HEIGHT 4
#define DISPLAY_LEN 80

#define BUFFER_SIZE 12

#define WEB_TO_DEV_NAME "/chatlog_lcd_web_to_dev_shm"



typedef struct message{
    char text[DISPLAY_WIDTH];
} message_t;



typedef struct {
    message_t messages[BUFFER_SIZE];
    int last_idx;
    int first_idx;
    int display_position;
    char empty;

    int buffer_fp;
    sem_t sem_busy;

    sem_t sem_new_message;
} sh_mem_buffer_t;



void write_buffer(sh_mem_buffer_t * buffer, message_t event);
message_t read_buffer(sh_mem_buffer_t * buffer, int idx);

sh_mem_buffer_t * init_buffer();
void free_buffer(sh_mem_buffer_t * event_buffer);


#endif
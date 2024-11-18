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

#define BUFFER_SIZE 12

#define WEB_TO_DEV_NAME "/lcd_web_to_dev_shm"



typedef struct event_web_to_dev{
    char message[DISPLAY_WIDTH];
} event_web_to_dev;



typedef struct {
    event_web_to_dev web_to_dev_shm[BUFFER_SIZE];
    int web_to_dev_fp;

    int web_to_dev_write_idx;

    sem_t sem_busy;

} event_buffer_t;



void write_web_to_dev(event_buffer_t * buffer, event_web_to_dev event);
event_web_to_dev read_web_to_dev(event_buffer_t * buffer, int idx);

event_buffer_t * init_buffer();
void free_buffer(event_buffer_t * event_buffer);


#endif
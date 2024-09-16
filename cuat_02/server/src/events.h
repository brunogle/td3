#ifndef EVENTS_H
#define EVENTS_H

#include <netinet/in.h>
#include <sys/mman.h> // for mmap and shm_open
#include <sys/stat.h> // for mode constants
#include <fcntl.h>    // for O_* constants
#include <unistd.h>   // for ftruncate
#include <semaphore.h>

#define DISPLAY_WIDTH 16
#define DISPLAY_HEIGHT 4

#define BUFFER_SIZE 8

#define WEB_TO_DEV_NAME "/lcd_web_to_dev_shm" // Name of the shared memory object



typedef struct event_web_to_dev{
    char text_display[DISPLAY_HEIGHT][DISPLAY_WIDTH];
} event_web_to_dev;



typedef struct {
    event_web_to_dev web_to_dev_shm[BUFFER_SIZE];
    int web_to_dev_fp;

    int web_to_dev_write_idx;
    int web_to_dev_read_idx;

    sem_t web_to_dev_write_sem;
    sem_t web_to_dev_read_sem;

} event_buffer_t;



void write_web_to_dev(event_buffer_t * buffer, event_web_to_dev event);
event_web_to_dev read_web_to_dev(event_buffer_t * buffer);

event_buffer_t * init_buffer();


#endif
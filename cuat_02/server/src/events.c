#include <stdio.h>
#include <stdlib.h>

#include "events.h"


void write_web_to_dev(event_buffer_t * buffer, event_web_to_dev event){
    sem_wait(&buffer->web_to_dev_write_sem); // Espera a que haya lugar en el buffer

    buffer->web_to_dev_shm[buffer->web_to_dev_write_idx] = event;
    buffer->web_to_dev_write_idx = (buffer->web_to_dev_write_idx + 1) % BUFFER_SIZE; 

    sem_post(&buffer->web_to_dev_read_sem); // Hay un evento para leer
}

event_web_to_dev read_web_to_dev(event_buffer_t * buffer){
    event_web_to_dev ret;

    sem_wait(&buffer->web_to_dev_read_sem); // Espera a que haya lugar en el buffer

    ret = buffer->web_to_dev_shm[buffer->web_to_dev_read_idx];
    buffer->web_to_dev_read_idx = (buffer->web_to_dev_read_idx + 1) % BUFFER_SIZE; 

    sem_post(&buffer->web_to_dev_write_sem); // Hay un evento para leer

    return ret;

}



event_buffer_t * init_buffer(){

    event_buffer_t * ret;

    int shm_fp = shm_open(WEB_TO_DEV_NAME, O_CREAT | O_RDWR, 0666);
    if (shm_fp == -1) {
        perror("FATAL: shm_open failed");
        exit(EXIT_FAILURE);
    }

    if (ftruncate(shm_fp, sizeof(event_buffer_t)) == -1) {
        perror("FATAL: ftruncate failed");
        exit(EXIT_FAILURE);
    }

    ret = (event_buffer_t*)mmap(0, sizeof(event_buffer_t), PROT_READ | PROT_WRITE, MAP_SHARED, shm_fp, 0);
    if (ret == MAP_FAILED) {
        perror("FATAL: mmap failed");
        exit(EXIT_FAILURE);
    }

    sem_init(&ret->web_to_dev_write_sem, 1, BUFFER_SIZE);
    sem_init(&ret->web_to_dev_read_sem, 1, 0);

    ret->web_to_dev_write_idx = 0;
    ret->web_to_dev_read_idx = 0;
    ret->web_to_dev_fp = shm_fp;

    return ret;

}


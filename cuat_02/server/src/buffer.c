#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <memory.h>

#include "buffer.h"


void write_web_to_dev(event_buffer_t * buffer, event_web_to_dev event){
    sem_wait(&buffer->sem_busy); // Espera a que haya lugar en el buffer

    buffer->web_to_dev_shm[buffer->web_to_dev_write_idx] = event;
    buffer->web_to_dev_write_idx = (buffer->web_to_dev_write_idx + 1) % BUFFER_SIZE; 

    sem_post(&buffer->sem_busy); // Hay un evento para leer
}

event_web_to_dev read_web_to_dev(event_buffer_t * buffer, int idx){
    event_web_to_dev ret;

    sem_wait(&buffer->sem_busy); // Espera a que haya lugar en el buffer

    ret = buffer->web_to_dev_shm[idx];

    sem_post(&buffer->sem_busy); // Hay un evento para leer

    return ret;

}


event_buffer_t * init_buffer(){

    event_buffer_t * ret;

    /*
        Creacion de memoria compartida donde reciden los buffers y semaforos
    */

    int shm_fp = shm_open(WEB_TO_DEV_NAME, O_CREAT | O_RDWR, 0666);
    if (shm_fp == -1) {
        perror("FATAL: shm_open failed");
        return NULL;
    }

    // Limita el tamano de la memoria compartida
    if (ftruncate(shm_fp, sizeof(event_buffer_t)) == -1) {
        perror("FATAL: ftruncate failed");
        close(shm_fp);
        shm_unlink(WEB_TO_DEV_NAME);
        return NULL;
    }

    // Mapea memoria compartida
    ret = (event_buffer_t*)mmap(0, sizeof(event_buffer_t), PROT_READ | PROT_WRITE, MAP_SHARED, shm_fp, 0);
    if (ret == MAP_FAILED) {
        perror("FATAL: mmap failed");
        shm_unlink(WEB_TO_DEV_NAME);
        return NULL;
    }

    memset(ret, 0, sizeof(event_buffer_t));

    
    if (sem_init(&ret->sem_busy, 1, BUFFER_SIZE) != 0){
        perror("FATAL: sem_init failed");
        munmap((void *)ret, sizeof(event_buffer_t));
        shm_unlink(WEB_TO_DEV_NAME);       
    }
    

    ret->web_to_dev_write_idx = 0;
    ret->web_to_dev_fp = shm_fp;

    return ret;

}

void free_buffer(event_buffer_t * event_buffer){

    sem_close(&event_buffer->sem_busy);

    munmap((void *)event_buffer, sizeof(event_buffer_t));
    shm_unlink(WEB_TO_DEV_NAME);

    return;

}


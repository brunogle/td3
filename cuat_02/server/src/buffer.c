#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <memory.h>

#include "buffer.h"


void write_buffer(sh_mem_buffer_t * buffer, message_t message){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    buffer->last_idx = (buffer->last_idx + 1) % BUFFER_SIZE; 

    if(!buffer->empty && buffer->last_idx == buffer->first_idx){
        buffer->first_idx++;
        buffer->first_idx%=BUFFER_SIZE;
    }

    buffer->empty = 0;

    buffer->messages[buffer->last_idx] = message;

    printf("last: %d,   first:  %d", buffer->last_idx, buffer->first_idx);

    sem_post(&buffer->sem_busy);
    sem_post(&buffer->sem_new_message); 

}

message_t read_buffer(sh_mem_buffer_t * buffer, int idx){
    message_t ret;

    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    ret = buffer->messages[idx];

    sem_post(&buffer->sem_busy); 

    return ret;

}

void set_last_idx(sh_mem_buffer_t * buffer, int value){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    buffer->last_idx = value;

    sem_post(&buffer->sem_busy); 
}


void set_first_idx(sh_mem_buffer_t * buffer, int value){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    buffer->first_idx = value;

    sem_post(&buffer->sem_busy);
}

void set_display_position(sh_mem_buffer_t * buffer, int value){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    buffer->display_position = value;

    sem_post(&buffer->sem_busy);
}

void set_display_driver_file(sh_mem_buffer_t * buffer, int driver_file){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    buffer->display_driver_file = driver_file;

    sem_post(&buffer->sem_busy);
}


int get_last_idx(sh_mem_buffer_t * buffer){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    int ret = buffer->last_idx;

    sem_post(&buffer->sem_busy); 

    return ret;
}


int get_first_idx(sh_mem_buffer_t * buffer){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    int ret = buffer->first_idx;

    sem_post(&buffer->sem_busy);

    return ret;
}

int get_display_position(sh_mem_buffer_t * buffer){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    int ret = buffer->display_position;

    sem_post(&buffer->sem_busy);

    return ret;
}

int get_display_driver_file(sh_mem_buffer_t * buffer){
    sem_wait(&buffer->sem_busy); // Espera a que se pueda acceder a la memoria

    int ret = buffer->display_driver_file;

    sem_post(&buffer->sem_busy);

    return ret;
}

sh_mem_buffer_t * init_buffer(){

    sh_mem_buffer_t * ret;

    /*
        Creacion de memoria compartida donde reciden los buffers y semaforos
    */

    int shm_fp = shm_open(WEB_TO_DEV_NAME, O_CREAT | O_RDWR, 0666);
    if (shm_fp == -1) {
        perror("FATAL: shm_open failed");
        return NULL;
    }

    // Limita el tamano de la memoria compartida
    if (ftruncate(shm_fp, sizeof(sh_mem_buffer_t)) == -1) {
        perror("FATAL: ftruncate failed");
        close(shm_fp);
        shm_unlink(WEB_TO_DEV_NAME);
        return NULL;
    }

    // Mapea memoria compartida
    ret = (sh_mem_buffer_t*)mmap(0, sizeof(sh_mem_buffer_t), PROT_READ | PROT_WRITE, MAP_SHARED, shm_fp, 0);
    if (ret == MAP_FAILED) {
        perror("FATAL: mmap failed");
        shm_unlink(WEB_TO_DEV_NAME);
        return NULL;
    }

    memset(ret, 0, sizeof(sh_mem_buffer_t));

    
    if (sem_init(&ret->sem_busy, 1, BUFFER_SIZE) != 0){
        perror("FATAL: sem_init failed");
        munmap((void *)ret, sizeof(sh_mem_buffer_t));
        shm_unlink(WEB_TO_DEV_NAME);       
        return NULL;
    }
    
    
    if (sem_init(&ret->sem_new_message, 1, 0) != 0){
        perror("FATAL: sem_init failed");
        munmap((void *)ret, sizeof(sh_mem_buffer_t));
        shm_unlink(WEB_TO_DEV_NAME);
        sem_close(&ret->sem_busy);
        return NULL;   
    }
    
    ret->last_idx = BUFFER_SIZE - 1;
    ret->first_idx = 0;
    ret->display_position = 0;
    ret->empty = 1;
    
    ret->buffer_fp = shm_fp;
    
    return ret;

}

void free_buffer(sh_mem_buffer_t * event_buffer){

    sem_close(&event_buffer->sem_busy);

    munmap((void *)event_buffer, sizeof(sh_mem_buffer_t));
    shm_unlink(WEB_TO_DEV_NAME);

    return;

}


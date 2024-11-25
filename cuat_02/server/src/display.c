#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ipc.h>
#include <sys/shm.h>

#include "display.h"
#include "buffer.h"


/*
Este archivo contiene todo el codigo para el manejo de la interfaz,
que consiste del LCD y dos botones.

Es el unico lugar del servidor donde se accede al driver
*/


void update_display(sh_mem_buffer_t *buffer){
/*
Esta funcion actualiza el display usando la informacion de posicion (display_position)
y la cola de mensajes disponible en la memoria compartida
*/

    char lcd_str[DISPLAY_LEN];
    memset(lcd_str, 0, DISPLAY_LEN);

    int display_position = get_display_position(buffer);

    for(int row = 0; row < 4; row++){
        int message_idx = display_position + row - 3;

        if(message_idx < 0) // Si estoy intentando leer una posicion negativa, loopea
            message_idx += BUFFER_SIZE;

        message_t message = read_buffer(buffer, message_idx);

        strncpy(&lcd_str[(row)*DISPLAY_WIDTH], message.text, DISPLAY_WIDTH);

    }

    for(int i = 0; i < DISPLAY_LEN; i++){
        if(lcd_str[i] == 0){
            lcd_str[i] = ' ';
        }
    }
    

    if(write(buffer->display_driver_file, lcd_str, DISPLAY_LEN) == -1){
        printf("ERROR: Write to LCD failed\n");
    }
}

void button_listener(sh_mem_buffer_t * buffer){
    /*
    Esta funcion espera actividad en el read() del driver, que le da 
    informacion de que boton se apreto. Actualiza display_position y el
    display
    */

    char recv_buffer[20];

    int display_driver_file = get_display_driver_file(buffer);

    while(1){

        int bytes_read = read(display_driver_file, recv_buffer, sizeof(recv_buffer) - 1);

        int first_idx = get_first_idx(buffer);
        int last_idx = get_last_idx(buffer);
        int display_position = get_display_position(buffer);

        if (bytes_read == -1){
            perror("Failed to read from device");
        }

        recv_buffer[bytes_read] = '\0';

        char move_is_valid = 1;

        if (strcmp(recv_buffer, "up\n") == 0){
            printf("UP button pressed\n");

            // Revisa si se puede mover en esa direccion.
            // Condicion: Si el primer mensaje en el buffer esta en una de
            // las 4 filas del display, ya no se puede mover mas.
            for(int i = 0; i < 4; i++){
                if((first_idx + i)%BUFFER_SIZE == display_position){
                    move_is_valid = 0;
                    break;
                }
            }

            if(move_is_valid){
                display_position--;

                // Si el movimiento causo que display_position sea negativo, lo hace positivo
                if(display_position < 0){
                    display_position+=BUFFER_SIZE;
                }
                
                set_display_position(buffer, display_position); // Actualiza el valor en la memoria compartida
                update_display(buffer);
            }


        }
        else if (strcmp(recv_buffer, "down\n") == 0){
            printf("DOWN button pressed\n");

            // Revisa si se puede mover en esa direccion.
            // Condicion: Si el ultimo mensaje en el buffer esta en una de
            // las 4 filas del display, ya no se puede mover mas.
            for(int i = 0; i < 4; i++){
                if((last_idx + i)%BUFFER_SIZE == display_position){
                    move_is_valid = 0;
                    break;
                }
            }

            if(move_is_valid){
                display_position++;
                // Si el movimiento hizo que ahora sea >= a BUFFER_SISE, tiene que volver a 0
                display_position %= BUFFER_SIZE;
                set_display_position(buffer, display_position); // Actualiza el valor en la memoria compartida
                update_display(buffer);
            }

        }
        else{
            printf("ERROR: unkown message received from driver\n");
        }
    }
}

void message_listener(sh_mem_buffer_t *buffer){
    /*
    Esta funcion espera a que se inserte un nuevo mensaje en el buffer
    Actualiza el display
    */
    int prev_last_idx = -1;
    
    while (1){

        sem_wait(&buffer->sem_new_message);

        int first_idx = get_first_idx(buffer);
        int last_idx = get_last_idx(buffer);
        int display_position = get_display_position(buffer);

        if(last_idx != prev_last_idx){

            if(display_position == prev_last_idx){
                display_position = last_idx;
            }

            if((last_idx + 3)%BUFFER_SIZE ==  display_position){
                display_position++;
            }

            display_position %= BUFFER_SIZE;

            set_display_position(buffer, display_position);

            update_display(buffer);

            prev_last_idx = last_idx;

        }
    }
}

void display_interface(sh_mem_buffer_t *buffer){
    /*
    Esta es la funcion que se debe llamar para invocar el manejo de la interfaz
    (display + botones)
    */

    char lcd_text[DISPLAY_LEN];

    int display_driver_file = open(DISPLAY_DRIVER, O_RDWR);
    if(display_driver_file == -1){
        perror("ERROR: open failed for display driver: ");
        perror(DISPLAY_DRIVER);
        perror("\n");
        exit(EXIT_FAILURE);
    }

    set_display_driver_file(buffer, display_driver_file);

    int pid = fork();
    if (pid < 0) {
        perror("ERROR: fork failed (display.c)\n");
        exit(EXIT_FAILURE);
    }
    else if(pid == 0){
        // Un proceso para esperar que se aprete un boton
        button_listener(buffer);    
    }
    else{
        // Otro proceso para esperar que se haya un mensaje nuevo
        message_listener(buffer);
    }

}
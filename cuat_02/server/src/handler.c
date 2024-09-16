#include <stdio.h>


#include "handler.h"
#include "events.h"


void handler_proc(event_buffer_t * buffer){
    while(1){
        event_web_to_dev event = read_web_to_dev(buffer);

        for(int row = 0; row < 4; row++){
            for(int i = 0; i < 16; i++){
                if(event.text_display[row][i] != 0){
                    printf("%c", event.text_display[row][i]);
                }
            }
            printf("\n");
        }

    }
}
#include "events.h"
#include <stdio.h>
#include <string.h>

#define DISPLAY_WIDTH 16
#define DISPLAY_HEIGHT 4


typedef struct event_web_to_dev{
    char text_display[DISPLAY_HEIGHT][DISPLAY_WIDTH];
} event_web_to_dev;


int ajax_handler_callback(char * request, char * response, unsigned int * response_len, char * payload, int payload_size){
    
    if(strcmp(request, "update_lcd") == 0){
        
        char text[1024];
        memcpy(text, payload, payload_size);
        text[payload_size] = '\0';


        printf("Request:%s\n", text);
    }



    response = "123";
    *response_len = 3;

    return 1;
}
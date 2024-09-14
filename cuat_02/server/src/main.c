#include <getopt.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <semaphore.h>
#include <ctype.h>
#include "nxjson.h"

#include "server.h"
#include "events.h"
#include "handler.h"

#define DEFAULT_PORT 8080
#define DEFAULT_MAX_CONNECTIONS 10


int ajax_handler_callback(char * request, char * response, unsigned int * response_len, char * payload, int payload_size, void * context){
    
    event_buffer_t * buffer = (event_buffer_t *)context;

    if(strcmp(request, "update_lcd") == 0){
        event_web_to_dev event;

        for(int i = 0; i < 4; i++)
            memset(event.text_display[i], 0, 16);

        char json_text[1024];
        memcpy(json_text, payload, payload_size);
        json_text[payload_size] = '\0';
        
        //printf("%s\n", text);

        const nx_json * json = nx_json_parse(json_text, 0);
        if (!json) {
            fprintf(stderr, "Failed to parse JSON\n");
            return 1;
        }

        // Access JSON data
        const char * text = nx_json_get(json, "text")->text_value;

        char * ch = strtok((char *)text, "\n");
        int line = 0;
        while (ch != NULL) {
            strcpy(event.text_display[line], ch);
            ch = strtok(NULL, "\n");
            line++;
        }

        write_web_to_dev(buffer, event);

        // Print data
    }

    

    response = "123\0";
    *response_len = 4;

    return 1;
}

int main(int argc, char *argv[]){

    int port = DEFAULT_PORT;
    int max_connections = DEFAULT_MAX_CONNECTIONS;

    /*
    Parsing de argumentos
    */
    char * port_str = NULL;
    char * max_connections_str = NULL;
    char c;
    while ((c = getopt(argc, argv, "hp:n:")) != -1){
    switch (c)
        {
            
        case 'p': // Configuracion de numero de puerto
            port_str = optarg;
        break;

        
        case 'n': // Configuracion de maximo numero de conexiones
            max_connections_str = optarg;
        break;
        

        case 'h': // Help
            printf("Available Options:\n"
                   "-p <port>      Change port (default 8080)\n"
                   "-n <max_conn>  Change maximum connections (default 10)\n"
                   "-h             Displays help\n");
            exit(EXIT_SUCCESS);
        break;

        case '?':
            if (optopt == 'p'){
                fprintf (stderr, "Option -%c requires an argument.\n", optopt);
            }  
            else if (isprint (optopt)){
                fprintf (stderr, "Unknown option `-%c'.\n", optopt);
            }
            else{
                fprintf (stderr,
                    "Unknown option character `\\x%x'.\n",
                    optopt);
            }
            exit(EXIT_FAILURE);

        default:
            exit(EXIT_FAILURE);
        }
    }
    if(port_str != NULL){
        sscanf(port_str, "%i", &port);
    }
    if(max_connections_str != NULL){
        sscanf(max_connections_str, "%i", &max_connections);
    }    

    event_buffer_t * event_buffer = init_buffer();

    /*
    Comienzo ejecucion del server en un proceso separado
    */

    int pid = fork();
    if (pid < 0) {
        perror("ERROR: fork failed\n");
        exit(EXIT_FAILURE);
    }
    else if(pid == 0){
        /*
        Proceso child (Proceso server)
        Este proceso abre un socket, espera conexiones HTTP, hostea los conteidos del directorio "www"
        y los requests de AJAX las maneja el callback "ajax_handler_callback".
        */
        http_server_proc(port, max_connections, ajax_handler_callback, event_buffer);
    }
    else{
        /*
        Proceso parent
        */
        while(1){
            handler_proc(event_buffer);
        }
    }

        


}
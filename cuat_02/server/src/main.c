#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>


#include "nxjson.h"
#include "server.h"
#include "buffer.h"
#include "handler.h"

#define DEFAULT_PORT 8080
#define DEFAULT_MAX_CONNECTIONS 10


/*
Callback usado para atender requests de AJAX.
Escribe el buffer circular con el texto contenido en el JSON del payload.
Esta funcion es invocada solamente por procesos hijos del server.
*/
int ajax_handler_callback(http_request_t http_request, ajax_response_t * ajax_response, void * context){

    //El unico tipo de request que atiende es "/update_lcd"
    if(strcmp(http_request.url, "/update_lcd") == 0){
 
        //Preparo un event_web_to_dev para escribir en el buffer
        event_web_to_dev event;
        for(int i = 0; i < 4; i++)
            memset(event.text_display[i], 0, DISPLAY_WIDTH);

        //Parsing del JSON
        char json_text[1024];

        memcpy(json_text, http_request.body, http_request.body_size);
        json_text[http_request.body_size] = '\0';

        const nx_json * json = nx_json_parse(json_text, 0);
        if (!json) {
            perror("ERROR: Failed to parse JSON in update_lcd request\n");
            return 0;
        }
        const char * text = nx_json_get(json, "text")->text_value;
        if (!text) {
            perror("ERROR: \"text\" request not found in JSON in update_lcd request\n");
            return 0;
        }
        const int text_len = strlen(text);

        //Separo el texto en lineas, y las pongo en el event_web_to_dev

        int line = 0;
        int line_idx = 0;
        int text_idx = 0;
        
        while(line < DISPLAY_HEIGHT && text_idx < text_len){
            line_idx = 0;
            while(text_idx < text_len && line_idx < DISPLAY_WIDTH){
                event.text_display[line][line_idx] = text[text_idx];
                text_idx++;
                line_idx++;
                if(text[text_idx] == '\n'){
                    text_idx++;
                    line_idx++;
                    break;             
                }
            }

            line++;
        }


        //Escribe el evento en el buffer
        event_buffer_t * buffer = (event_buffer_t *)context;
        write_web_to_dev(buffer, event);

        //Respuesta HTTP
        char * response_str = "LCD Update Command Processed Correctly";
        strcpy(ajax_response->response, response_str);
        ajax_response->response_len = strlen(response_str);
    }


    return 1;
}

int parse_arguments(int argc, char *argv[], int * port, int * max_connections){
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
            return 1;

        default:
            return 1;
        }
    }
    if(port_str != NULL){
        sscanf(port_str, "%i", port);
    }
    if(max_connections_str != NULL){
        sscanf(max_connections_str, "%i", max_connections);
    }

    return 0;
}

int main(int argc, char *argv[]){

    int port = DEFAULT_PORT;
    int max_connections = DEFAULT_MAX_CONNECTIONS;

    /*
    Parsing de argumentos
    */
    if(parse_arguments(argc, argv, &port, &max_connections) != 0){
        perror("FATAL: Argument parsing errors\n");
        exit(EXIT_FAILURE);
    }

    event_buffer_t * event_buffer = init_buffer();


    /*
    El fork crea un proceso child que sera el servidor
    */

    int pid = fork();
    if (pid < 0) {
        perror("ERROR: fork failed\n");
        free_buffer(event_buffer);
        exit(EXIT_FAILURE);
    }
    else if(pid == 0){
        /*
        Proceso child (Proceso server)
        Este proceso abre un socket, espera conexiones HTTP, hostea los conteidos del directorio "www"
        y los requests de AJAX las maneja el callback "ajax_handler_callback". El callback necesita un
        contexto, en este caso, el buffer donde se escriben los eventos para controlar el LCD (event_buffer)
        */
        http_server_proc(port, max_connections, ajax_handler_callback, event_buffer);

        //Si el servidor termina, entonces hubo un error

        //TODO: Liberar sockets
        free_buffer(event_buffer);
        exit(EXIT_FAILURE);
    }
    else{
        /*
        Proceso parent

        Este proceso continua leyendo del buffer los eventos, y enviandolos al LCD mediante el server

        */
        while(1){
            handler_proc(event_buffer);
        }
    }

        


}
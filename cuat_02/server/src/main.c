#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>


#include "cJSON.h"
#include "server.h"
#include "buffer.h"
#include "handler.h"

#define DEFAULT_PORT 8081
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
        memset(event.message, 0, DISPLAY_WIDTH);

        //Parsing del JSON
        char json_text[1024];

        memcpy(json_text, http_request.body, http_request.body_size);
        json_text[http_request.body_size] = '\0';

        cJSON *json = cJSON_Parse(json_text);
        if (!json) {
            perror("ERROR: Failed to parse JSON in update_lcd request\n");
            return 0;
        }
        char * text = cJSON_GetObjectItem(json, "text")->valuestring;;
        if (!text) {
            perror("ERROR: \"text\" request not found in JSON in update_lcd request\n");
            return 0;
        }
        const int text_len = strlen(text);

        //Separo el texto en lineas, y las pongo en el event_web_to_dev

        int line = 0;
        int line_idx = 0;
        int text_idx = 0;
        
        strcpy(event.message, text);


        //Escribe el evento en el buffer
        event_buffer_t * buffer = (event_buffer_t *)context;
        write_web_to_dev(buffer, event);

    
        return 1;
    }

    else if(strcmp(http_request.url, "/fetch_log") == 0){
        event_buffer_t * buffer = (event_buffer_t *)context;
        char * log_text = malloc(DISPLAY_WIDTH*BUFFER_SIZE*sizeof(char));
        int size = 0;

        for(int i = 0; i < BUFFER_SIZE; i++){
            event_web_to_dev event = read_web_to_dev(buffer, i);
            if(event.message[0] == 0){
                break;
            }
            if(i != 0){
                size += sprintf(&log_text[size], "\n");
            }
            size += sprintf(&log_text[size], "%s", event.message);
        }


        cJSON *json = cJSON_CreateObject();
        if (json == NULL) {
            perror("ERROR: Failed to create JSON object\n");
            return 0;
        }

        //printf("%s\n", log_text);


        // Add the "log" field with the string value
        if (cJSON_AddStringToObject(json, "log", log_text) == NULL) {
            perror("ERROR: Failed to add log message to JSON object\n");
            cJSON_Delete(json);
            return 0;
        }

        // Convert the JSON object to a string
        ajax_response->response= cJSON_PrintUnformatted(json);
        if (ajax_response->response == NULL) {
            perror("ERROR: Failed to print JSON object as string\n");
        }

        ajax_response->response_len = strlen(ajax_response->response);


        // Clean up the cJSON object (the string must be freed by the caller)
        cJSON_Delete(json);


        


        return 1;
    }

    return 0;
  
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
    /*
    if(parse_arguments(argc, argv, &port, &max_connections) != 0){
        perror("FATAL: Argument parsing errors\n");
        exit(EXIT_FAILURE);
    }
*/
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
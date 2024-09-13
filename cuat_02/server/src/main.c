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

#include "server.h"
#include "events.h"

#define DEFAULT_PORT 8080
#define DEFAULT_MAX_CONNECTIONS 10          

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
        http_server_start(port, max_connections, ajax_handler_callback);
    }
    else{
        /*
        Proceso parent
        */
        while(1){
            sleep(1000);
        }
    }

        


}
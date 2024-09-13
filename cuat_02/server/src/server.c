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
#include <errno.h>

#include "server.h"


#define RECV_BUFF_SIZE 8192
#define WRITE_BUFF_SIZE 512
#define URL_SIZE 2024

//#define VERBOSE


#define STR_(X) #X
#define STR(X) STR_(X)


#define USE_COLORS

#ifdef USE_COLORS
#define COLOR_RESET   "\033[0m"
#define COLOR_BLACK   "\033[0;30m"
#define COLOR_RED     "\033[0;31m"
#define COLOR_GREEN   "\033[0;32m"
#define COLOR_YELLOW  "\033[0;33m"
#define COLOR_BLUE    "\033[0;34m"
#define COLOR_MAGENTA "\033[0;35m"
#define COLOR_CYAN    "\033[0;36m"
#define COLOR_WHITE   "\033[0;37m"
#else
#define COLOR_RESET   ""
#define COLOR_BLACK   ""
#define COLOR_RED     ""
#define COLOR_GREEN   ""
#define COLOR_YELLOW  ""
#define COLOR_BLUE    ""
#define COLOR_MAGENTA ""
#define COLOR_CYAN    ""
#define COLOR_WHITE   ""
#endif



/*********************************************************************
 *                                                                   *
 *                      VARIABLES GLOBALES                           *
 *                                                                   *
 *********************************************************************/


static child_desc_node * child_desc_node_ll; // Linked list para mantener registro de procesos client handler
static ajax_handler_callback_t ajax_handler_callback; // Esta funcion se ejecuta cuando llega un request de AJAX


/*********************************************************************
 *                                                                   *
 *                     MANEJO DE PROCESOS                            *
 *                                                                   *
 *********************************************************************

    Para mantener registro de los procesos se utiliza una lista enlazada. El nodo base esta apuntado por
    child_desc_node_ll y se puede interacutar con  insert_process, remove_process_by_pid, get_process_by_pid y
    count_processes.

 */


void insert_process(child_desc_node ** head, child_desc_node node) {
    child_desc_node * new_node = (child_desc_node *)malloc(sizeof(child_desc_node));

    if (!new_node) {
        perror("FATAL: malloc");
        exit(EXIT_FAILURE);
    }

    *new_node = node;
    new_node->next = NULL;

    if (*head == NULL) {
        *head = new_node;
    } else {
        child_desc_node * current = *head;
        while (current->next != NULL) {
            current = current->next;
        }
        current->next = new_node;
    }
}

void remove_process_by_pid(child_desc_node **head, pid_t pid) {
    child_desc_node *current = *head, *prev = NULL;

    while (current != NULL && current->pid != pid) {
        prev = current;
        current = current->next;
    }

    if (current == NULL) {
        fprintf(stderr, "WARN: remove_process_by_pid: PID %d not found in the list.\n", pid);
        return;
    }

    if (prev == NULL) {
        *head = current->next;
    }
    else {
        prev->next = current->next;
    }

    free(current);
    
    return;
}

child_desc_node * get_process_by_pid(child_desc_node *head, pid_t pid) {
    child_desc_node *current = head;

    while (current != NULL && current->pid != pid) {
        current = current->next;
    }

    if (current == NULL) {
        fprintf(stderr, "WARN: remove_process_by_pid: PID %d not found in the list.\n", pid);
        return (child_desc_node *)NULL;
    }

    return current;
}

int count_processes(child_desc_node * head){

    if(head == NULL)
        return 0;
    else{
        int count = 1;
        while (head->next != NULL) {
            head = head->next;
            count++;
        } 
        return count;
    }

}

/*********************************************************************
 *                                                                   *
 *                         RESPUESTAS HTTP                           *
 *                                                                   *
 *********************************************************************
    Esta seccion contiene:

    Funciones para enviar respuestas de error simples al client (400, 404, 413, 414, 500, 501 y 503)
    Funcion para enviar un archivo al cliente
    Funcion para procesar un AJAX request

 */
int http_bad_request_400(int socket_fd){
    char response[] = "HTTP/1.1 400 Bad Request\nContent-Length: 14\n\n404 Bad Request";

    write(socket_fd, response, strlen(response));

    return 400;
}


int http_not_found_404(int socket_fd){
    char response[] = "HTTP/1.1 404 Not Found\nContent-Length: 13\n\n404 Not Found";

    write(socket_fd, response, strlen(response));

    return 404;
}

int http_payload_too_large_413(int socket_fd){
    char response[] = "HTTP/1.1 413 Payload Too Large\nContent-Length: 21\n\n413 Payload Too Large";

    write(socket_fd, response, strlen(response));

    return 413;   
}

int http_uri_too_long_414(int socket_fd){
    char response[] = "HTTP/1.1 414 URI Too Long\nContent-Length: 16\n\n414 URI Too Long";

    write(socket_fd, response, strlen(response));

    return 414;
}


int http_not_implemented_501(int socket_fd){
    char response[] = "HTTP/1.1 501 Not Implemented\nContent-Length: 19\n\n501 Not Implemented";

    write(socket_fd, response, strlen(response));

    return 501;
}

int http_internal_server_error_500(int socket_fd){
    char response[] = "HTTP/1.1 500 Internal Server Error\nContent-Length: 19\n\n500 Internal Server Error";

    write(socket_fd, response, strlen(response));

    return 500;
}

int http_service_unavailable_503(int socket_fd){
    char response[] = "HTTP/1.1 503 Service Unavailable\nContent-Length: 23\n\n503 Service Unavailable";

    write(socket_fd, response, strlen(response));

    return 503;
}

int http_serve_file(int socket_fd, char * file_path){
    FILE * file_fd;
    

    file_fd = fopen(file_path, "rb");

    if (file_fd == NULL) {
        if (errno == ENOENT) {
            return http_not_found_404(socket_fd);
        } else {
            perror("ERROR: fopen failed\n");
            return http_internal_server_error_500(socket_fd);
        }
    }

    char content[512];
    char type[256];

    if (strstr(file_path, ".html")) {
        strcpy(type, "text/html");
    } else if (strstr(file_path, ".jpg")) {
        strcpy(type, "image/jpeg");
    } else if (strstr(file_path, ".png")) {
        strcpy(type, "image/png");
    } else {
        strcpy(type, "application/octet-stream");
    }

    fseek(file_fd, 0, SEEK_END);
    int content_size = ftell(file_fd);
    fseek(file_fd, 0, SEEK_SET);

    sprintf(content,
            "HTTP/1.1 200 OK\n"
            "Content-Type: %s\n"
            "Content-Length: %u\n\n",
            type, content_size);

    write(socket_fd, content, strlen(content));


    int file_bytesread;
    int bytes_sent = 0;
    while((file_bytesread = fread(content, 1, 512, file_fd)) > 0){
        write(socket_fd, content, file_bytesread);
        bytes_sent += file_bytesread;
    }
    return 200;

}

int handle_ajax_request(int client_socket, char * request, char * payload, int payload_size){
    
    char response[2048];
    unsigned int response_len;

    
    char success = ajax_handler_callback(&request[6], response, &response_len, payload, payload_size);

    if(success){

        char header_f[] =
            "HTTP/1.1 200 OK\n"
            "Content-Type: application/json\n"
            "Content-Length: %u\n\n";

        char header[256];

        sprintf(header, header_f, response_len);

        write(client_socket, header, strlen(header));

        write(client_socket, response, response_len);

    }
    else{
        http_internal_server_error_500(client_socket);
    }

    
    return 200;
}

/*********************************************************************
 *                                                                   *
 *                           Logica HTTP                             *
 *                                                                   *
 *********************************************************************
    Procesa requests de HTTP una vez parseado.
    Requests con un URL que comeinzan en "ajax_"

 */

int handle_http_request(int client_socket,  char * method, char * path, char * url, char * payload, int payload_size){

    int response = 0;

    if(strcmp(method, "GET") == 0){

        if(strcmp(path, "/") == 0){
            strcpy(path, "./www/index.html");
        }
        else{
            sprintf(path, "./www%s", url);
        }

        if(strncmp(url, "/ajax_", 6) == 0){
            response = handle_ajax_request(client_socket, url, payload, payload_size);
        }
        else{
            response = http_serve_file(client_socket, path);
        }
        

    }
    else if(strcmp(method, "POST") == 0){
        if(strncmp(url, "/ajax_", 6) == 0){
            response = handle_ajax_request(client_socket, url, payload, payload_size);
        }
        else{
            response = http_not_found_404(client_socket);
        }
    }
    else{
        response = http_not_implemented_501(client_socket);
    }

}

/*********************************************************************
 *                                                                   *
 *                          CLIENT HANDLER                           *
 *                                                                   *
 *********************************************************************

    Esta funcion se ejecuta como cliente hijo del servidor para cada una de
    los clientes siendo atendidos. Mantiene la conexion abierta al menos que
    ocurra un error de socket

    Realiza el parsing del request HTTP, en caso de que el parsing sea exitoso,
    llama a handle_http_request

    Formato de un request de HTTP
    [Method] [URL] [HTTP Version]
    [Headers]
    [Body]

 */

void client_handler(int client_socket, int connection_id) {

    char recv_buffer[RECV_BUFF_SIZE];



    while(1){

        int bytes_read = read(client_socket, recv_buffer, RECV_BUFF_SIZE - 1);
        if(bytes_read < 0){
            perror("FATAL: read failed\n");
            close(client_socket);
            exit(EXIT_FAILURE);
        }
        else if(bytes_read == 0){
            // El cliente cerro la conexion
            break;
        }
        else if(bytes_read == RECV_BUFF_SIZE - 1){
            //Si la cantidad de bytes recibidos es igual a la maxima cantidad que se puede recibir,
            //es porque seugramente haya mas datos por leer. En este caso, termino la conexion.
            //En el futuro se puede mejorar para recibir mensajes aribrariamente grandes para poder recibir
            //bloques de datos grandes.
            perror("ERROR: receive bufer is full. Ignoring request\n");
            http_payload_too_large_413(client_socket);
            continue;
        }


        int response = 0;
        char request_failed = 0;

        /*****************************************************************************
        * Obtiene las distintas partes del request line (Method, URL y version HTTP) *
        *****************************************************************************/

        char method[16];
        char url[URL_SIZE+16];
        char http_version[16];

        int url_start, url_end;

        // %15s : String de maximo 15 caraceres para el request
        // %n%sX%n : Posicion de comienzo de URL, string de URL limitado a X caracteres, posicion de fin de URL
        if(!request_failed && sscanf(recv_buffer, "%15s %n%"STR(URL_SIZE)"s%n %15s", method, &url_start, url, &url_end, http_version) != 3){
            response = http_bad_request_400(client_socket);
            request_failed = 1;
        }

        //Revisa que el URL se haya leido entero
        if(!request_failed && url_end - url_start >= URL_SIZE){
            response = http_uri_too_long_414(client_socket);
            request_failed = 1;
        }

        url[url_end] = '\0';

        /*****************************************************************************
        *          Obtiene la direccion de comienzo del body y su tamano             *
        *****************************************************************************/
        
        if(!request_failed){

            unsigned int body_pos = 0;
            int body_size = 0;
            char * body = NULL;
            char contains_body = 1;

            // Busca la posicion donde se encuenten el doble LF o CRLF
            const char *double_lf_ptr = strstr(recv_buffer, "\n\n");
            const char *double_crlf_ptr = strstr(recv_buffer, "\r\n\r\n");
            if(double_crlf_ptr != NULL){
                body_pos = double_crlf_ptr - recv_buffer + 4;
            }
            else if(double_lf_ptr != NULL){
                body_pos = double_crlf_ptr - recv_buffer + 2;
            }
            else{
                contains_body = 0;
            }

            if(contains_body){
                //Busca el Content-Length en el header para obtener el largo del body
                const char * content_length_ptr = strstr(recv_buffer, "Content-Length: ");
                if(content_length_ptr != NULL && content_length_ptr - recv_buffer < body_pos){
                    sscanf(&content_length_ptr[16], "%d", &body_size);
                }
                //Crea el pointer al body
                body = recv_buffer + bytes_read - body_size;
            } 



            /*****************************************************************************
            *          Parsing del URL para obtener el path y los parametros             *
            *****************************************************************************/


            char path[URL_SIZE];
            char parameters[URL_SIZE];

            char * delimeter = strchr(url, '?');
            
            if (delimeter != NULL) {
                //Si el URL tiene ?, tiene parametros
                size_t path_length = delimeter - url;
                strncpy(path, url, path_length);
                path[path_length] = '\0';
                strcpy(parameters, delimeter + 1);
            } else {
                //Si no, el URL es el path
                strcpy(path, url);
                parameters[0] = '\0';
            }

            response = handle_http_request(client_socket, method, path, url, body, body_size);
            
        }
        
        #ifdef VERBOSE
        printf("Handled Request from Client ID %d:\n%s\nResponse: %d\n", connection_id, recv_buffer, response);
        #else
        printf("Handled Request from Client ID %d: %s %-20s       Response: %d\n", connection_id, method, url, response);
        #endif

    }

    close(client_socket);
    exit(0);

}

void sigchld_handler(int signum) {
    (void)signum;  // Escribo esto para que no genere warnings de que no se usa este param
    int status;


    while(1){
        int pid = waitpid(-1, &status, WNOHANG);

        if (pid < 0) {
            if(errno == ECHILD){
                //No hay mas childs que manejar
                break;
            }
            else{
                //Fallo el waitpid
                perror("FATAL: waitpid failed");
                continue;
            }
        }
        else if(pid == 0){
            //Sigue habiendo childs que tienen que ser manejados
            continue;
        }

        child_desc_node * ended_node = get_process_by_pid(child_desc_node_ll, pid);
        remove_process_by_pid(&child_desc_node_ll, pid);
        printf(COLOR_YELLOW);
        printf("Client %d disconnected. Current connections: %d\n", ended_node->connection_id, count_processes(child_desc_node_ll));
        printf(COLOR_RESET);
        fflush(stdout);
    }

}



int http_server_start(int port, int max_connections, ajax_handler_callback_t ajax_handler_callback_){

    ajax_handler_callback = ajax_handler_callback_;
    

    /*
    Crea memoria comparida para enviar datos a proceso hijo
    */
    char * circ_buff;
    int circ_buff_fd;
    if((circ_buff_fd = shm_open("/td3_bruserver", O_CREAT | O_RDWR, 0666)) == -1){
        perror("FATAL: shm_open");
        exit(EXIT_FAILURE);
    }
    ftruncate(circ_buff_fd, 1000);
    if((circ_buff = (char*) mmap(0, 1000, PROT_READ | PROT_WRITE, MAP_SHARED, circ_buff_fd, 0)) == (char*)-1){
        perror("FATAL: mmap");
        exit(EXIT_FAILURE);  
    }


    /*
    Inicializa sigchild handler
    */
    struct sigaction sigchild_sa;
    sigchild_sa.sa_handler = sigchld_handler;
    sigemptyset(&sigchild_sa.sa_mask);
    sigchild_sa.sa_flags = SA_RESTART;
    if (sigaction(SIGCHLD, &sigchild_sa, NULL) == -1) {
        perror("ERROR: sigaction failed\n");
        exit(EXIT_FAILURE);
    }

    /*
    Creacion del socket
    */
    int server_socket;
    if ((server_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("FATAL: socket failed\n");
        return 1;
    }

    /*
    Configuracion opciones del socket
    */
    struct sockaddr_in client_address;
    int addrlen = sizeof(client_address);
    client_address.sin_family = AF_INET;
    client_address.sin_addr.s_addr = htonl(INADDR_ANY);
    client_address.sin_port = htons(port);
    int opt = 1;
    if (setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("FATAL: setsockopt failed\n");
        exit(EXIT_FAILURE);
    }

    /*
    Bind del socket
    */
    if (bind(server_socket, (struct sockaddr *)&client_address, sizeof(client_address)) == -1) {
        perror("FATAL: bind failed\n");
        exit(EXIT_FAILURE);
    }
    if (listen(server_socket, 2) == -1) {
        perror("FATAL: listen failed\n");
        exit(EXIT_FAILURE);
    }


    printf("Server ready at port: %d\n", port);

    int client_socket;
    int connection_id_counter = 0;

    while (1) {
        /*
        Espera conexion
        */
        if ((client_socket = accept(server_socket, (struct sockaddr *)&client_address, (socklen_t *)&addrlen)) == -1) {
            perror("ERROR: Accept failed\n");
            continue;
        }

        if(count_processes(child_desc_node_ll) + 1 > max_connections){
            printf(COLOR_RED);
            printf("Max Connections Reached (%d), closing connection\n", max_connections);
            printf(COLOR_RESET);  
            fflush(stdout);  
            http_service_unavailable_503(client_socket);
            close(client_socket);
            continue;
        }

        char client_ip_str[32];
        inet_ntop(AF_INET, &(client_address.sin_addr), client_ip_str, INET_ADDRSTRLEN);
        int client_port = ntohs(client_address.sin_port);

        connection_id_counter++;
        printf(COLOR_GREEN);
        printf("New client connected (%s:%i) (ID %d). Current connections: %d\n", client_ip_str, client_port, connection_id_counter, count_processes(child_desc_node_ll)+1);
        printf(COLOR_RESET);
        fflush(stdout);
        
        
        pid_t new_pid = fork();
        if (new_pid < 0) {
            perror("ERROR: fork failed\n");
            close(client_socket);
            continue;

        } else if (new_pid == 0) {
            /*
            Codigo Child
            */
            close(server_socket);

            while(1){
                client_handler(client_socket, connection_id_counter);
                //El handler nunca deberia terminar!!
                perror("ERROR: client_handler returned\n");
                exit(EXIT_FAILURE);
            }

        } else {
            /*
            Codigo Parent
            */
            close(client_socket);

            // Agrega proceso hijo al administrador de procesos
            child_desc_node new_node;
            new_node.pid = new_pid;
            new_node.connection_id = connection_id_counter;
            insert_process(&child_desc_node_ll, new_node);
            
        }

        close(client_socket);
        
    }

    return 0;
}

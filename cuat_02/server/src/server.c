#include "server.h"
//#include "nxjson.h"

#include <complex.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <string.h>
#include <errno.h>

#define USE_COLORS
#include "colors.h"

// #define A_LITTLE_VERBOSE
// #define VERBOSE

#define STR_(X) #X
#define STR(X) STR_(X)



/*********************************************************************
 *                                                                   *
 *                      VARIABLES GLOBALES                           *
 *                                                                   *
 *********************************************************************/

child_desc_node * child_desc_node_ll; // Linked list para mantener registro de procesos client handler



/*********************************************************************
 *                                                                   *
 *                     MANEJO DE PROCESOS                            *
 *                                                                   *
 *********************************************************************

    Para mantener registro de los procesos se utiliza una lista enlazada. El nodo base esta apuntado por
    child_desc_node_ll y se puede interacutar con insert_process, remove_process_by_pid, get_process_by_pid y
    count_processes.

 */

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
        }
        else {
            perror("ERROR: fopen failed\n");
            return http_internal_server_error_500(socket_fd);
        }
    }

    // Obtiene el mime type en base a la extension del archivo
    char type[256];

    if (strstr(file_path, ".html")) {
        strcpy(type, "text/html");
    } else if (strstr(file_path, ".jpg")) {
        strcpy(type, "image/jpeg");
    } else if (strstr(file_path, ".png")) {
        strcpy(type, "image/png");
    } else if (strstr(file_path, ".js")){
        strcpy(type, "text/javascript");
    } else if(strstr(file_path, ".ttf")){
        strcpy(type, "font/ttf");
    } else {
        strcpy(type, "application/octet-stream");
    }

    // Obtiene el tamaño del archivo
    int content_size = 0;

    fseek(file_fd, 0, SEEK_END);
    content_size = ftell(file_fd);
    fseek(file_fd, 0, SEEK_SET);

    char write_buffer[WRITE_BUFF_SIZE];

    sprintf(write_buffer,
            "HTTP/1.1 200 OK\n"
            "Content-Type: %s\n"
            "Content-Length: %u\n\n",
            type, content_size);

    // Envia el header HTTP
    write(socket_fd, write_buffer, strlen(write_buffer));

    // Envia el contenido del arhcivo de a tramos
    int file_bytesread;
    while((file_bytesread = fread(write_buffer, 1, WRITE_BUFF_SIZE, file_fd)) > 0){
        write(socket_fd, write_buffer, file_bytesread);
    }

    return 200;

}

int handle_ajax_request(int client_socket, http_request_t http_request, ajax_handler_callback_t ajax_handler_callback, void * ajax_handler_context){
    
    ajax_response_t ajax_response;

    char success = ajax_handler_callback(http_request, &ajax_response, ajax_handler_context);
    
    if(success){
        char header[256];

        if(ajax_response.response == NULL){
            sprintf(header,
                "HTTP/1.1 200 OK\n"
                "Content-Type: application/json\n"
                "Content-Length: 0\n\n");

            write(client_socket, header, strlen(header));

        }
        else{
            sprintf(header,
                "HTTP/1.1 200 OK\n"
                "Content-Type: application/json\n"
                "Content-Length: %u\n\n",
                ajax_response.response_len);

            // Envia el header de la respuesta
            write(client_socket, header, strlen(header));

            // Envia la respuesta
            write(client_socket, ajax_response.response, ajax_response.response_len);

            free(ajax_response.response);
        }

        return 200;
    }
    else{
        return http_internal_server_error_500(client_socket);
    }
}

/*********************************************************************
 *                                                                   *
 *                           Logica HTTP                             *
 *                                                                   *
 *********************************************************************
    Procesa requests de HTTP una vez parseado.
    Requests con un URL que comeinzan en "ajax_"

 */

int handle_http_request(int client_socket, http_request_t http_request, void * ajax_handler_context, ajax_handler_callback_t ajax_handler_callback){

    int response = 0;

    if(strcmp(http_request.method, "GET") == 0){

        if(http_request.ajax_request){
            response = handle_ajax_request(client_socket, http_request, ajax_handler_callback, ajax_handler_context);
        }
        else if(strcmp(http_request.path, "/") == 0){
            strcpy(http_request.path, "./www/index.html");
            response = http_serve_file(client_socket, http_request.path);
        }
        else{
            sprintf(http_request.path, "./www%s", http_request.url);
            response = http_serve_file(client_socket, http_request.path);
        }   
    
        

    }
    else if(strcmp(http_request.method, "POST") == 0){
        if(http_request.ajax_request){

            response = handle_ajax_request(client_socket, http_request, ajax_handler_callback, ajax_handler_context);
        }
        else{
            response = http_not_found_404(client_socket);
        }
    }
    else{
        response = http_not_implemented_501(client_socket);
    }

    return response;

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

void client_handler(int client_socket, int connection_id, ajax_handler_callback_t ajax_handler_callback, void * ajax_handler_context) {

    char recv_buffer[RECV_BUFF_SIZE];


    int bytes_read = read(client_socket, recv_buffer, RECV_BUFF_SIZE - 1);

    if(bytes_read < 0){
        perror("FATAL: read failed\n");
        close(client_socket);
        exit(EXIT_FAILURE);
    }
    else if(bytes_read == 0){
        // El cliente cerro la conexion
        exit(EXIT_SUCCESS);
    }
    else if(bytes_read == RECV_BUFF_SIZE - 1){
        /*
        Si la cantidad de bytes recibidos es igual a la maxima cantidad que se puede recibir,
        es porque seugramente haya mas datos por leer. En este caso, termino la conexion.
        En el futuro se puede mejorar para recibir mensajes aribrariamente grandes para poder recibir
        bloques de datos grandes.
        */
        perror("ERROR: receive bufer is full. Ignoring request\n");
        http_payload_too_large_413(client_socket);
        exit(EXIT_FAILURE);
    }




    /*****************************************************************************
    * Obtiene las distintas partes del request line (Method, URL y version HTTP) *
    *****************************************************************************/

    http_request_t http_request;

    int url_start, url_end;

    int response = 0;
    char request_failed = 0;

    // Parsing del method, url y version

    int vars_read = sscanf(recv_buffer,
    "%15s %n%2048s%n %15s", // Retorna: method (%15s), url_start (%n), url (%2048s), url_end (%n), http_version (%15s)
    http_request.method, &url_start, http_request.url, &url_end, http_request.http_version);

    if(vars_read != 3){
        // No se leyo bien el method, url y http_version
        response = http_bad_request_400(client_socket);
        request_failed = 1;
    }
    if(!request_failed && url_end - url_start >= URL_SIZE){
        // Si el URL que se leyo es el maximo
        response =  http_uri_too_long_414(client_socket);
        request_failed = 1;
    }

    http_request.url[url_end] = '\0';



    /*****************************************************************************
    *          Obtiene la direccion de comienzo del body y su tamano             *
    *****************************************************************************/
    
    if(!request_failed){
        // Si no fallo el parsing, procedo con el resto

        unsigned int body_pos = 0;
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
                sscanf(&content_length_ptr[16], "%d", &http_request.body_size);
            }
            //Crea el pointer al body
            http_request.body = recv_buffer + bytes_read - http_request.body_size;
        } 


    /*****************************************************************************
    *          Determina informacion adicional del request (Si es un AJAX)       *
    *****************************************************************************/
    
    http_request.ajax_request = 0;

    char header_arg[64];

    char * content_type_ptr = strstr(recv_buffer, "Content-Type: ");

    if(content_type_ptr != NULL && content_type_ptr - recv_buffer < body_pos){
        if(sscanf(content_type_ptr + 14, "%63s", header_arg) == 1){
            if(strcmp(header_arg, "application/json") == 0){
                http_request.ajax_request = 1;
            }   
        }
    }




        /*****************************************************************************
        *          Parsing del URL para obtener el path y los parametros             *
        *****************************************************************************/


        char parameters[URL_SIZE];

        char * delimeter = strchr(http_request.url, '?');
        
        if (delimeter != NULL) {
            //Si el URL tiene ?, tiene parametros
            size_t path_length = delimeter - http_request.url;
            strncpy(http_request.path, http_request.url, path_length);
            http_request.path[path_length] = '\0';
            strcpy(parameters, delimeter + 1);
        } else {
            //Si no, el URL es el path
            strcpy(http_request.path, http_request.url);
            parameters[0] = '\0';
        }

        response = handle_http_request(client_socket, http_request, ajax_handler_context, ajax_handler_callback);
        
    }
    
    #ifdef VERBOSE
    printf("Handled Request from Client ID %d:\n%s\nResponse: %d\n", connection_id, recv_buffer, response);
    #else
    printf("Handled Request from Client ID %d: %s %-20s       Response: %d\n", connection_id, http_request.method, http_request.url, response);
    #endif

    close(client_socket);
    exit(EXIT_SUCCESS);

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


    }

}



int http_server_proc(int port, int max_connections, ajax_handler_callback_t ajax_handler_callback, void * ajax_handler_context){


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
        close(server_socket);
        exit(EXIT_FAILURE);
    }   

    /*
    Bind del socket
    */
    if (bind(server_socket, (struct sockaddr *)&client_address, sizeof(client_address)) == -1) {
        perror("FATAL: bind failed\n");
        close(server_socket);
        exit(EXIT_FAILURE);
    }
    if (listen(server_socket, max_connections) == -1) {
        perror("FATAL: listen failed\n");
        close(server_socket);
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

        char client_ip_str[32];
        inet_ntop(AF_INET, &(client_address.sin_addr), client_ip_str, INET_ADDRSTRLEN);
        int client_port = ntohs(client_address.sin_port);

        connection_id_counter++;

        #ifdef A_LITTLE_VERBOSE
        printf(COLOR_GREEN);
        printf("New client connected (%s:%i) (ID %d). Current connections: %d\n", client_ip_str, client_port, connection_id_counter, count_processes(child_desc_node_ll)+1);
        printf(COLOR_RESET);
        fflush(stdout);
        #endif
        
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
                client_handler(client_socket, connection_id_counter, ajax_handler_callback, ajax_handler_context);
                //El handler nunca deberia terminar!!
                perror("ERROR: client_handler returned\n");
                exit(EXIT_FAILURE);
            }

        } else {
            /*
            Codigo Parent
            */

            // Agrega proceso hijo al administrador de procesos

            
            close(client_socket);
        }
        
    }

    return 0;
}

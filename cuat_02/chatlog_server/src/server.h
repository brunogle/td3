#ifndef SERVER_H
#define SERVER_H

#include <sys/types.h>

#define RECV_BUFF_SIZE 8192
#define WRITE_BUFF_SIZE 512
#define URL_SIZE 2024


/*
Estructura almacena en linked list para manejar procesos
*/
typedef struct child_desc_node {
    pid_t pid;
    struct child_desc_node * next;
    int connection_id;
} child_desc_node;


typedef struct ajax_response_t {
    char * response; // Respuesta generada por el callback 
    unsigned int response_len; // Largo de la respuesta
} ajax_response_t;

typedef struct http_request_t {
    char method[16];       // "GET", "POST", etc.
    char path[URL_SIZE];   // 
    char url[URL_SIZE];
    char http_version[16];
    char * body;
    int body_size;
    char ajax_request;
    
} http_request_t;

/*
Esta es la funcion que se debe usar para el handling de requests AJAX.
*/
typedef int (* ajax_handler_callback_t)(http_request_t http_request, ajax_response_t * ajax_response, void * context);


/*
Esta funcion bloquea hasta que termina el server. Solo termina por un error.
*/
int http_server_proc(int port, int max_connections, ajax_handler_callback_t ajax_handler_callback_, void * ajax_handler_context);

#endif
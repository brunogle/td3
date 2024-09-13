#ifndef SERVER_H
#define SERVER_H

#include <sys/types.h>

/*
Estructura almacena en linked list para manejar procesos
*/
typedef struct child_desc_node {
    pid_t pid;
    struct child_desc_node * next;
    int connection_id;
} child_desc_node;


typedef int (* ajax_handler_callback_t)(char * request, char * response, unsigned int * response_len, char * payload, int payload_size);

int http_server_start(int port, int max_connections, ajax_handler_callback_t ajax_handler_callback_);

#endif
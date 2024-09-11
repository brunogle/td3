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

#define PORT 8080
#define RECV_BUFF_SIZE 16*1024
#define MAX_CONNECTIONS 10
#define HTML_FILENAME "index.html"
#define URL_SIZE 2048


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


/*
Estructura almacena en linked list para manejar procesos
*/
typedef struct child_desc_node {
    pid_t pid;
    struct child_desc_node * next;
    int connection_id;
} child_desc_node;

/*
Inserta un proceso en la lista
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

/*
Busca por PID y borra el proceso de la lista 
*/
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

/*
Busca por PID y retorna el nodo
*/
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

/*
Respuestas HTTP
*/


int http_bad_request_400(int socket_fd){
    char response[] = "HTTP/1.1 400 Bad Request\nContent-Length: 14\n\n404 Bad Request";

    write(socket_fd, response, strlen(response));

    return 0;
}


int http_not_found_404(int socket_fd){
    char response[] = "HTTP/1.1 404 Not Found\nContent-Length: 13\n\n404 Not Found";

    write(socket_fd, response, strlen(response));

    return 0;
}

int http_uri_too_long_414(int socket_fd){
    char response[] = "HTTP/1.1 414 URI Too Long\nContent-Length: 16\n\n414 URI Too Long";

    write(socket_fd, response, strlen(response));

    return 0;
}


int http_not_implemented_501(int socket_fd){
    char response[] = "HTTP/1.1 501 Not Implemented\nContent-Length: 19\n\n501 Not Implemented";

    write(socket_fd, response, strlen(response));

    return 0;
}

int http_internal_server_error_500(int socket_fd){
    char response[] = "HTTP/1.1 500 Internal Server Error\nContent-Length: 19\n\n500 Internal Server Error";

    write(socket_fd, response, strlen(response));

    return 0;
}

int http_serve_file(int socket_fd, char * file_path){
    FILE * file_fd;
    

    file_fd = fopen(file_path, "rb");

    if (file_fd == NULL) {
        if (errno == ENOENT) {
            http_not_found_404(socket_fd);
            return 404;
        } else {
            perror("ERROR: fopen failed\n");
            http_internal_server_error_500(socket_fd);
            return 500;
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

    fseek(file_fd, 0, SEEK_END); // seek to end of file
    int content_size = ftell(file_fd); // get current file pointer
    fseek(file_fd, 0, SEEK_SET); // seek back to beginning of file

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

void print_button_pushed(){
    printf("The button has been pressed\n");
}

int handle_ajax_request(int client_socket, char * request){
    print_button_pushed();
    const char *response =
        "HTTP/1.1 200 OK\n"
        "Connection: keep-alive\n"
        "Content-Type: application/json\n"
        "Access-Control-Allow-Origin: *\n"
        "Content-Length: 8\n"
        "\n"
        "response";
    
    write(client_socket, response, strlen(response));
    
    return 200;
}

/*
Handler del cliente. Se ejecuta siempre en un proceso hijo
*/
void client_handler(int client_socket, int connection_id) {


    //int shm_fd = shm_open("/td3_bruserver", O_CREAT | O_RDWR, 0666);
    //struct stat shm_stat;
    //fstat(shm_fd, &shm_stat);
    //size_t shm_size = shm_stat.st_size;
    //char * sh_mem = (char*) mmap(0, shm_size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);

    char recv_buffer[RECV_BUFF_SIZE];
    char url[URL_SIZE+1];
    char method[16];

    while(1){

        int bytes_read = read(client_socket, recv_buffer, RECV_BUFF_SIZE - 1);
        if(bytes_read < 0){
            perror("FATAL: read failed\n");
            close(client_socket);
            exit(EXIT_FAILURE);
        }
        else if(bytes_read == 0){
            break;
        }
        else if(bytes_read == RECV_BUFF_SIZE){
            perror("ERROR: receive bufer is full. Ignoring request\n");
            continue;
        }

        //printf("%s\n", recv_buffer);


        if(sscanf(recv_buffer, "%15s", method) < 1){
            http_bad_request_400(client_socket);
            continue;
        }

        if(strcmp(method, "GET") == 0){
            int url_size;

            if(sscanf(&recv_buffer[4], "%"STR(URL_SIZE)"s%n", url, &url_size) < 1){
                http_bad_request_400(client_socket);
                continue;
            }
            if(url_size == URL_SIZE){
                http_uri_too_long_414(client_socket);
                continue;
            }
        
            char file_path[URL_SIZE+5];
            if(strcmp(url, "/") == 0){
                strcpy(file_path, "./index.html");
            }
            else{
                sprintf(file_path, ".%s", url);
            }

            int response = 0;

            if(strncmp(url, "/ajax", 5) == 0){
                response = handle_ajax_request(client_socket, url);
            }
            else{
                response = http_serve_file(client_socket, file_path);
            }
            printf("Handled Request from Client ID %d: %s %-20s       Response: %d\n", connection_id, method, url, response);

        }
        else{
            http_not_implemented_501(client_socket);
        }

    }
    
    close(client_socket);
    exit(0);

}


/*
Estas variables son globales porque las necesita el sigchild_handler
*/
child_desc_node * child_desc_node_ll; //Linked list para mantener registro de procesos client handler
sem_t sigchld_semaphore;

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


int main(int argc, char *argv[]){



    /*
    Crea memoria comparida para enviar datos a proceso hijo
    */
    char *shmem_html;
    int shmem_html_fd;
    if((shmem_html_fd = shm_open("/td3_bruserver", O_CREAT | O_RDWR, 0666)) == -1){
        perror("FATAL: shm_open");
        exit(EXIT_FAILURE);
    }
    ftruncate(shmem_html_fd, 1000);
    if((shmem_html = (char*) mmap(0, 1000, PROT_READ | PROT_WRITE, MAP_SHARED, shmem_html_fd, 0)) == (char*)-1){
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
    struct sockaddr_in server_address;
    int addrlen = sizeof(server_address);
    server_address.sin_family = AF_INET;
    server_address.sin_addr.s_addr = htonl(INADDR_ANY);
    server_address.sin_port = htons(PORT);
    int opt = 1;
    if (setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("FATAL: setsockopt failed\n");
        exit(EXIT_FAILURE);
    }

    /*
    Bind del socket
    */
    if (bind(server_socket, (struct sockaddr *)&server_address, sizeof(server_address)) == -1) {
        perror("FATAL: bind failed\n");
        exit(EXIT_FAILURE);
    }
    if (listen(server_socket, 2) == -1) {
        perror("FATAL: listen failed\n");
        exit(EXIT_FAILURE);
    }


    printf("Server ready at port: %d\n", PORT);

    int client_socket;
    int connection_id_counter = 0;

    while (1) {
        /*
        Espera conexion
        */
        if ((client_socket = accept(server_socket, (struct sockaddr *)&server_address, (socklen_t *)&addrlen)) == -1) {
            perror("ERROR: Accept failed\n");
            continue;
        }

        if(count_processes(child_desc_node_ll) + 1 > MAX_CONNECTIONS){
            printf(COLOR_RED);
            printf("Max Connections Reached (%d), closing connection\n", MAX_CONNECTIONS);
            printf(COLOR_RESET);  
            fflush(stdout);  
            close(client_socket);
            continue;
        }


        connection_id_counter++;
        printf(COLOR_GREEN);
        printf("New client connected (ID %d). Current connections: %d\n", connection_id_counter, count_processes(child_desc_node_ll)+1);
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

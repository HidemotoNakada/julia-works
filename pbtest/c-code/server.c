#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>


void usage(char * name) {
    fprintf(stderr, "USAGE: %s PORT", name);
    exit(1);
}

int main(int argc, char ** argv) {
    int servPort = 4000;
    int num_send = 0;

    if (argc != 2)
        usage(argv[0]);
    servPort = atoi(argv[1]);


    struct sockaddr_in servSockAddr;
    int servSock; 

    if ((servSock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0 ){
        perror("socket() failed.");
        exit(1);
    }

    servSockAddr.sin_family      = AF_INET;
    servSockAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    servSockAddr.sin_port        = htons(servPort);

    if (bind(servSock, (struct sockaddr *) &servSockAddr, sizeof(servSockAddr)) < 0) {
        perror("bind() failed.");
        exit(1);
    }

    if (listen(servSock, 5) < 0) {
        perror("listen() failed.");
        exit(1);
    }



    while (1) {
        fprintf(stderr, "accepting at port %d\n", servPort);
        int sock;
        struct sockaddr_in clntSockAddr;
        unsigned int clntLen = sizeof(clntSockAddr);

        if ((sock = accept(servSock, (struct sockaddr *) &clntSockAddr, &clntLen)) < 0) {
            perror("accept() failed.");
            exit(1);
        }

        long int message = -1;
        long int reply = -1;


        while (1) {
            read(sock, &message, sizeof(long int));
//            fprintf(stderr, "message = %ld\n", message);
            if (message < 0)
                break;
            reply = message + 100;
            for (int i = 0; i < message; i++) {
                write(sock, &reply, sizeof(long int));
            }
        }
        close(sock);
    }

    return 0;
}
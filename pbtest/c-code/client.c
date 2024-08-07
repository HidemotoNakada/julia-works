#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>


#include <mach/clock.h>
#include <mach/mach.h>





void usage(char * name) {
    fprintf(stderr, "USAGE: %s PORT NUM_ITEMS NUM_TIMES\n", name);
    exit(1);
}


int main(int argc, char ** argv) {
    int port = 4000;
    int num_items = 0;
    int num_times = 0;
    const char * hostname = "127.0.0.1";

    if (argc != 4)
        usage(argv[0]);

    port = atoi(argv[1]);
    num_items = atoi(argv[2]);
    num_times = atoi(argv[3]);


    struct sockaddr_in sockAddr;
    int sock;
    
    if ((sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
        perror("socket() failed.");
        exit(1);
    }

    sockAddr.sin_family      = AF_INET;
    sockAddr.sin_addr.s_addr = inet_addr(hostname);
    sockAddr.sin_port        = htons(port);

    if (connect(sock, (struct sockaddr *) &sockAddr, sizeof(sockAddr)) < 0) {
        perror("connect() failed.");
        exit(1);
    }

    long int message = num_items;
    long int reply = -1;

clock_serv_t cclock;
mach_timespec_t before, after;
host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);

    clock_get_time(cclock, &before);

    for (int j = 0; j < num_times; j++) {

        write(sock, &message, sizeof(long int));

        for (int i = 0; i < num_items; i++) {
            read(sock, &reply, sizeof(long int));
        }

    }
    clock_get_time(cclock, &after);
    long int stop = -1L;
    write(sock, &stop, sizeof(long int));

    long int spent = (after.tv_nsec - before.tv_nsec) + (after.tv_sec - before.tv_sec) * 1000000000L; 
    fprintf(stderr, "time taken: %ld, time for %d items, %d times \n", spent, num_items, num_times);

    spent /= num_times;    
    fprintf(stderr, "average of %d times: %ld ns\n", num_times, spent);

mach_port_deallocate(mach_task_self(), cclock);

    close(sock);
}
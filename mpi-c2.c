#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <time.h>

int rank, comm_size;
const int times = 100;

long sizes[] = {1024, 10 * 1024, 100 * 1024, 1024 * 1024, 10 * 1024 * 1024, 100 * 1024 * 1024};
int nsize = 6;

#include <stdarg.h>

void info(const char *format, ...) {
	va_list args;
	va_start(args, format);
	fprintf(stderr, "%d ", rank);
	vfprintf(stderr, format, args);
	fprintf(stderr, "\n");
	va_end(args);
}

double time_diff(struct timespec * start, struct timespec * end) {
	double v = (double)(end->tv_sec - start->tv_sec);
	v += (double)(end->tv_nsec - start->tv_nsec) / ((double)(1000 * 1000 * 1000));
	return v;
}


double send_recv(void * a, int count, MPI_Datatype datatype, int target, int tag, int times) {
  struct timespec start, end;
  
  MPI_Status status;
  clock_gettime(CLOCK_REALTIME, &start);
  for (int i = 0; i < times; i++) {
    //	info("send_recv 1, %d", tag);
    MPI_Send(a, count, datatype, target, tag, MPI_COMM_WORLD);
    //	info("send_recv 2, %d", tag);
    MPI_Recv(a, count, datatype, target, tag, MPI_COMM_WORLD, &status);
  }
  clock_gettime(CLOCK_REALTIME, &end);
  return time_diff(&start, &end);
}

void recv_send(void * a, int count, MPI_Datatype datatype, int target, int tag, int times) {
  MPI_Status status;
  for (int i = 0; i < times; i++) {
    //	info("recv_send 1, %d", tag);
    MPI_Recv(a, count, datatype, target, tag, MPI_COMM_WORLD, &status);
    //	info("recv_send 2, %d", tag);
    MPI_Send(a, count, datatype, target, tag, MPI_COMM_WORLD);
  }
}


void * setup_buf(long datasize) {
  void * b = malloc(datasize);
  char * tmp = (char *) b;
  for (int i = 0; i < datasize; i++) 
    *tmp++ = i;
  return b;
}


void ave(int target, double * elapses, int datasize) {
  double sum = 0.0;
  for (int i = 1; i < times; i++)
    sum += elapses[i];
  double ave = sum / (times - 1);
  double th = ((double)datasize * 2) / ave;
  th /= (1024.0 * 1024.0 * 1024.0);
  printf("%d %d %f sec %f GB/s\n", target, datasize, ave, th);
}


void recvbuf(int target, long datasize, int times) {
  char * buf = setup_buf(datasize);
  recv_send(buf, datasize, MPI_UNSIGNED_CHAR, target, 1, times);
}

void sendbuf(int target, long datasize, int times) {
  char * buf = setup_buf(datasize);
  double diff = send_recv(buf, datasize, MPI_UNSIGNED_CHAR, target, 1, times);
  printf("%ld %f sec %f GBs\n", datasize, diff, ((2.0 * datasize * times) / diff) / (1024.0 * 1024.0 * 1024.0));
  free(buf);
}


void rank0(int target) {
  for (int sindex = 0; sindex < nsize; sindex++) 
    sendbuf(target, sizes[sindex], times);
}

void rankOther(int target) {
  for (int sindex = 0; sindex < nsize; sindex++) 
    recvbuf(target, sizes[sindex], times);
}

int main(int argc, char **argv){
  printf("%s\n", getenv("HOSTNAME"));

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &comm_size);
  
  //		printf("rank = %d, size = %d\n", rank, comm_size);
  
  if (rank == 0) {
    for (int target = 1; target < comm_size; target++) {
      rank0(target);
    }
  } else {
    rankOther(0);
  }
  MPI_Finalize();	
}


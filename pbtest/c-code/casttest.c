#include <stdio.h>

int main(){
    double a[] = {1.0, 2.0};
    unsigned char *p = (unsigned char *)a;

    for (int i = 0; i < 2; i++){
        printf("%f ", *(a + i));
    }
    printf("\n");

    for (int i = 0; i < sizeof(double) * 2; i++){
        printf("%02x ", *(p + i));
    }
    printf("\n");
    return 0;
}
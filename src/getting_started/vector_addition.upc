#include<upc_relaxed.h>

#define N 10

shared int v1[N], v2[N], v1plusv2[N];

int main()
{
    // initialize the vectors
    for(int i=0; i<N; i++)
    {
        v1[i] = i;
        v2[i] = i;
    }

    // add the vectors
    int i;
    for(i=0; i<N; i++)
        if(MYTHREAD == i % THREADS)
            v1plusv2[i] = v1[i] + v2[i];
    
    // print the result
    if(MYTHREAD == 0)
    {
        for(int i=0; i<N; i++)
            printf("%d ", v1plusv2[i]);
        printf("\n");
    } 
    
    return 0;
}
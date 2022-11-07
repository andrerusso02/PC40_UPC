#include <upc_relaxed.h>

shared int a [THREADS][THREADS];
shared int b [THREADS], c [THREADS];

// initialize the vectors randomly
void initialize()
{
    for(int i=0; i<THREADS; i++)
    {
        b[i] = rand() % 10;
        for(int j=0; j<THREADS; j++)
            a[i][j] = rand() % 10;
    }
}

int main (void)
{
    // initialize the vectors
    if(MYTHREAD == 0)
        initialize();
    
    // multiplication
    int i, j;
    upc_forall(i = 0; i < THREADS; i++; i)
    {
        c [i] = 0;
        for (j= 0; j <THREADS; j++)
            c [i] += a [i][j]*b [j];
    }

    // print the result
    if(MYTHREAD == 0)
    {
        for(int i=0; i<THREADS; i++)
            printf("%d ", c[i]);
        printf("\n");
    }

    return 0;
}
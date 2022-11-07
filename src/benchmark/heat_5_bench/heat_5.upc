#include <stdio.h>
#include <math.h>
#include <sys/time.h>
#include <upc_relaxed.h>


// Shared grid. Each cell will point to the rows stored the shared space of the concidere thread
shared[] double *shared local_chunks[THREADS];
shared[] double *shared new_local_chunks[THREADS];
shared[] double *shared tmp_local_chunks[THREADS];

// private pointer to the local chunk of grid of the thread
double *ptr_priv;
double *new_ptr_priv;
double *tmp_ptr_priv;

int N;
int N_LOCAL_ROWS; // number of rows stored in each thread (=number of rows in the local chunk)

shared double exectime[THREADS];
shared double dTmax_local[THREADS];


void initialize(void)
{
    int j;

    for( j=1; j<N+1; j++ )
    {
        local_chunks[0][j] = 1.0;
        new_local_chunks[0][j] = 1.0;
    }
}

void display_grid(void)
{
    for(int i=0; i<N+2; i++ )
    {
        for(int j=0; j<N+2; j++ )
            printf("%.2lf ", local_chunks[i%THREADS][i/THREADS*(N+2)+j]);
        printf("\n");
    }
    printf("\n");
}


int main(int argc, char **argv)
{
    struct timeval ts_st, ts_end;
    double dTmax, dT, epsilon, max_time;
    int finished, i, j, k, l;
    double T;
    int nr_iter;

    // get N from command line argument
    if( argc != 2 )
    {
        if( MYTHREAD == 0 )
            printf("Specify N as argument\n");
        return 1;
    }
    N = atoi(argv[1]);
    N_LOCAL_ROWS = (N+2)/THREADS;

    // allocate memory for the grids using upc_alloc so that each thread allocates the grid chunk which has affinity to it
    local_chunks[MYTHREAD] = (shared[] double *shared) upc_alloc(N_LOCAL_ROWS*(N+2)*sizeof(double));
    new_local_chunks[MYTHREAD] = (shared[] double *shared) upc_alloc(N_LOCAL_ROWS*(N+2)*sizeof(double));

     // initialize the private pointers to point to the local chunk of the grid
    ptr_priv = (double*) local_chunks[MYTHREAD];
    new_ptr_priv = (double*) new_local_chunks[MYTHREAD];

    // wait for the entire grid to be allocated
    upc_barrier;

    // initialize the grid
    if(MYTHREAD == 0){
        initialize();
    }

    // wait for the grid to be initialized
    upc_barrier;
    
    epsilon  = 0.0001;
    finished = 0;
    nr_iter = 0;

    gettimeofday( &ts_st, NULL);

    // iterate until the precision is reached
    do
    {
        dTmax = 0.0;
        upc_forall( i=1; i<N+1; i++; i)
        {
            // iterate over the grid's columns
            for( j=1; j<N+1; j++ )
            {
                // calculate the new temperature using private pointers when possible
                T = 0.25 * (
                    ptr_priv[(i/THREADS)*(N+2)+j-1] +
                    ptr_priv[(i/THREADS)*(N+2)+j+1] +
                    local_chunks[(i-1)%THREADS][(i-1)/THREADS*(N+2)+j] +
                    local_chunks[(i+1)%THREADS][(i+1)/THREADS*(N+2)+j]
                );
                // calculate the difference between the old and the new temperature
                dT = fabs(T - ptr_priv[(i/THREADS)*(N+2)+j]);
                // update the maximum difference
                if( dT > dTmax )
                    dTmax = dT;
                // update the new temperature
                new_ptr_priv[(i/THREADS)*(N+2)+j] = T;
            }
        }

        dTmax_local[MYTHREAD] = dTmax;
        // wait for all threads to update the dTmax_local
        upc_barrier;

        // find the max value of dTmax_local which is the max variation for this iteration
        dTmax = dTmax_local[0];
        for( i=1; i<THREADS; i++ )
            if( dTmax < dTmax_local[i] )
                dTmax = dTmax_local[i];

        if( dTmax < epsilon ) // precision reached, stop iterating
            finished = 1;
        else // keep iterating
        {
            // swap the pointers to the chunks
            upc_forall(i=0; i<THREADS; i++; i){
                tmp_local_chunks[i] = local_chunks[i];
                local_chunks[i] = new_local_chunks[i];
                new_local_chunks[i] = tmp_local_chunks[i];
            }

            // swap the private pointers
            tmp_ptr_priv = ptr_priv;
            ptr_priv = new_ptr_priv;
            new_ptr_priv = tmp_ptr_priv;
        }

        // wait for all threads to finish swapping the pointers
        upc_barrier;

        nr_iter++;
    } while( finished == 0 );

    // calculate the execution time of each thread
    gettimeofday( &ts_end, NULL );
    exectime[MYTHREAD] = ts_end.tv_sec + (ts_end.tv_usec / 1000000.0);
    exectime[MYTHREAD] -= ts_st.tv_sec + (ts_st.tv_usec / 1000000.0);

    // wait for all threads to finish before displaying the results
    upc_barrier;

    if( MYTHREAD == 0 )
    {
        // display execution time
        max_time = exectime[MYTHREAD];
        for( i=1; i<THREADS; i++ )
            if( max_time < exectime[i] )
                max_time = exectime[i];
        
        printf("Number of iterations: %d\n", nr_iter);
        printf("N, number of threads, execution time:\n");
        printf("%d, %d, %lf\n", N, THREADS, max_time);

        // display the final grid
        //display_grid();
    }

    // free the allocated memory
    upc_free(local_chunks[MYTHREAD]);
    upc_free(new_local_chunks[MYTHREAD]);
    return 0;
}


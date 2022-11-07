#include <stdio.h>
#include <math.h>
#include <sys/time.h>
#include <upc_relaxed.h>

#define N 302

/* ------------------------- shared variables ---------------------- */
// grid and new_grid are shared arrays blocked by rows
shared [N+2] double grid[N+2][N+2], new_grid[N+2][N+2];
// shared array of execution times so that each thread calculates its own
shared double exectime[THREADS];
// shared dTmax so that each thread calculates its own before thread 0 finds the max value
shared double dTmax_local[THREADS];
/* ----------------------------------------------------------------- */


/* ------------ Private to shared pointers ------------------------- */
shared [N+2] double *ptr[N+2], *new_ptr[N+2], *tmp_ptr;
/* ----------------------------------------------------------------- */

/**
 * @brief initialize the grid
 * 
 */
void initialize(void)
{
    int j;

    for( j=1; j<N+1; j++ )
    {
        grid[0][j] = 1.0;
        new_grid[0][j] = 1.0;
    }
}

int main(void)
{
    struct timeval ts_st, ts_end;
    double dTmax, dT, epsilon, max_time;
    int finished, i, j, k, l;
    double T;
    int nr_iter;

    if( MYTHREAD == 0 )
        initialize();

    // initialize the pointers ptr[] and new_ptr[] to point to the first element of each row
    for( i=0; i<N+2; i++ )
    {
        ptr[i] = &grid[i][0];
        new_ptr[i] = &new_grid[i][0];
    }

    epsilon  = 0.0001;
    finished = 0;
    nr_iter = 0;

    upc_barrier;

    gettimeofday( &ts_st, NULL);

    // iterate until the precision is reached
    do
    {
        dTmax = 0.0;
        // iterate over the grid's rows affecting each row to the thread that has affinity to it
        upc_forall( i=1; i<N+1; i++; i)
        {
            // the thread calculates the new values for the row 
            for( j=1; j<N+1; j++ )
            {
                // Calculate the new value for the grid point (i,j) using the pointers to allow swapping pointers at the end of the iteration
                T = 0.25 *
                    (ptr[i+1][j] + ptr[i-1][j] +
                     ptr[i][j-1] + ptr[i][j+1]);
                new_ptr[i][j] = T;
                // Calculate the max variation in this iteration for each thread
                dT = T - ptr[i][j];
                if( dTmax < fabs(dT) )
                    dTmax = fabs(dT);
            }
        }

        // compute dTmax across THREADS
        dTmax_local[MYTHREAD] = dTmax;
        // wait for all threads to finish before finding the max value, because dTmax_local is shared
        upc_barrier;
        // find the max value of dTmax_local which is the max variation in this iteration
        dTmax = dTmax_local[0];
        for( i=1; i<THREADS; i++ )
            if( dTmax < dTmax_local[i] )
                dTmax = dTmax_local[i];
        // barrier to make sure all threads have the same value of dTmax.
        upc_barrier;

        if( dTmax < epsilon ) // precision reached, stop iterating
            finished = 1;
        else // keep iterating
        {
            // swap the pointers to the grids
            for( k=0; k<N+2; k++ )
            {
                tmp_ptr    = ptr[k];
                ptr[k]     = new_ptr[k];
                new_ptr[k] = tmp_ptr;
            }
        }
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
        // for( i=0; i<N+2; i++ )
        // {
        //     for( j=0; j<N+2; j++ )
        //         printf("%.2lf ", grid[i][j]);
        //     printf("\n");
        // }
    }
    return 0;
}


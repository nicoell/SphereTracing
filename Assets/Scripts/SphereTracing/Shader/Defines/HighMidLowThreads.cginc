#ifndef HIGHMIDLOWTHREADS_INCLUDED
#define HIGHMIDLOWTHREADS_INCLUDED

#ifdef HIGH
    #define ThreadsX 32
    #define ThreadsY 20
    #define ThreadsZ 1
#elif MID
    #define ThreadsX 16
    #define ThreadsY 16
    #define ThreadsZ 1
#elif LOW
    #define ThreadsX 8
    #define ThreadsY 8
    #define ThreadsZ 1
#endif

#define ThreadsXY ThreadsX * ThreadsY

#endif // HIGHMIDLOWTHREADS_INCLUDED
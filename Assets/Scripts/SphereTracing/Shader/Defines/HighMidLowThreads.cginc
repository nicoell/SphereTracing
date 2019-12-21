#ifndef HIGHMIDLOWTHREADS_INCLUDED
#define HIGHMIDLOWTHREADS_INCLUDED

//Values are chosen to work with 16:9 formats like 1920x1080, 1280x720

#ifdef HIGH
    #define ThreadsX 32
    #define ThreadsY 24
    #define ThreadsZ 1
#elif MID
    #define ThreadsX 16
    #define ThreadsY 12
    #define ThreadsZ 1
#elif LOW
    #define ThreadsX 8
    #define ThreadsY 8
    #define ThreadsZ 1
#endif

#ifdef HIGHDOWNSAMPLED
    #define ThreadsX 30
    #define ThreadsY 27
    #define ThreadsZ 1
#elif MIDDOWNSAMPLED
    #define ThreadsX 16
    #define ThreadsY 15
    #define ThreadsZ 1
#elif LOWDOWNSAMPLED
    #define ThreadsX 8
    #define ThreadsY 5
    #define ThreadsZ 1
#endif

#ifdef HIGH1D
    #define ThreadsX 640
    #define ThreadsY 360
    #define ThreadsZ 1
#elif MID1D
    #define ThreadsX 320
    #define ThreadsY 180
    #define ThreadsZ 1
#elif LOW1D
    #define ThreadsX 80
    #define ThreadsY 90
    #define ThreadsZ 1
#endif

#define ThreadsXY ThreadsX * ThreadsY

#endif // HIGHMIDLOWTHREADS_INCLUDED
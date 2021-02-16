
// time.h
// 2012/08/13
// mm7t RTC enable
//

#ifndef _TIME_H
#define _TIME_H

//---------------------------------------------------------
struct _time {
        u32 year:6;     // 1980 + year
        u32 month:4;    // 1 - 12
        u32 day:5;      // 1 - 31
        u32 hour:5;     // 0 - 23
        u32 min:6;      // 0 - 59
        u32 sec:6;      // 0 - 59
};
typedef struct _time time_t;

time_t get_time();	// get time from RTC

#endif // _TIME_H

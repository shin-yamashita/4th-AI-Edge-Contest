//
//

#ifndef _TYPES_H
#define _TYPES_H

typedef unsigned size_t;
typedef int      ssize_t;

typedef signed char     s8;
typedef unsigned char   u8;
typedef signed short    s16;
typedef unsigned short  u16;
typedef signed int      s32;
typedef unsigned int    u32;

typedef union {float f; unsigned u;} fu_t;
#define fu(x)	((fu_t)(x)).u
#define uf(x)	((fu_t)(x)).f

#endif	// _TYPES_H

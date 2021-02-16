//======================================================
// ulib.h
//  library for mm6 hardware control
//

#ifndef _ULIB_H
#define _ULIB_H

#include <_ansi.h>
_BEGIN_STD_C

#include "types.h"

#define __START	__attribute__ ((__section__ (".start"))) 
#define __SRAM	__attribute__ ((__section__ (".sram"))) 
#define __DRAM	__attribute__ ((__section__ (".dram"))) 

#define DRAMTOP	((volatile u8*)0x20000000)
#define SUBTOP	((volatile u8*)0x10000000)

//	para port
#define POUT    ((volatile u8*)0xffff0000)

//      sr_timer interface
#define TIMERBR   ((volatile unsigned *)0xffff0040)
#define TIMERBRC  ((volatile unsigned *)0xffff0044)
#define TIMERCTL  ((volatile char *)0xffff0048)
#define TIMERFRC  ((volatile unsigned *)0xffff004c)

//      sr_sio interface
#define SIOTRX  ((volatile char *)0xffff0020)
#define SIOFLG  ((volatile char *)0xffff0021)
#define SIOBR   ((volatile short *)0xffff0022)

//	sr_cache_unit
//#define CACHECTRL	((volatile u8*)0xffff0180)
//#define CACHEBASE	((volatile u32*)0xffff0184)


//      ulib.c function prototypes

int get_pout();
void set_pout(int d);           // direct set 8bit
void set_port(int bit);         // bit set
void reset_port(int bit);       // bit reset
int get_port();


void init_timer(int br);
void timer_ctrl(void);
void wait(void);	// wait 1 ms
void n_wait(int n);	// wait n ms
void set_timer(int t);	// set 1ms counter val
int get_timer();	// 

void irq_handler(void);
void add_timer_irqh_sys(void (*irqh)(void));
void add_timer_irqh(void (*irqh)(void));
void add_user_irqh(void (*irqh)(void));
void add_user_irqh_1(void (*irqh)(void));
void add_user_irqh_2(void (*irqh)(void));
void remove_timer_irqh_sys(void);
void remove_timer_irqh(void);
void remove_user_irqh(void);
void remove_user_irqh_1(void);
void remove_user_irqh_2(void);

// memcpy32		len : # of bytes
void memcpy32(u32 *dst, u32 *src, size_t len);	// dst, src : u32 aligned

// from srmon.c
void getstr(char *str);
unsigned char asc2hex(int c);
unsigned int str2u32(char *s);

#include "uartdrv.h"

// clear bss section
extern u32 _bss_start, _end;
#define	zero_bss()	{u32 *p;for(p=&_bss_start;p<&_end;*p++=0);}
// get stack pointer
static inline u32 get_sp(){u32 sp;__asm__("mov sp,%0" : "=r" (sp));return sp;}


//#define f_clk	100e6
#define f_clk	150e6

_END_STD_C

#endif  // _ULIB_H

//======================================================
//  2010/04  ulib.c   mm6 hardware driver library
//

#include "stdio.h"
#include "ulib.h"
#include "time.h"

// POUT  parallel output port

static unsigned char _pout = 0;

int get_pout()
{
	return _pout;
}
void set_pout(int d)		// direct set 8bit
{
	*POUT = _pout = d;
}
void set_port(int bit)		// bit set
{
	_pout |= (1<<bit);
	*POUT = _pout;
}
void reset_port(int bit)	// bit reset
{
	_pout &= ~(1<<bit);
	*POUT = _pout;
}
int get_port()
{
	return *POUT;
}

//	sr_timer interface

static volatile int timer;
static volatile int tick;
static volatile int tmexp, expose;

void init_timer(int br)
{
	*TIMERBR = br;
	*TIMERCTL = 4 | 2;	// tmoe|inte
}

void wait(void)
{
        while(!tick) ;  // wait for 1 ms interrupt
        tick = 0;
}
void n_wait(int n)
{
        int i;
        for(i = 0; i < n; i++) wait();
}
void set_timer(int t)
{
	timer = t;
}
int get_timer()
{
	return timer;
}
//----- interrupt handler -----------------------------
//  irq (sr_core irq pin - vector #1)

static void (*timer_irqh_s)(void) = 0;
static void (*timer_irqh)(void) = 0;
static void (*user_irqh)(void) = 0;

static void timer_handl(void)
{
	if(*TIMERCTL & 1){
		*TIMERCTL = *TIMERCTL;	// clear irq when irq = 0
	//	pex_irqh_1ms();
	//	gyro_hpf();
		if(timer_irqh_s)
			(*timer_irqh_s)(); // 1ms system handler call
		if(timer_irqh)
			(*timer_irqh)(); // 1ms user handler call
		timer++;
		tick = 1;
	}
}

void irq_handler(void)
{
	timer_handl();
	txirq_handl();
}

void eirq_handler(void)
{
	if(user_irqh)  (*user_irqh)();
}

void add_timer_irqh_sys(void (*irqh)(void))
{
	timer_irqh_s = irqh;
}
void add_timer_irqh(void (*irqh)(void))
{
	timer_irqh = irqh;
}
void add_user_irqh(void (*irqh)(void))
{
	user_irqh = irqh;
}
void remove_timer_irqh(void)
{
	timer_irqh = 0;
}
void remove_timer_irqh_sys(void)
{
	timer_irqh_s = 0;
}
void remove_user_irqh(void)
{
	user_irqh = 0;
}

#if 0
//===== 2012/08/11 memif/sr_cache control

void d_cache_flush()
{
	*CACHECTRL = 2;	// flush d-cache
	while(*CACHECTRL);
}

void d_cache_clean()
{
	*CACHECTRL = 1;	// clean d-cache
	while(*CACHECTRL);
}

void i_cache_clean()
{
	*CACHECTRL = 4;	// clean i-cache
	while(*CACHECTRL);
}

void cache_flush()
{
	*CACHECTRL = 7;	// flush and clean all
	while(*CACHECTRL);
}
#endif


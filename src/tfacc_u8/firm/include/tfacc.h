//
// 2020/03/23 tfacc.h
// tfacc_core driver
//

#include "types.h"

//      tfacc_core 

#define CACHECTRL       ((volatile u8*)0xffff0180)
#define TFACCCACHE      ((volatile u32 *)0xffff0180)

#define TFACCFLG        ((volatile u32 *)0xffff0300)	// b0 w:kick r:run

#define BASEADR_OUT     ((volatile u32 *)0xffff0304)
#define BASEADR_IN      ((volatile u32 *)0xffff0308)
#define BASEADR_FILT    ((volatile u32 *)0xffff030c)
#define BASEADR_BIAS    ((volatile u32 *)0xffff0310)

#define TFACC_NP        ((volatile u32 *)0xffff031c)
#define TFACCMON        ((volatile u32 *)0xffff0320)    // monisel

#define TFACCPARAM      ((volatile u32 *)0xffff0400)	// accparams[64]

u32 *accparams = (u32*)0x100;
#define set_param(n, p)     (accparams[n] = (p))
#define get_param(n)        (accparams[n])
#define set_accparam(n, p)  set_param(7+(n), (p))
#define get_accparam(n)     get_param(7+(n))

typedef enum {
    kTfaccNstage = 4,
    kTfaccDWen,
    kTfaccRun,
} TfaccCtrl;


//
// srmon  monitor program 
// 2007/11/27
// 2010/06/27
// 2015/10/   mm8   
// 2016/01/   sbin
// 2020/03/01 dtc

#include "stdio.h"
#include <stdlib.h>
#include <string.h>

#include "ulib.h"
#include "tfacc.h"

#define limit(x, min, max)	((x)<(min)?(min):((x)>(max)?(max):(x)))

#undef f_clk
static float f_clk = 100e6f;

//CACHECTRL:flreq[3:0],clreq[3:0]

int d_cache_flush()
{
    int i = 0;
    *CACHECTRL = 0xf0; // flush d-cache
    while((*CACHECTRL & 0x80)){
        i++;
        if(uart_rx_ready()){
            getchar();
            printf("d_cache_flush() %2x %d\n", *CACHECTRL, i);
            break;
        }
    }
    return i;
}

int d_cache_clean()
{
    //	int i = 0;
    *CACHECTRL = 0xf; // clean d-cache
    //        *CACHECTRL = 0xf; // clean d-cache
    //	while((*CACHECTRL & 0xf)) i++;
    return 0;
}

u32 i_elapsed()
{
    static u32 lastfrc = 0;
    u32 elcnt, now;

    now = *TIMERFRC;	// frc : 1/10 * f_clk counter
    elcnt = (now - lastfrc);
    lastfrc = now;

    return elcnt;	// * (float)(1e3f / (f_clk / 10));	// elapsed(ms)
}

static volatile unsigned tick100, clock;

//============
// IRQ Handler
//============

static void
timer_irqh (void)
{
    tick100 = (tick100 + 1) % 100;
    if (tick100 == 0)
    {
        clock++;
        if ((clock & 1) && ((clock % 10) < 4))
            set_port (0);
        else
            reset_port (0);
    }
}

//==============================================
// Get Byte from Rx
//==============================================
unsigned char
asc2hex (int c)
{
    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    if (c >= '0' && c <= '9')
        return c - '0';
    return 0;
}

unsigned int
str2u32 (char *s)
{
    int c;
    u32 d = 0;
    while ((c = *s++))
    {
        d <<= 4;
        d |= asc2hex (c);
    }
    return d;
}

unsigned char
get_byte ()
{
    unsigned char hex;

    hex = asc2hex (getchar ());
    hex = (hex << 4) + asc2hex (getchar ());

    return (hex);
}


int
isBlank (char *s)
{
    while (*s)
    {
        if (!((*s == '\n') || (*s == ' ')))
            return 0;
        s++;
    }
    return 1;			// blank
}

unsigned char *
dump (unsigned char *pt)
{
    int i, j;

    for (i = 0; i < 256; i += 16)
    {
        printf ("%08x: ", (int) pt);

        for (j = 0; j < 16; j++)
        {
            printf ("%02x ", pt[j]);
        }
        for (j = 0; j < 16; j++)
        {
            char c = pt[j];
            putchar (c >= 0x20 && c < 0x7f ? c : '.');
            //                      putc(isgraph(c) ? c : '.');
        }
        putchar ('\n');
        pt += 16;
    }
    putchar ('\n');
    return pt;
}

void
getstr (char *str)
{
    char c;
    int p = 0;
    do
    {
#if 1
        while (!uart_rx_ready ())
        {
        }
#endif
        c = getchar ();
        switch (c)
        {
        case '\r':		// ignore cr
            break;
        case '\n':		// lf
            *str++ = '\0';
            putchar (c);
            break;
        case 0x7f:
        case '\b':
            if (p > 0)
            {
                str--;
                p--;
                printf ("\b \b");
            }
            break;
        default:
            *str++ = c;
            p++;
            putchar (c);
            break;
        }
    }
    while (c != '\n');
}

u32 i_elapsed_list[128];

int tfacc_run(int trig)
{
    int ncyc = 1;
    int i, c = 0;
    int cntrun, cntxrdy;
    float cnt2ms = (float)(1e3f/(f_clk));
    float el2ms = (float)(1e3f/(f_clk/10));

    int Np = *TFACC_NP;
    printf(" Np = %d\n", Np);
    for(i = 0; i < 128; i++) i_elapsed_list[i] = 0;

    i_elapsed();

    do{
        while(get_param(kTfaccRun) == 0){   // handshake with PS Invoke()
            ncyc = get_param(kTfaccNstage);
            ncyc = ncyc < 128 ? ncyc : 127;
            //	wait();
            if(uart_rx_ready()){
                c = getchar();
                if(c == 'q') return 0;
                if(c == 'e'){
                    u32 ute = 0;
                    for(i = 0; i <= ncyc; i++) ute += i_elapsed_list[i];
                    for(i = 0; i <= ncyc; i++)
                        printf("%2d: %5.2f %% %4.2f ms\n",
                                i, fu((float)i_elapsed_list[i]*100.0f/(float)ute), fu(i_elapsed_list[i]*el2ms));
                    printf("           %4.2f ms  run:%4.2f ms xrdy:%4.2f ms\n", fu(ute*el2ms), fu(cntrun*cnt2ms), fu(cntxrdy*cnt2ms));
                }
            }
        }
        if(ncyc < 1){	// init counter
	   cntrun = cntxrdy = 0;
           i_elapsed();
        }
 //       printf("%d %4.2f ", ncyc, fu(e1));

        BASEADR_OUT[0]  = get_param(0);
        BASEADR_IN[0]   = get_param(1);
        BASEADR_FILT[0] = get_param(2);
        BASEADR_BIAS[0] = get_param(3);

        int dwen = get_param(kTfaccDWen);
        int filH = get_accparam(3);
        int filW = get_accparam(4);
        int filC = get_accparam(5);
        int outH = get_accparam(6);
        int outW = get_accparam(7);
        int outWH = outH * outW;
        int pH = (outWH + (Np-1)) / Np;
        set_accparam(9, pH);

      // depthmul
        if(!dwen) set_accparam(12, 0);
        for(i = 0; i <= 19; i++){
          TFACCPARAM[i] = get_accparam(i);
        }
        TFACCPARAM[20] = outWH;
        TFACCPARAM[21] = filH * filW * filC;    // dim123
        TFACCPARAM[22] = (outWH+pH-1)/pH;   // Nchen

      // out_x, out_y initial value set
        for(i = 0; i < Np; i++){
          int out_y = i*pH / outW;
          int out_x = i*pH % outW;
          TFACCPARAM[i+24] = (out_y<<16)|out_x;
        }
        *CACHECTRL = 0x0f;  // read cache invalidate (clean) request
        *TFACCFLG = 1;  // kick PL accelarator
        *TFACCFLG = 0;
//        printf("%d kick ... ", ncyc);

        int run;
        do{
          run = *TFACCFLG;
        }while(!run);
        do{
          run = *TFACCFLG;
        }while(run);
//        printf(" done ... ");

        int flrdy;
        do{
            flrdy = *CACHECTRL;
        }while(flrdy != 0x40);  // wait out cache all complete
//        printf(" out cache complete and flush request ... ");
        *CACHECTRL = 0xf0;      // out cache flush request
        *CACHECTRL = 0x00;
        do{
            flrdy = *CACHECTRL;
        }while(flrdy != 0x40);  // wait out cache flush complete
//        printf("flush complete.\n");
        cntrun  += TFACCPARAM[0];
        cntxrdy += TFACCPARAM[1];

//printf(" %d: %d %d %d\n", ncyc, cntrun, cntxrdy, i_elapsed());

        i_elapsed_list[ncyc] = i_elapsed();
//        printf(" %d: %d\n", ncyc, i_elapsed_list[ncyc]);

        set_param(kTfaccRun, 0);    // handshake with PS

    }while(c != 'q');
    return 0;
}

int srmon_main (void)
{
    char str[200], *tok;
    int i;
    unsigned char *pt = 0;
    unsigned *wpt = 0;
    u32 *f_clock = (u32*)0xf0;
    int baud = 115200;

    f_clk = (float)(*f_clock);

    uart_set_baud((int)(f_clk / baud + 0.5f));
    init_timer ((int) (1e-3f * f_clk));
    add_timer_irqh_sys (timer_irqh);

    set_port (1);

    printf ("srmon loaded. %4.1f MHz\n", fu(f_clk * 1e-6f));

    reset_port (1);

    tfacc_run(0);

    while (1)
    {
        add_timer_irqh_sys (timer_irqh);
        printf ("srmon$ ");	//
        getstr (str);		// fgets(str, 199, stdin);

        tok = strtok (str, " \n");
        if (!strcmp ("d", tok))
        {
            tok = strtok (NULL, " \n");
            if (tok)
                pt = (unsigned char*)str2u32 (tok);
            pt = dump (pt);
        }
        else if (!strcmp ("f", tok)){	// cache flush
            i = d_cache_flush();
            printf("flush %d\n", i);
        }
        else if (!strcmp ("c", tok)){	// cache clean
            i = d_cache_clean();
            printf("clean %d\n", i);
        }
        else if (!strcmp ("b", tok)){	// cache base
            printf("out:  %8x\n", *BASEADR_OUT);
            printf("in:   %8x\n", *BASEADR_IN);
            printf("filt: %8x\n", *BASEADR_FILT);
            printf("bias: %8x\n", *BASEADR_BIAS);
        }
        else if (!strcmp ("m", tok)){	// monisel
            tok = strtok (NULL, " \n");
            if(tok) *TFACCMON = str2u32(tok);
            tok = strtok (NULL, " \n");
            if(tok) TFACCMON[1] = str2u32(tok);
            printf("moni : %d\n", *TFACCMON);
        }
        else if (!strcmp ("p", tok)){
            wpt--;
            printf("%8x : %08x\n", (u32)wpt, *wpt);
        }
        else if (!strcmp ("w", tok)){
            tok = strtok (NULL, " \n");
            if (tok){
                if(*tok == '@'){	// set address
                    wpt = (unsigned*)str2u32 (&tok[1]);
                    tok = strtok (NULL, " \n");
                    if(tok){
                        *wpt = str2u32(tok);
                    }
                }else{
                    *wpt = str2u32(tok);
                }
            }
            printf("%8x : %08x\n", (u32)wpt, *wpt);
            wpt++;
        }
        else if (!strcmp ("r", tok)){
            int trig = 1;
            tok = strtok (NULL, " \n");
            if (tok){
                trig = atoi(tok);
            }
            printf("tfacc run\n");
            tfacc_run(trig);
        }
        else if (!strcmp ("h", tok))
        {
            puts (
                    "    d  {addr}\n"
                    "    w  {@addr} {data}\n"
                    "    p   addr--\n"
                    "    b  print base addr\n"
                    "    f  cache flush\n"
                    "    c  cache clean\n"
                    "    r  tfacc run\n"
            );
        }
        remove_timer_irqh ();
        remove_user_irqh ();
    }
}


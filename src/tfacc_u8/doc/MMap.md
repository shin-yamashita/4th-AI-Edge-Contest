
# MMap tfacc_i8

## memory map sr_cpu 

```
0x0000 u32 reset vect
0x0004 u32 irq vect

0x0080 u32 xreset
0x0084 u32 eirq

0x00f0 u32 f_clock
0x0100 u32 accparams[64]

0x0200 srmon_main()

0x3fff stack end
        alias
0xffff
```

## tfacc register
```
0xffff0180 u32 TFACCCACHE W: [31:28] flush  [27:24] clean  R: [31]flash busy [30]flash comlete
0xffff0300 u32 TFACCFLG   W: [0] kick R: run [0]

0xffff0304 u32 BASEADR_OUT
0xffff0308 u32 BASEADR_IN
0xffff030c u32 BASEADR_FILT
0xffff0310 u32 BASEADR_BIAS

0xffff031c u32 TFACC_NP	  Np   u8_mac pallarel
0xffff0320 u32 TFACCMONI  monitor select

0xffff0400 u32 TFACCPARAM[64]

```


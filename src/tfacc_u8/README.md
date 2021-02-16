
# tfacc_u8 sources

2020/9/16 4th AI edge contest

tflite delegate FPGA accelerator

delegate Conv2d, dwConv2d Ops from tflite interpreter

execute uint8 quantized FlatBuffer

```
.
├── bd  PL block design user clock 150MHz
├── doc
├── firm          CPU firmware
│ ├── include
│ ├── lib
│ ├── srmon      monitor program
│ └── term       debug terminal
├── hdl           FPGA RTL sources
│ ├── acc        Accelerator source
│ │ ├── input_arb.sv
│ │ ├── input_cache.sv
│ │ ├── logic_types.svh
│ │ ├── output_arb.sv
│ │ ├── output_cache.sv
│ │ ├── rd_cache_nk.sv filter/bias buffer
│ │ ├── tfacc_core.sv  Accelerator block top
│ │ ├── u8adrgen.sv    Conv2d address gen
│ │ └── u8mac.sv       MAC
│ ├── sr_core          CPU RTL
│ ├── tfacc_cpu_v1_0.v CPU block
│ └── tfacc_memif.sv   Accelerator block
├── ip                  FPGA ip
├── ReadMe.md
├── sim                Vivado simulation env
│ ├── compile_tfacc_core.sh
│ ├── run_tfacc_core.sh
│ ├── tb_tfacc_core.prj
│ ├── tb_tfacc_core.sv
│ ├── axi_slave_bfm.sv
│ ├── c_main.c           dpi-c source
│ ├── tvec               test vector
│ │ ├── tdump-0-u8.in
│ │ ├──  :
│ │ ├── tdump-65-u8.in
│ └── xsim_tfacc_core.sh
└── syn                Vivado synthesis env
    ├── build.sh       build FPGA script
    ├── build.tcl
    ├── design_1_bd.tcl
    ├── dont_touch.xdc
    ├── read_hdl.tcl
    ├── read_ip.tcl
    ├── tfacc_pin.xdc
    ├── timingan.sh
    ├── timing.xdc
    ├── vivado_gui.sh
    └── vivado_tcl.sh
```


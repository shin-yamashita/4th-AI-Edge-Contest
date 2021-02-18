
# FPGA sources

FPGA に実装した accelerator の RTL ソースである。  

Vivado/2019.2 Webpack で論理シミュレーション、論理合成を行った。 

## simulation 実行
$ cd sim  
$ sh compile_tfacc_core.sh  
$ sh run_tfacc_core.sh 0 5   # 0 番目から 5 番目までの test vector を shimulation 実行   
結果は xsim-r.log に

## synthesis 実行
$ cd syn  
$ sh build.sh  
生成物は、./rev/design_1_wrapper.bit  
design_1.bit に rename して用いる  

## files
```
tfacc_u8
├── bd                   PL block design (user clock = 150MHz)
├── firm                 Firmware for controller
│ └── srmon               monitor program
├── hdl                  FPGA RTL sources
│ ├── acc                 Accelerator sources (SystemVerilog)
│ │ ├── input_arb.sv     input access arbiter
│ │ ├── input_cache.sv
│ │ ├── output_arb.sv    output access arbiter
│ │ ├── output_cache.sv
│ │ ├── rd_cache_nk.sv   filter/bias buffer
│ │ ├── tfacc_core.sv    Accelerator block top
│ │ ├── u8adrgen.sv      Conv2d/dwConv2d address generator
│ │ └── u8mac.sv         uint8 MAC
│ ├── sr_core             Controller sources (VHDL)
│ ├── tfacc_cpu_v1_0.v    Controller top design
│ └── tfacc_memif.sv      Data pass top design
├── ip                   FPGA ip (axi/bram)
├── README.md
├── sim                  Vivado simulation environment
│ ├── compile_tfacc_core.sh Elaborate testbench  
│ ├── run_tfacc_core.sh  Execute logic simulation
│ ├── xsim_tfacc_core.sh Execute logic simulation (GUI)
│ ├── tb_tfacc_core.prj
│ ├── tb_tfacc_core.sv   Testbench
│ ├── axi_slave_bfm.sv   AXI bus functiol model with dpi-c interface
│ ├── c_main.c           dpi-c source
│ └── tvec               test vectors
│ 　 ├── tdump-0-u8.in
│ 　 ├──  :
│ 　 └── tdump-65-u8.in
└── syn                  Vivado synthesis environment
    ├── build.sh         build FPGA script
    ├── build.tcl  
    ├── design_1_bd.tcl
    ├── dont_touch.xdc
    ├── read_hdl.tcl
    ├── read_ip.tcl
    ├── tfacc_pin.xdc
    └── timing.xdc
```


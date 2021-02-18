
# 4th AI Edge Contest

## TFlite delegate による実装

このリポジトリでは、[4th AI Edge Contest](https://signate.jp/competitions/285) に向けて実装したシステムのソースコードを公開する。  
- TFlite の delegate 機構を用いて FPGA にアクセラレータを実装した。
- アクセラレータは主に SystemVerilog で記述した。
- 推論アプリは PYNQ Linux (Ubuntu18.04) 上で実行する python で実装した。
- この推論アプリとFPGAをつなぐ delegate-interface は、ハードウェア実装のためのリファレンスモデルと、FPGA 上での delegate 実行制御を兼ねる。

### files
```
├── app/ 
│ ├── infer_seg.py          Inference application
│ └── tflite_delegate/      Delegate interface sources (C++)
├── doc/                     Presentation materials
└── src/                     FPGA design sources
    └── tfacc_u8/
        ├── bd/              ZYNQ block design
        ├── firm/            Firmware for controller
        ├── hdl/             hdl sources
        │ ├─ acc/            Accelerator sources (SystemVerilog)
        │ ├─ sr_core/        Controller sources (VHDL)
        │ ├─ tfacc_cpu_v1_0.v Controller top design
        │ └─ tfacc_memif.sv   Data pass top design
        ├── sim/             Logic simulation environment
        └── syn/             Logic synthesis environment 

```


# 4th AI Edge Contest

## TFlite delegate による実装

このリポジトリでは、[4th AI Edge Contest](https://signate.jp/competitions/285) に向けて実装したシステムのソースコードを公開する。  
- TFlite の delegate 機構を用いて FPGA にアクセラレータを実装した。
- アクセラレータは主に SystemVerilog で記述した。
- 推論アプリは PYNQ Linux (Ubuntu18.04) 上で実行する python で実装した。
- この推論アプリとFPGAをつなぐ delegate-interface は、ハードウェア実装のためのリファレンスモデルと、FPGA 上での delegate 実行制御を兼ねる。

詳細は [doc/レポート](doc/s_yamashita_report.pdf) 参照

### ./app/ [推論実行アプリケーション](app/)  

- python で記述した推論アプリケーション。  
- [deeplabv3+ mobilenetv3](http://download.tensorflow.org/models/deeplab_mnv3_small_cityscapes_trainfine_2019_11_15.tar.gz) をベースに今回の課題に合わせて転移学習し、[quantization aware training](https://www.tensorflow.org/model_optimization/guide/quantization/training?hl=ja) の後 uint8 量子化した tflite graph を含む。  

### ./app/tflite_delegate/  [TFlite delegate interface](app/tflite_delegate/)  
- 推論アプリから delegate API を介して C++ reference model または FPGA アクセラレータに実行委譲するインターフェース関数のソース。  
- Conv2d, depthwiseConv2d の２種の演算を delegate する。
- C++ reference model は tflite の [Tensor ごとの uint8 量子化と チャネルごとの int8 量子化](https://www.tensorflow.org/lite/performance/quantization_spec) で実装した。
- FPGA アクセラレータは Tensor ごとの uint8 量子化のみに対応する。  


### ./src/tfacc_u8/  [FPGA sources](src/tfacc_u8/)  
- アクセラレータの RTL ソース。
- 論理シミュレーション環境、論理合成環境。


## files
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
## References
- [第4回AIエッジコンテスト（実装コンテスト②)](https://signate.jp/competitions/285)
- [Avnet / Ultra96-PYNQ](https://github.com/Avnet/Ultra96-PYNQ/releases)
- [tensorflow r2.1 sources](https://github.com/tensorflow/tensorflow/tree/r2.1) 
- [TensorFlow Lite デリゲート](https://www.tensorflow.org/lite/performance/delegates)
- [TensorFlow Lite カスタムデリゲートの実装](https://www.tensorflow.org/lite/performance/implementing_delegate#when_should_i_create_a_custom_delegate)
- [TensorFlow Lite 8ビット量子化仕様](https://www.tensorflow.org/lite/performance/quantization_spec) 

## License
- [Apache License 2.0](LICENSE)

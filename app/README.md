
# 推論実行アプリケーション

## 実行環境

同一のソースで以下の２つの環境で動作を確認した。  

1. ultra96v2 [PYNQ Linux(Ubuntu18.04)](https://github.com/Avnet/Ultra96-PYNQ/releases)   
   FPGA にアクセラレーション実行する。  
   FPGA に delegate できる tflite graph は uint8 量子化されたもののみである。(int8 量子化には対応しない)  

2. LinuxPC (Ubuntu18.06)  
   C++ reference model に delegate 実行する。  

#### ultra96 PYNQ の設定

- PYNQ Linux の cma 領域設定確認: boot message  
  [    0.000000] cma: Reserved 128 MiB at 0x0000000077c00000  
- /boot/uEnv.txt に cpuidle.off=1 を追加：
  [JTAG 接続時 hungup の問題](https://japan.xilinx.com/support/answers/69143.html)

## files

- tflite_delegate/ 以下は TFlite の delegate API で FPGA と接続するためのインターフェース関数のソースである。  
同時にハード実装のための C++ リファレンス実装でもある。  
- 推論アプリ infer_seg.py は tflite_runtime python ライブラリを用いたアプリである。  
  tflite_runtime の build は、[tflite_delegate/README.md](tflite_delegate/README.md) を参照。  
- tflite_graphs/ に今回の課題で作成した学習済み tflite graph を置いた。  

```
app
├── infer_seg.py        Inference application
├── tfacc_load.py       FPGA initialize appli、load fpga-data and controller firm
├── benchmark.sh        tflite benchmark execution script
├── fpga-data
│ ├── design_1.bit
│ ├── design_1.hwh
│ └── srmon.mot         firmware for controller
├── images              input image dir
├── README.md
├── tflite_delegate/    delegate interface function
└── tflite_graphs
    ├── seg_graph_f.tflite  TFlite graph float (cpu only)
    ├── seg_graph_q.tflite  TFlite graph uint8 (cpu or FPGA/C++ delegate)
    └── seg_graph_i8.tflite TFlite graph int8  (cpu or C++ delegate)
```


## 推論実行手順

#### 準備 : PYNQ Linux (Ubuntu 18.04) 及び LinuxPC (Ubuntu 18.04)  
  - python3-opencv Pillow のインストールが必要  
  - [./tflite_delegate/README.md](./tflite_delegate/README.md) に従って tflite-runtime の build/install
    及び ./tflite_delegate/libmydelegate.so.1 を build しておく。  

#### ultra96v2 での実行

PYNQ Linux (Ubuntu 18.04) に login  

1. **FPGA 初期化**  
   $ sudo ./tfacc_load.py  # FPGA に fpga-data/design_1.bit をロードし、 fpga 内 cpu にプログラムロードする  
   ** Load "design_1.bit" to Overlay  
   PL clock : 150 (MHz)  
   base:a0000000 range:10000  
   *** Load "srmon.mot" to sr_cpu memory  
 
2. **推論実行**  
   **a) 結果を画像で表示**  
   ssh -X xilinx@192.168.3.1  # usb 経由で X forwarding  
   $ sudo -E ./infer_seg.py   # FPGA のレジスタ及び cma 領域のアクセスのため、root 権限が必要。  
     ./images/*.jpg を読んで推論実行し、結果を cv2.imshow() で表示。  
      ESC キーで終了、任意のキーで次の画像  
   **b) 推論時間計測**  
   $ sudo ./infer_seg.py --test  
   tflite model:  ./signate_mvn3/tflite_graphs/seg_graph_q.tflite  
   PL_if_config(): m_reg:0x7f765cd000 accparam:0x7f765cd100  
   PL_if_config(): tfacc_buf:0x7f7038b000  
   infer: .//signate/seg_infer/train_1125.png  
    pre: 19.87  infer: 423.97  post: 17.10 total: 460.94ms / 1  
   infer: .//signate/seg_infer/train_1126.png  
    pre: 18.74  infer: 416.79  post: 12.36 total: 447.88ms / 2  
   infer: .//signate/seg_infer/train_1186.png　　　　　　　　　 # 推論結果 .png 出力  
    pre: 18.34  infer: 414.35  post: 10.43 total: 443.13ms / 3　# 表示時間は積算され、平均した値  

     - pre:   imread() 後、resize などの前処理  
     - infer: interpreter に画像をセットし、推論実行、結果を取り出し  
     - post:  推論結果を resize などし、.png 画像に変換  

     ./images/*.jpg を読んで推論実行し、結果を ./seg_infer/*.png に出力、推論時間を表示。  
     ESC キーで終了  
     
3. **ultra96 cpu で推論実行**  
   $ ./infer_seg.py -c  
   
#### LinuxPC での実行

1. **Reference model に delegate 実行**  
   $ ./infer_seg.py  
   ./images/*.jpg を読んで推論実行し、結果を cv2.imshow() で表示。  
   ESC キーで終了、任意のキーで次の画像  
   default では uint8 量子化モデルを C++ reference model に delegate  
   -I オプションで int8 量子化モデルを C++ reference model に delegate  

2. **cpu で推論実行**  
   $ ./infer_seg.py -c  
   -q/-I/-f オプションでモデル (uint8/int8/float) を切り替える。  
   

**infer_seq.py の他のオプション**
```
  $ ./infer_seg.py --help
  usage: infer_seg.py [-h] [-i INPUT] [-o OUTPUT] [-a ANNOTATION] [-c] [-q] [-I] [-f] [--eval] [--test]

  infer segmentation

  optional arguments:
   -h, --help            show this help message and exit
   -i INPUT, --input INPUT
                         Input file dir
   -o OUTPUT, --output OUTPUT
                         Output file dir
   -a ANNOTATION, --annotation ANNOTATION
                         annotation file dir
   -c, --cpu             disable delegate
   -q, --quantize        uint8 model           # model = tflite_graphs/seg_graph_q.tflite
   -I, --I8              int8 model            # model = tflite_graphs/seg_graph_i8.tflite
   -f, --float           float model (cpu exec)# model = tflite_graphs/seg_graph_f.tflite
   --eval                eval iou 
   --test                measure infer time
```


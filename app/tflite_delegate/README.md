
# TFlite delegate C++ sources


Linux PC (Ubuntu18.04) と、 ultra96v2 (PYNQ Ubuntu18.04) の共通ソース。  

- Linux で Reference model を作り、 delegate の動作確認、 test vector 生成。  
- ultra96v2 で FPGA に delegate する。  

## build

1. **環境設定**

   python3 version 3.6 で検証

   **tensorflow r2.1 ソースをダウンロード、 ../tensorflow に配置する。**  
   $ git clone -b r2.1 https://github.com/tensorflow/tensorflow.git  ../tensorflow
   
   **build libtensorflow-lite.a** (C/C++ で推論するときに用いる library)    
   $ bash ../tensorflow/tensorflow/lite/tools/make/download_dependencies.sh  
   $ bash ../tensorflow/tensorflow/lite/tools/make/build_lib.sh
   生成物: ../tensorflow/tensorflow/lite/tools/make/gen/linux_`uname -m`/lib/libtensorflow-lite.a  

   **build and install tflite_runtime for python3**  
   $ bash ../tensorflow/tensorflow/lite/tools/pip_package/build_pip_package.sh   # build tflite_runtime wheel  
   $ pip3 install /tmp/tflite_pip/python3/dist/tflite_runtime-2.1.0-cp36-cp36m-linux_x86_64.whl  

2. **build delegate interface library**

   **for Linux :**  
   $ make  
   $ make DFLAGS=-DDEBUG  # with more debug print  

   **for ultra96v2-pynq:**  
   $ make DFLAGS=-DULTRA96  # for FPGA delegate  

   生成物: **libmydelegate.so.1**   tflite python API から呼び出す。 tflite_runtime.Interpreter に link する。

## delegate interface source

Linux 用（Reference model） と、 ultra96v2-pynq 用(FPGA とのインターフェース) でソースは共通。 DFLAGS=-DULTRA96 で切り替える。

```
tflite_delegate  
├── libxlnk_cma.h  
├── Makefile  
├── MyDelegate.cc   delegate interface source (include Reference model)   
├── README.md  
├── tfacc_u8.cc     FPGA interface  
└── tfacc_u8.h  
```


## python API

```python
import tflite_runtime.interpreter as tflite

model = './tflite_graphs/seg_graph_q.tflite' # flatbuffer model
slib = './tflite_delegate/libmydelegate.so.1'

interpreter = tflite.Interpreter(model_path=model, experimental_delegates=[tflite.load_delegate(slib)] )
interpreter.allocate_tensors()

# Get input and output tensors.
input_details  = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# pre proc resize, expand dim, rgb
image = ...  # RGB image [1,H,W,C]  [1,513,1025,3]

# inference
interpreter.set_tensor(input_details[0]['index'], np.uint8(image))
interpreter.invoke()
segments = interpreter.get_tensor(output_details[0]['index'])[0]

# post proc label to color, resize

```



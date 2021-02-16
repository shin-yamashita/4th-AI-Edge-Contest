
#
# run tflite benchmark tool
#

GRAPH=tflite_graphs/seg_graph_q.tflite
INPUT=MobilenetV3/MobilenetV3/input
INPUTSHAPE=1,513,1025,3

tensorflow/tensorflow/lite/tools/make/gen/linux_`uname -m`/bin/benchmark_model \
  --graph=$GRAPH \
  --benchmark_name=mvn3\
  --output_prefix=mvn3\
  --input_layer=$INPUT \
  --input_layer_shape=$INPUTSHAPE \
  --enable_op_profiling=true\


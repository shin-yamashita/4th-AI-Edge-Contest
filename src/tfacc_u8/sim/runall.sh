#!/bin/bash

source /opt/Xilinx/Vivado/2019.2/settings64.sh

for ((i=0; i < 65; i++)); do
  echo "stage ", $i
  ./run.sh ${i}
done


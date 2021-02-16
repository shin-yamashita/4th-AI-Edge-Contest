#!/bin/bash

source /opt/Xilinx/Vivado/2019.2/settings64.sh

stage=0
endst=0
if [ $# -ge 1 ]; then
  stage=$1
  endst=$2
fi
echo $stage $endst > stage.in

xelab tb_tfacc_core -timescale 1ns/1ns -prj tb_tfacc_core.prj -L unisims_ver -s tb_tfacc_core_r -sv_lib dpi
xsim tb_tfacc_core_r -R --log xsim-r.log


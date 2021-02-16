#!/bin/bash

source /opt/Xilinx/Vivado/2019.2/settings64.sh

stage=0
if [ $# -ge 1 ]; then
  stage=$1
fi

xelab work.tb_u8adrgen work.glbl -generic_top "stage=${stage}" -timescale 1ns/1ns -prj tb_u8adrgen.prj -L unisims_ver -L secureip -s tb_u8adrgen -sv_lib dpi -R


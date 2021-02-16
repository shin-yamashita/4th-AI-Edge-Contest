#!/bin/bash

source /opt/Xilinx/Vivado/2019.2/settings64.sh

stage=0

if [ $# -ge 1 ]; then
  stage=$1
fi

xelab -timescale 1ns/1ns tb_u8adrgen -dpiheader dpi.h
##xsc --gcc_compile_options -DSTAGE=${stage} c_main.c
xsc c_main.c

xelab work.tb_u8adrgen -generic_top "stage=${stage}" work.glbl -timescale 1ns/1ns -prj tb_u8adrgen.prj -L unisims_ver -L secureip -s tb_u8adrgen -sv_lib dpi -debug typical


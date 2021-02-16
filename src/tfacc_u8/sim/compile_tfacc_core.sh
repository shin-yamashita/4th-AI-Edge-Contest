#!/bin/bash

source /opt/Xilinx/Vivado/2019.2/settings64.sh

#stage=0

#if [ $# -ge 1 ]; then
#  stage=$1
#fi

xelab -timescale 1ns/1ns tb_tfacc_core -L unisims_ver -dpiheader dpi.h
xsc c_main.c

#xelab work.tb_tfacc_core -generic_top "stage=${stage}" work.glbl -timescale 1ns/1ns -prj tb_tfacc_core.prj -L unisims_ver -L secureip -s tb_tfacc_core -sv_lib dpi -debug typical
xelab tb_tfacc_core  -timescale 1ns/1ns -prj tb_tfacc_core.prj -L unisims_ver -sv_lib dpi -s tb_tfacc_core -debug typical



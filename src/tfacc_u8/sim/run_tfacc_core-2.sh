#!/bin/bash

source /opt/Xilinx/Vivado/2019.2/settings64.sh


xelab tb_tfacc_core -timescale 1ns/1ns -prj tb_tfacc_core.prj -L unisims_ver -s tb_tfacc_core_2 -sv_lib dpi

echo 0 8 > stage.in
xsim  tb_tfacc_core_2 -R --log xsim-1.log > /dev/null &
sleep 15

echo 9 18 > stage.in
xsim  tb_tfacc_core_2 -R --log xsim-2.log > /dev/null &
sleep 15

echo 19 28 > stage.in
xsim  tb_tfacc_core_2 -R --log xsim-3.log > /dev/null &
sleep 15

echo 29 38 > stage.in
xsim  tb_tfacc_core_2 -R --log xsim-4.log > /dev/null &
sleep 15

echo 39 47 > stage.in
xsim  tb_tfacc_core_2 -R --log xsim-5.log > /dev/null &
sleep 15

echo 48 56 > stage.in
xsim  tb_tfacc_core_2 -R --log xsim-6.log > /dev/null &
sleep 15

echo 57 65 > stage.in
xsim  tb_tfacc_core_2 -R --log xsim-7.log > /dev/null &



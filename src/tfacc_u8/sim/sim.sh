#!/bin/bash

function chkerr
{
 if [ $? != 0 ] ; then
  echo "***** error exit ******"
  exit
 fi
}

#prj=fpmac
#prj=adrgen
#prj=tfacc_core
#prj=tfacc
prj=u8mac

if [ $# = 1 ] ; then
 prj=$1
fi

source /opt/Xilinx/Vivado/2019.2/settings64.sh

echo Simulation Tool: Viavdo Simulator $prj

xsim -g -wdb tb_$prj.wdb tb_$prj

chkerr

echo done


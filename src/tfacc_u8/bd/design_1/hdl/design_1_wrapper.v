//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
//Date        : Sun Oct 25 16:54:14 2020
//Host        : E6520 running 64-bit Ubuntu 18.04.5 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (RXD_0,
    TXD_0,
    fp_0,
    pout_0);
  output RXD_0;
  input TXD_0;
  output [4:0]fp_0;
  output [7:0]pout_0;

  wire RXD_0;
  wire TXD_0;
  wire [4:0]fp_0;
  wire [7:0]pout_0;

  design_1 design_1_i
       (.RXD_0(RXD_0),
        .TXD_0(TXD_0),
        .fp_0(fp_0),
        .pout_0(pout_0));
endmodule

// (c) Copyright 1995-2020 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:module_ref:tfacc_memif:1.0
// IP Revision: 1

(* X_CORE_INFO = "tfacc_memif,Vivado 2019.2" *)
(* CHECK_LICENSE_TYPE = "design_1_tfacc_memif_0_0,tfacc_memif,{}" *)
(* CORE_GENERATION_INFO = "design_1_tfacc_memif_0_0,tfacc_memif,{x_ipProduct=Vivado 2019.2,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=tfacc_memif,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module design_1_tfacc_memif_0_0 (
  cclk,
  xreset,
  adr,
  we,
  re,
  rdy,
  dw,
  dr,
  M00_AXI_ACLK,
  M00_AXI_ARESETN,
  M00_AXI_AWID,
  M00_AXI_AWADDR,
  M00_AXI_AWLEN,
  M00_AXI_AWSIZE,
  M00_AXI_AWBURST,
  M00_AXI_AWLOCK,
  M00_AXI_AWCACHE,
  M00_AXI_AWPROT,
  M00_AXI_AWQOS,
  M00_AXI_AWVALID,
  M00_AXI_AWREADY,
  M00_AXI_WDATA,
  M00_AXI_WSTRB,
  M00_AXI_WLAST,
  M00_AXI_WVALID,
  M00_AXI_WREADY,
  M00_AXI_BID,
  M00_AXI_BRESP,
  M00_AXI_BVALID,
  M00_AXI_BREADY,
  M00_AXI_ARID,
  M00_AXI_ARADDR,
  M00_AXI_ARLEN,
  M00_AXI_ARSIZE,
  M00_AXI_ARBURST,
  M00_AXI_ARLOCK,
  M00_AXI_ARCACHE,
  M00_AXI_ARPROT,
  M00_AXI_ARQOS,
  M00_AXI_ARVALID,
  M00_AXI_ARREADY,
  M00_AXI_RID,
  M00_AXI_RDATA,
  M00_AXI_RRESP,
  M00_AXI_RLAST,
  M00_AXI_RVALID,
  M00_AXI_RREADY,
  fp
);

input wire cclk;
input wire xreset;
input wire [31 : 0] adr;
input wire [3 : 0] we;
input wire re;
output wire rdy;
input wire [31 : 0] dw;
output wire [31 : 0] dr;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M00_AXI_ACLK, ASSOCIATED_BUSIF M00_AXI, ASSOCIATED_RESET M00_AXI_ARESETN, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN design_1_zynq_ultra_ps_e_0_0_pl_clk0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M00_AXI_ACLK CLK" *)
input wire M00_AXI_ACLK;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M00_AXI_ARESETN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M00_AXI_ARESETN RST" *)
input wire M00_AXI_ARESETN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWID" *)
output wire [3 : 0] M00_AXI_AWID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWADDR" *)
output wire [39 : 0] M00_AXI_AWADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWLEN" *)
output wire [7 : 0] M00_AXI_AWLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWSIZE" *)
output wire [2 : 0] M00_AXI_AWSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWBURST" *)
output wire [1 : 0] M00_AXI_AWBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWLOCK" *)
output wire M00_AXI_AWLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWCACHE" *)
output wire [3 : 0] M00_AXI_AWCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWPROT" *)
output wire [2 : 0] M00_AXI_AWPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWQOS" *)
output wire [3 : 0] M00_AXI_AWQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWVALID" *)
output wire M00_AXI_AWVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI AWREADY" *)
input wire M00_AXI_AWREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI WDATA" *)
output wire [127 : 0] M00_AXI_WDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI WSTRB" *)
output wire [15 : 0] M00_AXI_WSTRB;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI WLAST" *)
output wire M00_AXI_WLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI WVALID" *)
output wire M00_AXI_WVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI WREADY" *)
input wire M00_AXI_WREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI BID" *)
input wire [3 : 0] M00_AXI_BID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI BRESP" *)
input wire [1 : 0] M00_AXI_BRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI BVALID" *)
input wire M00_AXI_BVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI BREADY" *)
output wire M00_AXI_BREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARID" *)
output wire [3 : 0] M00_AXI_ARID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARADDR" *)
output wire [39 : 0] M00_AXI_ARADDR;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARLEN" *)
output wire [7 : 0] M00_AXI_ARLEN;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARSIZE" *)
output wire [2 : 0] M00_AXI_ARSIZE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARBURST" *)
output wire [1 : 0] M00_AXI_ARBURST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARLOCK" *)
output wire M00_AXI_ARLOCK;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARCACHE" *)
output wire [3 : 0] M00_AXI_ARCACHE;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARPROT" *)
output wire [2 : 0] M00_AXI_ARPROT;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARQOS" *)
output wire [3 : 0] M00_AXI_ARQOS;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARVALID" *)
output wire M00_AXI_ARVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI ARREADY" *)
input wire M00_AXI_ARREADY;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI RID" *)
input wire [3 : 0] M00_AXI_RID;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI RDATA" *)
input wire [127 : 0] M00_AXI_RDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI RRESP" *)
input wire [1 : 0] M00_AXI_RRESP;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI RLAST" *)
input wire M00_AXI_RLAST;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI RVALID" *)
input wire M00_AXI_RVALID;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M00_AXI, DATA_WIDTH 128, PROTOCOL AXI4, FREQ_HZ 100000000, ID_WIDTH 4, ADDR_WIDTH 40, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 1, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 1, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.000, CLK_DOMAIN design_1_zynq_ultra_ps_e_0_0_pl_clk0, NUM_READ_THREADS 1,\
 NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M00_AXI RREADY" *)
output wire M00_AXI_RREADY;
output wire [4 : 0] fp;

  tfacc_memif inst (
    .cclk(cclk),
    .xreset(xreset),
    .adr(adr),
    .we(we),
    .re(re),
    .rdy(rdy),
    .dw(dw),
    .dr(dr),
    .M00_AXI_ACLK(M00_AXI_ACLK),
    .M00_AXI_ARESETN(M00_AXI_ARESETN),
    .M00_AXI_AWID(M00_AXI_AWID),
    .M00_AXI_AWADDR(M00_AXI_AWADDR),
    .M00_AXI_AWLEN(M00_AXI_AWLEN),
    .M00_AXI_AWSIZE(M00_AXI_AWSIZE),
    .M00_AXI_AWBURST(M00_AXI_AWBURST),
    .M00_AXI_AWLOCK(M00_AXI_AWLOCK),
    .M00_AXI_AWCACHE(M00_AXI_AWCACHE),
    .M00_AXI_AWPROT(M00_AXI_AWPROT),
    .M00_AXI_AWQOS(M00_AXI_AWQOS),
    .M00_AXI_AWVALID(M00_AXI_AWVALID),
    .M00_AXI_AWREADY(M00_AXI_AWREADY),
    .M00_AXI_WDATA(M00_AXI_WDATA),
    .M00_AXI_WSTRB(M00_AXI_WSTRB),
    .M00_AXI_WLAST(M00_AXI_WLAST),
    .M00_AXI_WVALID(M00_AXI_WVALID),
    .M00_AXI_WREADY(M00_AXI_WREADY),
    .M00_AXI_BID(M00_AXI_BID),
    .M00_AXI_BRESP(M00_AXI_BRESP),
    .M00_AXI_BVALID(M00_AXI_BVALID),
    .M00_AXI_BREADY(M00_AXI_BREADY),
    .M00_AXI_ARID(M00_AXI_ARID),
    .M00_AXI_ARADDR(M00_AXI_ARADDR),
    .M00_AXI_ARLEN(M00_AXI_ARLEN),
    .M00_AXI_ARSIZE(M00_AXI_ARSIZE),
    .M00_AXI_ARBURST(M00_AXI_ARBURST),
    .M00_AXI_ARLOCK(M00_AXI_ARLOCK),
    .M00_AXI_ARCACHE(M00_AXI_ARCACHE),
    .M00_AXI_ARPROT(M00_AXI_ARPROT),
    .M00_AXI_ARQOS(M00_AXI_ARQOS),
    .M00_AXI_ARVALID(M00_AXI_ARVALID),
    .M00_AXI_ARREADY(M00_AXI_ARREADY),
    .M00_AXI_RID(M00_AXI_RID),
    .M00_AXI_RDATA(M00_AXI_RDATA),
    .M00_AXI_RRESP(M00_AXI_RRESP),
    .M00_AXI_RLAST(M00_AXI_RLAST),
    .M00_AXI_RVALID(M00_AXI_RVALID),
    .M00_AXI_RREADY(M00_AXI_RREADY),
    .fp(fp)
  );
endmodule

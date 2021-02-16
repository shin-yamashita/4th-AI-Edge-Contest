
`timescale 1ns/1ns


module tb_u8adrgen();

parameter stage = 0;
parameter Np = 32;

//----------------------------------------------------------
  import "DPI-C"  context task c_main();
  import "DPI-C"  pure function int mem_rd(int s, int adr);
  import "DPI-C"  pure function int mem_wr(int adr, int data);
  import "DPI-C"  context task compare_mem();
  export "DPI-C"  task reg_wr;
  export "DPI-C"  task reg_rd;
  export "DPI-C"  task nop;

  logic        clk = 1;

  logic [31:0] addr, wdata, rdata;
  logic we = 0, re = 0;

  task reg_wr(input int adr, input int data);
    @(posedge clk);
    #1
    we = 1;
    re = 0;
    addr = adr;
    wdata = data;
  endtask
  task nop();
    @(posedge clk);
    #1
    we = 0;
    re = 0;
  endtask
  task reg_rd(input int adr, output int data);
    @(posedge clk);
    #1
    we = 0;
    re = 1;
    addr = adr;
    @(posedge clk);
    #1
    re = 0;
    data = rdata;
//    $display("r a: %d d:%d", addr, data);
  endtask

//----------------------------------------------------------

logic xrst;
logic        kick = 0;     // start 1 frame sequence

// Convolution parameter
logic        pwe;      // param register write
logic        pre;      //                read
logic [7:0]  padr;     // param addr 0 to 19 (u32)
logic [31:0] pdata;    // param write data (u32)
logic [31:0] prdata;   //       read data

// address
logic [28:0] in_adr[Np]; // input addr (byte)
logic        valid[Np];  // in_adr valid
logic        in_rdy = 1;
logic [28:0] fil_adr;  // filter addr (byte)
logic        fil_rdy = 1;
logic [28:0] out_adr[Np];// output addr (byte)
logic        out_rdy = 1;
logic [28:0] bias_adr; // bias addr (byte)
logic        bias_rdy = 1;
logic        oen[Np];  // output enable
logic        chen[Np]; // para channel enable

// running flag
logic        run;      // 1 : running 

// u8mac control
logic        aen;      // acc en
logic        acl;      // acc clear
logic        acvalid;  // acc data valid

// quantize parameters
logic unsigned [7:0]  actmin  ; // act min
logic unsigned [7:0]  actmax  ; // act max
logic signed   [8:0]  in_offs ; // quantize params
logic signed   [8:0]  fil_offs;
logic signed   [8:0]  out_offs;
logic signed   [17:0] out_mult;
logic unsigned [7:0]  out_shift;

int nprd = 0;

/*
sr_cpu_bfm u_sr_cpu_bfm(
  .clk   (clk),	//  input  logic clk;
  .xreset(xrst),	//input  logic xreset;
  .adr   (addr),	//output logic [31:0] adr;
  .we    (we),	//output logic we;
  .re    (re),	//output logic re;
  .rdy   (1'b1),	//input  logic rdy;
  .dw    (wdata),	//output logic [31:0] dw;
  .dr    (rdata)		//input  logic [31:0] dr
  );
*/

// cpu bus
always@(posedge clk) begin
  if(we) begin
    if(addr == 32'hffff0300) kick <= wdata[0];
    if((addr & 32'hffffff00) == 32'hffff0400) begin
    end
  end
  if(re && (addr == 32'hffff0304)) nprd <= Np;
  else nprd <= 0;
end

logic cs_adrgen;

assign cs_adrgen = ((addr & 32'hfffffc00) == 32'hffff0400);
assign pwe   = we & cs_adrgen;
assign pre   = re & cs_adrgen;
assign padr  = addr >> 2;
assign pdata = wdata;
assign rdata = prdata | nprd;


u8adrgen #(.Np(Np)) u_u8adrgen
  (
  .clk	(clk),	//  input  logic        clk,
  .xrst	(xrst),	//  input  logic        xrst,
//
  .kick	(kick),	//  input  logic        kick,     // start 1 frame sequence

// Convolution parameter
  .pwe	(pwe),	//  input  logic        pwe,      // param register write
  .pre	(pre),	//  input  logic        pre,      //                read
  .padr	(padr),	//  input  logic [7:0]  padr,     // param addr 0 to 19
  .pdata	(pdata),	//  input  logic [31:0] pdata,    // param write data
  .prdata	(prdata),	//  output logic [31:0] prdata,   //       read data
// address
  .in_adr	(in_adr),	//  output logic [28:0] in_adr[Np], // input addr (byte)
  .valid	(valid),	//  output logic        valid[Np],  // in_adr valid
  .in_rdy	(in_rdy),	//  input  logic        in_rdy,
  .fil_adr	(fil_adr),	//  output logic [28:0] fil_adr,  // filter addr (byte)
  .fil_rdy	(fil_rdy),	//  input  logic        fil_rdy,
  .out_adr	(out_adr),	//  output logic [28:0] out_adr[Np],// output addr (byte)
  .out_rdy	(out_rdy),	//  input  logic        out_rdy,
  .bias_adr	(bias_adr),	//  output logic [28:0] bias_adr, // bias addr (byte)
  .bias_rdy	(bias_rdy),	//  input  logic        bias_rdy,
  .oen	(oen),	//  output logic        oen[Np],  // output enable
  .chen	(chen),	//  output logic        chen[Np], // para channel enable

// running flag
  .run	(run),	//  output logic        run,      // 1 : running 

// u8mac control
  .aen	(aen),	//  output logic        aen,      // acc en
  .acl	(acl),	//  output logic        acl,      // acc clear
  .acvalid	(acvalid),	//  input  logic        acvalid,  // acc data valid

// quantize parameters
  .actmin	(actmin),	//  output logic unsigned [7:0]  actmin  , // act min
  .actmax	(actmax),	//  output logic unsigned [7:0]  actmax  , // act max
  .in_offs	(in_offs),	//  output logic signed   [8:0]  in_offs , // quantize params
  .fil_offs	(fil_offs),	//  output logic signed   [8:0]  fil_offs,
  .out_offs	(out_offs),	//  output logic signed   [8:0]  out_offs,
  .out_mult	(out_mult),	//  output logic signed   [17:0] out_mult,
  .out_shift	(out_shift)	//  output logic unsigned [7:0]  out_shift
 );

logic match[Np];
logic rdy, aen_1d, acl_1d;
logic unsigned [7:0] in_d[Np], accd[Np];
logic unsigned [7:0] fil_d;
logic signed   [31:0] bias;
logic ivalid[Np];

assign rdy = in_rdy & fil_rdy;

//---- memory

always@(posedge clk) begin
  aen_1d <= aen;
  acl_1d <= acl;
  for(int i = 0; i < Np; i++) begin
    if(aen) begin
      if(valid[i]) in_d[i]  <= mem_rd(0, in_adr[i]);
      else in_d[i] <= 'x;
      ivalid[i] <= valid[i];	// memory read delay

      fil_d <= mem_rd(1, fil_adr);
      bias  <= mem_rd(2, bias_adr);
    end
    if(acvalid & !acl_1d) begin
      if(oen[i])
        match[i] <= mem_wr(out_adr[i], accd[i]);
      else
        match[i] <= 0;
    end
  end
end

logic acv[Np];
assign acvalid = acv[0];

generate
 for(genvar i = 0; i < Np; i++) begin
 u8mac u_u8mac (
  .clk       (clk),		//in                  clk     , //
  .xreset    (xrst),		//in                  xreset  , //
  .aen       (aen_1d),		//in                  aen     , // acc enable
  .acl       (acl_1d),		//in                  acl     , // acc clear
  .rdy       (rdy),		//in                  rdy     , // memory read data ready
  .ivalid    (ivalid[i]),		//in                  ivalid  , // input data valid
  .in_d      (in_d[i]),		//in  unsigned [7:0]  in_d    , // u8 input
  .fil_d     (fil_d),		//in  unsigned [7:0]  fil_d   , // u8 filter
  .bias      (bias),		//in  signed   [31:0] bias    , // s32 bias
  .actmin    (actmin),		//in  unsigned [7:0]  actmin  , // act min
  .actmax    (actmax),		//in  unsigned [7:0]  actmax  , // act max
  .in_offs   (in_offs),		//in  signed   [8:0]  in_offs , // quantize params
  .fil_offs  (fil_offs),	//in  signed   [8:0]  fil_offs,
  .out_offs  (out_offs),	//in  signed   [8:0]  out_offs,
  .out_mult  (out_mult),	//in  signed [17:0] out_mult,
  .out_shift (out_shift),	//in  unsigned [7:0]  out_shift,
  .accd      (accd[i]),		//out unsigned [7:0]  accd    , // u8 out
  .acvalid   (acv[i]) 		//out                 acvalid   // accd data valid
 );
 end
endgenerate


integer fd, fdo, id, acc;

always #5	// 100MHz
        clk <= !clk;

initial begin
  c_main();
end

initial begin
  xrst = 1'b0;
  #21
  xrst = 1'b1;
  #20 ;// acl = 'b1;

end


int runcount = 500;
int matchcount = 0;
int misscount = 0;

always@(posedge clk) begin
  if(run) runcount <= runcount > 500 ? 500 : (runcount + 1);
  else runcount <= runcount - 1;
  if(acl && acvalid) begin
    for(int i = 0; i < Np; i++) begin
      if(oen[i]) begin
        if(match[i]) matchcount = matchcount + 1;
        else misscount = misscount + 1;
      end
    end
  end
  if(runcount <= 0) begin
    $display("match : %d", matchcount);
    $display("miss  : %d", misscount);

    compare_mem();

    $finish;
  end
end

endmodule



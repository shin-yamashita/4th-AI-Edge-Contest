
`timescale 1ns/1ns

module tb_u8mac();

logic clk = 1, xreset, aen, acl, rdy, acvalid, ivalid;
logic unsigned [7:0] in_d, fil_d, actmin, actmax, accd, out_shift;
logic signed   [8:0] in_offs, fil_offs, out_offs;
logic signed   [31:0] bias;
logic signed   [23:0] out_mult;

u8mac u_u8mac (
  .clk       (clk),		//in                  clk     , //
  .xreset    (xreset),		//in                  xreset  , //
  .aen       (aen),		//in                  aen     , // acc enable
  .acl       (acl),		//in                  acl     , // acc clear
  .rdy       (rdy),		//in                  rdy     , // memory read data ready
  .ivalid    (ivalid),		//in                  ivalid  , // input data valid
  .in_d      (in_d),		//in  unsigned [7:0]  in_d    , // u8 input
  .fil_d     (fil_d),		//in  unsigned [7:0]  fil_d   , // u8 filter
  .bias      (bias),		//in  signed   [31:0] bias    , // s32 bias
  .actmin    (actmin),		//in  unsigned [7:0]  actmin  , // act min
  .actmax    (actmax),		//in  unsigned [7:0]  actmax  , // act max
  .in_offs   (in_offs),		//in  signed   [8:0]  in_offs , // quantize params
  .fil_offs  (fil_offs),	//in  signed   [8:0]  fil_offs,
  .out_offs  (out_offs),	//in  signed   [8:0]  out_offs,
  .out_mult  (out_mult),	//in  signed   [23:0] out_mult,
  .out_shift (out_shift),	//in  unsigned [7:0]  out_shift,
  .accd      (accd),		//out unsigned [7:0]  accd    , // u8 out
  .acvalid   (acvalid) 		//out                 acvalid   // accd data valid
);

assign rdy = 'b1;

integer fd, fdo, id, acc;

always #5
        clk <= !clk;

initial begin
  fd  = $fopen("tvec/tvec-u8.in", "r");
  $fscanf(fd, "%d %d %d %d %d %d %d %d", id, in_offs, fil_offs, out_offs, out_mult, out_shift, actmin, actmax);

  xreset = 1'b0;
  acl = 'b0;
  aen = 'b0;
  #21
  xreset = 1'b1;
  #20  acl = 'b1;

  while(1) begin
    @(posedge clk)
    #1;
    $fscanf(fd, "%d %d %d %d %d %d", id, ivalid, in_d, fil_d, bias, acc);
    aen = id == 1;
    if(id == 3) begin
      @(posedge clk);
      @(posedge clk);
    end
    #1;
    acl = id == 3;
    if($feof(fd)) begin
      aen = 'b0;
      #(1000)
      $fclose(fd);
      $finish;
    end
  end
end

bit match;
logic acl_d;
logic [7:0] accdref;
int count = 0;

always@(posedge clk) begin
  acl_d <= acl;
  accdref <= acc[7:0];
  if(acl_d) begin
    count <= count + 1;
    match <= accdref == accd;
    $display("%d %d", accdref, accd);
  end
end

endmodule



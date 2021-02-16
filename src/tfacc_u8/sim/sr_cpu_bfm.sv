
`timescale 1ns/1ns

/*--
        -- data bus
        xreset  : in  std_logic;
        adr     : out unsigned(31 downto 0);
        we      : out std_logic_vector(3 downto 0);
        re      : out std_logic;
        rdy     : in  std_logic;
        dw      : out unsigned(31 downto 0);
        dr      : in  unsigned(31 downto 0);

        -- ext irq input
        eirq    : in  std_logic;
--*/

module sr_cpu_bfm (
  input  logic clk,
  input  logic xreset,
  output logic [31:0] adr,
  output logic we,
  output logic re,
  input  logic rdy,
  output logic [31:0] dw,
  input  logic [31:0] dr
  );

//  import "DPI-C"  context task c_main(int st);
//  import "DPI-C"  pure function int mem_rd(int s, int adr);
//  import "DPI-C"  pure function int mem_wr(int adr, int data);

  export "DPI-C"  task reg_wr;
  export "DPI-C"  task reg_rd;
  export "DPI-C"  task nop;

  int addr, wdata, rdata;
//  logic we = 0, re = 0;

  task reg_wr(input int adr, input int data);
    @(posedge clk);
    #1
    we = 1;
    re = 0;
    addr = adr;
    dw = data;
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
    data = dr;
//    $display("r a: %d d:%d", addr, data);
  endtask

//  initial begin
//    c_main(stage);
//  end

  assign adr = addr;

endmodule



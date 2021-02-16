

module axi_master
   (
//-- memc interface
    input  logic        aclk,		//
    input  logic        arst_n,		//

    input logic [39:0] awaddr,		// 0 write port not used
    input logic [7:0]  awlen,		// 0
    input logic        awvalid,	// 0
    output  logic        awready,	// 

    input logic [127:0] wr_data,	// 0
    input logic        wvalid,		// 0
    input logic        wlast,		// 0
    output  logic        wready,		//

    input logic [39:0] araddr,		//
    input logic [7:0]  arlen,		//
    input logic        arvalid,	//
    output  logic        arready,	//

    output  logic [127:0] rd_data,	//
    output  logic        rvalid,		//
    output  logic        rlast,		//
    input logic        rready		//
    );

// axi bus sequencer

  enum {Idle, Ack, Readcyc, Readcmd, Post} mst;

  int rlen = 0;
  int radr = 0;
  always@(posedge aclk) begin
    if(!arst_n) begin
      mst <= Idle;
      arready <= 'b0;
      rvalid <= 'b0;
      rlast <= 'b0;
    end else begin
      case(mst)
      Idle: begin
          arready <= 'b1;
          rvalid <= 'b0;
          rlast <= 'b0;
          rlen <= arlen;
          radr <= araddr;
          if(arvalid) mst <= Readcmd;
        end
      Readcmd: begin
          rvalid <= 1'b1;
          rd_data <= radr;
          rlen <= rlen - 1;
          if(rlen == 0) begin
            rlast <= 1'b1;
            mst <= Idle;
          end
        end
      default: mst <= Idle;
      endcase
    end
  end

endmodule


//
// u8mac.sv
// tflite uint8 quantized MAC
//
`timescale 1ns/1ns

`include "logic_types.svh"

module u8mac (
  input  logic clk     , //
  input  logic xreset  , //
  input  logic aen     , // acc enable
  input  logic acl     , // acc clear
  input  logic rdy     , // memory read data ready (in & fil)
  input  logic ivalid  , // input data valid
  input  u8_t  in_d    , // u8 input
  input  u8_t  fil_d   , // u8 filter
  input  s32_t bias    , // s32 bias
  input  u8_t  actmin  , // act min
  input  u8_t  actmax  , // act max
  input  s9_t  in_offs , // quantize params
  input  s9_t  fil_offs,
  input  s9_t  out_offs,
  input  s18_t out_mult,
  input  u8_t  out_shift,
  output u8_t  accd    , // u8 out
  output logic acvalid   // accd data valid
);

  // s8*s8 acc
  // (in_d + in_offs) * (fil_d + fil_offs)
  s32_t acc;
  s32_t accm;
  s32_t xx;
  logic [19:0] mask, th, rem;
  logic [3:0] aen_d;
  logic cl, en, ben, en1;
  u8_t  in_d1, fil_d1;
  s18_t accn;

//  s9_t  in_offs1, fil_offs1, out_offs1;
//  s18_t out_mult1;
//  u8_t  out_shift1;

  assign cl = rdy && acl;
  assign en = rdy && aen && ivalid;
  assign ben = rdy && !aen && aen_d[0];

  always@(posedge clk) begin
    in_d1 <= in_d;
    fil_d1 <= fil_d;
    en1 <= en;

//    in_offs1   <= in_offs;
//    fil_offs1  <= fil_offs;
//    out_offs1  <= out_offs;
//    out_mult1  <= out_mult;
//    out_shift1 <= out_shift;
  end
  assign accn = 9'(signed'(in_d1 + in_offs)) * 9'(signed'(fil_d1 + fil_offs));
//  s32_t accr;

  always@(posedge clk) begin
    if(cl) begin
      acc <= 'd0;
    end else begin
      acc <= acc + (en1 ? s32_t'(accn) : 32'sd0) + (ben ? bias : 32'sd0);
    end
  end

  always@(posedge clk) begin
    if(!xreset) begin
      aen_d <= 'd0;
    end else if(rdy) begin
      aen_d <= {aen_d[2:0], aen};
//      if(acl) begin
//        acc <= 'd0;
//      end else if(aen && ivalid) begin		// accum
//        acc <= acc + 9'(signed'(in_d + in_offs)) * 9'(signed'(fil_d + fil_offs));
//      end else if(!aen && aen_d[0]) begin	// bias add
//        acc <= acc + bias;
//      end
    end

    if(!xreset) begin
        acvalid <= '0;
    end else if(!aen_d[0] && aen_d[1]) begin		// scale 1
        xx <= s48_t'(acc * out_mult) >>> 16;
    end else if(!aen_d[1] && aen_d[2]) begin	// scale 2
        accd <= accm < signed'(actmin) ? actmin : accm > actmax ? actmax : accm[7:0];
        acvalid <= '1;
//    end else if(acl) begin
    end else begin
        acvalid <= '0;
    end

  end

//  assign xx = signed'(acc * out_mult) >>> 16;
  assign mask = (1 << out_shift) - 1;
  assign th = (mask >> 1) + (acc < 0);
  assign rem = xx & mask;
  assign accm = signed'(((xx >>> out_shift) + out_offs) + ((rem > th)?1:0));

endmodule

/*--- tflite acc output rounding ------
inline int32 _MultiplyByQuantizedMultiplier(int32 x, int32 quantized_multiplier, int shift) {    // right shift only
    int32 xx = ((int64_t)x * (quantized_multiplier>>15)) >> 16;
    int32 mask = (1 << (-shift)) - 1;
    int32 th = (mask >> 1) + (x < 0);
    int32 rem = xx & mask;
    return (xx >> -shift) + (rem > th);
}
*/


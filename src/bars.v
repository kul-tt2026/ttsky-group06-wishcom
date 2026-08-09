`default_nettype none
// ---------------------------------------------------------------------------
// SATISFACTION BAR + COMBO BAR.  Two bars, same shape, one file.
// Each is 4 segments; `fill` says how many are lit.  Local coordinates.
//
// The boss instantiates this twice (once per bar) with different origins
// and different `fill` sources -- exactly like the chests.
// ---------------------------------------------------------------------------
module bars (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [2:0] fill,         // how many of the 4 segments are lit
    output wire       px_on,
    output wire [1:0] px_code       // 1 = frame/empty segment, 2 = lit segment
);
  // TODO (drawables owner): 4 segment boxes with small gaps; a segment is
  // "lit" when its index < fill... careful: fill==3 lights 3; decide
  // whether satisfaction 3 (happy) should show 4/4 -- maybe pass fill+1,
  // or make fill 3 mean full.  Write the choice in SIGNALS.md.

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{x, y, fill, 1'b0};
endmodule

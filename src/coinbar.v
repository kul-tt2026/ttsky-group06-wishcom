`default_nettype none
// ---------------------------------------------------------------------------
// Coins
// coins: max 256: 8 levels, elke 32 coins nieuw vakje, gewoon leeg en als vol gele kleur
// 2 kleuren: 0 frame + divider, 1: yellow 
// ---------------------------------------------------------------------------
module coinbar (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [1:0] fill,         // how many of the 4 segments are lit
    output wire       px_on,
    output wire [1:0] px_code       // 1 = frame/empty segment, 2 = lit segment
);
  // coins: kan tot 255 coins maximum, moet niet veranderen per bit (vakjes onbepaald)




  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{x, y, fill, 1'b0};
endmodule



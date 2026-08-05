`default_nettype none
// ---------------------------------------------------------------------------
// HEARTS + COIN DIGITS.  Shown in BOTH compositions (the boss decides where).
//
// Unlike the other drawables this one takes ABSOLUTE screen coordinates and
// owns its own placement -- it was built that way in the previous version
// and it works; not worth churning.  If you'd rather make it local like the
// others, that's a fine cleanup, but do it as its own small step.
//
// Contains the binary->decimal conversion (double dabble) so coins==170
// shows as "1 7 0".  digit_rom lives in sprites.v.
// ---------------------------------------------------------------------------
module hud (
    input  wire [9:0] pix_x,        // ABSOLUTE screen coordinates
    input  wire [9:0] pix_y,
    input  wire [1:0] hearts,
    input  wire [7:0] coins,
    input  wire [2:0] level,
    output wire       px_on,
    output wire [1:0] px_code       // 1 = heart red, 2 = text white
);
  // TODO (drawables owner): carry over the working implementation from the
  // previous hud.v -- hearts row, double-dabble, coin digits, level digit.
  // Only the port names changed (pixel_on -> px_on) to match the others.

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{pix_x, pix_y, hearts, coins, level, 1'b0};
endmodule

`default_nettype none
// ---------------------------------------------------------------------------
// DRAGON.  Answers one question: "is local dot (x,y) part of the dragon,
// and which part?"  Knows NOTHING about screen position, mode, or layers --
// the boss (renderer.v) handles all of that.
//
// Coordinates are LOCAL: (0,0) is the dragon's top-left corner.  The boss
// subtracts the origin before calling us.
// ---------------------------------------------------------------------------
module dragon_draw (
    input  wire [9:0] x,            // local, 0 = left edge of the dragon
    input  wire [9:0] y,            // local, 0 = top edge
    input  wire [2:0] level,        // evolution stage -> shape/size
    input  wire [2:0] mood_anim,    // 0 calm 1 wiggle 2 droop 3 shake
    input  wire [1:0] bob,          // idle bounce offset (apply to y here
                                    // or let the boss shift the origin --
                                    // pick ONE, write it in SIGNALS.md)
    output wire       px_on,        // 1 = the dragon covers this dot
    output wire [2:0] px_code       // which part: 1 outline, 2 body,
                                    // 3 belly, 4 horn, ...  (0 = not used;
                                    // px_on already says "nothing here")
);
  // TODO (drawables owner): the geometry.  Procedural shapes from
  // comparisons/boxes are cheap; avoid multiplies.  Branch on `level` for
  // size, on `mood_anim` for posture -- all variants live HERE, in one file.

  assign px_on   = 1'b0;            // placeholder: invisible
  assign px_code = 3'd0;

  wire _unused = &{x, y, level, mood_anim, bob, 1'b0};
endmodule

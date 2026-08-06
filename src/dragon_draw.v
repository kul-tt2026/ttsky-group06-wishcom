`default_nettype none
module dragon_draw (
    input  wire [9:0] x,            // local, 0 = left edge of the dragon
    input  wire [9:0] y,            // local, 0 = top edge
    input  wire [2:0] level,        // evolution stage -> shape/size
    input  wire [1:0] mood_anim,    // 0 calm 1 wiggle 2 droop 3 shake
    input  wire [1:0] bob,          // idle bounce offset (apply to y here
                                    // or let the boss shift the origin --
                                    // pick ONE, write it in SIGNALS.md)
    output wire       px_on,        // 1 = the dragon covers this dot
    output wire [2:0] px_code       // which part: 1 outline, 2 body,
                                    // 3 belly, 4 horn, ...  (0 = not used;
                                    // px_on already says "nothing here")
); 

  //teken de draak en assign px_on en px_code (kleur)

  assign px_on   = 1'b0;            // placeholder: invisible
  assign px_code = 3'd0;

  wire _unused = &{x, y, level, mood_anim, bob, 1'b0};
endmodule

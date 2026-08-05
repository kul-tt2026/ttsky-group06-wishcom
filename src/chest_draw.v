`default_nettype none
// ---------------------------------------------------------------------------
// ONE CHEST.  Written once, instantiated three times by the boss with three
// different origins.  Local coordinates, same contract as dragon_draw.
// ---------------------------------------------------------------------------
module chest_draw (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [1:0] frame,        // 0 closed, 1 opening, 2 open
    input  wire       highlighted,  // this chest is under the cursor
    output wire       px_on,
    output wire [1:0] px_code       // 1 outline, 2 wood, 3 gold
);
  // TODO (drawables owner): box + lid geometry; lid position from `frame`;
  // `highlighted` can thicken the outline or add a glow row -- your call.

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{x, y, frame, highlighted, 1'b0};
endmodule

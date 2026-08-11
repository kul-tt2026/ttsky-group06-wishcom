`default_nettype none
// ---------------------------------------------------------------------------
// BEEPER.  OWNER: PERSON C.  Entirely optional; add late or cut freely.
//
// A square wave: flip a pin at N Hz and you hear the tone N.  A small state
// machine steps through 2-4 notes when an event pulse arrives.
//
// Suggested jingles:  heart gained  -> two rising notes
//                     heart lost    -> two falling notes
//                     evolve        -> a little fanfare
//                     game over     -> slow descending three
// Coordinate the output pin with Person A (goes on a uio pin in project.v).
// ---------------------------------------------------------------------------
module audio (
    input  wire clk,
    input  wire rst_n,
    input  wire ev_heart_gain,    // pulses -- Person A wires these from the
    input  wire ev_heart_lose,    // req_* lines / dragon_state edges
    input  wire ev_evolve,
    input  wire ev_game_over,
    output reg  spkr
);
  // TODO Person C:
  //  * a divider: reg [15:0] div; a "period" value per note;
  //    toggle spkr each time div wraps -> tone
  //  * a tiny sequencer: on any ev_* pulse, load a 2-4 entry note list
  //    and a duration counter (frames are fine: reuse a slow tick)
  always @(posedge clk) begin
    if (!rst_n) spkr <= 1'b0;
    // ...
  end
  wire _unused = &{ev_heart_gain, ev_heart_lose, ev_evolve, ev_game_over, 1'b0};
endmodule

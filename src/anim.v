`default_nettype none
// ---------------------------------------------------------------------------
// ANIMATION HEARTBEAT.  OWNER: PERSON B.
//
// All time-varying visual state, so the renderer stays a pure function.
// New in this version: the dragon's MOOD animation, driven by satisfaction.
// Whoever decides the dragon is sad decides what sad looks like -- that's
// why this file and balance.v share an owner.
// ---------------------------------------------------------------------------
module anim (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire [1:0] mode,             // to pause animations off-home
    input  wire [1:0] satisfaction,     // 0 miserable .. 3 happy
    input  wire [1:0] chest_state,      // to run the chest-open sequence

    output reg  [1:0] dragon_bob,       // idle bounce 0..2
    output reg  [1:0] dragon_mood_anim, // 0 calm 1 wiggle 2 droop 3 shake
    output reg  [1:0] chest_frame,      // 0 closed 1 opening 2 open
    output reg        flash,            // evolve fanfare blink
    output reg        flame_frame       // flame flicker
);
  reg [5:0] slow;                       // free-running frame counter

  always @(posedge clk) begin
    if (!rst_n) begin
      slow<=0; dragon_bob<=0; dragon_mood_anim<=0;
      chest_frame<=0; flash<=0; flame_frame<=0;
    end else if (frame_tick) begin
      slow <= slow + 6'd1;
      flame_frame <= slow[3];

      // TODO Person B:
      //  * dragon_bob: 0,1,2,1 pattern, stepped every ~16 frames; consider
      //    bobbing FASTER when happy, slower/none when miserable
      //  * dragon_mood_anim from satisfaction:
      //      3 happy     -> occasional wiggle (1)
      //      2 neutral   -> calm (0)
      //      1 sad       -> droop (2)
      //      0 miserable -> shake (3)
      //  * chest_frame: step 0->1->2 while chest_state==OPENING
      //  * flash: blink ~4 Hz during the evolve fanfare (needs an evolve
      //    signal -- coordinate with Person A on how to see it)
    end
  end

  wire _unused = &{mode, satisfaction, chest_state, 1'b0};
endmodule

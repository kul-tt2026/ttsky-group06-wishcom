`default_nettype none
// ---------------------------------------------------------------------------
// THE BALANCE GAME.  OWNER: PERSON B.
//
// Watches the care actions (feed / drink / sleep) on the home screen and
// judges them:
//   * the SAME action three times in a row  -> over-care:
//         req_sat_down pulse  AND  req_heart_lose pulse
//   * FOUR different actions consecutively  -> balanced care:
//         req_heart_gain pulse (and the streak resets)
//   * a well-spaced action                  -> req_sat_up (small reward)
//
// DESIGN DECISIONS STILL OPEN (settle with the team before coding):
//   1. Only three care actions exist but the combo needs four DIFFERENT
//      ones.  Either (a) entering the minigame counts as the 4th action
//      type, or (b) add a 4th care action (pet?), or (c) combo length = 3.
//      The skeleton assumes (a): home.v could route a "played" pulse here.
//   2. Does feed,feed,sleep,feed count as strike 2 or strike 1?  Skeleton
//      assumes consecutive-only: any different action resets same_count.
//
// This module is fully testable in simulation: pulse the act_* inputs,
// check the req_* outputs.  Write that test before wiring anything up.
// ---------------------------------------------------------------------------
module balance (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire       restart,

    input  wire       act_feed,        // pulses from home.v
    input  wire       act_drink,
    input  wire       act_sleep,

    output reg        req_heart_gain,  // -> dragon_state
    output reg        req_heart_lose,
    output reg        req_sat_up,
    output reg        req_sat_down,

    output reg  [1:0] combo_len        // -> renderer (progress bar 0..3)
);
  // action encoding for the history registers
  localparam A_NONE=2'd0, A_FEED=2'd1, A_DRINK=2'd2, A_SLEEP=2'd3;

  wire        any_act  = act_feed | act_drink | act_sleep;
  wire [1:0]  this_act = act_feed  ? A_FEED  :
                         act_drink ? A_DRINK :
                         act_sleep ? A_SLEEP : A_NONE;

  reg  [1:0] last_act;     // the previous action
  reg  [1:0] same_count;   // how many times in a row (1-based)
  // For the four-different combo you need to know WHICH actions the current
  // streak has seen, not just how many: a 3/4-bit "seen" mask is the cheap
  // trick.  TODO Person B: seen[this_act] logic + reset rules.
  reg  [3:0] seen;

  always @(posedge clk) begin
    if (!rst_n || restart) begin
      last_act<=A_NONE; same_count<=2'd0; seen<=4'd0; combo_len<=2'd0;
      req_heart_gain<=0; req_heart_lose<=0; req_sat_up<=0; req_sat_down<=0;
    end else if (frame_tick) begin
      req_heart_gain<=0; req_heart_lose<=0; req_sat_up<=0; req_sat_down<=0;

      if (any_act) begin
        // TODO Person B:
        //  * same as last?  same_count++ ; at 3 -> req_sat_down AND
        //    req_heart_lose, then reset same_count (decide: to 0 or 1?)
        //  * different?     same_count <= 1; update seen mask; combo_len++
        //  * seen covers all four? -> req_heart_gain, clear seen & combo_len
        //  * consider req_sat_up on every "different" action as small reward
        last_act <= this_act;
      end
    end
  end

  wire _unused = &{last_act, same_count, seen, 1'b0};
endmodule

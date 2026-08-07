`default_nettype none
// ---------------------------------------------------------------------------
// THE CHEST MINIGAME.  OWNER: PERSON C.
//
// Runs only while mode == CHEST (home.v decides that).  Three chests, one
// hides a free level-up, one hides coins, one costs a heart.  Pick with
// LEFT/RIGHT (buttons 4/5), open with SELECT (6), leave with START (7).
//
// This is the old game_fsm, reshaped in two ways:
//   1. It no longer owns any stats -- it emits request pulses instead.
//   2. It no longer owns modes -- it raises minigame_done and home.v
//      switches back.
//
// Same superpower as before: fully testable in simulation with no screen.
// The shuffle TODO is the same one as the old file, and the same trap
// applies: pick one of the six orderings, never roll chests independently.
// ---------------------------------------------------------------------------
module chest_game (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire       active,             // mode == M_CHEST (from home.v)
    input  wire [7:0] btn_pressed,

    output reg  [1:0] chest_state,        // 0 picking, 1 opening, 2 result
    output reg  [1:0] chest_sel,          // cursor 0..2
    output reg  [1:0] chest_outcome,      // 0 level, 1 coins, 2 lose-heart

    output reg        req_coins_add,      // -> dragon_state
    output reg        req_level_up_paid,
    output reg        req_heart_lose_chest,
    output reg        minigame_done       // -> home.v: hand control back
);
  localparam C_PICK=2'd0, C_OPEN=2'd1, C_RESULT=2'd2;
  localparam O_LEVEL=2'd0, O_COIN=2'd1, O_LOSE=2'd2;

  // free-running random source; never seed with 0
  reg [15:0] lfsr;
  always @(posedge clk) begin
    if (!rst_n) lfsr <= 16'hACE1;
    else        lfsr <= {lfsr[0], lfsr[15:1]} ^ (lfsr[0] ? 16'hB400 : 16'h0000);
  end

  reg [1:0] contents [0:2];
  reg [7:0] timer;
  reg       dealt;

  integer i;
  always @(posedge clk) begin
    if (!rst_n) begin
      chest_state<=C_PICK; chest_sel<=0; chest_outcome<=O_COIN;
      timer<=0; dealt<=0; minigame_done<=0;
      req_coins_add<=0; req_level_up_paid<=0; req_heart_lose_chest<=0;
      for (i=0;i<3;i=i+1) contents[i]<=2'd0;
    end else if (frame_tick) begin
      req_coins_add<=0; req_level_up_paid<=0; req_heart_lose_chest<=0;
      minigame_done<=0;
      if (timer!=0) timer<=timer-8'd1;

      if (active) case (chest_state)
        C_PICK: begin
          // TODO Person C (same as the old file's TODO):
          //  * if (!dealt): use lfsr[2:0] to pick one of the SIX orderings
          //    of {O_LEVEL,O_COIN,O_LOSE} into contents[0..2]; dealt<=1
          //  * LEFT/RIGHT (btn 4/5) move chest_sel within 0..2
          //  * SELECT (btn 6): chest_outcome<=contents[chest_sel];
          //    timer<=45; chest_state<=C_OPEN
          //  * START (btn 7): minigame_done<=1 (leave without opening)
        end
        C_OPEN: begin
          // TODO Person C: when timer==0 -> timer<=60; chest_state<=C_RESULT
        end
        C_RESULT: begin
          // TODO Person C: when timer==0:
          //  * fire the matching req_* pulse for chest_outcome
          //  * dealt<=0; chest_state<=C_PICK; minigame_done<=1
          //    (decide with the team: one chest per visit, or several?)
        end
        default: chest_state<=C_PICK;
      endcase
      else begin
        chest_state<=C_PICK; dealt<=0;    // reset whenever we're not active
      end
    end
  end

  wire _unused = &{btn_pressed, contents[0], contents[1], contents[2], 1'b0};
endmodule

`default_nettype none
// ---------------------------------------------------------------------------
// TOP LEVEL.  OWNER: PERSON A.  Nobody else commits here.  Wiring only.
// Every signal below is documented in SIGNALS.md -- that page is the law.
// ---------------------------------------------------------------------------
module tt_um_dragonchi (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
  // ---- screen timing + 60 Hz heartbeat ----
  // wire hsync, vsync, video_active;
  // wire [9:0] pix_x, pix_y;
  // hvsync_generator u_hvsync (
  //   .clk(clk), .reset(~rst_n),
  //   .hsync(hsync), .vsync(vsync), .display_on(video_active),
  //   .hpos(pix_x), .vpos(pix_y)
  // );
  reg vsync_d;
  always @(posedge clk) begin
    if (!rst_n) vsync_d <= 1'b1; else vsync_d <= vsync;
  end
  wire frame_tick = vsync_d & ~vsync;

  // ---- controller: all 8 inputs ----
  wire [7:0] btn_level, btn_pressed;
  buttons u_buttons (
    .clk(clk), .rst_n(rst_n), .raw(ui_in),
    .level(btn_level), .pressed(btn_pressed)
  );

  // ---- home screen / mode control (Person A) ----
  wire [1:0] mode, menu_sel;
  wire act_feed, act_drink, act_sleep, req_evolve, restart;
  wire game_over, minigame_done;
  wire [9:0] coins;
  home u_home (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .btn_pressed(btn_pressed),
    .game_over(game_over), .minigame_done(minigame_done), .coins(coins),
    .mode(mode), .menu_sel(menu_sel),
    .act_feed(act_feed), .act_drink(act_drink), .act_sleep(act_sleep),
    .req_evolve(req_evolve), .restart(restart)
  );

  // ---- balance game (Person B) ----
  wire req_heart_gain, req_heart_lose, req_sat_up, req_sat_down;
  wire [1:0] combo_len;
  balance u_balance (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick), .restart(restart),
    .act_feed(act_feed), .act_drink(act_drink), .act_sleep(act_sleep),
    .req_heart_gain(req_heart_gain), .req_heart_lose(req_heart_lose),
    .req_sat_up(req_sat_up), .req_sat_down(req_sat_down),
    .combo_len(combo_len)
  );

  // ---- chest minigame (Person C) ----
  wire [1:0] chest_state, chest_sel, chest_outcome;
  wire req_coins_add, req_level_up_paid, req_heart_lose_chest;
  chest_game u_chest_game (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .active(mode == 2'd2),
    .btn_pressed(btn_pressed),
    .chest_state(chest_state), .chest_sel(chest_sel),
    .chest_outcome(chest_outcome),
    .req_coins_add(req_coins_add), .req_level_up_paid(req_level_up_paid),
    .req_heart_lose_chest(req_heart_lose_chest),
    .minigame_done(minigame_done)
  );

  // ---- the dragon's stats: the one owner (Person A) ----
  wire [2:0] hearts, satisfaction;
  wire [2:0] level;
  dragon_state u_state (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick), .restart(restart),
    .req_heart_gain(req_heart_gain), .req_heart_lose(req_heart_lose),
    .req_sat_up(req_sat_up), .req_sat_down(req_sat_down),
    .req_coins_add(req_coins_add), .req_level_up_paid(req_level_up_paid),
    .req_heart_lose_chest(req_heart_lose_chest),
    .req_evolve(req_evolve),
    .hearts(hearts), .satisfaction(satisfaction),
    .coins(coins), .level(level), .game_over(game_over)
  );

  // ---- animation heartbeat (Person B) ----
  wire [1:0] dragon_bob, dragon_mood_anim, chest_frame;
  wire flash, flame_frame;
  anim u_anim (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .mode(mode), .satisfaction(satisfaction), .chest_state(chest_state),
    .dragon_bob(dragon_bob), .dragon_mood_anim(dragon_mood_anim),
    .chest_frame(chest_frame), .flash(flash), .flame_frame(flame_frame)
  );

  // ---- screen painter (render group) ----

  // VGA singals:
  wire hsync, vsync, video_active;
  wire [1:0] R, G, B;
  wire [9:0] pix_x, pix_y;
  wire [1:0] dragenform; 

  // ---- TinyVGA Pmod.  Do not touch. ----
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  hvsync_generator u_hvsync (
    .clk(clk), .reset(~rst_n),
    .hsync(hsync), .vsync(vsync), .display_on(video_active),
    .hpos(pix_x), .vpos(pix_y)
  );
  wire overflow = 1'b0;
  renderer u_renderer (
    .pix_x(pix_x), .pix_y(pix_y), .video_active(video_active),
    .mode(mode), .menu_sel(menu_sel),
    .hearts(hearts), .satisfaction(satisfaction),
    .coins(coins), .level(level), .combo_len(combo_len),
    .chest_state(chest_state), .chest_sel(chest_sel),
    .chest_outcome(chest_outcome),
    .dragon_mood_anim(dragon_mood_anim),
    .chest_frame(chest_frame), .flash(flash), .flame_frame(flame_frame),
    .R(R), .G(G), .B(B), .evolve_now(req_evolve), .dragon_form(dragenform), .you_win(game_over), .overflow(overflow)
  );

  

  

  // audio later: assign uio_out[0] = spkr; uio_oe[0] = 1;
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  wire _unused = &{ena, uio_in, btn_level, chest_outcome, 1'b0};
endmodule



/*
Video sync generator, used to drive a VGA monitor.
Timing from: https://en.wikipedia.org/wiki/Video_Graphics_Array
To use:
- Wire the hsync and vsync signals to top level outputs
- Add a 3-bit (or more) "rgb" output to the top level
*/

module hvsync_generator(clk, reset, hsync, vsync, display_on, hpos, vpos);

  input clk;
  input reset;
  output reg hsync, vsync;
  output display_on;
  output reg [9:0] hpos;
  output reg [9:0] vpos;

  // declarations for TV-simulator sync parameters
  // horizontal constants
  parameter H_DISPLAY       = 640; // horizontal display width
  parameter H_BACK          =  48; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  96; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 480; // vertical display height
  parameter V_TOP           =  33; // vertical top border
  parameter V_BOTTOM        =  10; // vertical bottom border
  parameter V_SYNC          =   2; // vertical sync # lines
  // derived constants
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  wire hmaxxed = (hpos == H_MAX) || reset;	// set when hpos is maximum
  wire vmaxxed = (vpos == V_MAX) || reset;	// set when vpos is maximum
  
  // horizontal position counter
  always @(posedge clk)
  begin
    hsync <= ~(hpos>=H_SYNC_START && hpos<=H_SYNC_END);
    if(hmaxxed)
      hpos <= 0;
    else
      hpos <= hpos + 1;
  end

  // vertical position counter
  always @(posedge clk)
  begin
    vsync <= ~(vpos>=V_SYNC_START && vpos<=V_SYNC_END);
    if(hmaxxed)
      if (vmaxxed)
        vpos <= 0;
      else
        vpos <= vpos + 1;
  end
  
  // display_on is set when beam is in "safe" visible frame
  assign display_on = (hpos<H_DISPLAY) && (vpos<V_DISPLAY);

endmodule


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
`default_nettype none
// ---------------------------------------------------------------------------
// 8-input controller conditioning.  OWNER: PERSON A.  Done -- nobody edits.
// Debounces all eight inputs, gives clean held-state and press pulses.
// The MEANING of each bit lives in SIGNALS.md, not here.
// ---------------------------------------------------------------------------
module buttons (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] raw,
    output reg  [7:0] level,
    output reg  [7:0] pressed
);
  reg [14:0] tick_cnt;                   // ~768 Hz sampling
  wire tick = (tick_cnt == 15'h7FFF);
  reg [7:0] sync0, sync1;

  always @(posedge clk) begin
    if (!rst_n) begin
      tick_cnt<=0; sync0<=0; sync1<=0; level<=0; pressed<=0;
    end else begin
      tick_cnt <= tick_cnt + 15'd1;
      sync0 <= raw;
      sync1 <= sync0;
      pressed <= 8'd0;
      if (tick) begin
        level   <= sync1;
        pressed <= sync1 & ~level;
      end
    end
  end
endmodule
`default_nettype none
// ---------------------------------------------------------------------------
// 
// ---------------------------------------------------------------------------
module chest_draw (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [1:0] frame,        // 0 closed, 1 opening, 2 open
    input  wire       highlighted,  // this chest is under the cursor
    output wire       px_on,
    output wire [1:0] px_code       // 1 outline, 2 wood, 3 gold
);
  // 

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{x, y, frame, highlighted, 1'b0};
endmodule
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
    else        lfsr <= {lfsr[0], lfsr[15:1] ^ (lfsr[0] ? 16'hB400 : 16'h0000)};
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
`default_nettype none
module dragon_draw (
    input  wire [9:0] x,            // local, 0 = left edge of the dragon
    input  wire [9:0] y,            // local, 0 = top edge
    input  wire [1:0] state,        // evolution stage -> shape/size
    input  wire [1:0] mood_anim,    // nog onbepaald
    output wire       px_on,        // 1 = the dragon covers this dot
    output wire [2:0] px_code       // 1 outline, 2 body, 3 belly, 4 horn, ...
); 

  //op basis van state: ei, draak in ei, kleine draak, grote draak 
  //draak beweegt op en neer lichtjes 

  assign px_on   = 1'b0;            // placeholder: invisible
  assign px_code = 3'd0;

  wire _unused = &{x, y, level, mood_anim, bob, 1'b0};
endmodule
`default_nettype none
// ---------------------------------------------------------------------------
// THE DRAGON'S STATS.  OWNER: PERSON A.
//
// The single most important rule of the new architecture:
//   *** THIS is the only file that ever changes hearts, satisfaction,      ***
//   *** coins or level.  Everyone else sends one-clock REQUEST pulses.     ***
//
// Why: both games affect the same stats.  If both wrote them directly you'd
// get merge conflicts daily and same-frame overwrite bugs.  Here, all the
// rules (caps, floors, the satisfaction->hearts coupling, evolve pricing)
// live in one testable place.
// ---------------------------------------------------------------------------
module dragon_state (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire       restart,            // from home.v: new game

    // requests from balance.v
    input  wire       req_heart_gain,
    input  wire       req_heart_lose,
    input  wire       req_sat_up,
    input  wire       req_sat_down,

    // requests from chest_game.v
    input  wire       req_coins_add,
    input  wire       req_level_up_paid,
    input  wire       req_heart_lose_chest,

    // request from home.v
    input  wire       req_evolve,

    // the stats -- read-only for everyone else
    output reg  [1:0] hearts,             // 3..0
    output reg  [1:0] satisfaction,       // 0 miserable .. 3 happy
    output reg  [7:0] coins,
    output reg  [2:0] level,              // 0..7
    output reg        game_over
);
  // evolve price: doubles-ish per level.  TODO Person A: tune with playtests.
  wire [7:0] evolve_price = 8'd20 << level[1:0];   // 20,40,80,160, then cap

  always @(posedge clk) begin
    if (!rst_n || restart) begin
      hearts       <= 2'd3;
      satisfaction <= 2'd2;               // start neutral
      coins        <= 8'd0;
      level        <= 3'd0;
      game_over    <= 1'b0;
    end else if (frame_tick && !game_over) begin

      // ---- hearts ----------------------------------------------------
      // TODO Person A: combine the three lose-sources and the gain source.
      // Rules to implement:
      //   * gain: +1, capped at 3
      //   * lose (any source): -1; when hearts would hit 0 -> game_over
      //   * req_sat_down while ALREADY at miserable: costs a heart
      //     instead of dropping satisfaction further

      // ---- satisfaction ----------------------------------------------
      // TODO Person A:
      //   * req_sat_up:   +1 capped at happy(3)
      //   * req_sat_down: -1 floored at miserable(0)  (heart rule above)

      // ---- coins & level ---------------------------------------------
      // TODO Person A:
      //   * req_coins_add:       coins <= coins + 10 (saturate at 255)
      //   * req_level_up_paid:   level <= level + 1 (cap 7) -- chest freebie
      //   * req_evolve:          if coins >= evolve_price:
      //                              coins <= coins - evolve_price;
      //                              level <= level + 1 (cap 7)
      //                          else: ignore (home.v greys the option out
      //                          by reading coins itself)

    end
  end

  wire _unused = &{req_heart_gain, req_heart_lose, req_sat_up, req_sat_down,
                   req_coins_add, req_level_up_paid, req_heart_lose_chest,
                   req_evolve, evolve_price, 1'b0};
endmodule
`default_nettype none
// ---------------------------------------------------------------------------
// HOME SCREEN + MODE SWITCHING.  OWNER: PERSON A.
//
// The hub the player lives on.  Four options: FEED, DRINK, SLEEP, PLAY.
// Feed/drink/sleep fire "action" pulses that balance.v judges.
// PLAY hands control to the chest minigame; minigame_done hands it back.
// Also: title screen, game-over screen, restart, and the evolve request.
//
// Button map (fixed, see SIGNALS.md): 0 FEED 1 DRINK 2 SLEEP 3 PLAY
//                                     4 LEFT 5 RIGHT 6 SELECT 7 START
// ---------------------------------------------------------------------------
module home (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire [7:0] btn_pressed,
    input  wire       game_over,       // from dragon_state
    input  wire       minigame_done,   // from chest_game
    input  wire [7:0] coins,           // to grey out evolve when unaffordable

    output reg  [1:0] mode,            // 0 TITLE, 1 HOME, 2 CHEST, 3 GAMEOVER
    output reg  [1:0] menu_sel,        // cursor over the four options
    output reg        act_feed,        // one-frame pulses ->  balance.v
    output reg        act_drink,
    output reg        act_sleep,
    output reg        req_evolve,      // -> dragon_state
    output reg        restart          // -> dragon_state (new game reset)
);
  localparam M_TITLE=2'd0, M_HOME=2'd1, M_CHEST=2'd2, M_GAMEOVER=2'd3;

  always @(posedge clk) begin
    if (!rst_n) begin
      mode<=M_TITLE; menu_sel<=2'd0;
      act_feed<=0; act_drink<=0; act_sleep<=0; req_evolve<=0; restart<=0;
    end else if (frame_tick) begin
      // default: pulses last one frame only
      act_feed<=0; act_drink<=0; act_sleep<=0; req_evolve<=0; restart<=0;

      case (mode)
        M_TITLE: begin
          // TODO Person A: START -> restart pulse + mode <= M_HOME
        end

        M_HOME: begin
          // TODO Person A:
          //  * direct action buttons: FEED/DRINK/SLEEP -> matching act_* pulse
          //  * PLAY -> mode <= M_CHEST
          //  * LEFT/RIGHT move menu_sel (purely visual; actions are direct)
          //  * SELECT while affordable (coins >= price) -> req_evolve pulse
          //  * game_over -> mode <= M_GAMEOVER
        end

        M_CHEST: begin
          // TODO Person A: minigame_done -> mode <= M_HOME
          //                game_over     -> mode <= M_GAMEOVER
        end

        M_GAMEOVER: begin
          // TODO Person A: START -> restart + mode <= M_HOME
        end
      endcase
    end
  end

  wire _unused = &{btn_pressed, game_over, minigame_done, coins, 1'b0};
endmodule
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
`default_nettype none
// ---------------------------------------------------------------------------
//
//   1. PLACE things: subtract each drawable's origin -> local coordinates
//   2. SHOW things: per composition, which drawables are visible
//   3. STACK things: the layer cascade (first visible layer wins)
//   4. COLOUR things: map each drawable's px_code to real RGB
//
// ---------------------------------------------------------------------------
module renderer (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire       video_active,

    input  wire [1:0] mode,          // 0 TITLE, 1 HOME, 2 CHEST, 3 GAMEOVER
    input  wire [1:0] menu_sel,
    input  wire [2:0] hearts, // 3 bit
    input  wire [2:0] satisfaction, // 3 bit => 5 options
    input  wire [9:0] coins, //tot 1000: level 1 20, level 2 40, level 3 80, level 160, level 
    input  wire [2:0] level, // max 7 levels 

    input  wire       evolve_now, // of je genoeg geld hebt om te evolven 
    input  wire [1:0] combo_len, // ongebruikt

    input  wire [1:0] chest_frame, // 0 closed, 1 opening, 2 open
    input  wire [1:0] chest_state,
    input  wire [1:0] chest_sel, // welke kist is selected (0,1,2)
    input  wire [1:0] chest_outcome,

    input  wire [1:0] dragon_form, // weet niet of dit voldoende bits heeft 
    input  wire [1:0] dragon_mood_anim,
    input  wire       flash,
    input  wire       flame_frame,

    input  wire       you_win,
    input             overflow, // als hartjes vol of geld vol

    output reg  [1:0] R,
    output reg  [1:0] G,
    output reg  [1:0] B
);
  localparam M_TITLE=2'd0, M_HOME=2'd1, M_CHEST=2'd2, M_GAMEOVER=2'd3;

  // ======================= 1. PLACE =======================================
  // Every position is a constant HERE, in one file.  Moving anything on
  // screen is a one-line edit.

  localparam DRAGON_X = 10'd240, DRAGON_Y = 10'd100;
  localparam SATBAR_X = 10'd24,  SATBAR_Y = 10'd56;
  localparam COINBAR_X  = 10'd24,  COINBAR_Y  = 10'd80;
  localparam CHEST0_X = 10'd80,  CHEST1_X = 10'd272, CHEST2_X = 10'd464;
  localparam CHEST_Y  = 10'd300; // moet x niet hetzelfde? 

  // ======================= drawable instances =============================
  // DRAGON -----------------------------------------------------------------
  // uiterlijk draak hangt af van dragon_state
  // als in toekomst genoeg tijd, beinvloed mood ook uiterlijk van draak (houden we momenteel achterwegen)
 
  wire        dragon_on; //of er een pixel van draak is
  wire [2:0]  dragon_code; //welke kleur die moet krijgen als er pixel is 

  dragon_draw u_dragon (
    .x(pix_x - DRAGON_X), .y(pix_y - DRAGON_Y),
    .state(dragon_form), .mood_anim(dragon_mood_anim),
    .px_on(dragon_on), .px_code(dragon_code)
  );

  // THREE CHESTS ---------------------------------
  // chest_frame: staat van box selected?
  // chest_state: 
  // chest_sel: chest selection (0,1,2)
  // chest_outcome: wat er in chest zit

  // 3 verschillende statussen: 
  // - chest selection: alle 3 chest toe, chest van chest_sel groter 
  // - gekozen chest opening: chest_sel open met inhoud erin, (chest_outcome), andere 2 toe, opening niet echt open maar 
  // toont gwn pictogram van inhoud: bommetje (zwart cirkel met rechthoekje), munt (geel cirkel), hartje verliezen (hartje, miss kruis erdoor), 
  // maal 2 van geld ( X 2 pictogram) 
  // - rest tonen: alle 3 chests open
  // 
  wire       c0_on, c1_on, c2_on;
  wire [1:0] c0_code, c1_code, c2_code;

  chest_draw u_chest0 (
    .x(pix_x - CHEST0_X), .y(pix_y - CHEST_Y),
    .frame(chest_sel==2'd0 ? chest_frame : 2'd0),
    .highlighted(chest_sel==2'd0),
    .px_on(c0_on), .px_code(c0_code)
  );
  chest_draw u_chest1 (
    .x(pix_x - CHEST1_X), .y(pix_y - CHEST_Y),
    .frame(chest_sel==2'd1 ? chest_frame : 2'd0),
    .highlighted(chest_sel==2'd1),
    .px_on(c1_on), .px_code(c1_code)
  );
  chest_draw u_chest2 (
    .x(pix_x - CHEST2_X), .y(pix_y - CHEST_Y),
    .frame(chest_sel==2'd2 ? chest_frame : 2'd0),
    .highlighted(chest_sel==2'd2),
    .px_on(c2_on), .px_code(c2_code)
  );
  wire       chest_on   = c0_on | c1_on | c2_on;
  wire [1:0] chest_code = c0_on ? c0_code : c1_on ? c1_code : c2_code; // moet derde niet? 


  // TWO BARS: satisfaction (5 levels, 3 bits ) & coins (8 bits)  ---------------------
  wire sat_on;
  wire [2:0] sat_code;
  satisfactionbar u_satbar (
    .x(pix_x - SATBAR_X), .y(pix_y - SATBAR_Y),
    .sat(satisfaction),
    .px_on(sat_on), .px_code(sat_code)
  );
  // LEVEL moet hier ook nog bij, best apart want bits zitten vol

  wire coin_on;
  wire [1:0] coin_code;
  coinbar u_coinbar (
    .x(pix_x - COINBAR_X), .y(pix_y - COINBAR_Y),
    .coins(coins),
    .px_on(coin_on), .px_code(coin_code)
  );
  // vraag: hier nog aantal bijschrijven + overflow

  // HEARTS  + OVERFLOW (absolute coordinates??) -------------------------
  // --- vraag: wat bedoelen ze met absolute coordinaten? en waarom hierwel absolute coordinaten? 
  wire heartsinfo_on;
  wire [1:0] heartsinfo_code;
  heartsinfo u_heartsinfo (
    .pix_x(pix_x), .pix_y(pix_y),
    .hearts(hearts), .overflow(overflow),
    .px_on(heartsinfo_on), .px_code(heartsinfo_code)
  );

  // BUTTONS ----------------------------------------
  // 5 knoppen:            FOOD
  //             WATER    level up    SLEEP
  //                       GAME
  // level up moet oplichten als boolean level_up 1 is 
  // voor de rest gewoon vaste display vanonder aan scherm 
  wire button_on;
  wire [2:0] button_code;

  draw_buttons buttons_u (
    .pix_x(pix_x), .pix_y(pix_y),
    .evolve_now (evolve_now),
    .px_on(button_on), .px_code(button_code)
  );

  // ======================= 2. SHOW ========================================
  // welke dingen moeten getoond worden bij welke gamemode
  wire show_dragon = (mode == M_HOME);
  wire show_satbar   = (mode == M_HOME);
  wire show_buttons   = (mode == M_HOME);

  wire show_chests = (mode == M_CHEST);

  wire show_coin_hearts    = (mode == M_HOME) || (mode == M_CHEST); // altijd getoond 

  // ======================= 4. COLOUR ======================================
  // Per-drawable palettes: code -> 6-bit {R,G,B}
  reg [5:0] dragon_rgb;
  always @(*) case (dragon_code)
    3'd1: dragon_rgb = 6'b000000;      // outline
    3'd2: dragon_rgb = 6'b011001;      // body green
    3'd3: dragon_rgb = 6'b101110;      // belly
    default: dragon_rgb = 6'b011001;
  endcase

  reg [5:0] chest_rgb;
  always @(*) case (chest_code)
    2'd1: chest_rgb = 6'b000000;
    2'd2: chest_rgb = 6'b100100;       // wood
    2'd3: chest_rgb = 6'b111000;       // gold
    default: chest_rgb = 6'b100100;
  endcase

  reg [5:0] coin_rgb;
  always @(*) case (chest_code)
    2'd1: coin_rgb = 6'b000000;
    2'd2: coin_rgb = 6'b100100;       // wood
    2'd3: coin_rgb = 6'b111000;       // gold
    default: coin_rgb = 6'b100100;
  endcase

  reg [5:0] buttons_rgb;
  always @(*) case (chest_code)
    2'd1: buttons_rgb = 6'b000000;
    2'd2: buttons_rgb = 6'b100100;       // wood
    2'd3: buttons_rgb = 6'b111000;       // gold
    default: buttons_rgb = 6'b100100;
  endcase

  

//coin_rgb
// satisfaction (nieuw)
  reg [5:0] sat_rgb;
  always @(*) case (sat_code)
    3'd1: sat_rgb = 6'b11_00_00;   // rood
    3'd2: sat_rgb = 6'b11_01_00;   // oranje
    3'd3: sat_rgb = 6'b11_11_00;   // geel
    3'd4: sat_rgb = 6'b10_11_00;   // limoen
    3'd5: sat_rgb = 6'b00_11_00;   // groen
    3'd6: sat_rgb = 6'b11_11_11;   // wit kader
    3'd7: sat_rgb = 6'b01_01_01;   // donker (alleen in FILL)
    default: sat_rgb = 6'b00_00_00; // frame + schotjes
  endcase

  // heartsinfo: juist kleuren nog aanpassen: rood: wit (denk ik)
  wire [5:0] heartsinfo_rgb       = (heartsinfo_code  == 2'd1) ? 6'b110000 : 6'b111111;

  //buttons_rgb

  // ======================= 3. STACK =======================================
  // volgorde: 
  // GAME: bars > chests > background: show_coin_hearts > show_chests 
  // HOME: bars > dragon >  background: show_coin_hearts > show_satbar > show_buttons > show_dragon

  localparam [5:0] BG_HOME  = 6'b011011; // background home (lichtblauw)
  localparam [5:0] BG_CHEST = 6'b100000; //background game (rood)

  reg [5:0] rgb;
  always @(*) begin
    if (!video_active)           rgb = 6'b000000;      // MUST stay black
    else if (mode == M_TITLE)    rgb = 6'b000110;      // TODO: title text
    else if (mode == M_GAMEOVER) rgb = 6'b010000;      // TODO: game over text
    else if (show_coin_hearts    && heartsinfo_on)    rgb = heartsinfo_rgb;
    else if (show_coin_hearts    && coin_on)          rgb = coin_rgb;
    else if (show_satbar   && sat_on)                 rgb = sat_rgb;
    else if (show_buttons  && button_on)              rgb = buttons_rgb;
    else if (show_chests && chest_on)                 rgb = chest_rgb;
    else if (show_dragon && dragon_on)                rgb = dragon_rgb;
    else rgb = (mode == M_CHEST) ? BG_CHEST : BG_HOME;
    {R, G, B} = rgb;
  end

  wire _unused = &{menu_sel, chest_state, chest_outcome, flame_frame, 1'b0};
endmodule
`default_nettype none
// ---------------------------------------------------------------------------
// Sprite storage.  OWNER: RENDER GROUP.
//
// THIS FILE IS GENERATED.  Do not hand-edit the case blocks -- run:
//     python3 tools/png2rom.py art/egg.png      --name dragon_l0 --bits 3
//     python3 tools/png2rom.py art/adult.png    --name dragon_l3 --bits 3
//     python3 tools/png2rom.py art/chest_c.png  --name chest_f0  --bits 2
//     ...then paste / redirect the output here.
//
// Code 0 always means TRANSPARENT (background shows through).
// The placeholder egg below exists so the pipeline can be tested end-to-end
// before any real art is converted.
// ---------------------------------------------------------------------------
module dragon_rom (
    input  wire [2:0] level,
    input  wire [5:0] row,
    input  wire [5:0] col,
    output reg  [2:0] code       // 0=transparent 1=outline 2=body 3=belly ...
);
  always @(*) begin
    code = 3'd0;
    // placeholder: 16x16 egg shown for every level.
    // codes: 1=outline, 2=body
    if (row<6'd16 && col<6'd16) begin
      case (row[3:0])
        4'd0 : code = (col>=6 && col<=9)  ? 3'd1 : 3'd0;
        4'd1 : code = (col>=5 && col<=10) ? ((col==5||col==10)?3'd1:3'd2) : 3'd0;
        4'd2 : code = (col>=4 && col<=11) ? ((col==4||col==11)?3'd1:3'd2) : 3'd0;
        4'd3 : code = (col>=3 && col<=12) ? ((col==3||col==12)?3'd1:3'd2) : 3'd0;
        4'd4,4'd5 : code = (col>=2 && col<=13) ? ((col==2||col==13)?3'd1:3'd2) : 3'd0;
        4'd6,4'd7,4'd8,4'd9,4'd10 :
               code = (col>=1 && col<=14) ? ((col==1||col==14)?3'd1:3'd2) : 3'd0;
        4'd11,4'd12 : code = (col>=2 && col<=13) ? ((col==2||col==13)?3'd1:3'd2) : 3'd0;
        4'd13: code = (col>=3 && col<=12) ? ((col==3||col==12)?3'd1:3'd2) : 3'd0;
        4'd14: code = (col>=4 && col<=11) ? ((col==4||col==11)?3'd1:3'd2) : 3'd0;
        4'd15: code = (col>=6 && col<=9)  ? 3'd1 : 3'd0;
        default: code = 3'd0;
      endcase
    end
  end
  wire _unused = &{level, row[5:4], col[5:4], 1'b0};
endmodule

module chest_rom (
    input  wire [1:0] frame,     // 0 closed, 1 opening, 2 open
    input  wire [4:0] row,
    input  wire [4:0] col,
    output reg  [1:0] code       // 0=transparent 1=outline 2=wood 3=gold
);
  // placeholder: simple 24x16 box with a gold band
  always @(*) begin
    code = 2'd0;
    if (row>=5'd4 && row<5'd20 && col<5'd24) begin
      if (row==5'd4 || row==5'd19 || col==5'd0 || col==5'd23) code = 2'd1;
      else if (row==5'd11 || row==5'd12)                      code = 2'd3;
      else                                                    code = 2'd2;
    end
  end
  wire _unused = &{frame, 1'b0};
endmodule

module flame_rom (
    input  wire       frame,
    input  wire [3:0] row,
    input  wire [3:0] col,
    output reg  [1:0] code       // 0=transparent 1=bright 2=pale
);
  // placeholder: 8x12 teardrop, two frames differ by one row
  always @(*) begin
    code = 2'd0;
    if (col<4'd8) case (row)
      4'd0 : code = (col==3||col==4) && frame ? 2'd1 : 2'd0;
      4'd1 : code = (col==3||col==4) ? 2'd1 : 2'd0;
      4'd2,4'd3 : code = (col>=2&&col<=5) ? 2'd1 : 2'd0;
      4'd4,4'd5,4'd6 : code = (col>=1&&col<=6) ? ((col>=3&&col<=4)?2'd2:2'd1) : 2'd0;
      4'd7,4'd8 : code = (col>=1&&col<=6) ? ((col>=2&&col<=5)?2'd2:2'd1) : 2'd0;
      4'd9,4'd10: code = (col>=2&&col<=5) ? 2'd2 : 2'd0;
      4'd11: code = (col==3||col==4) ? 2'd2 : 2'd0;
      default: code = 2'd0;
    endcase
  end
endmodule

module heart_rom (
    input  wire [3:0] row,
    input  wire [3:0] col,
    output reg        on         // 1-bit: hearts are a single colour
);
  always @(*) begin
    on = 1'b0;
    if (col<4'd12) case (row)
      4'd1,4'd2 : on = (col>=1&&col<=4)||(col>=7&&col<=10);
      4'd3,4'd4,4'd5 : on = (col>=0&&col<=11);
      4'd6 : on = (col>=1&&col<=10);
      4'd7 : on = (col>=2&&col<=9);
      4'd8 : on = (col>=3&&col<=8);
      4'd9 : on = (col>=4&&col<=7);
      4'd10: on = (col==5||col==6);
      default: on = 1'b0;
    endcase
  end
endmodule

module digit_rom (
    input  wire [3:0] digit,     // 0..9
    input  wire [2:0] row,       // 0..5
    output reg  [3:0] bits       // 4 wide; bits[3] = leftmost
);
  always @(*) begin
    case ({digit, row})
      {4'd0,3'd0}: bits=4'b0110; {4'd0,3'd1}: bits=4'b1001; {4'd0,3'd2}: bits=4'b1001;
      {4'd0,3'd3}: bits=4'b1001; {4'd0,3'd4}: bits=4'b1001; {4'd0,3'd5}: bits=4'b0110;
      {4'd1,3'd0}: bits=4'b0010; {4'd1,3'd1}: bits=4'b0110; {4'd1,3'd2}: bits=4'b0010;
      {4'd1,3'd3}: bits=4'b0010; {4'd1,3'd4}: bits=4'b0010; {4'd1,3'd5}: bits=4'b0111;
      {4'd2,3'd0}: bits=4'b0110; {4'd2,3'd1}: bits=4'b1001; {4'd2,3'd2}: bits=4'b0001;
      {4'd2,3'd3}: bits=4'b0010; {4'd2,3'd4}: bits=4'b0100; {4'd2,3'd5}: bits=4'b1111;
      {4'd3,3'd0}: bits=4'b1110; {4'd3,3'd1}: bits=4'b0001; {4'd3,3'd2}: bits=4'b0110;
      {4'd3,3'd3}: bits=4'b0001; {4'd3,3'd4}: bits=4'b0001; {4'd3,3'd5}: bits=4'b1110;
      {4'd4,3'd0}: bits=4'b1001; {4'd4,3'd1}: bits=4'b1001; {4'd4,3'd2}: bits=4'b1111;
      {4'd4,3'd3}: bits=4'b0001; {4'd4,3'd4}: bits=4'b0001; {4'd4,3'd5}: bits=4'b0001;
      {4'd5,3'd0}: bits=4'b1111; {4'd5,3'd1}: bits=4'b1000; {4'd5,3'd2}: bits=4'b1110;
      {4'd5,3'd3}: bits=4'b0001; {4'd5,3'd4}: bits=4'b0001; {4'd5,3'd5}: bits=4'b1110;
      {4'd6,3'd0}: bits=4'b0110; {4'd6,3'd1}: bits=4'b1000; {4'd6,3'd2}: bits=4'b1110;
      {4'd6,3'd3}: bits=4'b1001; {4'd6,3'd4}: bits=4'b1001; {4'd6,3'd5}: bits=4'b0110;
      {4'd7,3'd0}: bits=4'b1111; {4'd7,3'd1}: bits=4'b0001; {4'd7,3'd2}: bits=4'b0010;
      {4'd7,3'd3}: bits=4'b0100; {4'd7,3'd4}: bits=4'b0100; {4'd7,3'd5}: bits=4'b0100;
      {4'd8,3'd0}: bits=4'b0110; {4'd8,3'd1}: bits=4'b1001; {4'd8,3'd2}: bits=4'b0110;
      {4'd8,3'd3}: bits=4'b1001; {4'd8,3'd4}: bits=4'b1001; {4'd8,3'd5}: bits=4'b0110;
      {4'd9,3'd0}: bits=4'b0110; {4'd9,3'd1}: bits=4'b1001; {4'd9,3'd2}: bits=4'b0111;
      {4'd9,3'd3}: bits=4'b0001; {4'd9,3'd4}: bits=4'b0001; {4'd9,3'd5}: bits=4'b0110;
      default: bits=4'b0000;
    endcase
  end
endmodule
// module ei_generator (
//     input  wire [9:0] x,
//     input  wire [9:0] y,
//     input  wire [2:0] level,
//     input  wire [1:0] mood_anim,
//     input  wire [1:0] bob,
//     output wire       px_on,
//     output wire [2:0] px_code
// );

//     //---------------------------------------------------------
//     // Middelpunt
//     //---------------------------------------------------------
//     wire signed [11:0] dx = $signed({2'b00, x}) - 12'sd320;
//     wire signed [11:0] dy = $signed({2'b00, y}) - 12'sd240;

//     //---------------------------------------------------------
//     // Hoogte en rand
//     //---------------------------------------------------------
//     localparam [11:0] B    = 12'd166;
//     localparam [11:0] RAND = 12'd6;

//     //---------------------------------------------------------
//     // 64-bit
//     //---------------------------------------------------------
//     wire signed [63:0] dx_ext = dx;
//     wire signed [63:0] dy_ext = dy;
//     wire signed [63:0] b_ext  = B;

//     //---------------------------------------------------------
//     // Kwadraten
//     //---------------------------------------------------------
//     wire signed [63:0] dx_sq = dx_ext * dx_ext;
//     wire signed [63:0] dy_sq = dy_ext * dy_ext;

//     wire signed [63:0] b_sq = b_ext * b_ext;

//     //---------------------------------------------------------
//     // Dynamische breedte
//     //
//     // boven ≈ 90 px
//     // midden ≈ 111 px
//     // onder ≈ 132 px
//     //---------------------------------------------------------
//     wire signed [63:0] a_dyn =
//         64'd90 + (dy_ext + 64'd166) / 8;

//     wire signed [63:0] a_dyn_out = a_dyn + RAND;

//     wire signed [63:0] a_dyn_sq     = a_dyn * a_dyn;
//     wire signed [63:0] a_dyn_out_sq = a_dyn_out * a_dyn_out;

//     //---------------------------------------------------------
//     // Binnenbox
//     //---------------------------------------------------------
//     wire binnen_in =
//         (dx_ext >= -a_dyn) &&
//         (dx_ext <=  a_dyn) &&
//         (dy_ext >= -b_ext) &&
//         (dy_ext <=  b_ext);

//     wire binnen_out =
//         (dx_ext >= -a_dyn_out) &&
//         (dx_ext <=  a_dyn_out) &&
//         (dy_ext >= -(b_ext+RAND)) &&
//         (dy_ext <=  (b_ext+RAND));

//     //---------------------------------------------------------
//     // Eivorm
//     //---------------------------------------------------------
//     wire in_ei =
//         binnen_in &&
//         ((dx_sq * b_sq + dy_sq * a_dyn_sq)
//             <= (a_dyn_sq * b_sq));

//     wire signed [63:0] b_out = b_ext + RAND;
//     wire signed [63:0] b_out_sq = b_out * b_out;

//     wire in_ei_out =
//         binnen_out &&
//         ((dx_sq * b_out_sq + dy_sq * a_dyn_out_sq)
//             <= (a_dyn_out_sq * b_out_sq));

//     //---------------------------------------------------------
//     // Output
//     //---------------------------------------------------------
//     assign px_on = 1'b1;

//     // 2 = groen
//     // 0 = zwart
//     // 1 = wit

//     assign px_code =
//         in_ei      ? 3'd2 :
//         in_ei_out  ? 3'd0 :
//                      3'd1;

//     wire _unused = &{level, mood_anim, bob, 1'b0};

// endmodule
`default_nettype none

module ei_generator (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [2:0] level,
    input  wire [1:0] mood_anim,
    input  wire [1:0] bob,
    output wire       px_on,
    output wire [2:0] px_code
);

    // Ongebruikte signalen direct afvangen
    wire _unused = &{level, mood_anim, bob, 1'b0};

    //---------------------------------------------------------
    // Middelpunt
    //---------------------------------------------------------
    wire signed [11:0] dx = $signed({2'b00,x}) - 12'sd320;
    wire signed [11:0] dy = $signed({2'b00,y}) - 12'sd240;

    //---------------------------------------------------------
    // Parameters
    //---------------------------------------------------------
    localparam signed [63:0] B = 64'd145;
    localparam signed [63:0] RAND = 64'd8;

    //---------------------------------------------------------
    // 64-bit & Kwadraten
    //---------------------------------------------------------
    wire signed [63:0] dx64 = dx;
    wire signed [63:0] dy64 = dy;
    wire signed [63:0] dx_sq = dx64 * dx64;
    wire signed [63:0] dy_sq = dy64 * dy64;
    wire signed [63:0] b_sq = B * B;

    // Dynamische breedte (kwadratische eivorm)
    wire signed [63:0] t = dy64 + 64'd166;
    wire signed [63:0] a_dyn = 64'd90 + (t * t) / 2500;
    wire signed [63:0] a_dyn_sq = a_dyn * a_dyn;

    //---------------------------------------------------------
    // Buitenste ei
    //---------------------------------------------------------
    wire signed [63:0] a_out = a_dyn + RAND;
    wire signed [63:0] b_out = B + RAND;

    wire signed [63:0] a_out_sq = a_out * a_out;
    wire signed [63:0] b_out_sq = b_out * b_out;

    //---------------------------------------------------------
    // Binnenboxen
    //---------------------------------------------------------
    wire box_in =
        (dx64 >= -a_dyn) &&
        (dx64 <=  a_dyn) &&
        (dy64 >= -B) &&
        (dy64 <=  B);

    wire box_out =
        (dx64 >= -a_out) &&
        (dx64 <=  a_out) &&
        (dy64 >= -b_out) &&
        (dy64 <=  b_out);

    //---------------------------------------------------------
    // Ovalen
    //---------------------------------------------------------
    wire in_ei =
        box_in &&
        ((dx_sq * b_sq + dy_sq * a_dyn_sq)
            <= (a_dyn_sq * b_sq));

    wire in_ei_out =
        box_out &&
        ((dx_sq * b_out_sq + dy_sq * a_out_sq)
            <= (a_out_sq * b_out_sq));

    //---------------------------------------------------------
    // Vlekjes binnen het ei
    //---------------------------------------------------------
    wire signed [63:0] vlek1_dx = dx64 - 64'sd25;
    wire signed [63:0] vlek1_dy = dy64 - (-64'sd60);
    wire vlek1 = (vlek1_dx * vlek1_dx + vlek1_dy * vlek1_dy) <= (64'sd27 * 64'sd27);

    wire signed [63:0] vlek2_dx = dx64 - 64'sd30;
    wire signed [63:0] vlek2_dy = dy64 - 64'sd70;
    wire vlek2 = (vlek2_dx * vlek2_dx + vlek2_dy * vlek2_dy) <= (64'sd35 * 64'sd35);

    wire signed [63:0] vlek3_dx = dx64 + 64'sd50;
    wire signed [63:0] vlek3_dy = dy64 - 64'sd20;
    wire vlek3 = (vlek3_dx * vlek3_dx + vlek3_dy * vlek3_dy) <= (64'sd30 * 64'sd30);

    //---------------------------------------------------------
    // Rand & Output
    //---------------------------------------------------------
    wire border = in_ei_out && !in_ei;

    assign px_on = 1'b1;

    assign px_code =
        border                       ? 3'd0 : 
        (in_ei && (vlek1 || vlek2 || vlek3)) ? 3'd2 : 
        in_ei                        ? 3'd1 : 
                                       3'd1;  

endmodule`default_nettype none
// ---------------------------------------------------------------------------
// 5 knoppen:            FOOD
//             WATER    level up    SLEEP
//                       GAME
// zie foto buttons 
// zwarte rand, vulling, highlight level up

// ---------------------------------------------------------------------------
module draw_buttons (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [1:0] evolve_now,         // of level_up border
    output wire       px_on,
    output wire [2:0] px_code       // 
);

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{x, y, fill, 1'b0};
endmodule`default_nettype none
// ---------------------------------------------------------------------------
// hearts + overflow, 5 hearts, red
// colors: 0: red, 1: text for overflow
// next to eachother (left text and right hearts), hearts appear 
// ---------------------------------------------------------------------------
module hearts (
    input  wire [9:0] pix_x,        // ABSOLUTE screen coordinates
    input  wire [9:0] pix_y,
    input  wire [1:0] hearts,
    input             overflow,
    output wire       px_on,
    output wire [1:0] px_code       
);

// 

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{pix_x, pix_y, hearts, 1'b0};
endmodule
`default_nettype none
// ---------------------------------------------------------------------------
// SATISFACTION
// ---------------------------------------------------------------------------
module satisfactionbar (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [2:0] sat,         // how many of the 5 segments are lit
    output wire       px_on,
    output wire [2:0] px_code        // 0     = frame + dividers
                                    // 1..5  = segment 0..4, ramp colour
                                    // 6     = highlight ring on the selected
                                    // 7     = dark / unlit segment
);
  // satisfaction: 5 levels an satisfaction, wordt gwn meegegeven via aantal bit (5 vakjes nodig) 
  // ======================= mode ===========================================
  // 1 = CURSOR : all five keep their colour, a white ring marks `sat`.
  // 0 = FILL   : segments 0..sat are coloured, the rest go dark (code 7),
  //              no ring.  Reads faster from a distance; you lose sight of
  //              the top of the scale.  Flip this one bit and re-render.
  localparam CURSOR_MODE = 1'b1;
 
  // ======================= geometry =======================================
  localparam [9:0] NSEG  = 10'd5;
  localparam [9:0] FRAME = 10'd3;      // border thickness
  localparam [9:0] PITCH = 10'd32;     // segment stride -- MUST be a power of 2
  localparam [9:0] SEG_W = 10'd28;     // segment body; PITCH-SEG_W = 4px divider
  localparam [9:0] SEG_H = 10'd18;     // segment height
  localparam [9:0] RING  = 10'd2;      // thickness of the selection ring
 
  // Outer size.  The last segment needs no divider after it, hence the -gap.
  localparam [9:0] BAR_W = FRAME + (NSEG * PITCH) - (PITCH - SEG_W) + FRAME;
  localparam [9:0] BAR_H = FRAME + SEG_H + FRAME;
 
  // ======================= where are we ===================================
  // Local coords wrap to ~1023 left of / above the origin, so an unsigned
  // "< BAR_W" doubles as the left/top edge test.  No signed compare needed.
  wire in_bar = (x < BAR_W) && (y < BAR_H);
 
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);
 
  wire [9:0] rx  = x - FRAME;          // 0-based inside the frame
  wire [2:0] idx = rx[7:5];            // which segment: rx / PITCH, as a slice
  wire [4:0] sx  = rx[4:0];            // position within this segment's pitch
 
  wire in_seg = in_inner && (sx < SEG_W[4:0]) && (idx < NSEG[2:0]);
 
  // ======================= selection ======================================
  wire selected = (idx == sat);
 
  // White inset ring around the selected segment.
  wire ring = CURSOR_MODE && in_seg && selected &&
              ((sx < RING[4:0]) || (sx >= SEG_W[4:0] - RING[4:0]) ||
               (y  < FRAME + RING) || (y >= BAR_H - FRAME - RING));
 
  // In CURSOR mode every segment shows its colour; in FILL mode only up to
  // and including the current level.
  wire coloured = CURSOR_MODE ? 1'b1 : (idx <= sat);
 
  // ======================= output =========================================
  // The whole rectangle is opaque: frame and dividers share code 0, so the
  // bar reads as one solid object instead of showing the background through.
  assign px_on   = in_bar;
  assign px_code = !in_seg  ? 3'd0             :   // frame + dividers
                   ring     ? 3'd6             :   // selection ring
                   coloured ? (idx + 3'd1)     :   // ramp colour 1..5
                              3'd7;                // dark / unlit
endmodule

 
`default_nettype none

// ---------------------------------------------------------------------------
// COINBAR -- VERTICAAL.  8 vakjes, vult van ONDER naar BOVEN.
//
// SCHAAL: coins is 10 bits en loopt tot COINS_MAX (1000).  Om de deling
// "hoeveel vakjes zijn vol" gratis te houden delen we op 1024 in plaats van
// op 1000: 8 vakjes x 128 coins, dus coins[9:7] IS de vakjesteller.
// Gevolg: het bovenste vakje begint bij 896; bij coins >= COINS_MAX zetten
// we alles aan zodat de balk bij het maximum echt vol staat.
//

// GEOMETRIE: FRAME / SEG_W / SEG_H / NSEG mag je vrij aanpassen.
// PITCH MOET een macht van 2 blijven -- daarop rust idx = ry[6:4].
//
// px_code: 0 = frame + schotjes   (donker)
//          1 = leeg vakje         (donkergrijs)
//          2 = vol vakje          (geel)
// ---------------------------------------------------------------------------
module coinbar (
    input  wire [9:0] x,            // local (pix_x - COINBAR_X)
    input  wire [9:0] y,            // local (pix_y - COINBAR_Y)
    input  wire [9:0] coins,        // 0..1000, uit dragon_state
    output wire       px_on,
    output wire [1:0] px_code
);
  // ======================= schaal =========================================
  localparam [9:0] COINS_MAX = 10'd1000;   // waar de balk vol staat
 
  // ======================= geometrie ======================================
  localparam [9:0] NSEG  = 10'd8;      // 8 vakjes onder elkaar
  localparam [9:0] FRAME = 10'd3;      // randdikte
  localparam [9:0] PITCH = 10'd16;     // stride per vakje -- MOET macht van 2
  localparam [9:0] SEG_H = 10'd14;     // vakjehoogte; 16-14 = 2px schotje
  localparam [9:0] SEG_W = 10'd18;     // vakjebreedte
 
  // Onder het laatste vakje komt geen schotje meer: -(PITCH-SEG_H).
  localparam [9:0] BAR_W = FRAME + SEG_W + FRAME;                            // 24
  localparam [9:0] BAR_H = FRAME + (NSEG * PITCH) - (PITCH - SEG_H) + FRAME; // 132
 
  // ======================= waar zijn we ===================================
  // Boven/links van de origin wrapt de local coord naar ~1023, dus "< BAR_H"
  // test meteen ook de boven- en linkerrand.  Geen signed compare nodig.
  wire in_bar   = (x < BAR_W) && (y < BAR_H);
 
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);
 
  wire [9:0] ry  = y - FRAME;          // 0-based binnen de rand
  wire [2:0] idx = ry[6:4];            // ry / PITCH -> vakje 0 (boven) .. 7 (onder)
  wire [3:0] sy  = ry[3:0];            // positie binnen dit vakje
 
  wire in_seg = in_inner && (sy < SEG_H[3:0]);
 
  // ======================= hoeveel vakjes vol =============================
  // coins[9:7] = coins / 128 = aantal volle vakjes (0..7).  Gratis: dit is
  // gewoon een stuk van de bus, geen deler.
  wire [2:0] nfull = coins[9:7];
  wire       maxed = (coins >= COINS_MAX);
 
  // Let op: 8 past niet in 3 bits, dus deze vergelijking MOET 4 bits breed
  // zijn -- anders is first_lit bij nfull==0 gelijk aan 0 en licht alles op.
  wire [3:0] first_lit = 4'd8 - {1'b0, nfull};
 
  wire lit = in_seg && (maxed || ({1'b0, idx} >= first_lit));
 
  // ======================= output =========================================
  assign px_on   = in_bar;
  assign px_code = !in_seg ? 2'd0 :    // frame + schotjes
                   lit     ? 2'd2 :    // vol -> geel
                             2'd1;     // leeg vakje
endmodule



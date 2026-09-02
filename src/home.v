`default_nettype none
// ---------------------------------------------------------------------------
// HOME SCREEN + MODE SWITCHING.  OWNER: PERSON A.
//
// The hub the player lives on.  Every action has its own button, so there is
// no cursor: the player just presses what they want.
//
// Button map (see RENDER_GUIDE.md), on the HOME screen:
//     1 EVOLVE   4 FEED   5 DRINK   6 SLEEP   7 PLAY
//     0, 2, 3 unused here (chest_game uses 1/3 as its chest cursor)
//
// This module is the ONLY writer of `mode`.  renderer.v is the only reader.
// ---------------------------------------------------------------------------
module home (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire [7:0] btn_pressed,     // one-frame pulses from buttons.v
    input  wire       game_over,       // from dragon_state (a LEVEL, not a pulse)
    input  wire       you_win,         // from dragon_state (a LEVEL, not a pulse)
    input  wire       minigame_done,   // from chest_game (one-frame pulse)
    input  wire [9:0] coins,           // unused: dragon_state checks the price
    input  wire       fx_on, 

    output reg  [2:0] mode,            // see localparams below
    output reg  [2:0] menu_sel,        // kept for the interface; always 0 now
    output reg        act_feed,        // one-frame pulses -> balance.v
    output reg        act_drink,
    output reg        act_sleep,
    output reg        act_minigame,    // the 4th combo action
    output reg        req_evolve,      // -> dragon_state
    output reg        restart,
    output reg  [2:0] egg_frame,       // 0=whole, 1-4=cracks, 5=flashing
    output reg  [9:0] flash_r          // flash refresh rate
);
  localparam [2:0] M_TITLE    = 3'd0,
                   M_EGG      = 3'd1,
                   M_HOME     = 3'd2,
                   M_CHEST    = 3'd3,
                   M_GAMEOVER = 3'd4,
                   M_YOU_WIN  = 3'd5;

  // button bit names, so the code reads like the controller card
  localparam BTN_EVOLVE = 3'd1,
             BTN_FEED   = 3'd4,
             BTN_DRINK  = 3'd5,
             BTN_SLEEP  = 3'd6,
             BTN_PLAY   = 3'd7;

  // any button at all -- used on the title / end screens
  wire any_btn = |btn_pressed;

  reg [6:0] egg_timer;

    // egg_frame combinatorisch uit egg_timer.  LET OP: egg_timer == 0 betekent
  // twee dingen -- "nog niet begonnen" (op TITLE) en "klaar met barsten" (in
  // M_EGG, terwijl de flits loopt).  Daarom eerst op mode gaten, anders
  // springt het ei tijdens de flits terug naar heel en begint het te hoppen.
  always @(*) begin
    if      (mode != M_EGG)      egg_frame = 3'd0; // TITLE: heel ei, hopt
    else if (egg_timer == 7'd0)  egg_frame = 3'd5; // klaar; flits dekt het af
    else if (egg_timer >  7'd72) egg_frame = 3'd1;
    else if (egg_timer >  7'd54) egg_frame = 3'd2;
    else if (egg_timer >  7'd36) egg_frame = 3'd3;
    else if (egg_timer >  7'd18) egg_frame = 3'd4;
    else                         egg_frame = 3'd5;   
  end
  always @(posedge clk) begin
    if (!rst_n) begin
      mode         <= M_TITLE;
      menu_sel     <= 3'd0;
      act_feed     <= 1'b0;
      act_drink    <= 1'b0;
      act_sleep    <= 1'b0;
      act_minigame <= 1'b0;
      req_evolve   <= 1'b0;
      restart      <= 1'b0;
      egg_timer    <= 7'd0;
      flash_r      <= 10'd0;
    end else if (frame_tick) begin
      // every pulse defaults to 0; the case below may raise one for one frame
      act_feed     <= 1'b0;
      act_drink    <= 1'b0;
      act_sleep    <= 1'b0;
      act_minigame <= 1'b0;
      req_evolve   <= 1'b0;
      restart      <= 1'b0;
      case (mode)

        // -------------------------------------------------------------
        M_TITLE: begin
          // any button starts a new game.  restart clears the stats.
          if (any_btn) begin
            egg_timer <= 7'd90;   // 90 frames = 1.5 s barsten
            mode      <= M_EGG;
          end
        end
        // -------------------------------------------------------------
        M_EGG: begin
          if (egg_timer != 7'd0) begin
            egg_timer <= egg_timer - 7'd1;          // barst groeit
          end else if (flash_r < 10'd760) begin
            flash_r <= flash_r + 10'd16;             // flits groeit
          end else begin
            restart <= 1'b1;
            flash_r <= 10'd0;
            mode    <= M_HOME;
          end
        end
        // -------------------------------------------------------------
        M_HOME: begin
          if (game_over)      mode <= M_GAMEOVER;
          else if (you_win)   mode <= M_YOU_WIN;
          else if (!fx_on) begin        // <-- knoppen dood tijdens een effect
            if (btn_pressed[BTN_PLAY]) begin
              act_minigame <= 1'b1; mode <= M_CHEST;
            end
            else if (btn_pressed[BTN_EVOLVE]) req_evolve <= 1'b1;
            else if (btn_pressed[BTN_FEED])   act_feed   <= 1'b1;
            else if (btn_pressed[BTN_DRINK])  act_drink  <= 1'b1;
            else if (btn_pressed[BTN_SLEEP])  act_sleep  <= 1'b1;
          end
        end

        // -------------------------------------------------------------
        M_CHEST: begin
          // chest_game owns everything here, including its own MENU phase
          // (buttons 1/3 cursor, 6 open/continue, 7 bank and leave).
          // We only watch for the way out and for death.
          if (game_over)          mode <= M_GAMEOVER;
          else if (minigame_done) mode <= M_HOME;
        end

        // -------------------------------------------------------------
        M_GAMEOVER: begin
          // NOTE: do not test game_over here -- it is still high until the
          // restart pulse lands, and we would bounce straight back.
          if (any_btn) mode <= M_TITLE;
        end

        // -------------------------------------------------------------
        M_YOU_WIN: begin
          if (any_btn) mode <= M_TITLE;
        end

        // -------------------------------------------------------------
        default: mode <= M_HOME;
      endcase
    end
  end

  wire _unused = &{coins, 1'b0};
endmodule
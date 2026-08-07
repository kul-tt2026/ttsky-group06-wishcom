`default_nettype none
// ---------------------------------------------------------------------------
// HOME SCREEN + MODE SWITCHING.  OWNER: PERSON A.
//
// The hub the player lives on.  Five menu options: FEED DRINK SLEEP PLAY EVOLVE.
// The four care buttons also work directly, whatever the cursor is on.
// PLAY hands control to the chest minigame; minigame_done hands it back.
//
// Button map (fixed, see SIGNALS.md): 0 FEED 1 DRINK 2 SLEEP 3 PLAY
//                                     4 LEFT 5 RIGHT 6 SELECT 7 START
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
    input  wire [9:0] coins,           // unused for now: dragon_state checks price

    output reg  [2:0] mode,            // see localparams below
    output reg  [2:0] menu_sel,        // cursor 0..4
    output reg        act_feed,        // one-frame pulses -> balance.v
    output reg        act_drink,
    output reg        act_sleep,
    output reg        act_minigame,    // the 4th combo action
    output reg        req_evolve,      // -> dragon_state
    output reg        restart          // -> dragon_state (one frame only!)
);
  localparam [2:0] M_TITLE    = 3'd0,
                   M_HOME     = 3'd1,
                   M_CHEST    = 3'd2,
                   M_GAMEOVER = 3'd3,
                   M_YOU_WIN  = 3'd4;

  localparam [2:0] SEL_FEED  = 3'd0, SEL_DRINK = 3'd1, SEL_SLEEP = 3'd2,
                   SEL_PLAY  = 3'd3, SEL_EVOLVE = 3'd4;
  localparam [2:0] SEL_MAX = 3'd4;

  // any button at all -- used on the title / end screens
  wire any_btn = |btn_pressed;

  always @(posedge clk) begin
    if (!rst_n) begin
      mode         <= M_TITLE;
      menu_sel     <= SEL_FEED;
      act_feed     <= 1'b0;
      act_drink    <= 1'b0;
      act_sleep    <= 1'b0;
      act_minigame <= 1'b0;
      req_evolve   <= 1'b0;
      restart      <= 1'b0;
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
            restart <= 1'b1;
            mode    <= M_HOME;
          end
        end

        // -------------------------------------------------------------
        M_HOME: begin
          // end conditions first: they are levels, so test before buttons
          if (game_over)      mode <= M_GAMEOVER;
          else if (you_win)   mode <= M_YOU_WIN;
          else begin
            // cursor (cosmetic + used by SELECT)
            if (btn_pressed[4] && menu_sel != 3'd0)   menu_sel <= menu_sel - 3'd1;
            if (btn_pressed[5] && menu_sel != SEL_MAX) menu_sel <= menu_sel + 3'd1;

            // direct care buttons -- always work, wherever the cursor is
            if (btn_pressed[0]) act_feed  <= 1'b1;
            if (btn_pressed[1]) act_drink <= 1'b1;
            if (btn_pressed[2]) act_sleep <= 1'b1;
            if (btn_pressed[3]) begin
              act_minigame <= 1'b1;      // counts as the 4th combo action
              mode         <= M_CHEST;
            end

            // SELECT acts on whatever the cursor is on
            if (btn_pressed[6]) begin
              case (menu_sel)
                SEL_FEED:   act_feed   <= 1'b1;
                SEL_DRINK:  act_drink  <= 1'b1;
                SEL_SLEEP:  act_sleep  <= 1'b1;
                SEL_PLAY:   begin act_minigame <= 1'b1; mode <= M_CHEST; end
                SEL_EVOLVE: req_evolve <= 1'b1;  // dragon_state checks the price
                default: ;
              endcase
            end
          end
        end

        // -------------------------------------------------------------
        M_CHEST: begin
          // chest_game owns everything here, including its own CONTINUE phase.
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

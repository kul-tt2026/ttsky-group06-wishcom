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
    input  wire [9:0] coins,           // to grey out evolve when unaffordable

    output reg  [2:0] mode,            // 0 TITLE, 1 HOME, 2 CHEST, 3 GAMEOVER, 4 CONTINUE 5 YOU_WIN
    output reg  [2:0] menu_sel,        // cursor over the five options
    output reg        act_feed,        // one-frame pulses ->  balance.v
    output reg        act_drink,
    output reg        act_sleep,
    output reg        act_minigame,
    output reg        req_evolve,      // -> dragon_state
    output reg        restart          // -> dragon_state (new game reset)
);
  localparam M_TITLE=2'd0, M_HOME=3'd1, M_CHEST=3'd2, M_GAMEOVER=3'd3, M_CONTINUE=3'd4, M_YOU_WIN=3'd5;

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

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

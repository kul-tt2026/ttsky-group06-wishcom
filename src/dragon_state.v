`default_nettype none
// ---------------------------------------------------------------------------
// THE DRAGON'S STATS. 
// The only file that ever changes hearts, satisfaction, coins or level.
// ---------------------------------------------------------------------------
module dragon_state (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire       restart,

    input  wire       req_heart_gain,        // from balance
    input  wire       req_heart_lose,
    input  wire       req_sat_up,
    input  wire       req_sat_down,

    input  wire       req_coins_add,         // from chest_game
    input  wire [9:0] coins_amount,
    input  wire       req_heart_lose_chest,

    input  wire       req_evolve,            // from home

    output reg  [2:0] hearts,                // 0..5
    output reg  [2:0] satisfaction,          // 0 miserable .. 5 happy
    output reg  [9:0] coins,
    output reg  [2:0] level,                 // 1..7
    output reg        game_over,
    output reg        you_win,
    output reg        overflow,              // "already at max" flash
    output wire       evolve_now,            // renderer: light up the option
    output wire       evolved
);
  localparam MAX_HEARTS = 3'd5;
  localparam MAX_SAT    = 3'd4;
  localparam MAX_LEVEL  = 3'd7;
  localparam COIN_CAP = 10'd999;
  localparam [2:0] FORM_A = 3'd3;
  localparam [2:0] FORM_B = 3'd7;

  // ---- evolve price per level -------------------------------------------
  // A case, not a shift: `20 << level[1:0]` wraps at level 4 back to 20.
  // The last step (6 -> 7) costs 255, which is the whole purse.
  reg [9:0] evolve_price;
  always @(*) case (level)
    3'd1: evolve_price = 10'd90;
    3'd2: evolve_price = 10'd220;
    3'd3: evolve_price = 10'd180;
    3'd4: evolve_price = 10'd250;
    3'd5: evolve_price = 10'd340;
    3'd6: evolve_price = 10'd400;
    3'd7: evolve_price = 10'd999;   // final evolution
    default: evolve_price = 10'd999;   // already at max level
  endcase

  assign evolve_now = (coins >= evolve_price);

  // satisfaction at rock bottom: another drop costs a heart instead
  wire sat_floor_hit = req_sat_down && (satisfaction == 3'd0);
  wire lose_any = req_heart_lose | req_heart_lose_chest | sat_floor_hit;
  wire do_evolve = req_evolve && (coins >= evolve_price);
  assign evolved = do_evolve;
  wire heal_up = do_evolve && (level == FORM_A - 1 || level == FORM_B - 1);
  reg [6:0] overflow_timer;
  wire [10:0] coins_na_evolve = do_evolve ? ({1'b0, coins} - {1'b0, evolve_price})
                                        : {1'b0, coins};
  wire [10:0] add_amt   = req_coins_add ? {1'b0, coins_amount} : 11'd0;
  wire [10:0] coins_sum = coins_na_evolve + add_amt;
  

  always @(posedge clk) begin
    if (!rst_n || restart) begin
      hearts         <= MAX_HEARTS;
      satisfaction   <= 3'd2;
      coins          <= 10'd0;
      level          <= 3'd1;
      game_over      <= 1'b0;
      you_win        <= 1'b0;
      overflow       <= 1'b0;
      overflow_timer <= 7'd0;
    end else if (frame_tick && !game_over && !you_win) begin

      // ---- overflow flash timer ----------------------------------------
      if (overflow_timer != 0) begin
        overflow_timer <= overflow_timer - 7'd1;
        if (overflow_timer == 7'd1) overflow <= 1'b0;
      end

      // ---- hearts: ONE chain, so simultaneous requests resolve on purpose
      if (heal_up) begin
        hearts <= MAX_HEARTS;
      end else if (lose_any) begin
          if (hearts <= 3'd1) begin
            hearts    <= 3'd0;
            game_over <= 1'b1;
          end else
            hearts <= hearts - 3'd1;
        end else if (req_heart_gain) begin
          if (hearts != MAX_HEARTS)
            hearts <= hearts + 3'd1;
          else begin
            overflow       <= 1'b1;
            overflow_timer <= 7'd120;
        end
      end

      // ---- satisfaction -------------------------------------------------
      if (req_sat_up) begin
        if (satisfaction != MAX_SAT)
          satisfaction <= satisfaction + 3'd1;
        else begin
          overflow       <= 1'b1;
          overflow_timer <= 7'd120;
        end
      end else if (req_sat_down && satisfaction != 3'd0) begin
        satisfaction <= satisfaction - 3'd1;
      end
      // (at 0, sat_floor_hit already took a heart above)

      // ---- coins ---------------------------------------------------------
      
      if (do_evolve || req_coins_add) begin
        if (coins_sum >= {1'b0, COIN_CAP}) begin
          coins <= COIN_CAP; overflow <= 1'b1; overflow_timer <= 7'd120;
        end else coins <= coins_sum[9:0];
      end    
      



      // ---- level ---------------------------------------------------------
      if (do_evolve) begin
        if (level == MAX_LEVEL) begin
          you_win <= 1'b1;
        end else begin
          level <= level + 3'd1;
        end
      end
    end

  end
endmodule
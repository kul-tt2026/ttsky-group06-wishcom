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
// ---------------------------------------------------------------------------
// THE BALANCE GAME.
// ---------------------------------------------------------------------------
module balance (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,     // 60Hz tick for game loop timing
    input  wire       restart,

    input  wire       act_feed,        // pulses from home.v
    input  wire       act_drink,
    input  wire       act_sleep,
    input  wire       act_minigame,    // 4e actie: minigame gespeeld
    input  wire [2:0] satisfaction,    

    output reg        req_heart_gain,  // -> dragon_state
    output reg        req_heart_lose,
    output reg        req_sat_up,
    output reg        req_sat_down,

    output reg  [1:0] combo_len        // -> renderer (progress bar 0..3)
);

  // Exact 4 acties
  localparam A_MINIGAME = 2'd0, 
             A_FEED     = 2'd1, 
             A_DRINK    = 2'd2, 
             A_SLEEP    = 2'd3;

  wire        any_act_in  = act_feed | act_drink | act_sleep | act_minigame;
  wire [1:0]  this_act_in = act_feed     ? A_FEED     :
                            act_drink    ? A_DRINK    :
                            act_sleep    ? A_SLEEP    :
                            act_minigame ? A_MINIGAME : A_MINIGAME;

  // Latch registers om snelle knoppulsen op te vangen tussen frame_ticks in
  reg        act_latched;
  reg  [1:0] latched_action;

  // Interne statusregisters
  reg [1:0] history [0:5];        // Schuifregister voor de laatste 6 acties
  reg [2:0] actions_count;        // Totaal aantal acties uitgevoerd (max 6)

  // Bepaal welke actie NU uitgevoerd wordt op deze frame_tick
  wire       has_act     = act_latched | any_act_in;
  wire [1:0] current_act = act_latched ? latched_action : this_act_in;

  // Next-state reconstructie voor de laatste 6 acties (als has_act == 1)
  wire [1:0] next_hist [0:5];
  assign next_hist[0] = current_act;
  assign next_hist[1] = history[0];
  assign next_hist[2] = history[1];
  assign next_hist[3] = history[2];
  assign next_hist[4] = history[3];
  assign next_hist[5] = history[4];

  // 1. Directe controle op 4 unieke acties in next_hist[0:3]
  wire next_unique_4 = (next_hist[0] != next_hist[1]) && 
                       (next_hist[0] != next_hist[2]) && 
                       (next_hist[0] != next_hist[3]) && 
                       (next_hist[1] != next_hist[2]) && 
                       (next_hist[1] != next_hist[3]) && 
                       (next_hist[2] != next_hist[3]);

  // 2. Directe controle op ontbrekende actie in next_hist[0:5]
  reg [2:0] next_count_00, next_count_01, next_count_10, next_count_11;
  always @(*) begin
    // actions_count telt vóór de flank. Met de huidige actie erbij zijn er (actions_count + 1) acties gedaan.
    next_count_00 = ((actions_count >= 3'd0 && next_hist[0] == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_hist[1] == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_hist[2] == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_hist[3] == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_hist[4] == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_hist[5] == A_MINIGAME) ? 3'd1 : 3'd0);

    next_count_01 = ((actions_count >= 3'd0 && next_hist[0] == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_hist[1] == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_hist[2] == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_hist[3] == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_hist[4] == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_hist[5] == A_FEED) ? 3'd1 : 3'd0);

    next_count_10 = ((actions_count >= 3'd0 && next_hist[0] == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_hist[1] == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_hist[2] == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_hist[3] == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_hist[4] == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_hist[5] == A_DRINK) ? 3'd1 : 3'd0);

    next_count_11 = ((actions_count >= 3'd0 && next_hist[0] == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_hist[1] == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_hist[2] == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_hist[3] == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_hist[4] == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_hist[5] == A_SLEEP) ? 3'd1 : 3'd0);
  end

  wire next_missing_an_action = (next_count_00 == 3'd0) || (next_count_01 == 3'd0) || 
                                (next_count_10 == 3'd0) || (next_count_11 == 3'd0);

  // 3. Bitmasker berekening voor unieke acties in de laatste 3 stappen (voor combo_len weergave)
  wire [3:0] seen_recent = (4'b1 << history[0]) | 
                           (4'b1 << history[1]) | 
                           (4'b1 << history[2]);
  wire [2:0] num_unique_3 = {2'b0, seen_recent[0]} + 
                            {2'b0, seen_recent[1]} + 
                            {2'b0, seen_recent[2]} + 
                            {2'b0, seen_recent[3]};

  wire current_unique_4 = (history[0] != history[1]) && (history[0] != history[2]) && 
                          (history[0] != history[3]) && (history[1] != history[2]) && 
                          (history[1] != history[3]) && (history[2] != history[3]);

  // Update combo_len voor de renderer
  always @(*) begin
    if (actions_count >= 3'd4 && current_unique_4) begin
      combo_len = 2'd3;           // Combo compleet (4 unieke)
    end else begin
      case (num_unique_3)
        3'd2:    combo_len = 2'd1;
        3'd3:    combo_len = 2'd2;
        default: combo_len = 2'd0;
      endcase
    end
  end

  // --- STAP 1: Acties direct vangen op de snelle klok ---
  always @(posedge clk) begin
    if (!rst_n || restart) begin
      act_latched    <= 1'b0;
      latched_action <= A_MINIGAME;
    end else begin
      if (any_act_in) begin
        act_latched    <= 1'b1;
        latched_action <= this_act_in;
      end else if (frame_tick) begin
        act_latched    <= 1'b0;
        latched_action <= A_MINIGAME;
      end
    end
  end

  // --- STAP 2: Spellogica verwerken op de vertraagde frame_tick ---
  integer idx;
  always @(posedge clk) begin
    if (!rst_n || restart) begin
      for (idx = 0; idx < 6; idx = idx + 1) begin
        history[idx] <= 2'b00;
      end
      actions_count  <= 3'd0;
      req_heart_gain <= 1'b0;
      req_heart_lose <= 1'b0;
      req_sat_up     <= 1'b0;
      req_sat_down   <= 1'b0;
    end else if (frame_tick) begin
      // Pulse reset
      req_heart_gain <= 1'b0;
      req_heart_lose <= 1'b0;
      req_sat_up     <= 1'b0;
      req_sat_down   <= 1'b0;

      if (has_act) begin
        // Schuifregister bijwerken
        for (idx = 5; idx > 0; idx = idx - 1) begin
          history[idx] <= history[idx-1];
        end
        history[0] <= current_act;

        if (actions_count < 3'd6) begin
          actions_count <= actions_count + 1'b1;
        end

        // --- EVALUATIE LOGICA HUMEUR & PULSEN (Direct op actie 4 en actie 6) ---

        // A) Stijgen: Er zijn al 3 acties gedaan EN de huidige 4e maakt 4 unieke
        if ((actions_count >= 3'd3) && next_unique_4) begin
          req_sat_up <= 1'b1;
        end 
        // B) Dalen: Er zijn al minstens 5 acties gedaan EN de huidige 6e mist een actie
        else if ((actions_count >= 3'd5) && next_missing_an_action) begin
          req_sat_down <= 1'b1;
        end

        // --- IMPACT OP LEVENS (HARTJES) ---
        
        // Stijging naar 3, 4 of capped op 4 -> req_heart_gain pulse
        if ((actions_count >= 3'd3) && next_unique_4 && 
            (satisfaction == 3'd2 || satisfaction == 3'd3 || satisfaction == 3'd4)) begin
          req_heart_gain <= 1'b1;
        end
        // Daling naar 1, 0 of capped op 0 -> req_heart_lose pulse
        else if ((actions_count >= 3'd5) && next_missing_an_action && 
                 (satisfaction == 3'd2 || satisfaction == 3'd1 || satisfaction == 3'd0)) begin
          req_heart_lose <= 1'b1;
        end

      end // if (has_act)
    end // else if (frame_tick)
  end

endmodule
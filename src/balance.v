`default_nettype none
// ---------------------------------------------------------------------------
// THE BALANCE GAME.  OWNER: PERSON B.
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

  localparam A_MINIGAME = 2'd0, 
             A_FEED     = 2'd1, 
             A_DRINK    = 2'd2, 
             A_SLEEP    = 2'd3;

  wire        any_act_in  = act_feed | act_drink | act_sleep | act_minigame;
  wire [1:0]  this_act_in = act_feed     ? A_FEED     :
                            act_drink    ? A_DRINK    :
                            act_sleep    ? A_SLEEP    : A_MINIGAME;

  // Latch registers om snelle knoppulsen op te vangen tussen frame_ticks in
  reg        act_latched;
  reg  [1:0] latched_action;

  // Losse registers (geen 2D memory array -> geen Yosys memory warnings!)
  reg [1:0] hist_0, hist_1, hist_2, hist_3, hist_4, hist_5;
  reg [2:0] actions_count;

  // Bepaal de huidige actie
  wire       has_act     = act_latched | any_act_in;
  wire [1:0] current_act = act_latched ? latched_action : this_act_in;

  // Directe next-state reconstructie
  wire [1:0] next_h0 = current_act;
  wire [1:0] next_h1 = hist_0;
  wire [1:0] next_h2 = hist_1;
  wire [1:0] next_h3 = hist_2;
  wire [1:0] next_h4 = hist_3;
  wire [1:0] next_h5 = hist_4;

  // 1. Directe controle op 4 unieke acties
  wire next_unique_4 = (next_h0 != next_h1) && 
                       (next_h0 != next_h2) && 
                       (next_h0 != next_h3) && 
                       (next_h1 != next_h2) && 
                       (next_h1 != next_h3) && 
                       (next_h2 != next_h3);

  // 2. Directe controle op ontbrekende actie in 6 stappen
   wire [3:0] seen_mask =
      (4'b0001 << next_h0) |
      ((actions_count >= 3'd1) ? (4'b0001 << next_h1) : 4'b0000) |
      ((actions_count >= 3'd2) ? (4'b0001 << next_h2) : 4'b0000) |
      ((actions_count >= 3'd3) ? (4'b0001 << next_h3) : 4'b0000) |
      ((actions_count >= 3'd4) ? (4'b0001 << next_h4) : 4'b0000) |
      ((actions_count >= 3'd5) ? (4'b0001 << next_h5) : 4'b0000);
  wire next_missing_an_action = (seen_mask != 4'b1111);

  // Bitmasker voor de renderer combo balk
  wire [3:0] seen_recent = (actions_count >= 3'd1 ? (4'b0001 << hist_0) : 4'b0000) | 
                           (actions_count >= 3'd2 ? (4'b0001 << hist_1) : 4'b0000) | 
                           (actions_count >= 3'd3 ? (4'b0001 << hist_2) : 4'b0000);

  wire [2:0] num_unique_3 = {2'b0, seen_recent[0]} + 
                            {2'b0, seen_recent[1]} + 
                            {2'b0, seen_recent[2]} + 
                            {2'b0, seen_recent[3]};

  wire current_unique_4 = (hist_0 != hist_1) && (hist_0 != hist_2) && 
                          (hist_0 != hist_3) && (hist_1 != hist_2) && 
                          (hist_1 != hist_3) && (hist_2 != hist_3);

  // Balk weergave op het scherm (0..3)
  always @(*) begin
    if (actions_count >= 3'd4 && current_unique_4) begin
      combo_len = 2'd3;
    end else begin
      case (num_unique_3)
        3'd2:    combo_len = 2'd1;
        3'd3:    combo_len = 2'd2;
        default: combo_len = 2'd0;
      endcase
    end
  end

  // --- STAP 1: Snelle klok latching ---
  always @(posedge clk) begin
    if (!rst_n || restart) begin
      act_latched    <= 1'b0;
      latched_action <= A_MINIGAME;
    end else if (frame_tick) begin
      act_latched    <= 1'b0;
      latched_action <= A_MINIGAME;
    end else if (any_act_in) begin
      act_latched    <= 1'b1;
      latched_action <= this_act_in;
    end
  end

  // --- STAP 2: Frame-tick spellogica (Zonder for-lussen) ---
  always @(posedge clk) begin
    if (!rst_n || restart) begin
      hist_0         <= 2'b00;
      hist_1         <= 2'b00;
      hist_2         <= 2'b00;
      hist_3         <= 2'b00;
      hist_4         <= 2'b00;
      hist_5         <= 2'b00;
      actions_count  <= 3'd0;
      req_heart_gain <= 1'b0;
      req_heart_lose <= 1'b0;
      req_sat_up     <= 1'b0;
      req_sat_down   <= 1'b0;
    end else if (frame_tick) begin
      req_heart_gain <= 1'b0;
      req_heart_lose <= 1'b0;
      req_sat_up     <= 1'b0;
      req_sat_down   <= 1'b0;

      if (has_act) begin
        // Schuifregister expliciet parallel doorverbinden
        hist_5 <= hist_4;
        hist_4 <= hist_3;
        hist_3 <= hist_2;
        hist_2 <= hist_1;
        hist_1 <= hist_0;
        hist_0 <= current_act;

        // A) COMBO VOLTOOID: Beloning en harde reset naar 0
        if ((actions_count >= 3'd3) && next_unique_4) begin
          req_sat_up    <= 1'b1;
          actions_count <= 3'd0; // Streak reset: Schone lei voor de volgende combo
          if (satisfaction == 3'd2 || satisfaction == 3'd3 || satisfaction == 3'd4) begin
            req_heart_gain <= 1'b1;
          end
        end 
        // B) ACTIE VERGETEN IN 6 STAPPEN: Straf en harde reset naar 0
        else if ((actions_count >= 3'd5) && next_missing_an_action) begin
          req_sat_down  <= 1'b1;
          actions_count <= 3'd0; // Straf reset: Speler krijgt 6 nieuwe acties de tijd
          if (satisfaction == 3'd2 || satisfaction == 3'd1 || satisfaction == 3'd0) begin
            req_heart_lose <= 1'b1;
          end
        end 
        // C) NOG GEEN TRIGGER: Gewoon verder tellen tot max 6
        else begin
          if (actions_count < 3'd6) begin
            actions_count <= actions_count + 1'b1;
          end
        end

      end // if (has_act)
    end // else if (frame_tick)
  end

  wire _unused_balance = &{hist_5, 1'b0};

endmodule
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
    input  wire       act_minigame,     // 4e actie: minigame gespeeld
    input  wire [2:0] satisfaction,    

    output reg        req_heart_gain,  // -> dragon_state
    output reg        req_heart_lose,
    output reg        req_sat_up,
    output reg        req_sat_down,

    output reg  [1:0] combo_len        // -> renderer (progress bar 0..3)
);

  // Exact 4 acties (geen dummy NONE)
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

  // 1. Controle op 4 verschillende acties in de laatste 4 stappen (history[0:3])
  wire unique_last_4 = (history[0] != history[1]) && (history[0] != history[2]) && 
                       (history[0] != history[3]) && (history[1] != history[2]) && 
                       (history[1] != history[3]) && (history[2] != history[3]);

  // 2. Tellers om te controleren of alle 4 de acties voorkomen in history[0:5] (geen 'i' lus meer in always @(*))
  reg [2:0] count_00, count_01, count_10, count_11;
  always @(*) begin
    count_00 = ((actions_count > 3'd0 && history[0] == A_MINIGAME) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd1 && history[1] == A_MINIGAME) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd2 && history[2] == A_MINIGAME) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd3 && history[3] == A_MINIGAME) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd4 && history[4] == A_MINIGAME) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd5 && history[5] == A_MINIGAME) ? 3'd1 : 3'd0);

    count_01 = ((actions_count > 3'd0 && history[0] == A_FEED) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd1 && history[1] == A_FEED) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd2 && history[2] == A_FEED) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd3 && history[3] == A_FEED) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd4 && history[4] == A_FEED) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd5 && history[5] == A_FEED) ? 3'd1 : 3'd0);

    count_10 = ((actions_count > 3'd0 && history[0] == A_DRINK) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd1 && history[1] == A_DRINK) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd2 && history[2] == A_DRINK) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd3 && history[3] == A_DRINK) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd4 && history[4] == A_DRINK) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd5 && history[5] == A_DRINK) ? 3'd1 : 3'd0);

    count_11 = ((actions_count > 3'd0 && history[0] == A_SLEEP) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd1 && history[1] == A_SLEEP) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd2 && history[2] == A_SLEEP) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd3 && history[3] == A_SLEEP) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd4 && history[4] == A_SLEEP) ? 3'd1 : 3'd0) +
               ((actions_count > 3'd5 && history[5] == A_SLEEP) ? 3'd1 : 3'd0);
  end

  // Minstens 1 van de 4 acties ontbreekt in de laatste 6 stappen
  wire missing_an_action = (count_00 == 3'd0) || (count_01 == 3'd0) || 
                           (count_10 == 3'd0) || (count_11 == 3'd0);

  // 3. Bitmasker berekening voor unieke acties in de laatste 3 stappen
  wire [3:0] seen_recent = (4'b1 << history[0]) | 
                           (4'b1 << history[1]) | 
                           (4'b1 << history[2]);
  wire [2:0] num_unique_3 = {2'b0, seen_recent[0]} + 
                            {2'b0, seen_recent[1]} + 
                            {2'b0, seen_recent[2]} + 
                            {2'b0, seen_recent[3]};

  // Update combo_len voor de renderer (progress bar 0..3)
  always @(*) begin
    if (unique_last_4) begin
      combo_len = 2'd3;           // Situatie 1: Combo compleet (4 unieke) -> Balk is vol (3/3)
    end else begin
      case (num_unique_3)
        3'd2:    combo_len = 2'd1; // Situatie 2: 2 unieke acties gezien  -> Balk op 1/3
        3'd3:    combo_len = 2'd2; // Situatie 3: 3 unieke acties gezien  -> Balk op 2/3
        default: combo_len = 2'd0; // Situatie 4: 0 of 1 unieke actie    -> Balk op 0/3
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
  integer idx; // Lokaal voor het synchrone klokblok
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
      // Pulse reset (pulsen duren exact 1 frame tick)
      req_heart_gain <= 1'b0;
      req_heart_lose <= 1'b0;
      req_sat_up     <= 1'b0;
      req_sat_down   <= 1'b0;

      if (act_latched || any_act_in) begin
        
        // Schuifregister bijwerken
        for (idx = 5; idx > 0; idx = idx - 1) begin
          history[idx] <= history[idx-1];
        end
        history[0] <= act_latched ? latched_action : this_act_in;

        // Tel totaal aantal uitgevoerde acties op
        if (actions_count < 3'd6) begin
          actions_count <= actions_count + 1'b1;
        end

        // --- EVALUATIE LOGICA HUMEUR & PULSEN ---

        // A) Stijgen: Minstens 4 acties gedaan EN alle 4 uniek in history[0:3]
        if ((actions_count >= 3'd3) && unique_last_4) begin
          req_sat_up <= 1'b1;
        end 
        // B) Dalen: Minstens 6 acties gedaan EN 1 van de 4 acties ontbreekt in history[0:5]
        else if ((actions_count >= 3'd5) && missing_an_action) begin
          req_sat_down <= 1'b1;
        end

        // --- IMPACT OP LEVENS (HARTJES) ---
        
        // Stijging naar 4 of 5 -> req_heart_gain pulse
        if ((actions_count >= 3'd3) && unique_last_4 && (satisfaction == 3'd2 || satisfaction == 3'd3 || satisfaction == 3'd4)) begin
          req_heart_gain <= 1'b1;
        end
        // Daling naar 2 of 1 -> req_heart_lose pulse
        else if ((actions_count >= 3'd5) && missing_an_action && (satisfaction == 3'd2 || satisfaction == 3'd1 || satisfaction == 3'd0)) begin
          req_heart_lose <= 1'b1;
        end

      end // if (act_latched || any_act_in)
    end // else if (frame_tick)
  end

endmodule
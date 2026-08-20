// Interne statusregisters (expliciet plat geslagen)
  reg [1:0] hist_0, hist_1, hist_2, hist_3, hist_4, hist_5;
  reg [2:0] actions_count;

  // Bepaal welke actie NU uitgevoerd wordt op deze frame_tick
  wire       has_act     = act_latched | any_act_in;
  wire [1:0] current_act = act_latched ? latched_action : this_act_in;

  // Next-state reconstructie
  wire [1:0] next_h0 = current_act;
  wire [1:0] next_h1 = hist_0;
  wire [1:0] next_h2 = hist_1;
  wire [1:0] next_h3 = hist_2;
  wire [1:0] next_h4 = hist_3;
  wire [1:0] next_h5 = hist_4;

  // 1. Directe controle op 4 unieke acties in next_hist[0:3]
  wire next_unique_4 = (next_h0 != next_h1) && 
                       (next_h0 != next_h2) && 
                       (next_h0 != next_h3) && 
                       (next_h1 != next_h2) && 
                       (next_h1 != next_h3) && 
                       (next_h2 != next_h3);

  // 2. Directe controle op ontbrekende actie in next_hist[0:5]
  reg [2:0] next_count_00, next_count_01, next_count_10, next_count_11;
  always @(*) begin
    next_count_00 = ((actions_count >= 3'd0 && next_h0 == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_h1 == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_h2 == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_h3 == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_h4 == A_MINIGAME) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_h5 == A_MINIGAME) ? 3'd1 : 3'd0);

    next_count_01 = ((actions_count >= 3'd0 && next_h0 == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_h1 == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_h2 == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_h3 == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_h4 == A_FEED) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_h5 == A_FEED) ? 3'd1 : 3'd0);

    next_count_10 = ((actions_count >= 3'd0 && next_h0 == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_h1 == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_h2 == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_h3 == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_h4 == A_DRINK) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_h5 == A_DRINK) ? 3'd1 : 3'd0);

    next_count_11 = ((actions_count >= 3'd0 && next_h0 == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd1 && next_h1 == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd2 && next_h2 == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd3 && next_h3 == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd4 && next_h4 == A_SLEEP) ? 3'd1 : 3'd0) +
                    ((actions_count >= 3'd5 && next_h5 == A_SLEEP) ? 3'd1 : 3'd0);
  end

  wire next_missing_an_action = (next_count_00 == 3'd0) || (next_count_01 == 3'd0) || 
                                (next_count_10 == 3'd0) || (next_count_11 == 3'd0);

  // Bitmasker voor de laatste 3 acties
  wire [3:0] seen_recent = (4'b1 << hist_0) | 
                           (4'b1 << hist_1) | 
                           (4'b1 << hist_2);
  wire [2:0] num_unique_3 = {2'b0, seen_recent[0]} + 
                            {2'b0, seen_recent[1]} + 
                            {2'b0, seen_recent[2]} + 
                            {2'b0, seen_recent[3]};

  wire current_unique_4 = (hist_0 != hist_1) && (hist_0 != hist_2) && 
                          (hist_0 != hist_3) && (hist_1 != hist_2) && 
                          (hist_1 != hist_3) && (hist_2 != hist_3);

  // Update combo_len voor de renderer
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

  // --- STAP 1: Acties direct vangen op de snelle klok ---
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

  // --- STAP 2: Spellogica verwerken op frame_tick ---
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
        hist_5 <= hist_4;
        hist_4 <= hist_3;
        hist_3 <= hist_2;
        hist_2 <= hist_1;
        hist_1 <= hist_0;
        hist_0 <= current_act;

        if (actions_count < 3'd6) begin
          actions_count <= actions_count + 1'b1;
        end

        // Humeur logica
        if ((actions_count >= 3'd3) && next_unique_4) begin
          req_sat_up <= 1'b1;
        end else if ((actions_count >= 3'd5) && next_missing_an_action) begin
          req_sat_down <= 1'b1;
        end

        // Levens logica
        if ((actions_count >= 3'd3) && next_unique_4 && 
            (satisfaction == 3'd2 || satisfaction == 3'd3 || satisfaction == 3'd4)) begin
          req_heart_gain <= 1'b1;
        end else if ((actions_count >= 3'd5) && next_missing_an_action && 
                     (satisfaction == 3'd2 || satisfaction == 3'd1 || satisfaction == 3'd0)) begin
          req_heart_lose <= 1'b1;
        end
      end
    end
  end
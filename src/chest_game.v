`default_nettype none   // zorgt dat verilog niet vanzelf een nieuwe wire aanmaakt als je ergens een typefout maakt maar gwn meteen error geeft

// ---------------------------------------------------------------------------
// CHEST MINIGAME
//
// Runs when mode == CHEST (home.v decides that). Three chests, one
// hides a free level-up, one hides coins, one costs a heart. Pick with
// UP/DOWN (buttons 1/3), open with SELECT (6), leave with START (7).
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
    output reg  [2:0] chest_outcome,      // BOM, andere BOM, coin, 2x, CURSED

    output reg        req_coins_add,      // -> dragon_state
    output reg  [9:0] pot_payout,         // Amount of coins to add to total
    output reg        req_heart_lose_chest, // When hitting a bomb
    output reg        minigame_done       // -> home.v: hand control back
);
  localparam C_PICK=2'd0, C_OPEN=2'd1, C_RESULT=2'd2, C_MENU=2'd3;
  
  // outputs
  localparam O_COIN   = 3'd0;
  localparam O_2X     = 3'd1;
  localparam O_CURSED = 3'd2;
  localparam O_BOMB   = 3'd3;
  localparam O_BOMB2  = 3'd4;

// 1. init van dual lfsr (rng)
  wire [2:0] random_3bit;
  dual_lfsr my_rng_chip (
      .clk(clk),
      .rst_n(rst_n),
      .frame_tick(frame_tick),
      .rand_val(random_3bit) // Verbind de output van de RNG met wire
  );

// simpelere rng dan "dual_lfsr.v"
  // free-running random source; never seed with 0
  //reg [15:0] lfsr;
  //always @(posedge clk) begin
  //  if (!rst_n) lfsr <= 16'hACE1;
  //  else        lfsr <= {lfsr[0], lfsr[15:1] ^ (lfsr[0] ? 16'hB400 : 16'h0000)};
  //end


  // we hebben maar 6 waarden nodig dus als >= 6 zet dan op 0 of 1, niet modulo want das blijkbaar duur in hardware
  wire [2:0] safe_random = (random_3bit >= 3'd6) ? (random_3bit - 3'd6) : random_3bit;

  reg [2:0] contents [0:2];
  reg [7:0] timer;  // hoelang de animatie duurt
  reg       dealt;  // have the chests been shuffled yet?

  reg [9:0]  pot;
  reg [3:0]  round;

  // -------------------------------------------------------------------------
  // DE ROUND TABLE (Combinatorial)
  // Bepaalt continu wat de beloning en de set van 3 kisten is.
  // -------------------------------------------------------------------------
  reg [2:0] itemA, itemB, itemC;
  reg [7:0] reward;

  always @(*) begin
      case (round)
          4'd0: begin itemA = O_COIN; itemB = O_COIN; itemC = O_BOMB;  reward = 8'd40;  end
          4'd1: begin itemA = O_COIN; itemB = O_2X;   itemC = O_CURSED;reward = 8'd60;  end
          4'd2: begin itemA = O_COIN; itemB = O_2X;   itemC = O_BOMB2; reward = 8'd100; end
          4'd3: begin itemA = O_COIN; itemB = O_2X;   itemC = O_BOMB2; reward = 8'd160; end
          4'd4: begin itemA = O_2X;   itemB = O_2X;   itemC = O_BOMB2;reward = 8'd0; end
          4'd5: begin itemA = O_2X;   itemB = O_CURSED;itemC = O_BOMB2; reward = 8'd0;   end
          default: begin itemA = O_2X; itemB = O_CURSED; itemC = O_BOMB2; reward = 8'd0; end
      endcase
  end

  integer i;
  always @(posedge clk) begin
    if (!rst_n) begin // init
      chest_state<=C_PICK; chest_sel<=0; chest_outcome<=O_COIN;
      timer<=0; dealt<=0; minigame_done<=0;
      pot <= 0; round <= 0; pot_payout <= 0;
      req_coins_add<=0; req_heart_lose_chest<=0;
      for (i=0;i<3;i=i+1) contents[i]<=3'd0;
    end
    else if (frame_tick) begin
      req_coins_add<=0; req_heart_lose_chest<=0;
      minigame_done<=0;
      if (timer!=0) timer<=timer-8'd1;

      if (active) case (chest_state)
        C_PICK: begin
          //  * if (!dealt): use lfsr[2:0] to pick one of the SIX orderings
          //    of {O_BOM,O_COIN,O_LOSE} into contents[0..2]; dealt<=1
          //  * UP/DOWN (btn 1/3) move chest_sel within 0..2
          //  * SELECT (btn 6): chest_outcome<=contents[chest_sel];
          //    timer<=45; chest_state<=C_OPEN
          //  * START (btn 7): minigame_done<=1 (leave without opening)
          if (!dealt) begin
              dealt <= 1;
              case (safe_random)
                  3'd0: begin contents[0]<=itemA; contents[1]<=itemB; contents[2]<=itemC; end
                  3'd1: begin contents[0]<=itemA; contents[1]<=itemC; contents[2]<=itemB; end
                  3'd2: begin contents[0]<=itemB; contents[1]<=itemA; contents[2]<=itemC; end
                  3'd3: begin contents[0]<=itemB; contents[1]<=itemC; contents[2]<=itemA; end
                  3'd4: begin contents[0]<=itemC; contents[1]<=itemA; contents[2]<=itemB; end
                  3'd5: begin contents[0]<=itemC; contents[1]<=itemB; contents[2]<=itemA; end
                  default: begin contents[0]<=itemA; contents[1]<=itemB; contents[2]<=itemC; end
              endcase
          end

          // UP/DOWN (btn 1/3) move chest_sel within 0..2
          if (btn_pressed[1] && chest_sel > 0) chest_sel <= chest_sel - 1;
          if (btn_pressed[3] && chest_sel < 2) chest_sel <= chest_sel + 1;

          // SELECT (btn 6)
          if (btn_pressed[6]) begin
              chest_outcome <= contents[chest_sel];
              timer <= 45;  // 45 frames wachten eer we naar open gaan voor eventuele animatie
              chest_state <= C_OPEN;  // kist is open, volgende case
          end

          // START (btn 7: Cash out & Exit)
          if (btn_pressed[7]) begin
              if (pot > 0) begin
                  req_coins_add <= 1;
                  pot_payout <= pot;
              end
              minigame_done <= 1;
          end
        end

        C_OPEN: begin
          // when timer==0 -> timer<=60; chest_state<=C_RESULT
          if (timer == 0) begin 
              timer <= 60; 
              chest_state <= C_RESULT;  // uitslag is klaar, volgende case
          end
        end

        C_RESULT: begin
          // TODO Person C: when timer==0:
          //  * fire the matching req_* pulse for chest_outcome
          //  * dealt<=0; chest_state<=C_PICK; minigame_done<=1
          //    (decide with the team: one chest per visit, or several?)
          if (timer == 0) begin
            case (chest_outcome)
                O_BOMB: begin
                    pot <= 0;
                    minigame_done <= 1;
                end
                O_BOMB2: begin
                    pot <= 0;
                    req_heart_lose_chest <= 1;
                    minigame_done <= 1;
                end
                O_CURSED: begin
                    pot_payout <= (pot + {2'b0, reward} > 11'd999) ? 10'd999 : (pot + {2'b0, reward});
                    req_coins_add <= 1;
                    req_heart_lose_chest <= 1;
                    minigame_done <= 1;
                end
                O_COIN: begin
                    pot <= (pot + {2'b0, reward} > 11'd999) ? 10'd999 : (pot + {2'b0, reward});
                    round <= (round == 4'd15) ? 4'd15 : (round + 1);
                    chest_state <= C_MENU;
                end
                O_2X: begin
                    pot <= (pot << 1 > 11'd999) ? 10'd999 : (pot << 1);  // aka *2
                    round <= (round == 4'd15) ? 4'd15 : (round + 1);
                    chest_state <= C_MENU;
                    end
                default: ;  // lege default ma anders geeft dat warning
            endcase
          end
        end
      C_MENU: begin
        if (btn_pressed[6]) begin
          dealt <= 0;
          chest_state <= C_PICK;
        end
        else if (btn_pressed[7]) begin
          if (pot > 0) begin
                  req_coins_add <= 1;
                  pot_payout <= pot;
          end
          minigame_done <= 1;
        end
      end

      default: chest_state<=C_PICK;
      endcase
      else begin
        chest_state<=C_PICK; dealt<=0; pot <= 0; round <= 0;   // reset whenever we're not active
      end
    end
  end

  wire _unused = &{btn_pressed, contents[0], contents[1], contents[2], 1'b0}; // Dit lijntje code is een manier om tegen de compiler te zeggen: "Kijk, ik weet dat deze signalen bestaan, ik heb ze zogenaamd gelezen, dus stop met klagen!"
endmodule

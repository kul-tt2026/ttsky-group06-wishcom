`default_nettype none
// ---------------------------------------------------------------------------
// ANIMATION HEARTBEAT.  OWNER: PERSON B.
//
// Alle tijdsafhankelijke beeldtoestand, zodat de renderer een pure functie
// blijft van zijn ingangen.
//
// DRIE DINGEN DIE HIER NIEUW ZIJN
//
// 1. DE DRAAK LANDT EERST.  Vroeger kende het bob-blok act_feed niet, dus de
//    vlam kon vertrekken terwijl de draak in de lucht hing.  Nu blijft een
//    aangevraagde actie in `pending` staan tot dragon_bob weer 0 is, precies
//    zoals het ei zijn hop afmaakt voordat het gaat barsten.  Tijdens het
//    effect staat de bob stil, zodat de draak niet halverwege de vlam
//    wegspringt.
//
//    fx_on is daarbij hoog vanaf de knopdruk, dus home.v blokkeert de knoppen
//    al tijdens het wachten -- anders zou de speler in dat gaatje nog eens
//    kunnen drukken.
//
// 2. EVOLVE-ANIMATIE.  Een puls op `evolved` start een reeks van EVO_LEN
//    frames: eerst knippert de OUDE vorm, dan groeit dezelfde achthoek-flits
//    als bij het ei vanuit het midden van de draak, en op het hoogtepunt
//    daarvan wisselt de vorm.  `level_shown` is wat de renderer moet tekenen;
//    die loopt dus even achter op `level` uit dragon_state.
//
// 3. RESTART wist nacht, een lopend effect en een lopende evolve.
// ---------------------------------------------------------------------------
module anim (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire       restart,
    input  wire [2:0] satisfaction,     // 0 boos .. 4 heel blij

    input  wire       act_feed,         // eenframe-pulsen uit home.v
    input  wire       act_drink,
    input  wire       act_sleep,
    input  wire       wake,

    input  wire       evolved,          // puls uit dragon_state: het is gelukt
    input  wire [2:0] level,            // de NIEUWE vorm

    output reg        night,
    output reg  [2:0] dragon_bob,       // idle wip 0..2
    output reg        flash,            // knippert tijdens de evolve-opbouw
    output reg        evolve_blink,     // trage knipper op de evolve-KNOP
    output reg  [2:0] level_shown,      // wat de renderer moet tekenen

    output reg  [1:0] fx_kind,          // 0 niets, 1 feed, 2 drink
    output wire       fx_on,            // effect loopt (of staat te wachten)
    output wire [6:0] fx_age,

    output wire       evo_on,           // evolve-flits loopt
    output wire [9:0] evo_r             // straal van de flits, 0 = uit
);
  localparam [1:0] FX_NONE = 2'd0, FX_FEED = 2'd1, FX_DRINK = 2'd2;
  localparam [6:0] FX_FEED_LEN  = 7'd73;
  localparam [6:0] FX_DRINK_LEN = 7'd30;

  // ======================= evolve-knop knippert ===========================
  reg [7:0] blink_cnt;
  always @(posedge clk) begin
    if (!rst_n) begin
      blink_cnt <= 8'd0; evolve_blink <= 1'b1;
    end else if (frame_tick) begin
      if (blink_cnt == 8'd179) blink_cnt <= 8'd0;
      else                     blink_cnt <= blink_cnt + 8'd1;
      evolve_blink <= (blink_cnt < 8'd170);
    end
  end

  
  // ======================= dragon_bob =====================================
  reg [7:0] bob_timer;
  reg [7:0] total_cycle;
  always @(*) begin
    case (satisfaction)
      3'd0:    total_cycle = 8'd0;    // Boos: staat permanent stil
      3'd1:    total_cycle = 8'd150;
      3'd2:    total_cycle = 8'd90;
      3'd3:    total_cycle = 8'd60;
      default: total_cycle = 8'd48;
    endcase
  end

  wire fx_busy  = (fx_t != 7'd0);          // een effect speelt ECHT
  wire grounded = (dragon_bob == 3'd0);    // de draak staat op het gras

  // De bob staat stil zolang er een effect speelt of evolve loopt.
  always @(posedge clk) begin
    if (!rst_n || restart) begin
      bob_timer  <= 8'd0;
      dragon_bob <= 3'd0;
    end else if (frame_tick && !fx_busy && !evo_on) begin
      if (total_cycle == 8'd0) begin
        bob_timer  <= 8'd0;
        dragon_bob <= 3'd0;
      end else begin
        if (bob_timer >= total_cycle - 8'd1) bob_timer <= 8'd0;
        else                                 bob_timer <= bob_timer + 8'd1;

        case (satisfaction)
          // 1: Ontevreden (1 px klein hupje)
          3'd1: begin
            if (bob_timer >= 8'd3 && bob_timer < 8'd8) dragon_bob <= 3'd1;
            else                                       dragon_bob <= 3'd0;
          end

          // 2: Neutraal (2 px sprong)
          3'd2: begin
            if      (bob_timer < 8'd3)  dragon_bob <= 3'd0;
            else if (bob_timer < 8'd6)  dragon_bob <= 3'd1;
            else if (bob_timer < 8'd11) dragon_bob <= 3'd2; // hangtime op de top
            else if (bob_timer < 8'd13) dragon_bob <= 3'd1; // snelle val
            else                        dragon_bob <= 3'd0;
          end

          // 3: Blij (3 px sprong)
          3'd3: begin
            if      (bob_timer < 8'd3)  dragon_bob <= 3'd0;
            else if (bob_timer < 8'd6)  dragon_bob <= 3'd1;
            else if (bob_timer < 8'd9)  dragon_bob <= 3'd2;
            else if (bob_timer < 8'd14) dragon_bob <= 3'd3; // hangtime op de top
            else if (bob_timer < 8'd16) dragon_bob <= 3'd1; // snelle val
            else                        dragon_bob <= 3'd0;
          end

          // 4: Heel blij (4 px topsprong met snappy landing)
          3'd4: begin
            if      (bob_timer < 8'd3)  dragon_bob <= 3'd0;
            else if (bob_timer < 8'd6)  dragon_bob <= 3'd1;
            else if (bob_timer < 8'd9)  dragon_bob <= 3'd3;
            else if (bob_timer < 8'd14) dragon_bob <= 3'd4; // hangtime op de top (5 frames)
            else if (bob_timer < 8'd16) dragon_bob <= 3'd2; // snelle val (2 frames)
            else                        dragon_bob <= 3'd0; // landing
          end

          default: dragon_bob <= 3'd0;
        endcase
      end
    end
  end
  // ======================= voeren / drinken ===============================
  reg [6:0] fx_t;
  reg [1:0] pending;        // aangevraagd, wacht tot de draak geland is

  // Alleen op de FLANK starten, niet op het niveau: blijft een knop hangen,
  // dan begint het effect een keer en niet telkens opnieuw.
  reg fd_q, dr_q;
  wire feed_edge  = act_feed  && !fd_q;
  wire drink_edge = act_drink && !dr_q;

  // fx_on is al hoog terwijl we op de landing wachten, zodat home.v de
  // knoppen meteen doodlegt.  fx_kind staat in die fase op FX_NONE, dus
  // feed_fx en water_fx tekenen nog niets.
  assign fx_on = fx_busy || (pending != FX_NONE);

  wire [6:0] fx_len_now = (fx_kind == FX_DRINK) ? FX_DRINK_LEN : FX_FEED_LEN;
  assign fx_age = fx_len_now - fx_t;

  always @(posedge clk) begin
    if (!rst_n || restart) begin
      fx_kind <= FX_NONE; fx_t <= 7'd0; pending <= FX_NONE;
      fd_q <= 1'b0; dr_q <= 1'b0;
    end else if (frame_tick) begin
      fd_q <= act_feed; dr_q <= act_drink;
      if (fx_busy) begin
        fx_t <= fx_t - 7'd1;
      end else if (pending != FX_NONE) begin
        // wachten tot de draak op de grond staat, dan pas losbarsten
        if (grounded) begin
          fx_kind <= pending;
          fx_t    <= (pending == FX_DRINK) ? FX_DRINK_LEN : FX_FEED_LEN;
          pending <= FX_NONE;
        end
      end else if (feed_edge)  begin pending <= FX_FEED;  fx_kind <= FX_NONE; end
      else if (drink_edge)     begin pending <= FX_DRINK; fx_kind <= FX_NONE; end
      else                     fx_kind <= FX_NONE;
    end
  end

  // ======================= evolve-animatie ================================
  // 0 .. EVO_BLINK-1        de OUDE vorm knippert
  // EVO_BLINK .. EVO_PEAK-1 de flits groeit vanuit het midden van de draak
  // EVO_PEAK                de vorm wisselt, verstopt achter de volle flits
  // EVO_PEAK .. EVO_LEN-1   de flits krimpt weg en onthult de nieuwe vorm
  // Draai hieraan om de animatie te stemmen:
  //   EVO_BLINK  hoeveel frames de OUDE vorm knippert voor de flits begint
  //   EVO_STEP   hoeveel groeistappen de flits neemt; straal = EVO_STEP * 16
  //              10 stappen = 160 px, net genoeg om de draak te dekken.
  //              Groter getal = grotere flits.
  localparam [6:0] EVO_BLINK = 7'd48;                 // 0.80 s knipperen
  localparam [6:0] EVO_STEP  = 7'd11;                 // 11 * 16 = 176 px
  localparam [6:0] EVO_PEAK   = EVO_BLINK + EVO_STEP + 7'd1;  // 59: flits op zijn grootst
  localparam [6:0] EVO_SWITCH = EVO_BLINK + EVO_STEP;         // 58: hier wisselt de vorm
  localparam [6:0] EVO_LEN    = EVO_PEAK + EVO_STEP + 7'd1;   // 70 frames = 1.17 s

  reg [6:0] evo_t;
  assign evo_on = (evo_t != 7'd0);
  wire [6:0] evo_age = EVO_LEN - evo_t;

  // De straal: groeien tot het hoogtepunt, dan krimpen.  De klem op `step` is
  // niet cosmetisch -- zonder hem loopt step<<4 over de 10-bits grens als
  // evo_age ooit buiten bereik komt en klapt de schijf terug naar nul, precies
  // de fout van het "tweede schaap" in feed_fx.
  wire [6:0] grow_raw = (evo_age >= EVO_BLINK) ? (evo_age - EVO_BLINK) : 7'd0;
  wire [6:0] fade_raw = (evo_age <  EVO_LEN)   ? (EVO_LEN - 7'd1 - evo_age) : 7'd0;
  wire [6:0] step_raw = (evo_age <  EVO_PEAK)  ? grow_raw : fade_raw;
  wire [3:0] step     = (step_raw > EVO_STEP) ? EVO_STEP[3:0] : step_raw[3:0];
  assign evo_r = (evo_on && (evo_age >= EVO_BLINK)) ? {2'd0, step, 4'b0} : 10'd0;

  always @(posedge clk) begin
    if (!rst_n || restart) begin
      evo_t <= 7'd0;
    end else if (frame_tick) begin
      if (evo_t != 7'd0)  evo_t <= evo_t - 7'd1;
      else if (evolved)   evo_t <= EVO_LEN;
    end
  end

  // De oude vorm vasthouden tot de flits op zijn hoogtepunt is.  Buiten een
  // evolve loopt level_shown gewoon mee met level, zodat een restart of een
  // reset hem meteen goed zet.
  // LET OP de volgorde van deze takken.  Op het frame waarop `evolved` pulst
  // heeft dragon_state `level` AL omgezet, maar staat evo_t nog op nul -- dus
  // evo_on is nog laag.  Zonder de eerste tak zou de `!evo_on`-tak dan winnen
  // en sprong de draak meteen naar zijn nieuwe vorm, waarna je de hele
  // knipper- en groeifase naar de VERKEERDE vorm zat te kijken.
  always @(posedge clk) begin
    if (!rst_n || restart)                 level_shown <= 3'd0;
    else if (frame_tick) begin
      if (evolved)                         level_shown <= level_shown;  // vasthouden
      else if (!evo_on)                    level_shown <= level;
      else if (evo_age >= EVO_SWITCH)      level_shown <= level;
      // knipper- en groeifase: de OUDE vorm blijft staan
    end
  end

  // flash = de knipper op de draak zelf, alleen in de eerste fase.
  // Vier frames aan, vier uit: bit 2 van de leeftijd.
  always @(posedge clk) begin
    if (!rst_n || restart) flash <= 1'b0;
    else if (frame_tick)   flash <= evo_on && (evo_age < EVO_BLINK) && evo_age[3];
  end

  // ======================= nacht ==========================================
  always @(posedge clk) begin
    if (!rst_n || restart) night <= 1'b0;
    else if (frame_tick) begin
      if      (wake)       night <= 1'b0;
      else if (act_sleep)  night <= 1'b1;
    end
  end
endmodule
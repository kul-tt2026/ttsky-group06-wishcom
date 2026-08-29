`default_nettype none
// ---------------------------------------------------------------------------
// ANIMATION HEARTBEAT.  OWNER: PERSON B.
//
// Alle tijdsafhankelijke beeldtoestand, zodat de renderer een pure functie
// blijft van zijn ingangen.
//
// Hier stonden ooit ook chest_frame, flame_frame en dragon_mood_anim.  De
// kistanimatie is er nooit gekomen -- de renderer leidt de drie standen
// rechtstreeks af uit chest_state -- en de vlam en het humeur evenmin.  Alle
// drie zijn eruit; git bewaart ze.
//
// LET OP: `flash` hier is NIET de flits van het ei.  Die komt uit home.v als
// flash_r, de straal van de groeiende achthoek.  Deze is bedoeld voor een
// fanfare bij het evolven en is nog niet geschreven.
// ---------------------------------------------------------------------------
module anim (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       frame_tick,
    input  wire [2:0] satisfaction,     // 0 boos .. 4 heel blij

    input  wire       act_feed,         // eenframe-pulsen uit home.v
    input  wire       act_drink,
    input  wire       act_sleep,

    input  wire       wake,

    output reg        night,  

    output reg  [1:0] dragon_bob,       // idle wip 0..2   -- NOG TE SCHRIJVEN
    output reg        flash,            // fanfare bij evolve -- NOG TE SCHRIJVEN
    output reg        evolve_blink,

    output reg  [1:0] fx_kind,          // 0 niets, 1 feed, 2 drink, 3 sleep
    output wire       fx_on,             // effect loopt
    output wire [6:0] fx_age
);
  // ======================= evolve-knop knippert ===========================
  reg [7:0] blink_cnt;

  always @(posedge clk) begin
    if (!rst_n) begin
      blink_cnt    <= 8'd0;
      evolve_blink <= 1'b1;
      dragon_bob   <= 2'd0;
      flash        <= 1'b0;
    end else if (frame_tick) begin
      if (blink_cnt == 8'd179) blink_cnt <= 8'd0;
      else                     blink_cnt <= blink_cnt + 8'd1;
      evolve_blink <= (blink_cnt < 8'd170);

      // TODO Person B -- dragon_bob:
      //   patroon 0,1,2,1, een stap per ~16 frames.  Sneller wippen naarmate
      //   satisfaction hoger is, en bij 0 helemaal stilstaan -- een boze draak
      //   die vrolijk op en neer gaat leest verkeerd.
      //   Aansluiten kost EEN opteller: in dragon_draw.v `wire [9:0] yb =
      //   y + {8'd0, dragon_bob};` en die yb aan alle drie de generatoren
      //   geven.  Een hogere y voeren betekent verder in de sprite kijken,
      //   dus de draak komt omhoog.

      // TODO Person B -- flash:
      //   knipperen op ~4 Hz tijdens het evolven.  Daarvoor is een signaal
      //   nodig dat zegt DAT er geevolueerd is: `req_evolve` uit home.v is de
      //   voor de hand liggende kandidaat, maar die wordt ook gestuurd als de
      //   speler te weinig munten heeft.  Overleg met Person A of dragon_state
      //   een bevestiging kan geven.
    end
  end

  // ======================= dragon_bob animatie ============================
  reg [7:0] bob_timer;
  reg [7:0] total_cycle;

  // Bepaal totale cyclusduur per humeur (16 frames hop + rustperiode)
  always @(*) begin
    case (satisfaction)
      3'd0:    total_cycle = 8'd0;    // Boos: staat permanent stil
      3'd1:    total_cycle = 8'd150;  // Ontevreden: 16 frames hop + ~2.23s rust (2.5s totaal)
      3'd2:    total_cycle = 8'd90;   // Neutraal:   16 frames hop + ~1.23s rust (1.5s totaal)
      3'd3:    total_cycle = 8'd60;   // Blij:       16 frames hop + ~0.73s rust (1.0s totaal)
      default: total_cycle = 8'd48;   // Heel blij:  16 frames hop + ~0.53s rust (0.8s totaal)
    endcase
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      bob_timer  <= 8'd0;
      dragon_bob <= 2'd0;
    end else if (frame_tick) begin
      if (total_cycle == 8'd0) begin
        bob_timer  <= 8'd0;
        dragon_bob <= 2'd0;
      end else begin
        if (bob_timer >= total_cycle - 8'd1) begin
          bob_timer <= 8'd0;
        end else begin
          bob_timer <= bob_timer + 8'd1;
        end

        // Vlotte sprong van 16 frames (4 frames per stand: 0 -> 1 -> 2 -> 1)
        if      (bob_timer < 8'd4)   dragon_bob <= 2'd0;
        else if (bob_timer < 8'd8)   dragon_bob <= 2'd1;
        else if (bob_timer < 8'd12)  dragon_bob <= 2'd2;
        else if (bob_timer < 8'd16)  dragon_bob <= 2'd1;
        else                         dragon_bob <= 2'd0; // Rustperiode op gras
      end
    end
  end
  // ======================= voeren / drinken / slapen ======================
  // De meest basale versie: een halve seconde lang kleurt de renderer de lucht
  // om.  EEN teller voor alle drie, want ze kunnen niet tegelijk -- home.v
  // geeft per frame hoogstens een van deze pulsen.
  //
  // Wil je later meer: het vallende blok bij drinken volgt uit fx_t (hoe lager
  // de teller, hoe verder gezakt), en bij slapen kan de draak grijs worden met
  // een mux op sprite_rgb.  De teller hier hoeft daar niet voor te veranderen.
  localparam [1:0] FX_NONE = 2'd0, FX_FEED = 2'd1, FX_DRINK = 2'd2;
  localparam [6:0] FX_FEED_LEN  = 7'd73;   // lam valt, pauze, vlam, nagloeien
  localparam [6:0] FX_DRINK_LEN = 7'd30;   // water landt op frame 8, dan hold

  // ---- HIER staat fx_t: puur lokaal, nergens een poort -------------------
  reg [6:0] fx_t;

  assign fx_on = (fx_t != 7'd0);

  // fx_age telt OP vanaf 0, voor welk effect dan ook loopt.
  wire [6:0] fx_len_now = (fx_kind == FX_DRINK) ? FX_DRINK_LEN : FX_FEED_LEN;
  assign fx_age = fx_len_now - fx_t;

  always @(posedge clk) begin
    if (!rst_n) begin
      fx_kind <= FX_NONE;
      fx_t    <= 7'd0;
    end else if (frame_tick) begin
      if (fx_t != 7'd0)   fx_t <= fx_t - 7'd1;     // bezig wint van alles
      else if (act_feed)  begin fx_kind <= FX_FEED;  fx_t <= FX_FEED_LEN;  end
      else if (act_drink) begin fx_kind <= FX_DRINK; fx_t <= FX_DRINK_LEN; end
      else                fx_kind <= FX_NONE;
    end
  end

  // ---- nacht: blijft staan tot een andere actie je wekt -------------------
  // Eigen always-blok met eigen reset: Verilog verbiedt dat een register
  // vanuit twee blokken gedreven wordt.
  always @(posedge clk) begin
    if (!rst_n)            night <= 1'b0;
    else if (frame_tick) begin
      if      (wake)       night <= 1'b0;
      else if (act_sleep)  night <= 1'b1;
    end
  end






  // satisfaction wordt pas gelezen zodra dragon_bob geschreven is.
  wire _unused = &{satisfaction, 1'b0};





endmodule
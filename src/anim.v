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

  // ======================= voeren / drinken / slapen ======================
  // De meest basale versie: een halve seconde lang kleurt de renderer de lucht
  // om.  EEN teller voor alle drie, want ze kunnen niet tegelijk -- home.v
  // geeft per frame hoogstens een van deze pulsen.
  //
  // Wil je later meer: het vallende blok bij drinken volgt uit fx_t (hoe lager
  // de teller, hoe verder gezakt), en bij slapen kan de draak grijs worden met
  // een mux op sprite_rgb.  De teller hier hoeft daar niet voor te veranderen.
  localparam [1:0] FX_NONE  = 2'd0,
                   FX_FEED  = 2'd1,
                   FX_DRINK = 2'd2;

  localparam [6:0] FX_FEED_LEN = 7'd45;      // 30 frames = een halve seconde
  localparam [6:0] FX_DRINK_LEN = 7'd30;
  reg [4:0] fx_t;

  always @(posedge clk) begin
    if (!rst_n) begin
      fx_kind <= FX_NONE;
      fx_t    <= 7'd0;
    end else if (frame_tick) begin
      if      (act_feed)  begin fx_kind <= FX_FEED;  fx_t <= FX_FEED_LEN; end
      else if (act_drink) begin fx_kind <= FX_DRINK; fx_t <= FX_DRINK_LEN; end
      else if (fx_t != 7'd0)    fx_t <= fx_t - 7'd1;
      else                      fx_kind <= FX_NONE;
    end
  end

  assign fx_on = (fx_t != 7'd0);
  assign fx_age = FX_FEED_LEN - fx_t;

  // satisfaction wordt pas gelezen zodra dragon_bob geschreven is.
  wire _unused = &{satisfaction, 1'b0};




    // ---- nacht: een TOESTAND, geen effect ----------------------------------
  // Slapen zet hem aan en hij blijft aan tot je iets anders doet.  Daarom een
  // eigen blokje met een eigen reset, los van de knipperteller hierboven --
  // die twee hebben niets met elkaar te maken.
  always @(posedge clk) begin
    if (!rst_n) begin
      night <= 1'b0;
    end else if (frame_tick) begin
      if      (act_sleep) night <= 1'b1;
      else if (wake)      night <= 1'b0;
    end
  end
endmodule
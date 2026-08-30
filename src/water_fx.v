`default_nettype none
// ---------------------------------------------------------------------------
// WATER_FX -- drinken: een waterpistool spuit een straal naar de bek van de
// draak, en op het punt van inslag spat het water uit elkaar.
//
// Drie lagen, van links naar rechts:
//   1. PISTOOL   32x16 sprite, 2x geschaald -> 64x32 px.  Staat stil.
//   2. STRAAL    puur wiskundig: zwarte rand / blauwe kern / zwarte rand, en
//                die groeit per frame naar rechts.  De dikte is EXACT die van
//                de stomp aan de linkerrand van de spat-sprite (bronrij 8/9/10
//                = zwart/blauw/zwart), zodat de twee naadloos in elkaar
//                overlopen.  Verander je SPL_SH, dan schuift de straal mee --
//                alle grenzen zijn afgeleid, niet met de hand ingetikt.
//   3. SPLASH    17x17 sprite, 4x geschaald -> 68x68 px.  Verschijnt pas als
//                de straal er is en steekt bewust OVER de draak heen (de draak
//                begint op x = 186) zodat het contact leest als een treffer.
//
// De straal is opzettelijk GEEN sprite: een rechthoek die groeit kost een paar
// vergelijkingen, terwijl elke pixel ROM cellen kost.  De twee dingen die je
// wel als sprite wil -- de vorm van het pistool en de grillige spat -- zijn
// precies de dingen die wiskundig lelijk worden.
//
// TWEE KNOPPEN OM AAN TE DRAAIEN (bovenaan, allebei localparam):
//   SHOW_SPLASH  0 = spat helemaal weg; de straal loopt dan door tot de bek.
//                Yosys gooit de hele spat-ROM eruit, dus dat scheelt ~200
//                cellen.  1 = spat aan.
//   SPL_X        de x waar de spat begint.  Alles eromheen (waar de straal
//                stopt, hoe lang hij moet groeien) rekent zichzelf om.
//
// Tijdlijn bij FX_DRINK_LEN = 30 frames (0.5 s):
//   fx_age 0..n   straal groeit van de loop naar de spat (16 px/frame)
//   daarna        straal staat vol, spat zichtbaar
// ---------------------------------------------------------------------------
module water_fx (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [6:0] fx_age,
    input  wire       active,
    output wire       water_on,
    output wire [5:0] water_rgb
);
  // =========================================================================
  // DE TWEE KNOPPEN
  // =========================================================================
  localparam        SHOW_SPLASH = 1'b1;    // 0 = zonder spat (bespaart ~200 cellen)
  localparam [9:0]  SPL_X       = 10'd153; // linkerrand van de spat-sprite

  // =========================================================================
  // vaste maten -- hier hoef je niets aan te doen
  // =========================================================================
  localparam [9:0] MOUTH_X = 10'd185;      // linkerrand van de draak = zijn bek
  localparam [9:0] MOUTH_Y = 10'd210;

  // -- spat: 17x17 bron, 4x geschaald ---------------------------------------
  // De stomp zit op bronrij 8 (zwart), 9 (blauw), 10 (zwart).  Rij 9 moet op
  // de bekhoogte liggen, dus de sprite begint 9 bronrijen daarboven.
  localparam [3:0] SPL_SH  = 4'd2;                       // 4x
  localparam [9:0] SPL_PX  = 10'd17 << SPL_SH;           // 68 px breed/hoog
  localparam [9:0] SPL_ROW = 10'd1   << SPL_SH;          // 4 px per bronrij
  localparam [9:0] SPL_Y   = MOUTH_Y - (10'd9 << SPL_SH) - (SPL_ROW >> 1); // 172

  // -- straal: precies de drie bronrijen van de stomp ------------------------
  localparam [9:0] JET_TOP  = SPL_Y + (10'd8 << SPL_SH);   // 204, zwarte rand
  localparam [9:0] JET_C0   = SPL_Y + (10'd9 << SPL_SH);   // 208, blauwe kern
  localparam [9:0] JET_C1   = JET_C0 + SPL_ROW;            // 212, kern eindigt
  localparam [9:0] JET_BOT  = JET_C1 + SPL_ROW;            // 216, rand eindigt

  // -- pistool: 32x16 bron, 2x geschaald ------------------------------------
  // De loop is bronrij 1..3; op 2x is het midden daarvan PIST_Y + 4.5, en dat
  // moet samenvallen met het midden van de blauwe kern.
  localparam [3:0] PIST_SH = 4'd1;                         // 2x
  localparam [9:0] PIST_X  = 10'd64;   // NIET lager: de coinbar staat op px 24..63 EN wint in de STACK
  localparam [9:0] PIST_W  = 10'd32 << PIST_SH;            // 64
  localparam [9:0] PIST_H  = 10'd16 << PIST_SH;            // 32
  localparam [9:0] PIST_Y  = 10'd205;
  localparam [9:0] MUZZLE  = PIST_X + PIST_W;              // 88: start van de straal

  // waar de straal ophoudt: bij de spat, of bij de bek als de spat uit staat
  localparam [9:0] JET_END = SHOW_SPLASH ? SPL_X : MOUTH_X;
  localparam [9:0] JET_LEN = JET_END - MUZZLE;

  // ---- kleuren -----------------------------------------------------------
  localparam [5:0] C_BLACK = 6'b00_00_00;
  localparam [5:0] C_GREEN = 6'b10_11_01;   // lichtgroen pistoolhuis
  localparam [5:0] C_RED   = 6'b11_00_01;   // rode mond van de loop
  localparam [5:0] C_BLUE  = 6'b01_01_11;   // het blauw van de spat EN de straal

  // ---- de straal groeit naar rechts --------------------------------------
  // De klem op fx_age is niet cosmetisch: zonder hem loopt fx_age<<4 over de
  // 10-bits grens zodra fx_age groot genoeg wordt en klapt reach terug naar
  // nul -- dezelfde fout als het "tweede schaap" in feed_fx.
  wire [4:0] age_c   = (fx_age > 7'd16) ? 5'd16 : fx_age[4:0];
  wire [9:0] reach_r = {1'b0, age_c, 4'b0};                // age_c * 16
  wire [9:0] reach   = (reach_r > JET_LEN) ? JET_LEN : reach_r;
  wire       arrived = (reach >= JET_LEN);

  wire in_jet_x = active && (x >= MUZZLE) && (x < MUZZLE + reach);
  wire jet_core = in_jet_x && (y >= JET_C0)  && (y < JET_C1);
  wire jet_edge = in_jet_x && (((y >= JET_TOP) && (y < JET_C0)) ||
                               ((y >= JET_C1)  && (y < JET_BOT)));
  wire in_jet   = jet_core || jet_edge;

  // ---- pistool ------------------------------------------------------------
  wire in_pist = active && (x >= PIST_X) && (x < PIST_X + PIST_W) &&
                           (y >= PIST_Y) && (y < PIST_Y + PIST_H);
  wire [9:0] pox = x - PIST_X;
  wire [9:0] poy = y - PIST_Y;
  wire [4:0] psx = in_pist ? pox[5:1] : 5'd0;      // >>PIST_SH = gratis
  wire [3:0] psy = in_pist ? poy[4:1] : 4'd0;
  reg [1:0] prom [0:511];
  initial $readmemh("wpistol.hex", prom);
  wire [1:0] pcode   = prom[{psy, psx}];
  wire       pist_on = in_pist && (pcode != 2'd0);

  // ---- spat ---------------------------------------------------------------
  // Staat SHOW_SPLASH op 0, dan is in_spl constant nul en snoeit yosys de
  // hele ROM plus de adresberekening weg.
  wire in_spl = SHOW_SPLASH && active && arrived &&
                (x >= SPL_X) && (x < SPL_X + SPL_PX) &&
                (y >= SPL_Y) && (y < SPL_Y + SPL_PX);
  wire [9:0] sox = x - SPL_X;
  wire [9:0] soy = y - SPL_Y;
  wire [4:0] ssx = in_spl ? sox[6:2] : 5'd0;       // >>SPL_SH = gratis
  wire [4:0] ssy = in_spl ? soy[6:2] : 5'd0;
  reg [1:0] srom [0:1023];
  initial $readmemh("wsplash.hex", srom);
  wire [1:0] scode  = srom[{ssy, ssx}];
  wire       spl_on = in_spl && (scode != 2'd0);

  // ---- samenvoegen --------------------------------------------------------
  // Volgorde: spat boven de straal boven het pistool.  Code 1 is in beide
  // sprites zwart, dus de twee tabellen delen die tak.
  reg [5:0] rgb;
  always @(*) begin
    if (spl_on)        rgb = (scode == 2'd1) ? C_BLACK : C_BLUE;
    else if (jet_core) rgb = C_BLUE;
    else if (jet_edge) rgb = C_BLACK;
    else               rgb = (pcode == 2'd1) ? C_BLACK :
                             (pcode == 2'd2) ? C_GREEN : C_RED;
  end

  assign water_on  = spl_on || in_jet || pist_on;
  assign water_rgb = rgb;

  wire _unused = &{1'b0, pox[9:6], pox[0], poy[9:5], poy[0], sox[9:7], sox[1:0], soy[9:7], soy[1:0]};
endmodule
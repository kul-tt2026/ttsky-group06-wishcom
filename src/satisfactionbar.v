`default_nettype none
// ---------------------------------------------------------------------------
// SATISFACTIONBAR -- vijf vakjes met een smiley, van chagrijnig naar blij.
//
// Het actieve vakje krijgt een witte rand.  Alle vijf houden hun kleur, zodat
// je de hele schaal blijft zien (CURSOR_MODE).  Zet CURSOR_MODE op 0 en de
// vakjes boven `sat` gaan uit; dat leest sneller van een afstand maar je
// verliest zicht op de bovenkant van de schaal.
//
// GEEN DELER, GEEN MODULO.  PITCH is 62 en dus geen macht van twee; diff_x/62
// en diff_x%62 kostten samen honderden cellen.  Met vijf vakjes is een
// vergelijkingsketen goedkoper dan welke deeltruc ook -- zelfde aanpak als in
// hearts.v en coinbar.v.
//
// DE SMILEY kost weinig omdat hij in elk vakje op dezelfde plek staat: de
// cirkel en de ogen hangen alleen van (sx, sy) af, en alleen de MONDHOOGTE
// komt uit een tabel op idx.  Dat is een tabel van 45 ingangen, geen vijf
// aparte gezichten.  Zet SMILEY op 0 als je de vakjes leeg wilt.
//
// Het vakje is 40 px hoog (was 20) zodat het gezicht straal 16 kan hebben --
// op straal 8 was er van de mond niets te zien.
//
// px_code: 0 = zwart (frame, schotjes, en de lijnen van de smiley)
//          1..5 = kleur van vakje 0..4
//          6 = witte selectierand
//          7 = onverlicht (alleen in FILL-modus)
// ---------------------------------------------------------------------------
module satisfactionbar (
    input  wire [9:0] x,             // local (px - SATBAR_X)
    input  wire [9:0] y,             // local (py - SATBAR_Y)
    input  wire [2:0] sat,           // 0..4: actieve segment
    output wire       px_on,
    output wire [2:0] px_code
);
  localparam CURSOR_MODE = 1'b1;
  localparam SMILEY      = 1'b1;

  // ======================= geometrie =======================================
  localparam [9:0] NSEG  = 10'd5;
  localparam [9:0] FRAME = 10'd2;       // zwarte buitenrand
  localparam [9:0] PITCH = 10'd62;      // afstand per segment
  localparam [9:0] SEG_W = 10'd60;      // vakje langs x
  localparam [9:0] SEG_H = 10'd40;      // vakje langs y

  localparam [9:0] RING_X = 10'd2;      // randdikte op de lange as
  localparam [9:0] RING_Y = 10'd2;      // randdikte op de korte as

  localparam [9:0] BAR_W = FRAME + (NSEG * PITCH) - (PITCH - SEG_W) + FRAME; // 312
  localparam [9:0] BAR_H = FRAME + SEG_H + FRAME;                            //  44

  // ======================= coordinaten =====================================
  // Links/boven van de origin wrapt de lokale coordinaat naar ~1023, dus
  // "< BAR_W" vangt meteen de linker- en bovenrand af.  Geen signed compare.
  wire in_bar   = (x < BAR_W) && (y < BAR_H);
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);

  wire [9:0] diff_x = x - FRAME;        // 0..307 binnen in_inner
  wire [9:0] diff_y = y - FRAME;        // 0..39
  wire [5:0] sy     = diff_y[5:0];

  // Vijf vaste grenzen in plaats van diff_x/62 en diff_x%62.
  reg [2:0] idx;
  reg [9:0] sbase;
  always @(*) begin
    if      (diff_x < 10'd62)  begin idx = 3'd0; sbase = 10'd0;   end
    else if (diff_x < 10'd124) begin idx = 3'd1; sbase = 10'd62;  end
    else if (diff_x < 10'd186) begin idx = 3'd2; sbase = 10'd124; end
    else if (diff_x < 10'd248) begin idx = 3'd3; sbase = 10'd186; end
    else                       begin idx = 3'd4; sbase = 10'd248; end
  end
  wire [9:0] sxw = diff_x - sbase;
  wire [5:0] sx  = sxw[5:0];            // 0..61

  // idx is door de keten hierboven altijd 0..4, dus een "idx < NSEG" test
  // zou niets meer doen -- die is eruit.
  wire in_seg = in_inner && (sx < 6'd60);

  // ======================= selectie =======================================
  wire selected = (idx == sat);

  wire ring = CURSOR_MODE && in_seg && selected &&
              ((sx < 6'd2) || (sx >= 6'd58) ||
               (sy < 6'd2) || (sy >= 6'd38));

  wire coloured = CURSOR_MODE ? 1'b1 : (idx <= sat);

  // ======================= de smiley ======================================
  // Gezicht met straal 16 rond (30, 20) binnen het vakje.  De tabel geeft per
  // rij de halve breedte PLUS EEN, uit floor(sqrt(256 - ay^2)) + 1, zodat 0
  // netjes "deze rij raakt de cirkel niet" betekent -- zelfde patroon als de
  // bollen in hearts.v en de ellips in draw_buttons.v.
  wire [5:0] fdx = (sx >= 6'd30) ? (sx - 6'd30) : (6'd30 - sx);
  wire [5:0] ay  = (sy >= 6'd20) ? (sy - 6'd20) : (6'd20 - sy);

  reg [5:0] fw;
  always @(*) case (ay)
    6'd0:    fw = 6'd17;
    6'd1:    fw = 6'd16;
    6'd2:    fw = 6'd16;
    6'd3:    fw = 6'd16;
    6'd4:    fw = 6'd16;
    6'd5:    fw = 6'd16;
    6'd6:    fw = 6'd15;
    6'd7:    fw = 6'd15;
    6'd8:    fw = 6'd14;
    6'd9:    fw = 6'd14;
    6'd10:   fw = 6'd13;
    6'd11:   fw = 6'd12;
    6'd12:   fw = 6'd11;
    6'd13:   fw = 6'd10;
    6'd14:   fw = 6'd8;
    6'd15:   fw = 6'd6;
    6'd16:   fw = 6'd1;
    default: fw = 6'd0;
  endcase

  wire in_face   = (fdx < fw);
  wire face_ring = in_face && (fdx + 6'd3 >= fw);      // 3 px dikke omtrek

  // Twee ogen van 4x6.
  wire eye = in_face && (sy >= 6'd12) && (sy <= 6'd17) &&
             (((sx >= 6'd22) && (sx <= 6'd25)) ||
              ((sx >= 6'd35) && (sx <= 6'd38)));

  // De mond: per segment en per kolom een rij.  Bij een chagrijnig gezicht
  // liggen de hoeken LAGER dan het midden, bij een blij gezicht hoger.
  // 63 betekent "hier geen mond"; sy komt nooit boven 39, dus de test
  // (sy >= mrow) valt dan vanzelf af.
  reg [5:0] mrow;
  always @(*) case ({idx, fdx[3:0]})
    {3'd0,4'd0}: mrow=6'd24; {3'd0,4'd1}: mrow=6'd24; {3'd0,4'd2}: mrow=6'd24;
    {3'd0,4'd3}: mrow=6'd25; {3'd0,4'd4}: mrow=6'd26; {3'd0,4'd5}: mrow=6'd27;
    {3'd0,4'd6}: mrow=6'd28; {3'd0,4'd7}: mrow=6'd29; {3'd0,4'd8}: mrow=6'd30;

    {3'd1,4'd0}: mrow=6'd26; {3'd1,4'd1}: mrow=6'd26; {3'd1,4'd2}: mrow=6'd26;
    {3'd1,4'd3}: mrow=6'd26; {3'd1,4'd4}: mrow=6'd26; {3'd1,4'd5}: mrow=6'd27;
    {3'd1,4'd6}: mrow=6'd28; {3'd1,4'd7}: mrow=6'd28; {3'd1,4'd8}: mrow=6'd28;

    {3'd2,4'd0}: mrow=6'd28; {3'd2,4'd1}: mrow=6'd28; {3'd2,4'd2}: mrow=6'd28;
    {3'd2,4'd3}: mrow=6'd28; {3'd2,4'd4}: mrow=6'd28; {3'd2,4'd5}: mrow=6'd28;
    {3'd2,4'd6}: mrow=6'd28; {3'd2,4'd7}: mrow=6'd28; {3'd2,4'd8}: mrow=6'd28;

    {3'd3,4'd0}: mrow=6'd30; {3'd3,4'd1}: mrow=6'd30; {3'd3,4'd2}: mrow=6'd30;
    {3'd3,4'd3}: mrow=6'd29; {3'd3,4'd4}: mrow=6'd28; {3'd3,4'd5}: mrow=6'd28;
    {3'd3,4'd6}: mrow=6'd27; {3'd3,4'd7}: mrow=6'd26; {3'd3,4'd8}: mrow=6'd26;

    {3'd4,4'd0}: mrow=6'd32; {3'd4,4'd1}: mrow=6'd32; {3'd4,4'd2}: mrow=6'd31;
    {3'd4,4'd3}: mrow=6'd30; {3'd4,4'd4}: mrow=6'd29; {3'd4,4'd5}: mrow=6'd28;
    {3'd4,4'd6}: mrow=6'd27; {3'd4,4'd7}: mrow=6'd26; {3'd4,4'd8}: mrow=6'd26;

    default:     mrow = 6'd63;
  endcase

  wire mouth = in_face && (fdx <= 6'd8) &&
               (sy >= mrow) && (sy < mrow + 6'd3);     // 3 px dikke mond

  wire smiley = SMILEY && in_seg && (face_ring || eye || mouth);

  // ======================= output =========================================
  // Het hele blok is dekkend: frame en schotjes delen code 0, zodat de balk
  // als een object leest in plaats van de achtergrond door te laten schijnen.
  assign px_on   = in_bar;
  assign px_code = !in_seg  ? 3'd0         :   // frame + schotjes
                   ring     ? 3'd6         :   // witte selectierand
                   smiley   ? 3'd0         :   // de lijnen van het gezichtje
                   coloured ? (idx + 3'd1) :   // kleur 1..5
                              3'd7;            // onverlicht
endmodule
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
// komt uit een tabel op idx.  Dat is een tabel van 25 ingangen, geen vijf
// aparte gezichten.  Zet SMILEY op 0 als je de vakjes leeg wilt.
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
  localparam [9:0] SEG_H = 10'd20;      // vakje langs y

  localparam [9:0] RING_X = 10'd2;      // randdikte op de lange as
  localparam [9:0] RING_Y = 10'd1;      // randdikte op de korte as

  localparam [9:0] BAR_W = FRAME + (NSEG * PITCH) - (PITCH - SEG_W) + FRAME; // 312
  localparam [9:0] BAR_H = FRAME + SEG_H + FRAME;                            //  24

  // ======================= coordinaten =====================================
  // Links/boven van de origin wrapt de lokale coordinaat naar ~1023, dus
  // "< BAR_W" vangt meteen de linker- en bovenrand af.  Geen signed compare.
  wire in_bar   = (x < BAR_W) && (y < BAR_H);
  wire in_inner = (x >= FRAME) && (x < BAR_W - FRAME) &&
                  (y >= FRAME) && (y < BAR_H - FRAME);

  wire [9:0] diff_x = x - FRAME;        // 0..307 binnen in_inner
  wire [9:0] diff_y = y - FRAME;        // 0..19
  wire [4:0] sy     = diff_y[4:0];

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
               (sy < 5'd1) || (sy >= 5'd19));

  wire coloured = CURSOR_MODE ? 1'b1 : (idx <= sat);

  // ======================= de smiley ======================================
  // Gezicht met straal 8 rond (30, 10) binnen het vakje.  De tabel geeft per
  // rij de halve breedte PLUS EEN, uit floor(sqrt(64 - ay^2)) + 1, zodat 0
  // netjes "deze rij raakt de cirkel niet" betekent -- zelfde patroon als de
  // bollen in hearts.v en de ellips in draw_buttons.v.
  wire [5:0] fdx = (sx >= 6'd30) ? (sx - 6'd30) : (6'd30 - sx);
  wire [4:0] ay  = (sy >= 5'd10) ? (sy - 5'd10) : (5'd10 - sy);

  reg [4:0] fw;
  always @(*) case (ay)
    5'd0:    fw = 5'd9;
    5'd1:    fw = 5'd8;
    5'd2:    fw = 5'd8;
    5'd3:    fw = 5'd8;
    5'd4:    fw = 5'd7;
    5'd5:    fw = 5'd7;
    5'd6:    fw = 5'd6;
    5'd7:    fw = 5'd4;
    5'd8:    fw = 5'd1;
    default: fw = 5'd0;
  endcase

  wire in_face   = (fdx < {1'b0, fw});
  wire face_ring = in_face && (fdx + 6'd2 >= {1'b0, fw});

  // Twee ogen van 2x3.
  wire eye = in_face && (sy >= 5'd6) && (sy <= 5'd8) &&
             (((sx >= 6'd26) && (sx <= 6'd27)) ||
              ((sx >= 6'd33) && (sx <= 6'd34)));

  // De mond: per segment en per kolom een rij.  Bij een chagrijnig gezicht
  // liggen de hoeken LAGER dan het midden, bij een blij gezicht hoger.
  // 31 betekent "hier geen mond".
  reg [4:0] mrow;
  always @(*) case ({idx, fdx[2:0]})
    {3'd0,3'd0}: mrow = 5'd12;  {3'd0,3'd1}: mrow = 5'd12;
    {3'd0,3'd2}: mrow = 5'd13;  {3'd0,3'd3}: mrow = 5'd14;
    {3'd0,3'd4}: mrow = 5'd15;
    {3'd1,3'd0}: mrow = 5'd13;  {3'd1,3'd1}: mrow = 5'd13;
    {3'd1,3'd2}: mrow = 5'd13;  {3'd1,3'd3}: mrow = 5'd14;
    {3'd1,3'd4}: mrow = 5'd14;
    {3'd2,3'd0}: mrow = 5'd14;  {3'd2,3'd1}: mrow = 5'd14;
    {3'd2,3'd2}: mrow = 5'd14;  {3'd2,3'd3}: mrow = 5'd14;
    {3'd2,3'd4}: mrow = 5'd14;
    {3'd3,3'd0}: mrow = 5'd15;  {3'd3,3'd1}: mrow = 5'd15;
    {3'd3,3'd2}: mrow = 5'd14;  {3'd3,3'd3}: mrow = 5'd14;
    {3'd3,3'd4}: mrow = 5'd13;
    {3'd4,3'd0}: mrow = 5'd16;  {3'd4,3'd1}: mrow = 5'd16;
    {3'd4,3'd2}: mrow = 5'd15;  {3'd4,3'd3}: mrow = 5'd14;
    {3'd4,3'd4}: mrow = 5'd13;
    default:     mrow = 5'd31;
  endcase

  wire mouth = in_face && (fdx <= 6'd4) &&
               ((sy == mrow) || (sy == mrow + 5'd1));

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
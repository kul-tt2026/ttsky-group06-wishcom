`default_nettype none
// ---------------------------------------------------------------------------
// CHEST_DRAW -- tekent EEN kist uit de sprite-ROM's.
//
// LOKALE COORDINATEN: (0,0) is de linkerbovenhoek van het vakje.
// Vakje is 128 x 128 op het scherm  (32 x 32 sprite, x4 geschaald).
//
//        y   0.. 63   deksel   (sprite rij  0..15)
//        y  64..127   bak      (sprite rij 16..31)
//
// TWEE APARTE UITGANGEN, en dat is het hele punt van deze module.  Het icoon
// moet VOOR het deksel maar ACHTER de bak zitten, dus renderer.v moet de
// lagen kunnen scheiden:
//
//        bak     (wint van alles)
//        icoon
//        deksel  (achtergrond)
//
// Zolang het icoon nog laag zit valt het achter de bak en zie je het niet.
// Zodra het boven de rand uitkomt is er geen bak-pixel meer en verschijnt
// het vanzelf.  Er is dus GEEN clipping-logica nodig -- de volgorde van de
// else-if keten in renderer.v doet het werk.
//
// px_code (gelijk aan de tabel in renderer.v):
//   1 = donker / outline    3 = goud
//   2 = hout                4 = wit (highlight-kader)
// ---------------------------------------------------------------------------
module chest_draw (
    input  wire [9:0] x,            // lokaal, 0..127
    input  wire [9:0] y,            // lokaal, 0..127
    input  wire       frame,        // 0 dicht, 1 open
    input  wire       highlighted,  // staat de cursor op mij?

    output wire       body_on,      // VOORGROND
    output wire [2:0] body_code,
    output wire       lid_on,       // ACHTERGROND
    output wire [2:0] lid_code
);

  localparam [9:0] BOX = 10'd192;   // 32 sprite-pixels x4

  // Boven/links van de origin wrapt de lokale coordinaat naar ~1023, dus een
  // enkele "< BOX" test vangt meteen ook de linker- en bovenrand af.  Geen
  // signed vergelijking nodig.
  wire in_box = (x < BOX) && (y < BOX);

  // Schaal x4: gewoon twee bits eraf schuiven.  Alleen machten van twee,
  // anders heb je een deler nodig.
  wire [15:0] xm = x[7:0] * 8'd171;
  wire [15:0] ym = y[7:0] * 8'd171;

  wire [4:0] sx = xm[14:10];        // 0..31 kolom in de sprite
  wire [4:0] sy = ym[14:10];        // 0..31 rij   in de sprite

  wire is_body = sy[4];             // rij 16..31 -> bak
  wire [3:0] srow = sy[3:0];        // rij binnen de laag

  // ---- ROM's -------------------------------------------------------------
  wire [1:0] lid_raw;
  chest_lid_rom u_lid (
    .frame (frame),
    .row   (srow),
    .col   (sx),
    .code  (lid_raw)
  );

  wire [1:0] body_raw;
  chest_body_rom u_body (
    .row   (srow),
    .col   (sx),
    .code  (body_raw)
  );

  // ---- highlight-kader ---------------------------------------------------
  // Rand van 4 px rond het vakje.  Goedkoper dan de kist groter tekenen: dat
  // zou een tweede schaalfactor vragen, en dus een tweede geometriepad.
  // De sprite raakt de buitenste 4 px nooit, dus overlap is uitgesloten.
  wire border = in_box && highlighted &&
                ((x < 10'd4) || (x >= BOX - 10'd4) ||
                 (y < 10'd4) || (y >= BOX - 10'd4));

  // ---- uitgangen ---------------------------------------------------------
  wire body_px = in_box &&  is_body && (body_raw != 2'd0);
  wire lid_px  = in_box && !is_body && (lid_raw  != 2'd0);

  assign body_on   = body_px;
  assign body_code = {1'b0, body_raw};

  // Het kader hangt aan de deksellaag: het ligt in de buitenste 4 px, waar
  // geen sprite-pixel komt, dus het botst nergens mee.
  assign lid_on    = lid_px || border;
  assign lid_code  = border ? 3'd4 : {1'b0, lid_raw};

endmodule
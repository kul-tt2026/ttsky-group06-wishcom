`default_nettype none
// ---------------------------------------------------------------------------
// ICON_DRAW -- tekent het pictogram dat IN een kist zit.
//
// Wiskundig, net als hearts.v en coinbar.v: geen sprite-ROM, alleen cirkels
// en rechthoeken.  Scheelt geheugen op de chip.
//
// LOKALE COORDINATEN: identiek aan chest_draw.v -- (0,0) is de linkerbovenhoek
// van het 192 x 192 vakje van die kist (32 x 32 sprite, x6 geschaald).  De
// plaatsing (CHEST_X / c_top) hoort in renderer.v, niet hier.
//
// LAAG: dit hoort in de cascade van renderer.v TUSSEN bak en deksel:
//
//        bak     (chest_body_on)   <- wint van alles
//        icoon   (deze module)
//        deksel  (chest_lid_on)
//
// Daardoor is er GEEN clipping nodig: alles onder y = 96 (sprite-rij 16, waar
// de bak begint) valt vanzelf achter de bak.  De iconen staan zo dat het
// grootste deel BOVEN die grens zit, dus je ziet ze bijna volledig zodra het
// deksel open is.
//
// LET OP: alle getallen hieronder horen bij BOX = 192.  Verander je de schaal
// in chest_draw.v, dan moeten deze mee -- ze staan vast, er wordt hier niet
// geschaald (dat zou een extra vermenigvuldiger kosten).
//
// px_code (zie icon_color in renderer.v):
//   1 = zwarte outline        5 = gifgroen
//   2 = goud                  6 = donkergroen (vloeistofrand)
//   3 = donkergoud            7 = kurk (bruin)
//   4 = wit (glans / glas)
// ---------------------------------------------------------------------------
module icon_draw (
    input  wire [9:0] x,          // lokaal, 0..191
    input  wire [9:0] y,          // lokaal, 0..191
    input  wire [2:0] icon,       // zelfde codering als chest_game.v

    output reg        px_on,
    output reg  [2:0] px_code
);

  // Zelfde nummers als de O_* localparams in chest_game.v.  Als je die daar
  // hernummert moet je ze HIER ook hernummeren.
  localparam [2:0] I_COIN   = 3'd0,
                   I_2X     = 3'd1,
                   I_CURSED = 3'd2,
                   I_BOMB   = 3'd3,
                   I_BOMB2  = 3'd4;

  // Boven/links van de origin wrapt de lokale coordinaat naar ~1023, dus een
  // enkele "< 192" test vangt meteen ook de linker- en bovenrand af.
  wire in_box = (x < 10'd192) && (y < 10'd192);

  wire is_coin = (icon == I_COIN);

  // ======================= gedeelde afstandsberekening ====================
  // Munt en flesbuik zijn allebei een cirkel, alleen met een ander middelpunt
  // en een andere straal.  Er is er altijd maar EEN tegelijk zichtbaar, dus we
  // rekenen ook maar EEN afstand uit -- dat scheelt een tweede paar
  // vermenigvuldigers.
  //
  //   munt : middelpunt (96, 69)
  //   fles : middelpunt (96, 78)   <- de buik
  wire [7:0] cy = is_coin ? 8'd69 : 8'd78;

  wire [7:0] dx = (x[7:0] >= 8'd96) ? (x[7:0] - 8'd96) : (8'd96 - x[7:0]);
  wire [7:0] dy = (y[7:0] >= cy)    ? (y[7:0] - cy)    : (cy - y[7:0]);

  wire [15:0] d2 = (dx * dx) + (dy * dy);

  // ======================= MUNT ===========================================
  wire coin_outer = (d2 <= 16'd1521);           // r = 39, buitenrand
  wire coin_gold  = (d2 <= 16'd1089);           // r = 33, gouden vlak
  wire coin_ring  = (d2 >= 16'd441) && (d2 <= 16'd625);  // r 21..25, reliefring

  // Glans linksboven.  Bewust een RUITJE en geen cirkel: een tweede cirkel
  // zou een tweede paar vermenigvuldigers kosten, een ruit alleen optellingen.
  wire [7:0] gx = (x[7:0] >= 8'd82) ? (x[7:0] - 8'd82) : (8'd82 - x[7:0]);
  wire [7:0] gy = (y[7:0] >= 8'd55) ? (y[7:0] - 8'd55) : (8'd55 - y[7:0]);
  wire coin_glint = ((gx + gy) <= 8'd8);

  // ======================= GIFDRANKJE =====================================
  // Kurk, hals en buik, elk met een buiten- en een binnenvorm.  Het verschil
  // tussen buiten en binnen IS de zwarte omtrek -- geen aparte randlogica.
  wire cork_out = (x >= 10'd84) && (x < 10'd108) && (y >= 10'd6)  && (y < 10'd27);
  wire cork_in  = (x >= 10'd88) && (x < 10'd104) && (y >= 10'd10) && (y < 10'd27);

  wire bulb_out = (d2 <= 16'd900);              // r = 30
  wire bulb_in  = (d2 <= 16'd484);              // r = 22

  wire neck_out = (x >= 10'd85) && (x < 10'd107) && (y >= 10'd21) && (y < 10'd81);
  wire neck_in  = (x >= 10'd91) && (x < 10'd101) && (y >= 10'd24) && (y < 10'd81);

  wire flask_out = bulb_out || neck_out;
  wire flask_in  = bulb_in  || neck_in;

  // Vloeistofniveau: alles onder y = 72 in de fles is drank, met een iets
  // donkerder bandje van 6 px als oppervlak.
  wire liquid  = flask_in && (y >= 10'd72);
  wire surface = liquid   && (y <  10'd78);

  // ======================= uitgangen ======================================
  always @(*) begin
    px_on   = 1'b0;
    px_code = 3'd0;

    if (in_box) begin
      case (icon)

        I_COIN: begin
          if (coin_outer) begin
            px_on = 1'b1;
            if      (!coin_gold)  px_code = 3'd1;   // zwarte rand
            else if (coin_glint)  px_code = 3'd4;   // witte glans
            else if (coin_ring)   px_code = 3'd3;   // donkergoud reliefring
            else                  px_code = 3'd2;   // goud
          end
        end

        I_CURSED: begin
          if (cork_out) begin
            px_on   = 1'b1;
            px_code = cork_in ? 3'd7 : 3'd1;        // kurk, met randje
          end else if (flask_out) begin
            px_on = 1'b1;
            if      (!flask_in) px_code = 3'd1;     // glaswand / omtrek
            else if (surface)   px_code = 3'd6;     // donkere vloeistofrand
            else if (liquid)    px_code = 3'd5;     // gifgroen
            else                px_code = 3'd4;     // leeg glas
          end
        end

        // TODO: I_2X (x2 met muntjes), I_BOMB (zwarte bom), I_BOMB2 (rode bom).
        // Voorlopig tekenen die niets -- de kist gaat dan gewoon leeg open.
        default: begin
          px_on   = 1'b0;
          px_code = 3'd0;
        end

      endcase
    end
  end

  wire _unused = &{I_2X, I_BOMB, I_BOMB2, x[9:8], y[9:8], 1'b0};

endmodule
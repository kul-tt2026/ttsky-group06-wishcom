`default_nettype none
// ---------------------------------------------------------------------------
// ICON_DRAW -- tekent het pictogram dat IN een kist zit.
//
// Wiskundig, net als hearts.v en satisfactionbar.v: geen sprite-ROM.
//
// LOKALE COORDINATEN: identiek aan chest_draw.v -- (0,0) is de linkerbovenhoek
// van het 128 x 128 vakje van die kist (32 x 32 sprite, x4 geschaald).
//
// GEEN ECHTE VERMENIGVULDIGING MEER.  Hier stond `dx*dx + dy*dy` en dat is
// variabele maal variabele, de dure soort -- zo'n 450 cellen voor die twee.
// Vervangen door een tabel met de halve breedte van de cirkel per rij, exact
// hetzelfde patroon als de bollen in hearts.v en de zon in background.v.  De
// tabel bevat halfbreedte+1, zodat 0 netjes "deze rij raakt de cirkel niet"
// betekent en we met "<" kunnen testen.
//
// Munt en flesbuik zijn allebei concentrische cirkels, en er is er altijd maar
// EEN zichtbaar, dus een tabel volstaat -- de inhoud hangt van `icon` af.
//
// De reliefring op de munt is eruit: die vroeg twee extra stralen en dus twee
// extra tabelkolommen, voor een detail dat je een halve seconde ziet.
//
// LAAG: dit hoort in de cascade van renderer.v TUSSEN bak en deksel:
//        bak (wint) > icoon > deksel
// Alles onder y = 64 valt vanzelf achter de bak; geen clipping nodig.
//
// px_code (zie icon_color in renderer.v):
//   1 = zwarte outline        5 = gifgroen
//   2 = goud                  6 = donkergroen (vloeistofrand)
//   3 = donkergoud            7 = kurk (bruin)
//   4 = wit (glans / glas)
// ---------------------------------------------------------------------------
module icon_draw (
    input  wire [9:0] x,          // lokaal, 0..127
    input  wire [9:0] y,          // lokaal, 0..127
    input  wire [2:0] icon,       // zelfde codering als chest_game.v

    output reg        px_on,
    output reg  [2:0] px_code
);

  // Zelfde nummers als de O_* localparams in chest_game.v.  Hernummer je die
  // daar, dan moeten ze HIER ook mee.
  localparam [2:0] I_COIN   = 3'd0,
                   I_2X     = 3'd1,
                   I_CURSED = 3'd2,
                   I_BOMB   = 3'd3,
                   I_BOMB2  = 3'd4;

  wire in_box = (x < 10'd128) && (y < 10'd128);

  wire is_coin = (icon == I_COIN);

  // ======================= gedeelde cirkelafstand =========================
  // Munt: middelpunt (64, 46), stralen 26 (buitenrand) en 22 (goud).
  // Fles : middelpunt (64, 52), stralen 20 (glas)      en 15 (binnen).
  wire [6:0] cy = is_coin ? 7'd46 : 7'd52;

  wire [6:0] dx = (x[6:0] >= 7'd64) ? (x[6:0] - 7'd64) : (7'd64 - x[6:0]);
  wire [6:0] dy = (y[6:0] >= cy)    ? (y[6:0] - cy)    : (cy - y[6:0]);

  // Halve breedte PLUS EEN per rij, voor de buiten- en de binnencirkel.
  reg [5:0] hw_out, hw_in;
  always @(*) begin
    if (is_coin) begin
      case (dy)                                  // r = 26 en r = 22
        7'd0:  begin hw_out=6'd27; hw_in=6'd23; end
        7'd1:  begin hw_out=6'd26; hw_in=6'd22; end
        7'd2:  begin hw_out=6'd26; hw_in=6'd22; end
        7'd3:  begin hw_out=6'd26; hw_in=6'd22; end
        7'd4:  begin hw_out=6'd26; hw_in=6'd22; end
        7'd5:  begin hw_out=6'd26; hw_in=6'd22; end
        7'd6:  begin hw_out=6'd26; hw_in=6'd22; end
        7'd7:  begin hw_out=6'd26; hw_in=6'd21; end
        7'd8:  begin hw_out=6'd25; hw_in=6'd21; end
        7'd9:  begin hw_out=6'd25; hw_in=6'd21; end
        7'd10: begin hw_out=6'd25; hw_in=6'd20; end
        7'd11: begin hw_out=6'd24; hw_in=6'd20; end
        7'd12: begin hw_out=6'd24; hw_in=6'd19; end
        7'd13: begin hw_out=6'd23; hw_in=6'd18; end
        7'd14: begin hw_out=6'd22; hw_in=6'd17; end
        7'd15: begin hw_out=6'd22; hw_in=6'd17; end
        7'd16: begin hw_out=6'd21; hw_in=6'd16; end
        7'd17: begin hw_out=6'd20; hw_in=6'd14; end
        7'd18: begin hw_out=6'd19; hw_in=6'd13; end
        7'd19: begin hw_out=6'd18; hw_in=6'd12; end
        7'd20: begin hw_out=6'd17; hw_in=6'd10; end
        7'd21: begin hw_out=6'd16; hw_in=6'd7;  end
        7'd22: begin hw_out=6'd14; hw_in=6'd1;  end
        7'd23: begin hw_out=6'd13; hw_in=6'd0;  end
        7'd24: begin hw_out=6'd11; hw_in=6'd0;  end
        7'd25: begin hw_out=6'd8;  hw_in=6'd0;  end
        7'd26: begin hw_out=6'd1;  hw_in=6'd0;  end
        default: begin hw_out=6'd0; hw_in=6'd0; end
      endcase
    end else begin
      case (dy)                                  // r = 20 en r = 15
        7'd0:  begin hw_out=6'd21; hw_in=6'd16; end
        7'd1:  begin hw_out=6'd20; hw_in=6'd15; end
        7'd2:  begin hw_out=6'd20; hw_in=6'd15; end
        7'd3:  begin hw_out=6'd20; hw_in=6'd15; end
        7'd4:  begin hw_out=6'd20; hw_in=6'd15; end
        7'd5:  begin hw_out=6'd20; hw_in=6'd15; end
        7'd6:  begin hw_out=6'd20; hw_in=6'd14; end
        7'd7:  begin hw_out=6'd19; hw_in=6'd14; end
        7'd8:  begin hw_out=6'd19; hw_in=6'd13; end
        7'd9:  begin hw_out=6'd18; hw_in=6'd13; end
        7'd10: begin hw_out=6'd18; hw_in=6'd12; end
        7'd11: begin hw_out=6'd17; hw_in=6'd11; end
        7'd12: begin hw_out=6'd17; hw_in=6'd10; end
        7'd13: begin hw_out=6'd16; hw_in=6'd8;  end
        7'd14: begin hw_out=6'd15; hw_in=6'd6;  end
        7'd15: begin hw_out=6'd14; hw_in=6'd1;  end
        7'd16: begin hw_out=6'd13; hw_in=6'd0;  end
        7'd17: begin hw_out=6'd11; hw_in=6'd0;  end
        7'd18: begin hw_out=6'd9;  hw_in=6'd0;  end
        7'd19: begin hw_out=6'd7;  hw_in=6'd0;  end
        7'd20: begin hw_out=6'd1;  hw_in=6'd0;  end
        default: begin hw_out=6'd0; hw_in=6'd0; end
      endcase
    end
  end

  wire circ_out = (dx < {1'b0, hw_out});
  wire circ_in  = (dx < {1'b0, hw_in});

  // ======================= MUNT ===========================================
  // Glans linksboven.  Bewust een RUITJE en geen cirkel: die kost alleen
  // optellingen, geen tweede tabel.
  wire [6:0] gx = (x[6:0] >= 7'd55) ? (x[6:0] - 7'd55) : (7'd55 - x[6:0]);
  wire [6:0] gy = (y[6:0] >= 7'd37) ? (y[6:0] - 7'd37) : (7'd37 - y[6:0]);
  wire coin_glint = ((gx + gy) <= 7'd5);

  // ======================= GIFDRANKJE =====================================
  // Kurk, hals en buik, elk met een buiten- en een binnenvorm.  Het verschil
  // tussen buiten en binnen IS de zwarte omtrek -- geen aparte randlogica.
  wire cork_out = (x >= 10'd56) && (x < 10'd72) && (y >= 10'd4)  && (y < 10'd18);
  wire cork_in  = (x >= 10'd59) && (x < 10'd69) && (y >= 10'd7)  && (y < 10'd18);

  wire neck_out = (x >= 10'd57) && (x < 10'd71) && (y >= 10'd14) && (y < 10'd54);
  wire neck_in  = (x >= 10'd61) && (x < 10'd67) && (y >= 10'd16) && (y < 10'd54);

  wire flask_out = circ_out || neck_out;
  wire flask_in  = circ_in  || neck_in;

  // Vloeistofniveau: alles onder y = 48 in de fles is drank, met een iets
  // donkerder bandje van 4 px als oppervlak.
  wire liquid  = flask_in && (y >= 10'd48);
  wire surface = liquid   && (y <  10'd52);

  // ======================= uitgangen ======================================
  always @(*) begin
    px_on   = 1'b0;
    px_code = 3'd0;

    if (in_box) begin
      case (icon)

        I_COIN: begin
          if (circ_out) begin
            px_on = 1'b1;
            if      (!circ_in)   px_code = 3'd1;   // zwarte rand
            else if (coin_glint) px_code = 3'd4;   // witte glans
            else                 px_code = 3'd2;   // goud
          end
        end

        I_CURSED: begin
          if (cork_out) begin
            px_on   = 1'b1;
            px_code = cork_in ? 3'd7 : 3'd1;       // kurk, met randje
          end else if (flask_out) begin
            px_on = 1'b1;
            if      (!flask_in) px_code = 3'd1;    // glaswand / omtrek
            else if (surface)   px_code = 3'd6;    // donkere vloeistofrand
            else if (liquid)    px_code = 3'd5;    // gifgroen
            else                px_code = 3'd4;    // leeg glas
          end
        end

        // TODO: I_2X, I_BOMB, I_BOMB2 -- zie de opmerking hieronder over een
        // gedeelde icoon-ROM; procedureel wordt elk nieuw icoon duur.
        default: begin
          px_on   = 1'b0;
          px_code = 3'd0;
        end

      endcase
    end
  end

  wire _unused = &{I_2X, I_BOMB, I_BOMB2, x[9:7], y[9:7], 1'b0};

endmodule
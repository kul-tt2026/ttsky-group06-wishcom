`default_nettype none
// ---------------------------------------------------------------------------
// DRAW_BUTTONS.  RENDER GROUP.  Puur combinatorisch, geen bitmap-ROM.
//
// Het knoppenpaneel (480 breed, 200 hoog) wiskundig getekend.  Referentie-
// beeld: docs/buttons_panel.png; de vormen hieronder zijn er 1-op-1 de bron
// van (docs/gen3.py).  Alle schuine randen: helling 2:1.  Witruimtes ~8 px.
//
// px_code: 0 transparant | 1 outline zwart | 2 donkerpaars
//         
//          4 wit (tekst + pijl)
// evolve_now laag -> middenknop kleurt donkerpaars mee (gedimd), geen
// aparte kleur nodig.
//
// Coordinaten: ABSOLUUT portret (x 0..479, y 0..639); het paneel plaatst
// zichzelf op BTN_Y.  Verplaatsen = 1 localparam.
// ---------------------------------------------------------------------------
module draw_buttons (
    input  wire [9:0] x,
    input  wire [9:0] y,
    output wire       px_on,
    output wire [2:0] px_code
);
  localparam [9:0] BTN_Y = 10'd420;

  wire        in_panel = (y >= BTN_Y) && (y < BTN_Y + 10'd200);
  wire [9:0]  lx = x;
  wire [9:0]  ly = in_panel ? (y - BTN_Y) : 10'd0;

  wire [9:0] xm  = 10'd480 - lx;                 // spiegel links<->rechts
  wire [9:0] ym  = 10'd200 - ly;                 // spiegel boven<->onder
  wire [9:0] adx = (lx >= 10'd240) ? (lx - 10'd240) : (10'd240 - lx);
  wire [9:0] ady = (ly >= 10'd100) ? (ly - 10'd100) : (10'd100 - ly);

  // ---- trapezium BOVEN: 6<=y<=52, |x-240| + 2(y-6) <= 152 ----------------
  // (som-vorm: alles blijft unsigned, nooit onderloop)
  wire top_o = (ly>=10'd6)  && (ly<=10'd52) && (adx + ((ly-10'd6)<<1) <= 10'd152);
  wire top_i = (ly>=10'd12) && (ly<=10'd46) && (adx + ((ly-10'd6)<<1) <= 10'd138);

  // ---- trapezium ONDER: zelfde test op de gespiegelde y ------------------
  wire bot_o = (ym>=10'd6)  && (ym<=10'd52) && (adx + ((ym-10'd6)<<1) <= 10'd152);
  wire bot_i = (ym>=10'd12) && (ym<=10'd46) && (adx + ((ym-10'd6)<<1) <= 10'd138);

  // ---- trapezium LINKS: randen parallel (2:1) aan boven/onder ------------
  //  x>=88, x<=160, x <= 58+2y (bovenrand), x+2y <= 458 (onderrand)
  wire lft_o = (lx>=10'd88) && (lx<=10'd160) &&
               (lx <= 10'd58 + (ly<<1)) && (lx + (ly<<1) <= 10'd458);
  wire lft_i = (lx>=10'd94) && (lx<=10'd154) &&
               (lx <= 10'd45 + (ly<<1)) && (lx + (ly<<1) <= 10'd445);

  // ---- trapezium RECHTS: zelfde test op de gespiegelde x -----------------
  wire rgt_o = (xm>=10'd88) && (xm<=10'd160) &&
               (xm <= 10'd58 + (ly<<1)) && (xm + (ly<<1) <= 10'd458);
  wire rgt_i = (xm>=10'd94) && (xm<=10'd154) &&
               (xm <= 10'd45 + (ly<<1)) && (xm + (ly<<1) <= 10'd445);

  // ---- ELLIPS via per-rij halfbreedte-ROM (geen vermenigvuldigers) -------
  // Tabel = halfbreedte+1 per rij (0 = niets), uit dezelfde kwadratische
  // test berekend; pixel-identiek aan het referentiebeeld, geen tip-puntjes.
  reg [6:0] ehw_o;
  always @(*) case (ady[5:0])
      6'd0: ehw_o = 7'd72;
      6'd1: ehw_o = 7'd72;
      6'd2: ehw_o = 7'd72;
      6'd3: ehw_o = 7'd72;
      6'd4: ehw_o = 7'd72;
      6'd5: ehw_o = 7'd71;
      6'd6: ehw_o = 7'd71;
      6'd7: ehw_o = 7'd71;
      6'd8: ehw_o = 7'd71;
      6'd9: ehw_o = 7'd70;
      6'd10: ehw_o = 7'd70;
      6'd11: ehw_o = 7'd69;
      6'd12: ehw_o = 7'd69;
      6'd13: ehw_o = 7'd68;
      6'd14: ehw_o = 7'd67;
      6'd15: ehw_o = 7'd67;
      6'd16: ehw_o = 7'd66;
      6'd17: ehw_o = 7'd65;
      6'd18: ehw_o = 7'd64;
      6'd19: ehw_o = 7'd63;
      6'd20: ehw_o = 7'd62;
      6'd21: ehw_o = 7'd61;
      6'd22: ehw_o = 7'd60;
      6'd23: ehw_o = 7'd59;
      6'd24: ehw_o = 7'd57;
      6'd25: ehw_o = 7'd56;
      6'd26: ehw_o = 7'd54;
      6'd27: ehw_o = 7'd53;
      6'd28: ehw_o = 7'd51;
      6'd29: ehw_o = 7'd49;
      6'd30: ehw_o = 7'd47;
      6'd31: ehw_o = 7'd45;
      6'd32: ehw_o = 7'd42;
      6'd33: ehw_o = 7'd40;
      6'd34: ehw_o = 7'd37;
      6'd35: ehw_o = 7'd34;
      6'd36: ehw_o = 7'd30;
      6'd37: ehw_o = 7'd26;
      6'd38: ehw_o = 7'd20;
      6'd39: ehw_o = 7'd12;
      6'd40: ehw_o = 7'd0;
      default: ehw_o = 7'd0;
    endcase
  reg [6:0] ehw_i;
  always @(*) case (ady[5:0])
      6'd0: ehw_i = 7'd66;
      6'd1: ehw_i = 7'd66;
      6'd2: ehw_i = 7'd66;
      6'd3: ehw_i = 7'd66;
      6'd4: ehw_i = 7'd66;
      6'd5: ehw_i = 7'd65;
      6'd6: ehw_i = 7'd65;
      6'd7: ehw_i = 7'd65;
      6'd8: ehw_i = 7'd64;
      6'd9: ehw_i = 7'd64;
      6'd10: ehw_i = 7'd63;
      6'd11: ehw_i = 7'd62;
      6'd12: ehw_i = 7'd62;
      6'd13: ehw_i = 7'd61;
      6'd14: ehw_i = 7'd60;
      6'd15: ehw_i = 7'd59;
      6'd16: ehw_i = 7'd58;
      6'd17: ehw_i = 7'd57;
      6'd18: ehw_i = 7'd56;
      6'd19: ehw_i = 7'd54;
      6'd20: ehw_i = 7'd53;
      6'd21: ehw_i = 7'd52;
      6'd22: ehw_i = 7'd50;
      6'd23: ehw_i = 7'd48;
      6'd24: ehw_i = 7'd46;
      6'd25: ehw_i = 7'd44;
      6'd26: ehw_i = 7'd42;
      6'd27: ehw_i = 7'd39;
      6'd28: ehw_i = 7'd36;
      6'd29: ehw_i = 7'd33;
      6'd30: ehw_i = 7'd30;
      6'd31: ehw_i = 7'd25;
      6'd32: ehw_i = 7'd20;
      6'd33: ehw_i = 7'd12;
      6'd34: ehw_i = 7'd0;
      6'd35: ehw_i = 7'd0;
      6'd36: ehw_i = 7'd0;
      6'd37: ehw_i = 7'd0;
      6'd38: ehw_i = 7'd0;
      6'd39: ehw_i = 7'd0;
      6'd40: ehw_i = 7'd0;
      default: ehw_i = 7'd0;
    endcase
  wire ell_o = (ady <= 10'd40) && ({3'b0, adx[6:0]} < {3'b0, ehw_o}) && (adx <= 10'd72);
  wire ell_i = (ady <= 10'd40) && ({3'b0, adx[6:0]} < {3'b0, ehw_i}) && (adx <= 10'd72);

   // ======================= TEKST: 3x5 font op schaal 4 ====================
  // lettercel 16 px breed (12 glyph + 4 spatie), 20 px hoog
  //
  // De vijf woorden staan op VIJF VERSCHILLENDE plekken van het paneel, dus
  // er kan er hooguit een tegelijk actief zijn.  Daarom muxen we eerst de
  // INVOER naar EEN enkele opzoeking.  Roep je frow() vijf keer aan, dan
  // lijnt de synthese die tabel van zeventig ingangen ook vijf keer in --
  // vier volledige kopieen die nooit tegelijk iets doen.  Zelfde reden
  // waarom renderer.v maar EEN title_egg instantieert voor twee modes.
  function [2:0] frow; input [3:0] ch; input [2:0] row; begin
    case ({ch, row})
      {4'd0,3'd0}: frow = 3'b010;
      {4'd0,3'd1}: frow = 3'b101;
      {4'd0,3'd2}: frow = 3'b111;
      {4'd0,3'd3}: frow = 3'b101;
      {4'd0,3'd4}: frow = 3'b101;
      {4'd1,3'd0}: frow = 3'b110;
      {4'd1,3'd1}: frow = 3'b101;
      {4'd1,3'd2}: frow = 3'b101;
      {4'd1,3'd3}: frow = 3'b101;
      {4'd1,3'd4}: frow = 3'b110;
      {4'd2,3'd0}: frow = 3'b111;
      {4'd2,3'd1}: frow = 3'b100;
      {4'd2,3'd2}: frow = 3'b110;
      {4'd2,3'd3}: frow = 3'b100;
      {4'd2,3'd4}: frow = 3'b111;
      {4'd3,3'd0}: frow = 3'b111;
      {4'd3,3'd1}: frow = 3'b100;
      {4'd3,3'd2}: frow = 3'b110;
      {4'd3,3'd3}: frow = 3'b100;
      {4'd3,3'd4}: frow = 3'b100;
      {4'd4,3'd0}: frow = 3'b111;
      {4'd4,3'd1}: frow = 3'b010;
      {4'd4,3'd2}: frow = 3'b010;
      {4'd4,3'd3}: frow = 3'b010;
      {4'd4,3'd4}: frow = 3'b111;
      {4'd5,3'd0}: frow = 3'b101;
      {4'd5,3'd1}: frow = 3'b101;
      {4'd5,3'd2}: frow = 3'b110;
      {4'd5,3'd3}: frow = 3'b101;
      {4'd5,3'd4}: frow = 3'b101;
      {4'd6,3'd0}: frow = 3'b100;
      {4'd6,3'd1}: frow = 3'b100;
      {4'd6,3'd2}: frow = 3'b100;
      {4'd6,3'd3}: frow = 3'b100;
      {4'd6,3'd4}: frow = 3'b111;
      {4'd7,3'd0}: frow = 3'b101;
      {4'd7,3'd1}: frow = 3'b111;
      {4'd7,3'd2}: frow = 3'b101;
      {4'd7,3'd3}: frow = 3'b101;
      {4'd7,3'd4}: frow = 3'b101;
      {4'd8,3'd0}: frow = 3'b111;
      {4'd8,3'd1}: frow = 3'b101;
      {4'd8,3'd2}: frow = 3'b101;
      {4'd8,3'd3}: frow = 3'b101;
      {4'd8,3'd4}: frow = 3'b111;
      {4'd9,3'd0}: frow = 3'b110;
      {4'd9,3'd1}: frow = 3'b101;
      {4'd9,3'd2}: frow = 3'b110;
      {4'd9,3'd3}: frow = 3'b100;
      {4'd9,3'd4}: frow = 3'b100;
      {4'd10,3'd0}: frow = 3'b110;
      {4'd10,3'd1}: frow = 3'b101;
      {4'd10,3'd2}: frow = 3'b110;
      {4'd10,3'd3}: frow = 3'b101;
      {4'd10,3'd4}: frow = 3'b101;
      {4'd11,3'd0}: frow = 3'b011;
      {4'd11,3'd1}: frow = 3'b100;
      {4'd11,3'd2}: frow = 3'b010;
      {4'd11,3'd3}: frow = 3'b001;
      {4'd11,3'd4}: frow = 3'b110;
      {4'd12,3'd0}: frow = 3'b101;
      {4'd12,3'd1}: frow = 3'b101;
      {4'd12,3'd2}: frow = 3'b101;
      {4'd12,3'd3}: frow = 3'b101;
      {4'd12,3'd4}: frow = 3'b010;
      {4'd13,3'd0}: frow = 3'b101;
      {4'd13,3'd1}: frow = 3'b101;
      {4'd13,3'd2}: frow = 3'b010;
      {4'd13,3'd3}: frow = 3'b010;
      {4'd13,3'd4}: frow = 3'b010;
      default: frow = 3'b000;
    endcase
  end endfunction

  // ---- de vijf tekstvakken: alleen vak, positie en letterkeuze -----------
  // ---- DRINK ----
  wire wd_box = (lx>=10'd202)&&(lx<=10'd277)&&(ly>=10'd19)&&(ly<=10'd38);
  wire [9:0] wd_u = lx - 10'd202;
  wire [9:0] wd_v = ly - 10'd19;
  reg [3:0] wd_ch;
  always @(*) case (wd_u[9:4])
      4'd0: wd_ch = 4'd1;
      4'd1: wd_ch = 4'd10;
      4'd2: wd_ch = 4'd4;
      4'd3: wd_ch = 4'd7;
      4'd4: wd_ch = 4'd5;
      default: wd_ch = 4'd0;
    endcase

  // ---- PLAY ----
  wire wp_box = (lx>=10'd210)&&(lx<=10'd269)&&(ly>=10'd161)&&(ly<=10'd180);
  wire [9:0] wp_u = lx - 10'd210;
  wire [9:0] wp_v = ly - 10'd161;
  reg [3:0] wp_ch;
  always @(*) case (wp_u[9:4])
      4'd0: wp_ch = 4'd9;
      4'd1: wp_ch = 4'd6;
      4'd2: wp_ch = 4'd0;
      4'd3: wp_ch = 4'd13;
      default: wp_ch = 4'd0;
    endcase

  // ---- EVOLVE ----
  wire we_box = (lx>=10'd194)&&(lx<=10'd285)&&(ly>=10'd96)&&(ly<=10'd115);
  wire [9:0] we_u = lx - 10'd194;
  wire [9:0] we_v = ly - 10'd96;
  reg [3:0] we_ch;
  always @(*) case (we_u[9:4])
      4'd0: we_ch = 4'd2;
      4'd1: we_ch = 4'd12;
      4'd2: we_ch = 4'd8;
      4'd3: we_ch = 4'd6;
      4'd4: we_ch = 4'd12;
      4'd5: we_ch = 4'd2;
      default: we_ch = 4'd0;
    endcase

  // ---- FEED (staand: u loopt langs y, v langs x) ----
  wire wf_box = (lx>=10'd114)&&(lx<=10'd133)&&(ly>=10'd70)&&(ly<=10'd129);
  wire [9:0] wf_u = 10'd129 - ly;
  wire [9:0] wf_v = lx - 10'd114;
  reg [3:0] wf_ch;
  always @(*) case (wf_u[9:4])
      4'd0: wf_ch = 4'd3;
      4'd1: wf_ch = 4'd2;
      4'd2: wf_ch = 4'd2;
      4'd3: wf_ch = 4'd1;
      default: wf_ch = 4'd0;
    endcase

  // ---- SLEEP (staand, andere kant op) ----
  wire ws_box = (lx>=10'd346)&&(lx<=10'd365)&&(ly>=10'd62)&&(ly<=10'd137);
  wire [9:0] ws_u = ly - 10'd62;
  wire [9:0] ws_v = 10'd365 - lx;
  reg [3:0] ws_ch;
  always @(*) case (ws_u[9:4])
      4'd0: ws_ch = 4'd11;
      4'd1: ws_ch = 4'd6;
      4'd2: ws_ch = 4'd2;
      4'd3: ws_ch = 4'd2;
      4'd4: ws_ch = 4'd9;
      default: ws_ch = 4'd0;
    endcase

  // ---- EEN gedeelde opzoeking voor alle vijf -----------------------------
  // De vakken sluiten elkaar uit, dus deze prioriteitsketen is gewoon een
  // keuze -- geen van de takken kan met een andere botsen.
  wire [3:0] f_ch  = wd_box ? wd_ch     : wp_box ? wp_ch     :
                     we_box ? we_ch     : wf_box ? wf_ch     : ws_ch;
  wire [2:0] f_row = wd_box ? wd_v[4:2] : wp_box ? wp_v[4:2] :
                     we_box ? we_v[4:2] : wf_box ? wf_v[4:2] : ws_v[4:2];
  wire [1:0] f_col = wd_box ? wd_u[3:2] : wp_box ? wp_u[3:2] :
                     we_box ? we_u[3:2] : wf_box ? wf_u[3:2] : ws_u[3:2];

  wire [2:0] f_bits = frow(f_ch, f_row);
  wire       in_word = wd_box | wp_box | we_box | wf_box | ws_box;
  wire       word_on = in_word && (f_col != 2'b11) &&
                       ( (f_col == 2'b00) ? f_bits[2]
                       : (f_col == 2'b01) ? f_bits[1] : f_bits[0] );

  // ---- pijl omhoog boven EVOLVE ------------------------------------------
  wire arr_head = (ly>=10'd71) && (ly<=10'd81) && (adx <= ly - 10'd71);
  wire arr_stem = (ly>=10'd82) && (ly<=10'd91) && (adx <= 10'd4);

  wire any_text = word_on | arr_head | arr_stem;
  wire any_fill_dark = top_i | bot_i | lft_i | rgt_i;
  wire any_out  = (top_o|bot_o|lft_o|rgt_o|ell_o) & ~(any_fill_dark|ell_i);

  assign px_code = !in_panel      ? 3'd0 :
                   any_text       ? 3'd4 :
                   any_out        ? 3'd1 :
                   any_fill_dark  ? 3'd2 :
                   ell_i          ? 3'd3 : 3'd0;
  assign px_on = (px_code != 3'd0);
endmodule
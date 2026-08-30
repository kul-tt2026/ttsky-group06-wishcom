`default_nettype none
// ---------------------------------------------------------------------------
// DRAW_BUTTONS.  RENDER GROUP.  Puur combinatorisch, geen bitmap-ROM.
//
// Het knoppenpaneel (480 breed, 200 hoog) wiskundig getekend.  Alle schuine
// randen: helling 2:1.  Witruimtes 8 px.
//
// De middenknop was een ellips met twee tabellen van 41 ingangen voor de
// halfbreedte per rij; die kostten samen zo'n 300 cellen.  Nu is het een
// rechthoek met exact dezelfde 8 px speling tot de vier trapezia: die
// eindigen op ly 52 / ly 148 / lx 160 / lx 320, en de rechthoek loopt van
// lx 168 tot 312 en van ly 60 tot 140.  Daardoor verdween ook `ady`, die
// nergens anders voor diende.
//
// px_code: 0 transparant | 1 outline zwart | 2 donkerpaars
//          3 middenknop-vulling | 4 wit (tekst + pijl)
// evolve_now laag -> middenknop kleurt gedimd mee, geen aparte kleur nodig.
//
// Coordinaten: ABSOLUUT portret (x 0..479, y 0..639); het paneel plaatst
// zichzelf op BTN_Y.  Verplaatsen = 1 localparam.
// ---------------------------------------------------------------------------
module draw_buttons (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [7:0] btn_level,   // {evolve, sleep, feed, play, drink}, actief = ingedrukt
                                   // VASTGEHOUDEN toestand uit buttons.v (`level`).
                                   // NIET btn_pressed: die is maar een klokcyclus
                                   // hoog en dus onzichtbaar.  En niet te
                                   // verwarren met `level` van de draak.

    output wire       px_on,
    output wire [2:0] px_code
);
  localparam [9:0] BTN_Y = 10'd420;
  localparam BTN_EVOLVE = 3'd1,
             BTN_FEED   = 3'd4,
             BTN_DRINK  = 3'd5,
             BTN_SLEEP  = 3'd6,
             BTN_PLAY   = 3'd7;

  wire        in_panel = (y >= BTN_Y) && (y < BTN_Y + 10'd200);
  wire [9:0]  lx = x;
  wire [9:0]  ly = in_panel ? (y - BTN_Y) : 10'd0;

  wire [9:0] xm  = 10'd480 - lx;                 // spiegel links<->rechts
  wire [9:0] ym  = 10'd200 - ly;                 // spiegel boven<->onder
  wire [9:0] adx = (lx >= 10'd240) ? (lx - 10'd240) : (10'd240 - lx);

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

  // ---- MIDDENKNOP: rechthoek, 8 px vrij van alle vier de trapezia --------
  // Boven eindigt op ly 52, onder begint op ly 148, links eindigt op lx 160,
  // rechts begint op lx 320.  Vandaar 60..140 en 168..312.  Randdikte 6,
  // net als bij de trapezia.
  localparam [9:0] EV_HW = 10'd72;      // halve breedte  (240 +- 72)
  localparam [9:0] EV_Y0 = 10'd60;      // bovenkant
  localparam [9:0] EV_Y1 = 10'd140;     // onderkant
  localparam [9:0] EV_B  = 10'd6;       // randdikte

  wire ell_o = (adx <= EV_HW) &&
               (ly >= EV_Y0) && (ly <= EV_Y1);
  wire ell_i = (adx <= EV_HW - EV_B) &&
               (ly >= EV_Y0 + EV_B) && (ly <= EV_Y1 - EV_B);

  // ======================= TEKST: 3x5 font op schaal 4 ====================
  // lettercel 16 px breed (12 glyph + 4 spatie), 20 px hoog
  //
  // De vijf woorden staan op VIJF VERSCHILLENDE plekken van het paneel, dus
  // er kan er hooguit een tegelijk actief zijn.  Daarom muxen we eerst de
  // INVOER naar EEN enkele opzoeking.  Roep je frow() vijf keer aan, dan
  // lijnt de synthese die tabel van zeventig ingangen ook vijf keer in --
  // vier volledige kopieen die nooit tegelijk iets doen.  Zelfde reden
  // waarom renderer.v maar EEN title_egg instantieert voor twee modes.
  //              DRINK
  //     FEED     EVOLVE     SLEEP
  //              PLAY
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
  always @(*) case (wd_u[7:4])          // 4 bits: de letterindex komt nooit boven 5
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
  always @(*) case (wp_u[7:4])
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
  always @(*) case (we_u[7:4])
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
  always @(*) case (wf_u[7:4])
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
  always @(*) case (ws_u[7:4])
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

  // ======================= samenstellen ===================================
  // ---- ingedrukte knop licht op ------------------------------------------
  // De vijf vullingen bestaan al; dit is alleen een extra kleur ertussen.
  // btn_level komt uit buttons.v en blijft hoog zolang de speler drukt, dus
  // je ziet het echt -- `pressed` daar duurt maar een klokcyclus.
  wire lit = (top_i & btn_level[BTN_DRINK])  |   // boven
             (lft_i & btn_level[BTN_FEED])   |   // links
             (rgt_i & btn_level[BTN_SLEEP])  |   // rechts
             (bot_i & btn_level[BTN_PLAY])   |   // onder
             (ell_i & btn_level[BTN_EVOLVE]);    // midden
  
  
  wire any_fill_dark = top_i | bot_i | lft_i | rgt_i;
  wire any_out  = (top_o|bot_o|lft_o|rgt_o|ell_o) & ~(any_fill_dark|ell_i);
  
  assign px_code = !in_panel      ? 3'd0 :
                   any_text       ? 3'd4 :
                   any_out        ? 3'd1 :
                   lit            ? 3'd5 :
                   any_fill_dark  ? 3'd2 :
                   ell_i          ? 3'd3 : 3'd0;
  assign px_on = (px_code != 3'd0);

  wire _unused = &{wd_u[9:8], wd_u[1:0], wd_v[9:5], wd_v[1:0], wp_u[9:8], wp_u[1:0], wp_v[9:5], wp_v[1:0], we_u[9:8], we_u[1:0], we_v[9:5], we_v[1:0], wf_u[9:8], wf_u[1:0], wf_v[9:5], wf_v[1:0], ws_u[9:8], ws_u[1:0], ws_v[9:5], ws_v[1:0], 1'b0};
endmodule
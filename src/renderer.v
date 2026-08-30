`default_nettype none
// ---------------------------------------------------------------------------
//
//   1. PLACE things: subtract each drawable's origin -> local coordinates
//   2. SHOW things: per composition, which drawables are visible
//   3. STACK things: the layer cascade (first visible layer wins)
//   4. COLOUR things: map each drawable's px_code to real RGB
//
// GEDEELDE TABELLEN.  Waar twee dingen dezelfde tabel gebruiken en elkaar per
// pixel uitsluiten, staat er EEN opzoeking met gemuxte invoer in plaats van
// twee of vier kopieen.  Dat geldt voor:
//   * het palet van de draak en het titel-ei (andere modes)
//   * de kleur van de kistbodem en het deksel (de STACK kiest er altijd een)
//   * digit_rom, gedeeld door het menu, de munten en het level
// ---------------------------------------------------------------------------
module renderer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire       video_active,

    input  wire [2:0] mode,  // 0 TITLE, 1 EGG, 2 HOME, 3 CHEST, 4 GAMEOVER, 5 YOU_WIN
    input  wire [2:0] menu_sel,
    input  wire [2:0] hearts, // 3 bit
    input  wire [2:0] satisfaction, // 3 bit => 5 options
    input  wire [1:0] dragon_bob,
    input  wire [9:0] coins, //tot 1000: level 1 20, level 2 40, level 3 80, level 160
    input  wire [2:0] level, // max 7 levels

    input  wire       evolve_now, // of je genoeg geld hebt om te evolven
    input  wire [1:0] combo_len, // ongebruikt

    input  wire [1:0] chest_state, // 0 closed, 1 opening, 2 open, 3 menu
    input  wire [1:0] chest_sel, // welke kist is selected (0,1,2)
    input  wire [2:0] chest_outcome, // bevat alleen gekozen kist

    input  wire       flash,
    input  wire       evolve_blink,

    input  wire       night,

    input  wire       frame_tick, // voor animatie van ei
    input  wire [7:0] btn_level,

    input  wire [1:0] fx_kind,
    input  wire       fx_on,
    input  wire [6:0] fx_age,

    input  wire [2:0] level_shown, 
    input  wire       evo_on,
    input  wire [9:0] evo_r, 

    input  wire       overflow, // als hartjes vol of geld vol
    input  wire [8:0] chest_contents,  // {kist2, kist1, kist0}, 3 bits elk
    input  wire [9:0] pot,             // groot tonen, los van coins
    input  wire [3:0] round,           // teken round+1
    input  wire [2:0] egg_frame,       // 0=whole, 1-4=cracks, 5=flashing
    input  wire [9:0] flash_r,         // straal van de flits
    output reg  [1:0] R,
    output reg  [1:0] G,
    output reg  [1:0] B
);
  localparam [2:0] M_TITLE    = 3'd0,
                   M_EGG      = 3'd1,
                   M_HOME     = 3'd2,
                   M_CHEST    = 3'd3,
                   M_GAMEOVER = 3'd4,
                   M_YOU_WIN  = 3'd5;

  // ======================= 0. ROTATE ======================================
  // Fysiek scherm: 640x480 liggend.  Wij tekenen in PORTRET: 480 x 640.
  // De monitor staat 90 graden gedraaid.
  wire [9:0] px = pix_y;              // 0..479  -> portret-breedte
  wire [9:0] py = 10'd639 - pix_x;    // 0..639  -> portret-hoogte

  // Titel en ei delen alles behalve PRESS ANY BUTTON; die vergelijking hebben
  // we op twee plekken nodig, dus een keer uitrekenen.
  wire in_title = (mode == M_TITLE) || (mode == M_EGG);

  // ======================= 1. PLACE =======================================
  // Every position is a constant HERE, in one file.  Moving anything on
  // screen is a one-line edit.

  localparam [9:0] HEARTS_X  = 10'd270, HEARTS_Y  = 10'd16;  // 304 x 24
  localparam [9:0] SATBAR_X  = 10'd85,  SATBAR_Y  = 10'd318; // 162 x 24
  localparam [9:0] COINBAR_X = 10'd24,  COINBAR_Y = 10'd50;  //  40 x 220
  localparam [9:0] LEVEL_X   = 10'd24,   LEVEL_Y   = 10'd24;   //  48 x 18

  localparam DRAGON_X = 10'd0, DRAGON_Y = 10'd0;
  localparam [9:0] CHEST_X     = 10'd176;   // horizontaal gecentreerd
  localparam [9:0] CHEST_Y0    = 10'd204;   // 18 px onder de bies
  localparam [9:0] CHEST_PITCH = 10'd145;   // 128 kist + 17 tussenruimte
  localparam [9:0] CHEST_BOX   = 10'd128;

  localparam [1:0] C_PICK = 2'd0, C_OPEN = 2'd1, C_RESULT = 2'd2;

  // ======================= drawable instances =============================

  // TITELKAART -------------------------------------------------------------
  wire       title_on;
  wire [2:0] title_code;
  title_card u_title (
    .x(px), .y(py),
    .px_on(title_on), .px_code(title_code)
  );

  // EI OP GRAS + BARST + FLITS + PRESS ANY BUTTON --------------------------
  // Precies EEN instantie, gedeeld door M_TITLE en M_EGG.  Twee instanties
  // zetten alle tabellen twee keer op de chip.
  wire       tegg_on, crack_on, flash_on, flash_rim, press_on;
  wire       tground_on, tground_shadow;
  wire [2:0] tegg_code;
  wire [9:0] fl_cx = evo_on ? 10'd283 : 10'd240;
  wire [9:0] fl_cy = evo_on ? 10'd236 : 10'd462;
  wire [9:0] fl_r  = evo_on ? evo_r   : flash_r;

  title_egg u_title_egg (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .x(px), .y(py),
    .egg_frame(egg_frame), .flash_r(flash_r), .flash_cx(fl_cx),
    .egg_on(tegg_on),   .egg_code(tegg_code), .flash_cy(fl_cy),
    .crack_on(crack_on),
    .flash_on(flash_on), .flash_rim(flash_rim),
    .press_on(press_on),
    .ground_on(tground_on), .ground_shadow(tground_shadow)
  );

  // DRAGON -----------------------------------------------------------------
  // uiterlijk draak hangt af van level; mood beinvloedt voorlopig alleen
  // de animatie, niet het uiterlijk.
  wire       dragon_on;    // of er een pixel van de draak is
  wire [2:0] dragon_code;  // welke kleur die dan krijgt

  dragon_draw u_dragon (
    .x(px - DRAGON_X), .y(py - DRAGON_Y),
    .dragon_bob(dragon_bob),
    .px_on(dragon_on), .px_code(dragon_code),
    .level(level_shown), .clk(clk), .rst_n(rst_n)
  );

  // THREE CHESTS -----------------------------------------------------------
  // Drie standen:
  //  - PICK   : alle drie dicht, die van chest_sel opgelicht
  //  - OPEN   : de gekozen kist open met zijn pictogram, andere twee dicht
  //  - RESULT : alle drie open, de niet-gekozen doffer
  reg  [1:0] c_slot;      // 0, 1 of 2
  reg  [9:0] c_top;       // bovenkant van die rij
  reg        c_inrow;

  always @(*) begin
    if (py >= CHEST_Y0 && py < CHEST_Y0 + CHEST_BOX) begin
      c_slot = 2'd0;  c_top = CHEST_Y0;                       c_inrow = 1'b1;
    end else if (py >= CHEST_Y0 + CHEST_PITCH &&
                 py <  CHEST_Y0 + CHEST_PITCH + CHEST_BOX) begin
      c_slot = 2'd1;  c_top = CHEST_Y0 + CHEST_PITCH;         c_inrow = 1'b1;
    end else if (py >= CHEST_Y0 + (CHEST_PITCH << 1) &&
                 py <  CHEST_Y0 + (CHEST_PITCH << 1) + CHEST_BOX) begin
      c_slot = 2'd2;  c_top = CHEST_Y0 + (CHEST_PITCH << 1);  c_inrow = 1'b1;
    end else begin
      c_slot = 2'd0;  c_top = CHEST_Y0;                       c_inrow = 1'b0;
    end
  end

  wire c_is_sel = (c_slot == chest_sel);

  // De gekozen kist gaat open zodra we uit PICK zijn, de andere twee pas
  // in RESULT.
  wire c_frame = c_is_sel ? (chest_state != C_PICK)
                          : (chest_state == C_RESULT);

  // In RESULT worden de niet-gekozen kisten doffer, zodat de aandacht naar
  // de gekozen kist gaat.
  wire c_dim = (chest_state == C_RESULT) && !c_is_sel;

  wire       c_body_on, c_lid_on;
  wire [2:0] c_body_code, c_lid_code;
  wire in_chest    = (mode == M_CHEST);
  wire show_menu   = in_chest;                            // HUD altijd
  wire show_chests = in_chest && (chest_state != 2'd3);
  
  chest_draw u_chest (
    .x           (px - CHEST_X),
    .y           (py - c_top),
    .frame       (c_frame),
    .highlighted (c_is_sel && (chest_state == C_PICK)),
    .body_on     (c_body_on),
    .body_code   (c_body_code),
    .lid_on      (c_lid_on),
    .lid_code    (c_lid_code)
  );

  wire chest_body_on = show_chests && c_inrow && c_body_on;
  wire chest_lid_on  = show_chests && c_inrow && c_lid_on;

  // Welke inhoud hoort bij DEZE rij?  chest_contents is {kist2, kist1, kist0}.
  reg [2:0] c_content;
  always @(*) begin
    case (c_slot)
      2'd0:    c_content = chest_contents[2:0];
      2'd1:    c_content = chest_contents[5:3];
      default: c_content = chest_contents[8:6];
    endcase
  end

  // De gekozen kist verklapt zich al in OPEN, de andere twee pas in RESULT.
  wire c_show_icon = (chest_state == C_RESULT) ||
                     ((chest_state == C_OPEN) && c_is_sel);

  wire       c_icon_on;
  wire [2:0] c_icon_code;
  icon_draw u_icon (
    .x       (px - CHEST_X),
    .y       (py - c_top),
    .icon    (c_content),
    .px_on   (c_icon_on),
    .px_code (c_icon_code)
  );

  wire chest_icon_on = show_chests && c_inrow && c_show_icon && c_icon_on;

  // ======================= EEN GEDEELDE CIJFERTABEL =======================
  // Vier getallen op het scherm -- het rondenummer en de pot in het menu, de
  // munten, en het level -- en ze staan alle vier op plekken die elkaar
  // nergens overlappen.  Dus EEN digit_rom met gemuxte invoer, in plaats van
  // vier kopieen van 74 cellen waarvan er altijd drie niets doen.
  //
  // Dit ZIET eruit als een combinatorische lus (bits gaan omlaag, digit komt
  // omhoog) maar is het niet: q_digit en q_on hangen alleen van de positie en
  // de waarde af, nooit van q_bits.  Niet "repareren".
  //
  // LET OP: de mux is een prioriteitsketen, geen echte keuze.  Verplaats je
  // een van de vier zo dat ze elkaar wel raken, dan wint stilzwijgend de
  // eerste en tekent de andere het verkeerde cijfer.
  wire [3:0] menu_d, coin_d, lvl_d;
  wire [2:0] menu_r, coin_r, lvl_r;
  wire       menu_q, coin_q, lvl_q;

  wire [3:0] dig_digit = in_chest ? menu_d : (lvl_q ? lvl_d : coin_d);
  wire [2:0] dig_row   = in_chest ? menu_r : (lvl_q ? lvl_r : coin_r);
 
  wire [3:0] dig_bits;
  digit_rom u_digit (.digit(dig_digit), .row(dig_row), .bits(dig_bits));

  // MINI GAME MENU PAGE ----------------------------------------------------
  wire       menu_on;
  wire [2:0] menu_code;
  chest_menu u_menu (
    .x(px), .y(py), .pot(pot), .round(round),
    .menu_open(chest_state == 2'd3),
    .q_digit(menu_d), .q_row(menu_r), .q_bits(dig_bits), .q_on(menu_q),
    .px_on(menu_on), .px_code(menu_code)
  );

  // TWO BARS: satisfaction (5 niveaus) & coins ----------------------------
  wire       sat_on;
  wire [2:0] sat_code;
  satisfactionbar u_satbar (
    .x(px - SATBAR_X), .y(py - SATBAR_Y),
    .sat(satisfaction),
    .px_on(sat_on), .px_code(sat_code)
  );

  wire       coin_on;
  wire [1:0] coin_code;
  coinbar u_coinbar (
    .x(px - COINBAR_X), .y(py - COINBAR_Y),
    .coins(coins),
    .q_digit(coin_d), .q_row(coin_r), .q_bits(dig_bits), .q_on(coin_q),
    .px_on(coin_on), .px_code(coin_code)
  );

  // LEVEL ------------------------------------------------------------------
  // "LVL n" helemaal linksboven.  De letters zijn een vaste minibitmap in de
  // module zelf; alleen het cijfer komt uit de gedeelde tabel hierboven.
  wire lvl_on;
  level_box u_level (
    .x(px - LEVEL_X), .y(py - LEVEL_Y), .level(level),
    .q_digit(lvl_d), .q_row(lvl_r), .q_bits(dig_bits), .q_on(lvl_q),
    .on(lvl_on)
  );

  wire gameover_text_on;
  gameover_text u_gameover (
    .px(px), .py(py),
    .text_on(gameover_text_on)
  );

  wire win_on;
  win_screen u_win(.x(px), .y(py), .on(win_on));

  // HEARTS -----------------------------------------------------------------
  wire       heartsinfo_on;
  wire [1:0] heartsinfo_code;
  hearts u_heartsinfo (
    .x(px - HEARTS_X), .y(py - HEARTS_Y),
    .hearts(hearts), .overflow(overflow),
    .px_on(heartsinfo_on), .px_code(heartsinfo_code)
  );

  // BUTTONS ----------------------------------------------------------------
  //             FEED
  //   DRINK   level up   SLEEP
  //             PLAY
  wire       button_on;
  wire [2:0] button_code;
  draw_buttons buttons_u (
    .x(px), .y(py),
    .btn_level(btn_level),
    .px_on(button_on), .px_code(button_code)
  );

  wire [5:0] bg_home_rgb;
  background u_bg (
    .x(px), .y(py),
    .bg_rgb(bg_home_rgb),
    .night(night)
  );
  wire [5:0] bg_chest_rgb;

  velvet_bg u_velvet (
    .x(px), .y(py),
    .bg_rgb(bg_chest_rgb)
  );

 
wire feed_on;
wire [5:0] feed_rgb;
feed_fx u_feed (
  .x(px), .y(py), .fx_age(fx_age),
  .active(fx_on && (fx_kind == 2'd1)),
  .feed_on(feed_on), .feed_rgb(feed_rgb)
);

wire       water_on;
wire [5:0] water_rgb;
water_fx u_water (
    .x(px), .y(py), .fx_age(fx_age),
    .active(fx_on && (fx_kind == 2'd2)),   // FX_DRINK
    .water_on(water_on), .water_rgb(water_rgb)
  );


   

  // ======================= 2. SHOW ========================================
  wire show_dragon  = (mode == M_HOME);
  wire show_satbar  = (mode == M_HOME);
  wire show_buttons = (mode == M_HOME);

  wire show_hearts  = (mode == M_HOME) || (mode == M_CHEST);
  wire show_coin    = (mode == M_HOME);   // munten en level: niet bij de minigame

  // ======================= 4. COLOUR ======================================

  // -- sprites: draak en titel-ei delen EEN palet -------------------------
  // Deze twee waren letterlijk dezelfde tabel, en de modes sluiten elkaar uit
  // (M_HOME tegenover M_TITLE/M_EGG).  De comment in title_egg.v zei het al:
  // "gebruik hetzelfde palet als dragon_rgb".  Nu is dat afgedwongen in
  // plaats van afgesproken, en staat het maar een keer op de chip.
  wire [2:0] sprite_code = in_title ? tegg_code : dragon_code;

  reg [5:0] sprite_rgb;
  always @(*) case (sprite_code)
    3'd1: sprite_rgb = 6'b00_00_00;   // zwart, outlines
    3'd2: sprite_rgb = 6'b10_10_10;   // grijs, hoorns licht
    3'd3: sprite_rgb = 6'b00_11_00;   // fel groen, lichaam
    3'd4: sprite_rgb = 6'b11_11_11;   // wit, eierschaal / oogreflectie
    3'd5: sprite_rgb = 6'b00_10_00;   // donkergroen, eivlekken / schaduw
    3'd6: sprite_rgb = 6'b01_01_01;   // donkergrijs, hoorns schaduw
    3'd7: sprite_rgb = 6'b10_11_01;   // lichtgroen, nekje & buikje
    default: sprite_rgb = 6'b00_00_00;
  endcase

  // De draak wordt grijs bij nacht.  Een tweede palet in plaats van een
  // helderheidstruc, want dan houd je per code de hand aan hoe donker iets
  // wordt -- de omtrek moet zwart blijven, het buikje mag oplichten.
  reg [5:0] sprite_night;
  always @(*) case (sprite_code)
    3'd1: sprite_night = 6'b00_00_00;   // zwarte omtrek blijft zwart
    3'd2: sprite_night = 6'b01_01_01;   // hoorns licht
    3'd3: sprite_night = 6'b00_01_00;   // lichaam
    3'd4: sprite_night = 6'b10_10_10;   // wit
    3'd5: sprite_night = 6'b00_01_00;   // vlekken / schaduw
    3'd6: sprite_night = 6'b01_01_01;   // hoorns schaduw
    3'd7: sprite_night = 6'b00_01_00;   // nekje & buikje
    default: sprite_night = 6'b00_00_00;
  endcase





  // -- kisten: bodem en deksel delen EEN opzoeking ------------------------
  // Een pixel is bodem OF deksel, nooit allebei -- de STACK kiest er een.
  function [5:0] chest_color;
    input [2:0] code;
    begin
      case (code)
        3'd1:    chest_color = 6'b00_00_00;   // donker / outline
        3'd2:    chest_color = 6'b01_00_00;   // hout
        3'd3:    chest_color = 6'b11_10_00;   // goud
        3'd4:    chest_color = 6'b11_11_11;   // wit (highlight)
        default: chest_color = 6'b00_00_00;
      endcase
    end
  endfunction

  function [5:0] dim_color;
    /* verilator lint_off UNUSEDSIGNAL */
    input [5:0] c;
    /* verilator lint_on UNUSEDSIGNAL */
    begin
      dim_color = {1'b0, c[5], 1'b0, c[3], 1'b0, c[1]};
    end
  endfunction


    function [5:0] icon_color;
    input [2:0] code;
    begin
      case (code)
        3'd1:    icon_color = 6'b00_00_00;   // zwart (omtrek, bomromp)
        3'd2:    icon_color = 6'b10_01_00;   // bruin / donkeroranje (kurk, muntschaduw)
        3'd3:    icon_color = 6'b11_10_00;   // oranje (muntvlak)
        3'd4:    icon_color = 6'b01_01_01;   // creme / geel (muntglans, vonken bom2)
        3'd5:    icon_color = 6'b11_11_11;   // wit (glans op de bom)
        3'd6:    icon_color = 6'b10_00_00;   // rood (drank, vonken, rode bom)
        3'd7:    icon_color = 6'b01_01_10;   // grijsblauw (glas)
        default: icon_color = 6'b00_00_00;
      endcase
    end
  endfunction

 
        
  wire [2:0] chest_px_code = chest_body_on ? c_body_code : c_lid_code;
  wire [5:0] chest_raw_rgb = chest_color(chest_px_code);
  wire [5:0] chest_rgb     = c_dim ? dim_color(chest_raw_rgb) : chest_raw_rgb;

  wire [5:0] icon_raw_rgb  = icon_color(c_icon_code);
  wire [5:0] icon_rgb      = c_dim ? dim_color(icon_raw_rgb) : icon_raw_rgb;

  reg [5:0] menu_rgb;
  always @(*) case (menu_code)
    3'd1: menu_rgb = 6'b00_00_00;   // outline
    3'd2: menu_rgb = 6'b10_01_00;   // bruin, de pot
    3'd3: menu_rgb = 6'b11_10_00;   // goud, de HUD-tekst
    3'd4: menu_rgb = 6'b11_11_11;   // wit, menutekst
    3'd5: menu_rgb = 6'b11_10_00;   // goud, de CASH OUT-knop
    3'd6: menu_rgb = 6'b11_11_00;   // fel geel, munten
    3'd7: menu_rgb = 6'b00_10_00;   // groen, CONTINUE
    default: menu_rgb = 6'b10_01_00;
  endcase

  // title_card geeft vijf codes maar er zijn maar DRIE kleuren: 1 en 3 zijn
  // gelijk, 2 en 4 ook.  Laat title_card.v alleen nog 1, 2 en 5 uitgeven,
  // dan snoeit yosys de takken 3 en 4 hier vanzelf weg.
  reg [5:0] title_rgb;
  always @(*) case (title_code)
    3'd1: title_rgb = 6'b00_01_00;   // letters + vleugel-omtrek
    3'd2: title_rgb = 6'b01_11_01;   // vulling + vleugel-vlak
    3'd3: title_rgb = 6'b00_01_00;   // donkere rand   (== 1)
    3'd4: title_rgb = 6'b01_11_01;   // lichte rand    (== 2)
    3'd5: title_rgb = 6'b00_10_00;   // vleugel-aders
    default: title_rgb = 6'b00_00_00;
  endcase

  reg [5:0] coin_rgb;
  always @(*) case (coin_code)
    2'd0: coin_rgb = 6'b00_00_00;   // rand / outlines
    2'd1: coin_rgb = 6'b01_01_01;   // leeg segment
    2'd2: coin_rgb = 6'b11_11_00;   // vol segment + cijfers
    default: coin_rgb = 6'b11_11_11;
  endcase

  wire [5:0] evolve_rgb = !evolve_now  ? 6'b01_00_10 :   // gedimd
                          evolve_blink ? 6'b10_01_11 :   // middenpaars
                                         6'b01_00_10;    // donkerpaars

  reg [5:0] buttons_rgb;
  always @(*) case (button_code)
    3'd1: buttons_rgb = 6'b00_00_00;
    3'd2: buttons_rgb = 6'b01_00_10;   // donkerpaars
    3'd3: buttons_rgb = evolve_rgb;    // de evolve-knop
    3'd5: buttons_rgb = 6'b10_01_11;
    default: buttons_rgb = 6'b11_11_11;
  endcase

  reg [5:0] sat_rgb;
  always @(*) case (sat_code)
    3'd1: sat_rgb = 6'b11_00_00;   // rood
    3'd2: sat_rgb = 6'b11_01_00;   // oranje
    3'd3: sat_rgb = 6'b11_11_00;   // geel
    3'd4: sat_rgb = 6'b10_11_00;   // limoen
    3'd5: sat_rgb = 6'b00_11_00;   // groen
    3'd6: sat_rgb = 6'b11_11_11;   // wit kader
    3'd7: sat_rgb = 6'b01_01_01;   // donker (alleen in FILL)
    default: sat_rgb = 6'b00_00_00;
  endcase

  reg [5:0] heartsinfo_rgb;
  always @(*) case (heartsinfo_code)
    2'd0:    heartsinfo_rgb = 6'b00_00_00;   // zwarte omtrek
    2'd1:    heartsinfo_rgb = 6'b11_00_00;   // rood gevuld hartje
    2'd2:    heartsinfo_rgb = 6'b11_11_11;   // hartje bij overflow
    default: heartsinfo_rgb = 6'b00_00_00;
  endcase



  // ======================= 3. STACK =======================================
  // TITEL/EI : flits > titel > barst > ei > press > grond > lucht
  // HOME     : hartjes > level > munten > satbar > knoppen > draak > achtergrond
  // KIST     : hartjes > menu > kist > pictogram > deksel > achtergrond
  //localparam [5:0] BG_CHEST = 6'b10_00_00;   // achtergrond minigame (rood)

  reg [5:0] rgb;
  always @(*) begin
    if (!video_active) rgb = 6'b00_00_00;          // MOET zwart blijven
    else if (in_title) begin
      if      (flash_on)   rgb = flash_rim ? 6'b11_00_00 : 6'b11_10_00;
      else if (title_on)   rgb = title_rgb;
      else if (crack_on)   rgb = 6'b00_00_00;      // barst boven het ei
      else if (tegg_on)    rgb = sprite_rgb;
      else if (press_on && (mode == M_TITLE)) rgb = 6'b00_00_00;
      else if (tground_on) rgb = tground_shadow ? 6'b00_01_00 : 6'b00_10_00;
      else                 rgb = 6'b01_10_11;      // hemelsblauw
    end
    else if (mode == M_GAMEOVER) begin
      if (gameover_text_on) rgb = 6'b00_00_00;     // zwarte letters
      else                  rgb = 6'b01_00_00;     // donkerrode achtergrond
    end
    else if (mode == M_YOU_WIN) rgb = win_on ? 6'b11_10_00 : 6'b00_00_00;
    else if (show_hearts   && heartsinfo_on)       rgb = heartsinfo_rgb;
    else if (show_coin     && lvl_on)              rgb = 6'b00_00_00;  // LVL n
    else if (show_coin     && coin_on)             rgb = coin_rgb;
    else if (show_satbar   && sat_on)              rgb = sat_rgb;
    else if (show_buttons  && button_on)           rgb = buttons_rgb;
    else if (show_menu     && menu_on)             rgb = menu_rgb;
    else if (chest_body_on)                        rgb = chest_rgb;
    else if (chest_icon_on)                        rgb = icon_rgb;
    else if (chest_lid_on)                         rgb = chest_rgb;
    else if (feed_on)                              rgb = feed_rgb;
    else if (water_on)                             rgb = water_rgb;
    else if (evo_on && flash_on) rgb = flash_rim ? 6'b11_00_00 : 6'b11_10_00;
    else if (show_dragon && dragon_on && !flash)  rgb = night ? sprite_night : sprite_rgb;
    else if (in_chest)                             rgb = bg_chest_rgb;
    else                                           rgb = bg_home_rgb;
    {R, G, B} = rgb;
  end

  // coin_q hangt onderaan de prioriteitsketen en hoeft dus niet gelezen te
  // worden -- coin_d is de laatste tak.  Wel aangesloten laten, anders zie je
  // niet meer dat coinbar hem uitgeeft.
  wire _unused = &{menu_sel, chest_outcome, combo_len, flash, coin_q, 1'b0};
endmodule
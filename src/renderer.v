`default_nettype none
// ---------------------------------------------------------------------------
//
//   1. PLACE things: subtract each drawable's origin -> local coordinates
//   2. SHOW things: per composition, which drawables are visible
//   3. STACK things: the layer cascade (first visible layer wins)
//   4. COLOUR things: map each drawable's px_code to real RGB
//
// ---------------------------------------------------------------------------
module renderer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire       video_active,

    input  wire [2:0] mode,          // 0 TITLE, 1 EGG, 2 HOME, 4 CHEST 5GAMEOVER
    input  wire [2:0] menu_sel,
    input  wire [2:0] hearts, // 3 bit
    input  wire [2:0] satisfaction, // 3 bit => 5 options
    input  wire [9:0] coins, //tot 1000: level 1 20, level 2 40, level 3 80, level 160, level 
    input  wire [2:0] level, // max 7 levels 

    input  wire       evolve_now, // of je genoeg geld hebt om te evolven 
    input  wire [1:0] combo_len, // ongebruikt

    input  wire [1:0] chest_frame, // animatie (voorlopig nog niets)
    input  wire [1:0] chest_state, // 0 closed, 1 opening, 2 open, 3 menu 
    input  wire [1:0] chest_sel, // welke kist is selected (0,1,2), cursor + welke uiteindelijk is gekozen 
    input  wire [2:0] chest_outcome, // bevat alleen gekozen kist (moet nog worden aangepast dat alle 3)

    input  wire [2:0] dragon_mood_anim,
    input  wire       flash,
    input  wire       flame_frame,
    input  wire       evolve_blink,

    input             frame_tick, // voor animatie van ei

    input             overflow, // als hartjes vol of geld vol
    input  wire [8:0] chest_contents,  // {kist2, kist1, kist0}, 3 bits elk
    input  wire [9:0] pot,             // groot tonen, los van coins, hoeveel coins je hebt in minigame
    input  wire [3:0] round,           // teken round+1, wleke ronde je zit in mini game
    input  wire [2:0] egg_frame,       // 0 heel, 1 barst, 2 open, 3 weg

    output reg  [1:0] R,
    output reg  [1:0] G,
    output reg  [1:0] B
);
// VERANDER NAAR (3-bit):
localparam [2:0] M_TITLE    = 3'd0,
                 M_EGG      = 3'd1,
                 M_HOME     = 3'd2,
                 M_CHEST    = 3'd3,
                 M_GAMEOVER = 3'd4;

  // ======================= 0. ROTATE ======================================
  // Fysiek scherm: 640x480 liggend.  Wij tekenen in PORTRET: 480 x 640.
  // De monitor staat 90 graden gedraaid.
  wire [9:0] px = pix_y;              // 0..479  -> portret-breedte
  wire [9:0] py = 10'd639 - pix_x;    // 0..639  -> portret-hoogte


  // ======================= 1. PLACE =======================================
  // Every position is a constant HERE, in one file.  Moving anything on
  // screen is a one-line edit.

  localparam [9:0] HEARTS_X  = 10'd130, HEARTS_Y  = 10'd16;  // 304 x 24
  localparam [9:0] SATBAR_X  = 10'd85, SATBAR_Y  = 10'd370;  // 162 x 24
  localparam [9:0] COINBAR_X = 10'd24,  COINBAR_Y = 10'd80;  //  24 x 132
  localparam [9:0] EGG_X = 10'd0,  EGG_Y = 10'd0;  //  24 x 132

  localparam DRAGON_X = 10'd0, DRAGON_Y = 10'd0;
  // localparam SATBAR_X = 10'd24,  SATBAR_Y = 10'd56;
  // localparam COINBAR_X  = 10'd24,  COINBAR_Y  = 10'd80;
  localparam [9:0] CHEST_X     = 10'd176;
  localparam [9:0] CHEST_Y0    = 10'd60;
  localparam [9:0] CHEST_PITCH = 10'd192;
  localparam [9:0] CHEST_BOX   = 10'd128;
 
  localparam [1:0] C_PICK = 2'd0, C_OPEN = 2'd1, C_RESULT = 2'd2;
  // localparam HEARTS_X = 10'd168, HEARTS_Y = 10'd16;

  // ======================= drawable instances =============================


  // TITELKAART -------------------------------------------------------------
  // wire       title_on;
  // wire [2:0] title_code;
  // title_card u_title (
  //   .x(px), .y(py),
  //   .px_on(title_on), .px_code(title_code)
  // );

  // // WIEGEND EI OP GRAS (alleen titelscherm) --------------------------------
  // wire       tegg_on, tground_on, tground_shadow;
  // wire [2:0] tegg_code;
  // title_egg u_title_egg (
  //   .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
  //   .x(px), .y(py),
  //   .egg_on(tegg_on), .egg_code(tegg_code),
  //   .ground_on(tground_on), .ground_shadow(tground_shadow)
  // );


  `ifdef NO_TITLE
  // Titelscherm uitgeschakeld voor render-benches die M_TITLE niet tonen.
  // title_card is ~2500 regels combinatoriek die anders voor elke pixel
  // geevalueerd wordt; dat scheelt ongeveer 20 s per bench.
  // Bij synthese staat NO_TITLE niet gedefinieerd, dus daar verandert niets.
  wire       title_on       = 1'b0;
  wire [2:0] title_code     = 3'd0;
  wire       tegg_on        = 1'b0;
  wire [2:0] tegg_code      = 3'd0;
  wire       tground_on     = 1'b0;
  wire       tground_shadow = 1'b0;
`else
  wire       title_on;
  wire [2:0] title_code;
  title_card u_title (
    .x(px), .y(py),
    .px_on(title_on), .px_code(title_code)
  );

  // WIEGEND EI OP GRAS (alleen titelscherm) --------------------------------
  wire       tegg_on, tground_on, tground_shadow;
  wire [2:0] tegg_code;
  title_egg u_title_egg (
    .clk(clk), .rst_n(rst_n), .frame_tick(frame_tick),
    .x(px), .y(py),
    .egg_on(tegg_on), .egg_code(tegg_code),
    .ground_on(tground_on), .ground_shadow(tground_shadow)
  );
`endif

  // DRAGON -----------------------------------------------------------------
  // uiterlijk draak hangt af van dragon_state
  // als in toekomst genoeg tijd, beinvloed mood ook uiterlijk van draak (houden we momenteel achterwegen)
 
  wire        dragon_on; //of er een pixel van draak is
  wire [2:0]  dragon_code; //welke kleur die moet krijgen als er pixel is 


  dragon_draw u_dragon (
    .x(px - DRAGON_X), .y(py - DRAGON_Y), .mood_anim(dragon_mood_anim),
    .px_on(dragon_on), .px_code(dragon_code),
    .level(level),  .clk(clk), .rst_n(rst_n)
  );


  wire        egg_on; //of er een pixel van draak is
  wire [2:0]  egg_code;


  egg_draw u_egg (
    .x(px - EGG_X), .y(py - EGG_Y), .egg_frame(egg_frame),
    .px_on(egg_on), .px_code(egg_code),
    .clk(clk), .rst_n(rst_n)
  );

  

  // THREE CHESTS ---------------------------------
  // chest_frame: staat van box selected?
  // chest_state: 
  // chest_sel: chest selection (0,1,2)
  // chest_outcome: wat er in chest zit

  // 3 verschillende statussen: 
  // - chest selection: alle 3 chest toe, chest van chest_sel groter 
  // - gekozen chest opening: chest_sel open met inhoud erin, (chest_outcome), andere 2 toe, opening niet echt open maar 
  // toont gwn pictogram van inhoud: bommetje (zwart cirkel met rechthoekje), munt (geel cirkel), hartje verliezen (hartje, miss kruis erdoor), 
  // maal 2 van geld ( X 2 pictogram) 
  // - rest tonen: alle 3 chests open
  // 
  reg  [1:0] c_slot;      // 0, 1 of 2
  reg  [9:0] c_top;       // bovenkant van die rij
  reg        c_inrow;
 
  always @(*) begin
    if (py >= CHEST_Y0 && py < CHEST_Y0 + CHEST_BOX) begin
      c_slot = 2'd0;  c_top = CHEST_Y0;                    c_inrow = 1'b1;
    end else if (py >= CHEST_Y0 + CHEST_PITCH &&
                 py <  CHEST_Y0 + CHEST_PITCH + CHEST_BOX) begin
      c_slot = 2'd1;  c_top = CHEST_Y0 + CHEST_PITCH;      c_inrow = 1'b1;
    end else if (py >= CHEST_Y0 + 10'd384 &&
                 py <  CHEST_Y0 + 10'd384 + CHEST_BOX) begin
      c_slot = 2'd2;  c_top = CHEST_Y0 + 10'd384;          c_inrow = 1'b1;
    end else begin
      c_slot = 2'd0;  c_top = CHEST_Y0;                    c_inrow = 1'b0;
    end
  end


wire c_is_sel = (c_slot == chest_sel);
 
  // De gekozen kist gaat open zodra we uit PICK zijn.  De andere twee pas
  // in RESULT.
  wire c_frame = c_is_sel ? (chest_state != C_PICK)
                          : (chest_state == C_RESULT);
 
  // In RESULT worden de niet-gekozen kisten doffer, zodat de aandacht naar
  // de gekozen kist gaat.
  wire c_dim = (chest_state == C_RESULT) && !c_is_sel;
 
  wire       c_body_on, c_lid_on;
  wire [2:0] c_body_code, c_lid_code;
 
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





  // MINI GAME MENU PAGE 
  wire menu_on;
  wire [2:0] menu_code;
  chest_menu u_menu (
    .x(px), .y(py), .pot(pot), .round(round),
    .px_on(menu_on), .px_code(menu_code)
  );

  wire show_menu   = (mode == M_CHEST) && (chest_state == 2'd3);
  wire show_chests = (mode == M_CHEST) && (chest_state != 2'd3);


  // TWO BARS: satisfaction (5 levels, 3 bits ) & coins (8 bits)  ---------------------
  wire sat_on;
  wire [2:0] sat_code;
  satisfactionbar u_satbar (
    .x(px - SATBAR_X), .y(py - SATBAR_Y),
    .sat(satisfaction),
    .px_on(sat_on), .px_code(sat_code)
  );
  // LEVEL moet hier ook nog bij, best apart want bits zitten vol

  wire coin_on;
  wire [1:0] coin_code;
  coinbar u_coinbar (
    .x(px - COINBAR_X), .y(py - COINBAR_Y),
    .coins(coins),
    .px_on(coin_on), .px_code(coin_code)
  );
  // vraag: hier nog aantal bijschrijven + overflow

  wire gameover_text_on;
  gameover_text u_gameover (
    .px(px),
    .py(py),
    .text_on(gameover_text_on)
  );
  // HEARTS  + OVERFLOW (absolute coordinates??) -------------------------
  wire heartsinfo_on;
  wire [1:0] heartsinfo_code;
  hearts u_heartsinfo (
    .x(px - HEARTS_X), .y(py - HEARTS_Y),
    .hearts(hearts), .overflow(overflow),
    .px_on(heartsinfo_on), .px_code(heartsinfo_code)
  );

  // BUTTONS ----------------------------------------
  // 5 knoppen:            FOOD
  //             WATER    level up    SLEEP
  //                       GAME
  // level up moet oplichten als boolean level_up 1 is 
  // voor de rest gewoon vaste display vanonder aan scherm 
  wire button_on;
  wire [2:0] button_code;
  
  draw_buttons buttons_u (
    .x(px), .y(py),
    .px_on(button_on), .px_code(button_code)
  );

  // ======================= 2. SHOW ========================================
  // welke dingen moeten getoond worden bij welke gamemode
  // hier nog egg implementeren 
  wire show_dragon = (mode == M_HOME);
  wire show_satbar   = (mode == M_HOME);
  wire show_buttons   = (mode == M_HOME);

  //wire show_chests = (mode == M_CHEST);

  wire show_hearts    = (mode == M_HOME) || (mode == M_CHEST); // altijd getoond 
  wire show_coin      = show_hearts && (mode != M_CHEST); // niet bij minigame 


  // ======================= 4. COLOUR ======================================
  // Per-drawable palettes: code -> 6-bit {R,G,B}
  reg [5:0] dragon_rgb;
  always @(*) begin
  case (dragon_code)
    3'd0: dragon_rgb = 6'b00_00_00; // Transparant / Achtergrond
    3'd1: dragon_rgb = 6'b00_00_00; // Zwart (Outlines)
    3'd2: dragon_rgb = 6'b10_10_10; // Grijs (Hoorns licht)
    3'd3: dragon_rgb = 6'b00_11_00; // Fel groen (Lichaam draak)
    3'd4: dragon_rgb = 6'b11_11_11; // Wit (Eierschaal / Oogreflectie)
    3'd5: dragon_rgb = 6'b00_10_00; // Donkergroen (Eivlekken / Schaduw)
    3'd6: dragon_rgb = 6'b01_01_01; // Donkergrijs (Hoorns schaduw)
    3'd7: dragon_rgb = 6'b10_11_01; // Lichtgroen / Geelgroen (Nekje & Buikje)
    default: dragon_rgb = 6'b00_00_00;

endcase
end

wire [5:0] egg_rgb = (egg_code == 3'd1) ? 6'b00_00_00 :
                      (egg_code == 3'd2) ? 6'b10_10_10 :
                      (egg_code == 3'd3) ? 6'b00_11_00 :
                      (egg_code == 3'd4) ? 6'b11_11_11 :
                      (egg_code == 3'd5) ? 6'b00_10_00 :
                      (egg_code == 3'd6) ? 6'b01_01_01 :
                      (egg_code == 3'd7) ? 6'b10_11_01 :
                                            6'b00_00_00;

  function [5:0] chest_color;
    input [2:0] code;
    begin
      case (code)
        3'd1:    chest_color = 6'b00_00_00;   // donker / outline  (39,24,1)
        3'd2:    chest_color = 6'b01_00_00;   // hout              (77,48,1)
        3'd3:    chest_color = 6'b11_10_00;   // goud              (227,143,8)
        3'd4:    chest_color = 6'b11_11_11;   // wit (highlight)
        default: chest_color = 6'b00_00_00;
      endcase
    end
  endfunction

  function [5:0] dim_color;
    input [5:0] c;
    begin
      dim_color = {1'b0, c[5], 1'b0, c[3], 1'b0, c[1]};
    end
  endfunction
 
  wire [5:0] body_raw_rgb = chest_color(c_body_code);
  wire [5:0] lid_raw_rgb  = chest_color(c_lid_code);
 
  wire [5:0] body_rgb = c_dim ? dim_color(body_raw_rgb) : body_raw_rgb;
  wire [5:0] lid_rgb  = c_dim ? dim_color(lid_raw_rgb)  : lid_raw_rgb;

  reg [5:0] menu_rgb;
  always @(*) case (menu_code)
    3'd1: menu_rgb = 6'b00_00_00;   // outline
    3'd2: menu_rgb = 6'b10_01_00;   // bruin, de pot
    3'd3: menu_rgb = 6'b11_10_00;   // oranje highlight
    3'd4: menu_rgb = 6'b11_11_11;   // wit, tekst
    3'd5: menu_rgb = 6'b10_10_00;   // dof goud
    3'd6: menu_rgb = 6'b11_11_00;   // fel geel, munten
    3'd7: menu_rgb = 6'b001000;   // groen (CONTINUE)
    default: menu_rgb = 6'b10_01_00;
  endcase

    reg [5:0] tegg_rgb;
  always @(*) case (tegg_code)
    3'd1: tegg_rgb = 6'b00_00_00;
    3'd2: tegg_rgb = 6'b10_10_10;
    3'd3: tegg_rgb = 6'b00_11_00;
    3'd4: tegg_rgb = 6'b11_11_11;
    3'd5: tegg_rgb = 6'b00_10_00;
    3'd6: tegg_rgb = 6'b01_01_01;
    3'd7: tegg_rgb = 6'b10_11_01;
    default: tegg_rgb = 6'b00_00_00;
  endcase

  reg [5:0] title_rgb;
  always @(*) case (title_code)
    3'd1: title_rgb = 6'b00_01_00;   // letters + vleugel-omtrek
    3'd2: title_rgb = 6'b01_11_01;   // vulling + vleugel-vlak
    3'd3: title_rgb = 6'b00_01_00;   // donkere rand
    3'd4: title_rgb = 6'b01_11_01;   // lichte rand
    3'd5: title_rgb = 6'b00_10_00;   // vleugel-aders
    default: title_rgb = 6'b00_00_00;
  endcase

  reg [5:0] coin_rgb;
  always @(*) case (coin_code)
    2'd0: coin_rgb = 6'b00_00_00;       // Rand / Outlines (Zwart)
    2'd1: coin_rgb = 6'b01_01_01;       // Leeg segment (Donkergrijs)
    2'd2: coin_rgb = 6'b11_11_00;       // Vol segment + cijfers (#FFDB00 fel goudgeel)
    2'd3: coin_rgb = 6'b11_11_11;       // Optioneel: Wit
    default: coin_rgb = 6'b00_00_00;
  endcase
 
  wire [5:0] evolve_rgb = !evolve_now ? 6'b01_00_10 ://gedimd
                          evolve_blink ? 6'b10_01_11 :// middenpaars 
                          6'b01_00_10; //donkerpaars

  reg [5:0] buttons_rgb;
  always @(*) case (button_code)
    3'd1: buttons_rgb = 6'b000000;
    3'd2: buttons_rgb = 6'b010010;       // donkerpaars
    3'd3: buttons_rgb = evolve_rgb;       // lichtpaars 
    default: buttons_rgb = 6'b111111;
  endcase
  

//coin_rgb
// satisfaction (nieuw)
  reg [5:0] sat_rgb;
  always @(*) case (sat_code)
    3'd1: sat_rgb = 6'b11_00_00;   // rood
    3'd2: sat_rgb = 6'b11_01_00;   // oranje
    3'd3: sat_rgb = 6'b11_11_00;   // geel
    3'd4: sat_rgb = 6'b10_11_00;   // limoen
    3'd5: sat_rgb = 6'b00_11_00;   // groen
    3'd6: sat_rgb = 6'b11_11_11;   // wit kader
    3'd7: sat_rgb = 6'b01_01_01;   // donker (alleen in FILL)
    default: sat_rgb = 6'b00_00_00; // frame + schotjes
  endcase

  // Dynamische achtergrond voor M_HOME: Lucht + Grasvloer
  reg [5:0] bg_home_dynamic;
  always @(*) begin
    if (py < 10'd500)
      bg_home_dynamic = 6'b01_10_11; // Hemelsblauw
    else if (py < 10'd540)
      bg_home_dynamic = 6'b00_11_00; // Grasstrook onder de draak
    else
      bg_home_dynamic = 6'b01_01_00; // Aarde / onderlaag
  end

  // heartsinfo: juist kleuren nog aanpassen: rood: wit (denk ik)
  // ======================= 4. COLOUR (heartsinfo) ========================
  reg [5:0] heartsinfo_rgb;
  always @(*) case (heartsinfo_code)
    2'd0:    heartsinfo_rgb = 6'b00_00_00; // Zwarte rand / omtrek
    2'd1:    heartsinfo_rgb = 6'b11_00_00; // Rood gevuld hartje
    2'd2:    heartsinfo_rgb = 6'b11_11_11; // Witte OVERFLOW tekst
    default: heartsinfo_rgb = 6'b00_00_00;
  endcase

  wire [5:0] bg_home_rgb;

  background u_bg (
    .pix_x(pix_x),
    .pix_y(pix_y),
    .bg_rgb(bg_home_rgb)
  );
  //buttons_rgb

  // ======================= 3. STACK =======================================
  // volgorde: 
  // GAME: bars > chests > background: show_coin_hearts > show_chests 
  // HOME: bars > dragon >  background: show_coin_hearts > show_satbar > show_buttons > show_dragon

  localparam [5:0] BG_HOME  = 6'b011011; // background home (lichtblauw)
  localparam [5:0] BG_CHEST = 6'b100000; //background game (rood)

  reg [5:0] rgb;
  always @(*) begin
    if (!video_active)           rgb = 6'b000000;      // MUST stay black
    else if (mode == M_TITLE)   begin
      if      (title_on)   rgb = title_rgb;
      else if (tegg_on)    rgb = tegg_rgb;
      else if (tground_on) rgb = tground_shadow ? 6'b00_01_00 : 6'b00_10_00;
      else                 rgb = 6'b01_10_11;      // hemelsblauw
    end

    else if (mode == M_EGG) begin
      if (egg_on)
        rgb = egg_rgb;
      else
        rgb = bg_home_rgb; // of een eigen achtergrondkleur voor het ei-scherm
    end
    else if (mode == M_GAMEOVER) begin
    if (gameover_text_on)
      rgb = 6'b00_00_00; // Zwarte letters "GAME OVER"
    else
      rgb = 6'b01_00_00; // Donkerrode achtergrond
  end
    else if (show_hearts     && heartsinfo_on)    rgb = heartsinfo_rgb;
    else if (show_coin       && coin_on)          rgb = coin_rgb;
    else if (show_satbar   && sat_on)                 rgb = sat_rgb;
    else if (show_buttons  && button_on)              rgb = buttons_rgb;
    else if (show_menu     && menu_on)                rgb = menu_rgb;
    else if (chest_body_on)                           rgb = body_rgb;
    //else if (icon_on)                                 rgb = icon_rgb;
    else if (chest_lid_on)                            rgb = lid_rgb; 
    else if (show_dragon && dragon_on)                rgb = dragon_rgb;
    else rgb = (mode == M_CHEST) ? BG_CHEST : bg_home_rgb;
    {R, G, B} = rgb;
  end

  wire _unused = &{menu_sel, chest_state, chest_outcome, flame_frame, level, combo_len, flash,1'b0, chest_contents};
endmodule

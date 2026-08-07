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
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire       video_active,

    input  wire [1:0] mode,          // 0 TITLE, 1 HOME, 2 CHEST, 3 GAMEOVER
    input  wire [1:0] menu_sel,
    input  wire [2:0] hearts, // 3 bit
    input  wire [2:0] satisfaction, // 3 bit => 5 options
    input  wire [9:0] coins, //tot 1000: level 1 20, level 2 40, level 3 80, level 160, level 
    input  wire [2:0] level, // max 7 levels 

    input  wire       evolve_now, // of je genoeg geld hebt om te evolven 
    input  wire [1:0] combo_len, // ongebruikt

    input  wire [1:0] chest_frame, // 0 closed, 1 opening, 2 open
    input  wire [1:0] chest_state,
    input  wire [1:0] chest_sel, // welke kist is selected (0,1,2)
    input  wire [1:0] chest_outcome,

    input  wire [1:0] dragon_form, // weet niet of dit voldoende bits heeft 
    input  wire [1:0] dragon_mood_anim,
    input  wire       flash,
    input  wire       flame_frame,

    input  wire       you_win,
    input             overflow, // als hartjes vol of geld vol

    output reg  [1:0] R,
    output reg  [1:0] G,
    output reg  [1:0] B
);
  localparam M_TITLE=2'd0, M_HOME=2'd1, M_CHEST=2'd2, M_GAMEOVER=2'd3;

  // ======================= 1. PLACE =======================================
  // Every position is a constant HERE, in one file.  Moving anything on
  // screen is a one-line edit.

  localparam DRAGON_X = 10'd240, DRAGON_Y = 10'd100;
  localparam SATBAR_X = 10'd24,  SATBAR_Y = 10'd56;
  localparam COINBAR_X  = 10'd24,  COINBAR_Y  = 10'd80;
  localparam CHEST0_X = 10'd80,  CHEST1_X = 10'd272, CHEST2_X = 10'd464;
  localparam CHEST_Y  = 10'd300; // moet x niet hetzelfde? 

  // ======================= drawable instances =============================
  // DRAGON -----------------------------------------------------------------
  // uiterlijk draak hangt af van dragon_state
  // als in toekomst genoeg tijd, beinvloed mood ook uiterlijk van draak (houden we momenteel achterwegen)
 
  wire        dragon_on; //of er een pixel van draak is
  wire [2:0]  dragon_code; //welke kleur die moet krijgen als er pixel is 


  dragon_draw u_dragon (
    .x(pix_x - DRAGON_X), .y(pix_y - DRAGON_Y),
    .state(dragon_form), .mood_anim(dragon_mood_anim),
    .px_on(dragon_on), .px_code(dragon_code)
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
  wire       c0_on, c1_on, c2_on;
  wire [1:0] c0_code, c1_code, c2_code;

  chest_draw u_chest0 (
    .x(pix_x - CHEST0_X), .y(pix_y - CHEST_Y),
    .frame(chest_sel==2'd0 ? chest_frame : 2'd0),
    .highlighted(chest_sel==2'd0),
    .px_on(c0_on), .px_code(c0_code)
  );
  chest_draw u_chest1 (
    .x(pix_x - CHEST1_X), .y(pix_y - CHEST_Y),
    .frame(chest_sel==2'd1 ? chest_frame : 2'd0),
    .highlighted(chest_sel==2'd1),
    .px_on(c1_on), .px_code(c1_code)
  );
  chest_draw u_chest2 (
    .x(pix_x - CHEST2_X), .y(pix_y - CHEST_Y),
    .frame(chest_sel==2'd2 ? chest_frame : 2'd0),
    .highlighted(chest_sel==2'd2),
    .px_on(c2_on), .px_code(c2_code)
  );
  wire       chest_on   = c0_on | c1_on | c2_on;
  wire [1:0] chest_code = c0_on ? c0_code : c1_on ? c1_code : c2_code; // moet derde niet? 


  // TWO BARS: satisfaction (5 levels, 3 bits ) & coins (8 bits)  ---------------------
  wire sat_on;
  wire [2:0] sat_code;
  satisfactionbar u_satbar (
    .x(pix_x - SATBAR_X), .y(pix_y - SATBAR_Y),
    .sat(satisfaction),
    .px_on(sat_on), .px_code(sat_code)
  );
  // LEVEL moet hier ook nog bij, best apart want bits zitten vol

  wire coin_on;
  wire [1:0] coin_code;
  coinbar u_coinbar (
    .x(pix_x - COINBAR_X), .y(pix_y - COINBAR_Y),
    .coins(coins),
    .px_on(coin_on), .px_code(coin_code)
  );
  // vraag: hier nog aantal bijschrijven + overflow

  // HEARTS  + OVERFLOW (absolute coordinates??) -------------------------
  // --- vraag: wat bedoelen ze met absolute coordinaten? en waarom hierwel absolute coordinaten? 
  wire heartsinfo_on;
  wire [1:0] heartsinfo_code;
  hearts u_heartsinfo (
    .pix_x(pix_x), .pix_y(pix_y),
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
    .x(pix_x), .y(pix_y),
    .evolve_now (evolve_now),
    .px_on(button_on), .px_code(button_code)
  );

  // ======================= 2. SHOW ========================================
  // welke dingen moeten getoond worden bij welke gamemode
  wire show_dragon = (mode == M_HOME);
  wire show_satbar   = (mode == M_HOME);
  wire show_buttons   = (mode == M_HOME);

  wire show_chests = (mode == M_CHEST);

  wire show_coin_hearts    = (mode == M_HOME) || (mode == M_CHEST); // altijd getoond 

  // ======================= 4. COLOUR ======================================
  // Per-drawable palettes: code -> 6-bit {R,G,B}
  reg [5:0] dragon_rgb;
  always @(*) case (dragon_code)
    3'd1: dragon_rgb = 6'b000000;      // outline
    3'd2: dragon_rgb = 6'b011001;      // body green
    3'd3: dragon_rgb = 6'b101110;      // belly
    default: dragon_rgb = 6'b011001;
  endcase

  reg [5:0] chest_rgb;
  always @(*) case (chest_code)
    2'd1: chest_rgb = 6'b000000;
    2'd2: chest_rgb = 6'b100100;       // wood
    2'd3: chest_rgb = 6'b111000;       // gold
    default: chest_rgb = 6'b100100;
  endcase

  reg [5:0] coin_rgb;
  always @(*) case (chest_code)
    2'd1: coin_rgb = 6'b000000;
    2'd2: coin_rgb = 6'b100100;       // wood
    2'd3: coin_rgb = 6'b111000;       // gold
    default: coin_rgb = 6'b100100;
  endcase

  reg [5:0] buttons_rgb;
  always @(*) case (chest_code)
    2'd1: buttons_rgb = 6'b000000;
    2'd2: buttons_rgb = 6'b100100;       // wood
    2'd3: buttons_rgb = 6'b111000;       // gold
    default: buttons_rgb = 6'b100100;
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

  // heartsinfo: juist kleuren nog aanpassen: rood: wit (denk ik)
  wire [5:0] heartsinfo_rgb       = (heartsinfo_code  == 2'd1) ? 6'b110000 : 6'b111111;

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
    else if (mode == M_TITLE)    rgb = 6'b000110;      // TODO: title text
    else if (mode == M_GAMEOVER) rgb = 6'b010000;      // TODO: game over text
    else if (show_coin_hearts    && heartsinfo_on)    rgb = heartsinfo_rgb;
    else if (show_coin_hearts    && coin_on)          rgb = coin_rgb;
    else if (show_satbar   && sat_on)                 rgb = sat_rgb;
    else if (show_buttons  && button_on)              rgb = buttons_rgb;
    else if (show_chests && chest_on)                 rgb = chest_rgb;
    else if (show_dragon && dragon_on)                rgb = dragon_rgb;
    else rgb = (mode == M_CHEST) ? BG_CHEST : BG_HOME;
    {R, G, B} = rgb;
  end

  wire _unused = &{menu_sel, chest_state, chest_outcome, flame_frame, level, combo_len, flash, you_win,1'b0};
endmodule

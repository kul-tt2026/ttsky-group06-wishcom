`default_nettype none
// ---------------------------------------------------------------------------
// THE BOSS.  The ONLY render file that knows about `mode`.
//
// Its four jobs, and nothing else:
//   1. PLACE things: subtract each drawable's origin -> local coordinates
//   2. SHOW things: per composition, which drawables are visible
//   3. STACK things: the layer cascade (first visible layer wins)
//   4. COLOUR things: map each drawable's px_code to real RGB
//
// The drawables answer geometry questions; they never see `mode`.
// ---------------------------------------------------------------------------
module renderer (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire       video_active,

    input  wire [2:0] mode,          // 0 TITLE, 1 HOME, 2 CHEST, 3 GAMEOVER 4 YOU WIN
    input  wire [2:0] menu_sel,
    input  wire [2:0] hearts,
    input  wire [2:0] satisfaction,
    input  wire [9:0] coins,
    input  wire [2:0] level,
    input  wire [1:0] combo_len,
    input  wire [1:0] chest_state,
    input  wire [1:0] chest_sel,
    input  wire [2:0] chest_outcome,
    input  wire [1:0] dragon_bob,
    input  wire [2:0] dragon_mood_anim,
    input  wire [1:0] chest_frame,
    input  wire       flash,
    input  wire       flame_frame,
    input  wire       overflow,
    input  wire       evolve_now,


    output reg  [1:0] R,
    output reg  [1:0] G,
    output reg  [1:0] B
);
  localparam M_TITLE=2'd0, M_HOME=2'd1, M_CHEST=2'd2, M_GAMEOVER=2'd3, M_YOU_WIN=2'd4;

  // ======================= 1. PLACE =======================================
  // Every position is a constant HERE, in one file.  Moving anything on
  // screen is a one-line edit.

  localparam DRAGON_X = 10'd240, DRAGON_Y = 10'd100;
  localparam SATBAR_X = 10'd24,  SATBAR_Y = 10'd56;
  localparam COMBO_X  = 10'd24,  COMBO_Y  = 10'd80;
  localparam CHEST0_X = 10'd80,  CHEST1_X = 10'd272, CHEST2_X = 10'd464;
  localparam CHEST_Y  = 10'd300;
  // (hud places itself; menu icons TODO below)

  // ======================= drawable instances =============================
  // dragon -----------------------------------------------------------------
  wire        dragon_on;
  wire [2:0]  dragon_code;
  dragon_draw u_dragon (
    .x(pix_x - DRAGON_X), .y(pix_y - DRAGON_Y),
    .level(level), .mood_anim(dragon_mood_anim), .bob(dragon_bob),
    .px_on(dragon_on), .px_code(dragon_code)
  );

  // three chests: one module, three origins ---------------------------------
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
  wire [1:0] chest_code = c0_on ? c0_code : c1_on ? c1_code : c2_code;

  // two bars: one module, two origins, two fill sources ---------------------
  wire sat_on, combo_on;
  wire [1:0] sat_code, combo_code;
  bars u_satbar (
    .x(pix_x - SATBAR_X), .y(pix_y - SATBAR_Y),
    .fill(satisfaction),
    .px_on(sat_on), .px_code(sat_code)
  );
  bars u_combobar (
    .x(pix_x - COMBO_X), .y(pix_y - COMBO_Y),
    .fill(combo_len),
    .px_on(combo_on), .px_code(combo_code)
  );

  // hearts + coins (absolute coords, places itself) -------------------------
  wire hud_on;
  wire [1:0] hud_code;
  hud u_hud (
    .pix_x(pix_x), .pix_y(pix_y),
    .hearts(hearts), .coins(coins), .level(level),
    .px_on(hud_on), .px_code(hud_code)
  );

  // TODO (boss owner): menu icons for the four home options + menu_sel
  // highlight.  Either a fifth drawable (menu_draw.v) or boxes inline here.
  wire menu_on = 1'b0;

  // ======================= 2. SHOW ========================================
  // The whole cost of having two compositions is these four wires.
  wire show_dragon = (mode == M_HOME);
  wire show_bars   = (mode == M_HOME);
  wire show_menu   = (mode == M_HOME);
  wire show_chests = (mode == M_CHEST);
  wire show_you_win = (mode == M_YOU_WIN);
  // hud: visible in both HOME and CHEST
  wire show_hud    = (mode == M_HOME) || (mode == M_CHEST) || (mode == M_YOU_WIN);

  // ======================= 4. COLOUR ======================================
  // Per-drawable palettes: code -> 6-bit {R,G,B}.  TODO: real colours once
  // the geometry exists; these are placeholders in the right structure.
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

  wire [5:0] bar_rgb_sat   = (sat_code  ==2'd2) ? 6'b001100 : 6'b010101;
  wire [5:0] bar_rgb_combo = (combo_code==2'd2) ? 6'b111100 : 6'b010101;
  wire [5:0] hud_rgb       = (hud_code  ==2'd1) ? 6'b110000 : 6'b111111;

  // ======================= 3. STACK =======================================
  // Front to back: hud > bars > dragon > chests > background.
  localparam [5:0] BG_HOME  = 6'b000001;
  localparam [5:0] BG_CHEST = 6'b010001;
  

  reg [5:0] rgb;
  always @(*) begin
    if (!video_active)           rgb = 6'b000000;      // MUST stay black
    else if (mode == M_TITLE)    rgb = 6'b000110;      // TODO: title text
    else if (mode == M_GAMEOVER) rgb = 6'b010000;      // TODO: game over text
    else if (mode == M_YOU_WIN)  rgb = 6'b111100;      // TODO: you win text (bijv. felgeel/goud)
    else if (show_hud    && hud_on)    rgb = hud_rgb;
    else if (show_bars   && sat_on)    rgb = bar_rgb_sat;
    else if (show_bars   && combo_on)  rgb = bar_rgb_combo;
    else if (show_menu   && menu_on)   rgb = 6'b111111; // TODO
    else if (show_dragon && dragon_on) rgb = flash ? ~dragon_rgb : dragon_rgb;
    else if (show_chests && chest_on)  rgb = chest_rgb;
    else rgb = (mode == M_CHEST) ? BG_CHEST : BG_HOME;
    {R, G, B} = rgb;
  end

  wire _unused = &{menu_sel, chest_state, chest_outcome, overflow, evolve_now, flame_frame, 1'b0};
endmodule

`default_nettype none
// ---------------------------------------------------------------------------
// WATER_FX -- de DRINK-animatie.  Volledig wiskundig: geen ROM, geen array,
// geen random, geen maal of deel, en geen enkele aftrekker.
//
// Een blauwe rechthoek groeit van boven naar beneden op de draak en landt op
// een witte plas die 16 px links en rechts uitsteekt.  Allebei zwart omlijnd.
//
// De verticale lijnen staan op ELF onregelmatige plaatsen.  Die zitten in
// LINE_MASK, een constante bitvector die met x[7:3] wordt aangesproken --
// yosys maakt daar EEN booleaanse functie van vijf ingangen van, veel
// goedkoper dan elf losse vergelijkingen.  En omdat je de plaatsen zelf kiest
// leest het niet als streepjescode.
//
// Alles staat op bitgrenzen, want dat is waar de cellen zitten:
//   * de straal is 128..383, dus in_rx is x[9:7] == 1 of 2 -- drie bits.
//   * de plas is de straal plus twee stroken van 16 px: x[9:4] == 7 of 24.
//   * de randen zijn vier pixels breed en dus vergelijkingen op x[9:2].
//   * de straal begint op y = 0, dus "y < bodem" wordt y[9:5] < age_c.
//   * de plas begint op y = 256, dus in_pool is y[9:8] == 1 en "geland" is
//     gewoon age_c[3].
// De HUD blijft zichtbaar omdat renderer.v hartjes en level boven deze laag
// tekent.
// ---------------------------------------------------------------------------
module water_fx (
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [6:0] fx_age,
    input  wire       active,
    output wire       water_on,
    output wire [5:0] water_rgb
);
  localparam [9:0] GRASS = 10'd294;

  // ---- instelbare lijndikte, 1..8 px ------------------------------------
  localparam [3:0] LINE_W = 4'd3;

  // ---- de elf x-plaatsen ------------------------------------------------
  // Bit n hoort bij x = n*8 (modulo 256).  Deze staan op
  //   x = 136 152 176 192 208 240 264 288 312 336 368
  // Verzet gerust bits: een andere verdeling kost geen cel extra.
  localparam [31:0] LINE_MASK = 32'b01000101010010100100010010010010;

  // ---- valsnelheid: px per frame is een macht van twee -------------------
  //   4 -> 16 px/frame (16 frames tot de plas)   -- zet dan ook de klem op 16
  //   5 -> 32 px/frame ( 8 frames)   <-- default
  localparam [3:0] FALL_SH = 4'd5;

  // Klem op 8: de straal landt toch op frame 8, en dan volgt y < 256 vanzelf.
  wire [3:0] age_c = (|fx_age[6:3]) ? 4'd8 : {1'b0, fx_age[2:0]};
  wire       landed = active && age_c[3];

  // ---- vensters, allemaal op bitgrenzen ---------------------------------
  wire in_rx = (x[9:7] == 3'd1) || (x[9:7] == 3'd2);          // 128..383
  wire spill = (x[9:4] == 6'd7) || (x[9:4] == 6'd24);         // 112..127, 384..399
  wire in_px = in_rx || spill;

  wire grown = ({1'b0, y[9:5]} < {2'b0, age_c});   // y < age_c*32, dus ook < 256

  // ---- de straal ---------------------------------------------------------
  wire in_rect = active && in_rx && grown;
  wire r_edge  = (x[9:2] == 8'd32) || (x[9:2] == 8'd95);      // 128..131, 380..383
  wire is_line = LINE_MASK[x[7:3]] && ({1'b0, x[2:0]} < LINE_W);

  // ---- de plas -----------------------------------------------------------
  wire in_pool = landed && in_px && (y[9:8] == 2'b01) && (y < GRASS);
  wire p_edge  = (x[9:2] == 8'd28) || (x[9:2] == 8'd99) ||    // 112..115, 396..399
                 (y[9:2] == 8'd64) || (y >= GRASS - 10'd4);   // 256..259, 290..293

  // ---- kleur -------------------------------------------------------------
  reg [5:0] rgb;
  always @(*) begin
    if (in_pool) rgb = p_edge ? 6'b00_00_00 : 6'b11_11_11;
    else         rgb = (r_edge || is_line) ? 6'b00_00_00 : 6'b00_00_11;
  end

  assign water_on  = in_pool || in_rect;
  assign water_rgb = rgb;
endmodule
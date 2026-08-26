`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// CHEST RENDER-TESTBENCH
//
// Draait chest_draw over het hele portret-canvas (480 x 640) met dezelfde
// slot-logica als het blok in renderer.v, en schrijft drie frames weg:
//
//     chest_pick.ppm     alle kisten dicht, cursor op kist 1
//     chest_open.ppm     kist 1 open, andere twee dicht
//     chest_result.ppm   alle drie open, kist 0 en 2 doffer
//
// Daarnaast vier zelftests op de dingen die stil kunnen misgaan.
//
//     iverilog -o sim chest_draw_tb.v chest_draw.v chest_sprites.v && ./sim
//
// LET OP: chest_body.hex en chest_lid.hex moeten in dezelfde map staan.
// ---------------------------------------------------------------------------
module chest_draw_tb;

  localparam [9:0] SCR_W = 10'd480, SCR_H = 10'd640;
  localparam [9:0] CHEST_X = 10'd176, CHEST_Y0 = 10'd60;
  localparam [9:0] CHEST_PITCH = 10'd192, CHEST_BOX = 10'd128;
  localparam [1:0] C_PICK = 2'd0, C_OPEN = 2'd1, C_RESULT = 2'd2;

  reg [1:0] chest_state, chest_sel;
  reg [9:0] px, py;

  // ---- slot-logica, identiek aan renderer_chest_block.v -------------------
  reg  [1:0] c_slot;
  reg  [9:0] c_top;
  reg        c_inrow;

  always @(*) begin
    if (py >= CHEST_Y0 && py < CHEST_Y0 + CHEST_BOX) begin
      c_slot = 2'd0;  c_top = CHEST_Y0;                   c_inrow = 1'b1;
    end else if (py >= CHEST_Y0 + CHEST_PITCH &&
                 py <  CHEST_Y0 + CHEST_PITCH + CHEST_BOX) begin
      c_slot = 2'd1;  c_top = CHEST_Y0 + CHEST_PITCH;     c_inrow = 1'b1;
    end else if (py >= CHEST_Y0 + 10'd384 &&
                 py <  CHEST_Y0 + 10'd384 + CHEST_BOX) begin
      c_slot = 2'd2;  c_top = CHEST_Y0 + 10'd384;         c_inrow = 1'b1;
    end else begin
      c_slot = 2'd0;  c_top = CHEST_Y0;                   c_inrow = 1'b0;
    end
  end

  wire c_is_sel = (c_slot == chest_sel);
  wire c_frame  = c_is_sel ? (chest_state != C_PICK)
                           : (chest_state == C_RESULT);
  wire c_dim    = (chest_state == C_RESULT) && !c_is_sel;

  wire       c_body_on, c_lid_on;
  wire [2:0] c_body_code, c_lid_code;

  chest_draw dut (
    .x           (px - CHEST_X),
    .y           (py - c_top),
    .frame       (c_frame),
    .highlighted (c_is_sel && (chest_state == C_PICK)),
    .body_on     (c_body_on),
    .body_code   (c_body_code),
    .lid_on      (c_lid_on),
    .lid_code    (c_lid_code)
  );

  // ---- kleur --------------------------------------------------------------
  function [5:0] chest_color;
    input [2:0] code;
    case (code)
      3'd1:    chest_color = 6'b00_00_00;
      3'd2:    chest_color = 6'b01_00_00;
      3'd3:    chest_color = 6'b11_10_00;
      3'd4:    chest_color = 6'b11_11_11;
      default: chest_color = 6'b00_00_00;
    endcase
  endfunction

  function [5:0] dim_color;
    input [5:0] c;
    dim_color = {1'b0, c[5], 1'b0, c[3], 1'b0, c[1]};
  endfunction

  // achtergrondkleur van het kistenscherm (donkerblauw, pas gerust aan)
  localparam [5:0] BG = 6'b00_00_01;

  reg [5:0] rgb;
  always @(*) begin
    if      (c_inrow && c_body_on) rgb = c_dim ? dim_color(chest_color(c_body_code))
                                               : chest_color(c_body_code);
    // hier komt straks het icoon tussen
    else if (c_inrow && c_lid_on)  rgb = c_dim ? dim_color(chest_color(c_lid_code))
                                               : chest_color(c_lid_code);
    else                           rgb = BG;
  end

  function [7:0] expand;   // 2 bits -> 8 bits
    input [1:0] v;
    expand = {v, v, v, v};
  endfunction

  // ---- frame naar PPM -----------------------------------------------------
  integer f, xi, yi;
  task write_frame;
    input [8*24:1] name;
    begin
      f = $fopen(name, "w");
      $fwrite(f, "P3\n%0d %0d\n255\n", SCR_W, SCR_H);
      for (yi = 0; yi < SCR_H; yi = yi + 1) begin
        for (xi = 0; xi < SCR_W; xi = xi + 1) begin
          px = xi[9:0]; py = yi[9:0]; #1;
          $fwrite(f, "%0d %0d %0d\n",
                  expand(rgb[5:4]), expand(rgb[3:2]), expand(rgb[1:0]));
        end
      end
      $fclose(f);
      $display("  geschreven: %0s", name);
    end
  endtask

  // ---- zelftests ----------------------------------------------------------
  integer errors;
  integer r, cnt_a, cnt_b, gap;
  reg seen_lid, seen_body;

  task check;
    input cond;
    input [8*48:1] msg;
    begin
      if (!cond) begin
        errors = errors + 1;
        $display("  FOUT : %0s", msg);
      end else begin
        $display("  ok   : %0s", msg);
      end
    end
  endtask

  initial begin
    errors = 0;
    chest_state = C_PICK; chest_sel = 2'd1;

    $display("");
    $display("== frames ==");
    chest_state = C_PICK;   chest_sel = 2'd1; write_frame("chest_pick.ppm");
    chest_state = C_OPEN;   chest_sel = 2'd1; write_frame("chest_open.ppm");
    chest_state = C_RESULT; chest_sel = 2'd1; write_frame("chest_result.ppm");

    $display("");
    $display("== zelftests ==");

    // 1. NAAD: door het midden van de open kist mag tussen de onderste
    //    dekselpixel en de bovenste bakpixel geen gat zitten.
    chest_state = C_OPEN; chest_sel = 2'd1;
    gap = 0; seen_lid = 0; seen_body = 0;
    for (r = 0; r < 128; r = r + 1) begin
      px = CHEST_X + 10'd64;
      py = CHEST_Y0 + CHEST_PITCH + r[9:0]; #1;
      if (c_lid_on)  seen_lid  = 1;
      if (c_body_on) seen_body = 1;
      if (seen_lid && !seen_body && !c_lid_on) gap = gap + 1;
    end
    check(gap == 0, "geen naad tussen deksel en bak");

    // 2. BUITEN DE DOOS: 8 px links van kist 1 mag niets staan.
    px = CHEST_X - 10'd8; py = CHEST_Y0 + CHEST_PITCH + 10'd64; #1;
    check(!c_body_on && !c_lid_on, "niets buiten het 128x128 vakje");

    // 3. TUSSENRUIMTE: midden tussen kist 0 en 1 is leeg (icoonzone).
    px = CHEST_X + 10'd64; py = CHEST_Y0 + CHEST_BOX + 10'd32; #1;
    check(!c_inrow, "tussenruimte vrij voor het icoon");

    // 4. BAK IDENTIEK: dicht en open moeten dezelfde bak geven.
    cnt_a = 0; cnt_b = 0;
    chest_state = C_PICK; chest_sel = 2'd0;
    for (r = 64; r < 128; r = r + 1) begin
      px = CHEST_X + 10'd40; py = CHEST_Y0 + r[9:0]; #1;
      if (c_body_on) cnt_a = cnt_a + 1;
    end
    chest_state = C_RESULT; chest_sel = 2'd0;
    for (r = 64; r < 128; r = r + 1) begin
      px = CHEST_X + 10'd40; py = CHEST_Y0 + r[9:0]; #1;
      if (c_body_on) cnt_b = cnt_b + 1;
    end
    check(cnt_a == cnt_b && cnt_a > 0, "bak gelijk in dicht en open");

    $display("");
    if (errors == 0) $display("ALLES OK");
    else             $display("%0d FOUT(EN)", errors);
    $display("");
    $finish;
  end

endmodule
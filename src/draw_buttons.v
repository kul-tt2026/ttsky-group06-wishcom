`default_nettype none
// ---------------------------------------------------------------------------
// 5 knoppen:            FOOD
//             WATER    level up    SLEEP
//                       GAME
// zie foto buttons 
// zwarte rand, vulling, highlight level up

// ---------------------------------------------------------------------------
module draw_buttons (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire evolve_now,         // of level_up border
    output wire       px_on,
    output wire [2:0] px_code       // 
);

  assign px_on   = 1'b0;
  assign px_code = 3'd0;

  wire _unused = &{x, y, evolve_now, 1'b0};
endmodule
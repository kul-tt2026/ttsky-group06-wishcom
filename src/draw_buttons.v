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
    input  wire [1:0] level_up,         // of level_up border
    output wire       px_on,
    output wire [2:0] px_code       // 
);

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{x, y, fill, 1'b0};
endmodule
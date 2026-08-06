default_nettype none
// ---------------------------------------------------------------------------
// hearts + overflow, 5 hearts, red
// colors: 0: red, 1: text for overflow
// next to eachother (left text and right hearts), hearts appear 
// ---------------------------------------------------------------------------
module hearts (
    input  wire [9:0] pix_x,        // ABSOLUTE screen coordinates
    input  wire [9:0] pix_y,
    input  wire [1:0] hearts,
    input             overflow; 
    output wire       px_on,
    output wire [1:0] px_code       
);

// 

  assign px_on   = 1'b0;
  assign px_code = 2'd0;

  wire _unused = &{pix_x, pix_y, hearts, coins, level, 1'b0};
endmodule

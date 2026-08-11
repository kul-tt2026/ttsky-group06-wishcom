`default_nettype none
module dragon_draw(
    input  wire [9:0] x,            // local, 0 = left edge of the dragon
    input  wire [9:0] y,           // local, 0 = top edge
    input  wire [1:0] state,        // evolution stage -> shape/size
    input  wire [1:0] mood_anim,    // nog onbepaald
    output wire       px_on,      // 1 = the dragon covers this dot
    output wire [2:0] px_code       // 1 outline, 2 body, 3 belly, 4 horn, ...
); 

  //op basis van state: ei, draak in ei, kleine draak, grote draak 
  //draak beweegt op en neer lichtjes 

  assign px_on   = 1'b0;            // placeholder: invisible
  assign px_code = 3'd0;

  wire _unused = &{x, y, state, mood_anim, 1'b0};
endmodule

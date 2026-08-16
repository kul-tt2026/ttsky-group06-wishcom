`default_nettype none
module dragon_draw(
    input  wire [9:0] x,            // local, 0 = left edge of the dragon
    input  wire [9:0] y,           // local, 0 = top edge
    input  wire [2:0] level,
    input  wire [2:0] mood_anim,    // nog onbepaald
    output wire       px_on,      // 1 = the dragon covers this dot
    output wire [2:0] px_code      // 1 outline, 2 body, 3 belly, 4 horn, ...
); 

  reg lvl1_on;
  reg lvl2_on;
  reg lvl3_on;
  //op basis van state: ei, draak in ei, kleine draak, grote draak 
  //draak beweegt op en neer lichtjes 
  

  always @(*) begin
    lvl1_on = 1'b0;
    lvl2_on = 1'b0;
    lvl3_on = 1'b0;

    case (level)
      3'd1, 3'd2:       lvl1_on = 1'b1;
      3'd3, 3'd4, 3'd5, 3'd6: lvl2_on = 1'b1;
      3'd7:             lvl3_on = 1'b1;
      default: ; // 3'd0 blijft alles 0
    endcase
  end


    // 1. Maak draden (wires) aan voor de outputs van de module
  wire       egg_px_on;
  wire [2:0] egg_px_code;

  // 2. Instantieer de module (buiten elk if-statement!)
  ei_generator u_egg (
      .x         (x),
      .y         (y),
      .mood_anim (mood_anim),
      .px_on     (egg_px_on),
      .px_code   (egg_px_code)
  );

  wire       lvl2_px_on;
  wire [2:0] lvl2_px_code;

  dragon_l1_generator u_dragon_lvl1 (
      .x         (x),
      .y         (y),
      .mood_anim (mood_anim),
      .px_on     (lvl2_px_on),
      .px_code   (lvl2_px_code)
  );

  // 3. Stuur de outputs aan op basis van lvl1_on (met een ternary operator / multiplexer)
  // 1. Schakel de daadwerkelijke outputs aan/uit op basis van lvl1_on
  // Outputs doorsturen afhankelijk van welke status actief is
  assign px_on = lvl1_on ? egg_px_on :
                 lvl2_on ? lvl2_px_on :
                 1'b0; // Buiten deze niveaus staat de pixel uit

  assign px_code = lvl1_on ? egg_px_code :
                   lvl2_on ? lvl2_px_code :
                   3'd0; // Buiten deze niveaus is de kleur code 0

  wire _unused = &{x, y, mood_anim, 1'b0,lvl3_on};
endmodule



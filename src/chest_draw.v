`default_nettype none
// ---------------------------------------------------------------------------
// 
// ---------------------------------------------------------------------------
module chest_draw (
    input  wire [9:0] x,            // local
    input  wire [9:0] y,
    input  wire [1:0] frame,        // 0 closed, 1 opening, 2 open
    input  wire       highlighted,  // this chest is under the cursor
    output wire       px_on,
    output wire [2:0] px_code       // 1 outline (black), 2 wood, 3 gold
);
  // 

  assign px_on   = 1'b0;
  assign px_code = 3'd0;

  wire _unused = &{x, y, frame, highlighted, 1'b0};
endmodule


// `default_nettype none
// // ---------------------------------------------------------------------------
// // CHEST_DRAW -- tekent EEN kist.  Wordt 3x geinstantieerd in renderer.v.
// //
// //    frame       0 dicht, 1 opengaand, 2 open   (alleen de gekozen kist opent)
// //    highlighted staat de cursor op mij?
// //    content     wat zit er in MIJ?             (per instantie anders!)
// //
// // LOKALE COORDINATEN: (0,0) is de linkerbovenhoek van MIJN vakje.
// // Plaatsing gebeurt in renderer.v, niet hier.
// //
// // px_code (3 bits):
// //   1 = zwart / outline      4 = wit
// //   2 = hout (donkerbruin)   5 = rood
// //   3 = goud                 6 = donker (binnenkant kist)
// // ---------------------------------------------------------------------------
// module chest_draw (
//     input  wire [9:0] x,            // local
//     input  wire [9:0] y,
//     input  wire [1:0] frame,        // 0 closed, 1 opening, 2 open
//     input  wire       highlighted,  // this chest is under the cursor
//     input  wire [2:0] content,      // O_COIN / O_2X / O_CURSED / O_BOMB / O_BOMB2 (nog niet implemented)
//     output wire       px_on,
//     output wire [2:0] px_code
// );
//   // dezelfde codes als in chest_game.v -- houd ze gelijk!
//   localparam O_COIN = 3'd0, O_2X = 3'd1, O_CURSED = 3'd2,
//              O_BOMB = 3'd3, O_BOMB2 = 3'd4;

//   // ======================= 1. het vakje ===================================
//   // 120 breed, 112 hoog.  De bovenste ~30 px zijn LEEG als de kist dicht is:
//   // dat is de ruimte waar het deksel naartoe klapt als hij opengaat.
//   localparam [9:0] W       = 10'd120;
//   localparam [9:0] H       = 10'd112;
//   localparam [9:0] BODY_Y0 = 10'd56;   // bovenkant van de bak
//   localparam [9:0] LID_H   = 10'd26;   // hoogte van het deksel

//   //???
//   // Boven/links van de origin wrapt de local coord naar ~1023, dus "< W"
//   // test meteen ook de linker- en bovenrand.  Geen signed compare nodig.
//   wire in_box = (x < W) && (y < H);

//   // ======================= 2. het deksel ==================================

//   reg [9:0] lid_y0;
//   always @(*) case (frame)
//     2'd0:    lid_y0 = 10'd30;   // dicht: deksel ligt op de bak
//     2'd1:    lid_y0 = 10'd15;   // halverwege
//     default: lid_y0 = 10'd0;    // open: deksel helemaal bovenaan
//   endcase

//   wire [9:0] ly     = y - lid_y0;              // y binnen het deksel
//   wire       in_lid = in_box && (ly < LID_H);

//   // rand van 3 px rondom -> outline, de rest hout
//   wire lid_edge = in_lid && ((x < 10'd3) || (x >= W - 10'd3) ||
//                              (ly < 10'd3) || (ly >= LID_H - 10'd3));

//   // ======================= 3. de bak ======================================
//   wire [9:0] by     = y - BODY_Y0;             // y binnen de bak
//   wire       in_body = in_box && (y >= BODY_Y0);

//   wire body_edge = in_body && ((x < 10'd3) || (x >= W - 10'd3) ||
//                                (by < 10'd3) || (y >= H - 10'd3));

//   // donkere binnenkant: alleen zichtbaar zodra het deksel weg is
//   wire mouth = in_body && (frame != 2'd0) && (by >= 10'd3) && (by < 10'd14) &&
//                (x >= 10'd3) && (x < W - 10'd3);

//   // gouden band die verticaal over deksel EN bak loopt
//   wire band = (in_lid || in_body) && (x >= 10'd52) && (x < 10'd68);

//   // slot: klein goudblokje op de naad, alleen als de kist nog dicht is
//   wire lock = in_box && (frame == 2'd0) &&
//               (x >= 10'd50) && (x < 10'd70) &&
//               (y >= 10'd46) && (y < 10'd66);
//   wire lock_hole = lock && (x >= 10'd57) && (x < 10'd63) &&
//                           (y >= 10'd52) && (y < 10'd60);

//   // ======================= 4. het pictogram ===============================
//   // Alleen als de kist ECHT open is.  Middelpunt (60, 40): net boven de bak,
//   // in het gat dat het opgeklapte deksel achterlaat.
//   wire [9:0] ix = (x >= 10'd60) ? (x - 10'd60) : (10'd60 - x);   // |dx|
//   wire [9:0] iy = (y >= 10'd40) ? (y - 10'd40) : (10'd40 - y);   // |dy|

//   wire in_icon = in_box && (frame == 2'd2) && (ix < 10'd24) && (iy < 10'd24);

//   wire [5:0]  ax = ix[5:0];
//   wire [5:0]  ay = iy[5:0];
//   wire [11:0] r2 = (ax * ax) + (ay * ay);      // afstand^2 tot het midden

//   wire disc = in_icon && (r2 <= 12'd196);      // volle cirkel, straal 14
//   wire ring = in_icon && (r2 <= 12'd196) && (r2 >= 12'd121);  // alleen de rand

//   // de twee diagonalen van een X (binnen in_icon is x+40 altijd >= y)
//   wire [9:0] d1 = x + y;                       // = 100 op de diagonaal
//   wire [9:0] d2 = (x + 10'd40) - y;            // = 60  op de andere
//   wire [9:0] e1 = (d1 >= 10'd100) ? (d1 - 10'd100) : (10'd100 - d1);
//   wire [9:0] e2 = (d2 >= 10'd60)  ? (d2 - 10'd60)  : (10'd60  - d2);
//   wire cross_x  = in_icon && (r2 <= 12'd196) && ((e1 <= 10'd3) || (e2 <= 10'd3));

//   // hartje: ruit + twee bolletjes (zelfde truc als hearts.v, maar groter)
//   wire [9:0] hdx = ix;
//   wire [9:0] hdy = (y >= 10'd44) ? (y - 10'd44) : (10'd44 - y);
//   wire diamond = in_icon && (y >= 10'd40) && ((hdx + hdy) <= 10'd16);
//   wire [9:0] lx = (x >= 10'd53) ? (x - 10'd53) : (10'd53 - x);
//   wire [9:0] rx = (x >= 10'd67) ? (x - 10'd67) : (10'd67 - x);
//   wire [9:0] ty = (y >= 10'd36) ? (y - 10'd36) : (10'd36 - y);
//   wire [11:0] ty2 = ty[5:0] * ty[5:0];
//   wire lobe_l = in_icon && (((lx[5:0] * lx[5:0]) + ty2) <= 12'd49);
//   wire lobe_r = in_icon && (((rx[5:0] * rx[5:0]) + ty2) <= 12'd49);
//   wire heart  = diamond || lobe_l || lobe_r;

//   // lontje van de bom
//   wire fuse = in_icon && (x >= 10'd60) && (x < 10'd66) &&
//                          (y >= 10'd18) && (y < 10'd27);

//   // ---- welk pictogram, en in welke kleur? -------------------------------
//   // icon_on = is hier een pictogram-pixel, icon_code = welke kleur
//   reg       icon_on;
//   reg [2:0] icon_code;
//   always @(*) begin
//     icon_on   = 1'b0;
//     icon_code = 3'd1;
//     case (content)
//       O_COIN: begin                              // gouden munt met rand
//         icon_on   = disc;
//         icon_code = ring ? 3'd1 : 3'd3;
//       end
//       O_2X: begin                                // munt met witte X erover
//         icon_on   = disc;
//         icon_code = cross_x ? 3'd4 : (ring ? 3'd1 : 3'd3);
//       end
//       O_CURSED: begin                            // hartje met zwart kruis
//         icon_on   = heart;
//         icon_code = cross_x ? 3'd1 : 3'd5;
//       end
//       O_BOMB: begin                              // zwarte bol + houten lont
//         icon_on   = disc || fuse;
//         icon_code = fuse ? 3'd2 : 3'd1;
//       end
//       default: begin                             // O_BOMB2: rood lont = erger
//         icon_on   = disc || fuse;
//         icon_code = fuse ? 3'd5 : 3'd1;
//       end
//     endcase
//   end

//   // ======================= 5. de cursor ===================================
//   // Witte rand van 2 px rond het hele vakje als deze kist geselecteerd is.
//   wire cursor = in_box && highlighted &&
//                 ((x < 10'd2) || (x >= W - 10'd2) ||
//                  (y < 10'd2) || (y >= H - 10'd2));

//   // ======================= 6. stapelen ====================================
//   // Eerste regel die past wint.  Pictogram bovenaan, achtergrond onderaan.
//   assign px_on = in_box && (icon_on || cursor || in_lid || in_body);

//   assign px_code = icon_on               ? icon_code :
//                    cursor                ? 3'd4      :   // wit
//                    lock_hole             ? 3'd1      :   // zwart sleutelgat
//                    lock                  ? 3'd3      :   // goud slot
//                    mouth                 ? 3'd6      :   // donkere binnenkant
//                    (lid_edge || body_edge) ? 3'd1    :   // zwarte outline
//                    band                  ? 3'd3      :   // gouden band
//                                            3'd2;         // hout
// endmodule

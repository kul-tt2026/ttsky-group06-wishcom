/*
 * Sprite-tabel voor 4 groeistadia, VGA 640x480 @ 60 Hz
 * SPDX-License-Identifier: Apache-2.0
 *
 * Sprites:
 *   0 = ei (34x36)
 *   1 = ei met draakje (34x36)
 *   2 = staand draakje (35x37)
 *   3 = grote draak (44x60)
 *
 * Deze versie gebruikt nergens een vector breder dan 24 bits, zodat
 * frontends die brede vectoren intern als array behandelen niet
 * struikelen. De tabel is opgedeeld in blokken van 8 pixels
 * (8 x 3 bit = 24 bit); het adres is {sprite, rij, blok}.
 *
 * ui_in[1:0] = sprite-keuze
 * ui_in[2]   = wiebel-animatie aan
 */

`default_nettype none

module tt_um_dragon (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;
  wire _unused_ok = &{ena, uio_in, ui_in[7:3], 1'b0};

  vga_display vga_display_inst (
    .uo_out(uo_out), .sel(ui_in[1:0]), .bob_en(ui_in[2]),
    .clk(clk), .rst_n(rst_n)
  );

endmodule


module vga_display (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [1:0] sel,
    input  wire       bob_en,
    output wire [7:0] uo_out
);

  localparam TRANSPARENT = 1'b0;
  localparam [5:0] BG_COLOR = 6'b00_00_00;

  wire hsync, vsync, video_active;
  wire [9:0] pix_x, pix_y;
  wire [1:0] R, G, B;

  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  hvsync_generator hvsync_gen (
    .clk(clk), .reset(~rst_n), .hsync(hsync), .vsync(vsync),
    .display_on(video_active), .hpos(pix_x), .vpos(pix_y)
  );

  // ---------------- animatie ----------------
  reg [5:0] frame;
  always @(posedge vsync or negedge rst_n) begin
    if (!rst_n) frame <= 6'd0;
    else        frame <= frame + 1'b1;
  end
  wire [9:0] bob = (bob_en && frame[5]) ? 10'd8 : 10'd0;

  // ---------------- afmetingen en plaatsing ----------------
  reg [6:0] spr_w, spr_h;
  reg [9:0] org_x, org_y;

  always @(*) case (sel)
      2'd0: spr_w = 7'd34;
      2'd1: spr_w = 7'd34;
      2'd2: spr_w = 7'd35;
      2'd3: spr_w = 7'd44;
    default: spr_w = 7'd44;
  endcase

  always @(*) case (sel)
      2'd0: spr_h = 7'd36;
      2'd1: spr_h = 7'd36;
      2'd2: spr_h = 7'd37;
      2'd3: spr_h = 7'd60;
    default: spr_h = 7'd60;
  endcase

  always @(*) case (sel)
      2'd0: org_x = 10'd184;
      2'd1: org_x = 10'd184;
      2'd2: org_x = 10'd180;
      2'd3: org_x = 10'd144;
    default: org_x = 10'd144;
  endcase

  always @(*) case (sel)
      2'd0: org_y = 10'd96;
      2'd1: org_y = 10'd96;
      2'd2: org_y = 10'd92;
      2'd3: org_y = 10'd0;
    default: org_y = 10'd0;
  endcase

  wire [9:0] oy    = org_y + bob;
  wire [9:0] rel_x = pix_x - org_x;
  wire [9:0] rel_y = pix_y - oy;
  wire [6:0] sx    = {1'b0, rel_x[8:3]};
  wire [6:0] sy    = {1'b0, rel_y[8:3]};

  wire in_box = (pix_x >= org_x) && (pix_y >= oy) &&
                (sx < spr_w) && (sy < spr_h);

  // ---------------- spritetabel in blokken van 8 pixels ----------------
  wire [10:0] addr = {sel, sy[5:0], sx[5:3]};

  reg [23:0] chunk;
  always @(*) begin
    case (addr)
      // sprite 0: ei (34x36)
      11'd1: chunk = 24'h000049;
      11'd2: chunk = 24'h248000;
      11'd9: chunk = 24'h000240;
      11'd10: chunk = 24'h009000;
      11'd17: chunk = 24'h001000;
      11'd18: chunk = 24'h002200;
      11'd25: chunk = 24'h008000;
      11'd26: chunk = 24'h000440;
      11'd33: chunk = 24'h040000;
      11'd34: chunk = 24'h920088;
      11'd41: chunk = 24'h040024;
      11'd42: chunk = 24'h920088;
      11'd49: chunk = 24'h200124;
      11'd50: chunk = 24'h924011;
      11'd56: chunk = 24'h000001;
      11'd57: chunk = 24'h000124;
      11'd58: chunk = 24'h924002;
      11'd59: chunk = 24'h200000;
      11'd64: chunk = 24'h000001;
      11'd65: chunk = 24'h000124;
      11'd66: chunk = 24'h924002;
      11'd67: chunk = 24'h200000;
      11'd72: chunk = 24'h000008;
      11'd73: chunk = 24'h080024;
      11'd74: chunk = 24'h900000;
      11'd75: chunk = 24'h440000;
      11'd80: chunk = 24'h000040;
      11'd82: chunk = 24'h000080;
      11'd83: chunk = 24'h440000;
      11'd88: chunk = 24'h000040;
      11'd89: chunk = 24'h004900;
      11'd91: chunk = 24'h088000;
      11'd96: chunk = 24'h000040;
      11'd97: chunk = 24'h124900;
      11'd99: chunk = 24'h088000;
      11'd104: chunk = 24'h000200;
      11'd105: chunk = 24'h124900;
      11'd106: chunk = 24'h000120;
      11'd107: chunk = 24'h011000;
      11'd112: chunk = 24'h000200;
      11'd113: chunk = 24'h024902;
      11'd114: chunk = 24'h004924;
      11'd115: chunk = 24'h011000;
      11'd120: chunk = 24'h000200;
      11'd121: chunk = 24'h004800;
      11'd122: chunk = 24'h024924;
      11'd123: chunk = 24'h811000;
      11'd128: chunk = 24'h001024;
      11'd129: chunk = 24'h004800;
      11'd130: chunk = 24'h024924;
      11'd131: chunk = 24'h812200;
      11'd136: chunk = 24'h001124;
      11'd138: chunk = 24'h124924;
      11'd139: chunk = 24'h802200;
      11'd144: chunk = 24'h001024;
      11'd145: chunk = 24'h800000;
      11'd146: chunk = 24'h124924;
      11'd147: chunk = 24'h002200;
      11'd152: chunk = 24'h001024;
      11'd153: chunk = 24'h900000;
      11'd154: chunk = 24'h124920;
      11'd155: chunk = 24'h002200;
      11'd160: chunk = 24'h001004;
      11'd161: chunk = 24'h900000;
      11'd162: chunk = 24'h124900;
      11'd163: chunk = 24'h402200;
      11'd168: chunk = 24'h001004;
      11'd169: chunk = 24'h800024;
      11'd171: chunk = 24'h002200;
      11'd176: chunk = 24'h001000;
      11'd177: chunk = 24'h000124;
      11'd178: chunk = 24'h800000;
      11'd179: chunk = 24'h002200;
      11'd184: chunk = 24'h001010;
      11'd185: chunk = 24'h000924;
      11'd186: chunk = 24'h900000;
      11'd187: chunk = 24'h002200;
      11'd192: chunk = 24'h001000;
      11'd193: chunk = 24'h000924;
      11'd194: chunk = 24'h920024;
      11'd195: chunk = 24'h012200;
      11'd200: chunk = 24'h001000;
      11'd201: chunk = 24'h000124;
      11'd202: chunk = 24'h900024;
      11'd203: chunk = 24'h912200;
      11'd208: chunk = 24'h001004;
      11'd209: chunk = 24'h900024;
      11'd210: chunk = 24'h000124;
      11'd211: chunk = 24'h922200;
      11'd216: chunk = 24'h001024;
      11'd217: chunk = 24'h920000;
      11'd218: chunk = 24'h000124;
      11'd219: chunk = 24'h912200;
      11'd224: chunk = 24'h001024;
      11'd225: chunk = 24'h920020;
      11'd226: chunk = 24'h080924;
      11'd227: chunk = 24'h912200;
      11'd232: chunk = 24'h0014a4;
      11'd233: chunk = 24'h920124;
      11'd234: chunk = 24'h000924;
      11'd235: chunk = 24'h811000;
      11'd240: chunk = 24'h000294;
      11'd241: chunk = 24'h900924;
      11'd242: chunk = 24'h800924;
      11'd243: chunk = 24'h891000;
      11'd248: chunk = 24'h000050;
      11'd249: chunk = 24'h000924;
      11'd250: chunk = 24'h900920;
      11'd251: chunk = 24'h088000;
      11'd256: chunk = 24'h000052;
      11'd257: chunk = 24'h000924;
      11'd258: chunk = 24'h900000;
      11'd259: chunk = 24'h488000;
      11'd264: chunk = 24'h00000a;
      11'd265: chunk = 24'h400124;
      11'd266: chunk = 24'h900012;
      11'd267: chunk = 24'h440000;
      11'd272: chunk = 24'h000001;
      11'd273: chunk = 24'h4924a4;
      11'd274: chunk = 24'h892491;
      11'd275: chunk = 24'h200000;
      11'd281: chunk = 24'h249249;
      11'd282: chunk = 24'h249248;
      // sprite 1: ei met draakje (34x36)
      11'd521: chunk = 24'h0036c0;
      11'd529: chunk = 24'h0034c0;
      11'd530: chunk = 24'h0d8000;
      11'd537: chunk = 24'h01a4c0;
      11'd538: chunk = 24'h6d3000;
      11'd545: chunk = 24'h0494c3;
      11'd546: chunk = 24'h693000;
      11'd553: chunk = 24'h32424b;
      11'd554: chunk = 24'h49b000;
      11'd560: chunk = 24'h000001;
      11'd561: chunk = 24'h924923;
      11'd562: chunk = 24'h4c8000;
      11'd568: chunk = 24'h00000c;
      11'd569: chunk = 24'h924924;
      11'd570: chunk = 24'h6c8000;
      11'd576: chunk = 24'h00004c;
      11'd577: chunk = 24'h920324;
      11'd578: chunk = 24'h908000;
      11'd584: chunk = 24'h000324;
      11'd585: chunk = 24'h921324;
      11'd586: chunk = 24'h908000;
      11'd592: chunk = 24'h001964;
      11'd593: chunk = 24'h921324;
      11'd594: chunk = 24'h908000;
      11'd600: chunk = 24'h001921;
      11'd601: chunk = 24'h924924;
      11'd602: chunk = 24'h908000;
      11'd608: chunk = 24'h001924;
      11'd609: chunk = 24'h924924;
      11'd610: chunk = 24'h908000;
      11'd616: chunk = 24'h001924;
      11'd617: chunk = 24'h924924;
      11'd618: chunk = 24'h840000;
      11'd624: chunk = 24'h000324;
      11'd625: chunk = 24'h924924;
      11'd626: chunk = 24'h840000;
      11'd627: chunk = 24'h040000;
      11'd632: chunk = 24'h00004c;
      11'd633: chunk = 24'h924924;
      11'd634: chunk = 24'h840000;
      11'd635: chunk = 24'h388000;
      11'd640: chunk = 24'h000001;
      11'd641: chunk = 24'h249924;
      11'd642: chunk = 24'h840001;
      11'd643: chunk = 24'hd88000;
      11'd649: chunk = 24'h3ff924;
      11'd650: chunk = 24'h84000e;
      11'd651: chunk = 24'hd88000;
      11'd657: chunk = 24'h3fdb24;
      11'd658: chunk = 24'h84800e;
      11'd659: chunk = 24'hb88000;
      11'd664: chunk = 24'h000001;
      11'd665: chunk = 24'h26db24;
      11'd666: chunk = 24'h909075;
      11'd667: chunk = 24'hbb1000;
      11'd672: chunk = 24'h00000b;
      11'd673: chunk = 24'h6ed264;
      11'd674: chunk = 24'h909275;
      11'd675: chunk = 24'hb71200;
      11'd680: chunk = 24'h000059;
      11'd681: chunk = 24'h26900c;
      11'd682: chunk = 24'h908249;
      11'd683: chunk = 24'h009200;
      11'd688: chunk = 24'h001259;
      11'd689: chunk = 24'h04910c;
      11'd690: chunk = 24'h848200;
      11'd691: chunk = 24'h012200;
      11'd696: chunk = 24'h001048;
      11'd697: chunk = 24'h008909;
      11'd698: chunk = 24'h840000;
      11'd699: chunk = 24'h012200;
      11'd704: chunk = 24'h001000;
      11'd705: chunk = 24'h000921;
      11'd706: chunk = 24'h240024;
      11'd707: chunk = 24'h012200;
      11'd712: chunk = 24'h001000;
      11'd713: chunk = 24'h000124;
      11'd714: chunk = 24'h200024;
      11'd715: chunk = 24'h912200;
      11'd720: chunk = 24'h001004;
      11'd721: chunk = 24'h900024;
      11'd722: chunk = 24'h000124;
      11'd723: chunk = 24'h922200;
      11'd728: chunk = 24'h001024;
      11'd729: chunk = 24'h920000;
      11'd730: chunk = 24'h000124;
      11'd731: chunk = 24'h912200;
      11'd736: chunk = 24'h001024;
      11'd737: chunk = 24'h920020;
      11'd738: chunk = 24'h080924;
      11'd739: chunk = 24'h912200;
      11'd744: chunk = 24'h0014a4;
      11'd745: chunk = 24'h920124;
      11'd746: chunk = 24'h000924;
      11'd747: chunk = 24'h811000;
      11'd752: chunk = 24'h000294;
      11'd753: chunk = 24'h900924;
      11'd754: chunk = 24'h800924;
      11'd755: chunk = 24'h891000;
      11'd760: chunk = 24'h000050;
      11'd761: chunk = 24'h000924;
      11'd762: chunk = 24'h900920;
      11'd763: chunk = 24'h088000;
      11'd768: chunk = 24'h000052;
      11'd769: chunk = 24'h000924;
      11'd770: chunk = 24'h900000;
      11'd771: chunk = 24'h488000;
      11'd776: chunk = 24'h00000a;
      11'd777: chunk = 24'h400124;
      11'd778: chunk = 24'h900012;
      11'd779: chunk = 24'h440000;
      11'd784: chunk = 24'h000001;
      11'd785: chunk = 24'h4924a4;
      11'd786: chunk = 24'h892491;
      11'd787: chunk = 24'h200000;
      11'd792: chunk = 24'h000001;
      11'd793: chunk = 24'h249249;
      11'd794: chunk = 24'h249248;
      // sprite 2: staand draakje (35x37)
      11'd1041: chunk = 24'h0006d8;
      11'd1049: chunk = 24'h000698;
      11'd1050: chunk = 24'h01b000;
      11'd1057: chunk = 24'h003498;
      11'd1058: chunk = 24'h0da600;
      11'd1065: chunk = 24'h009298;
      11'd1066: chunk = 24'h6d2600;
      11'd1073: chunk = 24'h064849;
      11'd1074: chunk = 24'h693600;
      11'd1081: chunk = 24'h324924;
      11'd1082: chunk = 24'h699000;
      11'd1088: chunk = 24'h000001;
      11'd1089: chunk = 24'h924924;
      11'd1090: chunk = 24'h8d9000;
      11'd1096: chunk = 24'h000009;
      11'd1097: chunk = 24'h924064;
      11'd1098: chunk = 24'h921000;
      11'd1104: chunk = 24'h000064;
      11'd1105: chunk = 24'h924264;
      11'd1106: chunk = 24'h921000;
      11'd1112: chunk = 24'h00032c;
      11'd1113: chunk = 24'h924264;
      11'd1114: chunk = 24'h921000;
      11'd1120: chunk = 24'h000324;
      11'd1121: chunk = 24'h324924;
      11'd1122: chunk = 24'h921000;
      11'd1128: chunk = 24'h000324;
      11'd1129: chunk = 24'h924924;
      11'd1130: chunk = 24'h921000;
      11'd1136: chunk = 24'h000324;
      11'd1137: chunk = 24'h924924;
      11'd1138: chunk = 24'h908000;
      11'd1144: chunk = 24'h000064;
      11'd1145: chunk = 24'h924924;
      11'd1146: chunk = 24'h908000;
      11'd1147: chunk = 24'h000040;
      11'd1152: chunk = 24'h000009;
      11'd1153: chunk = 24'h924924;
      11'd1154: chunk = 24'h908000;
      11'd1155: chunk = 24'h000388;
      11'd1161: chunk = 24'h249324;
      11'd1162: chunk = 24'h908000;
      11'd1163: chunk = 24'h001d88;
      11'd1169: chunk = 24'h07ff24;
      11'd1170: chunk = 24'h908000;
      11'd1171: chunk = 24'h00ed88;
      11'd1177: chunk = 24'h07fb64;
      11'd1178: chunk = 24'h909000;
      11'd1179: chunk = 24'h00eb88;
      11'd1185: chunk = 24'h36db64;
      11'd1186: chunk = 24'h921200;
      11'd1187: chunk = 24'h075bb1;
      11'd1193: chunk = 24'h36db4c;
      11'd1194: chunk = 24'h924240;
      11'd1195: chunk = 24'h075b71;
      11'd1200: chunk = 24'h000001;
      11'd1201: chunk = 24'h36db4c;
      11'd1202: chunk = 24'h924840;
      11'd1203: chunk = 24'h075b71;
      11'd1208: chunk = 24'h00000c;
      11'd1209: chunk = 24'h36da64;
      11'd1210: chunk = 24'h864908;
      11'd1211: chunk = 24'h00cb48;
      11'd1216: chunk = 24'h000064;
      11'd1217: chunk = 24'h36d324;
      11'd1218: chunk = 24'h864909;
      11'd1219: chunk = 24'h00c840;
      11'd1224: chunk = 24'h000064;
      11'd1225: chunk = 24'h36d324;
      11'd1226: chunk = 24'h324921;
      11'd1227: chunk = 24'h264840;
      11'd1232: chunk = 24'h00007c;
      11'd1233: chunk = 24'h36d379;
      11'd1234: chunk = 24'h924924;
      11'd1235: chunk = 24'h924840;
      11'd1240: chunk = 24'h000009;
      11'd1241: chunk = 24'h36d249;
      11'd1242: chunk = 24'h924924;
      11'd1243: chunk = 24'h924840;
      11'd1249: chunk = 24'h36db6d;
      11'd1250: chunk = 24'h324924;
      11'd1251: chunk = 24'h927200;
      11'd1257: chunk = 24'h26db79;
      11'd1258: chunk = 24'h924921;
      11'd1259: chunk = 24'h939000;
      11'd1265: chunk = 24'h30dff9;
      11'd1266: chunk = 24'h924921;
      11'd1267: chunk = 24'hfc9000;
      11'd1273: chunk = 24'h321249;
      11'd1274: chunk = 24'h324909;
      11'd1275: chunk = 24'h240000;
      11'd1281: chunk = 24'h064849;
      11'd1282: chunk = 24'h264908;
      11'd1289: chunk = 24'h00c908;
      11'd1290: chunk = 24'h04c908;
      11'd1297: chunk = 24'h064908;
      11'd1298: chunk = 24'h064908;
      11'd1305: chunk = 24'h3e7848;
      11'd1306: chunk = 24'h37cf08;
      11'd1313: chunk = 24'h249240;
      11'd1314: chunk = 24'h249240;
      // sprite 3: grote draak (44x60)
      11'd1546: chunk = 24'h000003;
      11'd1553: chunk = 24'h000019;
      11'd1554: chunk = 24'h00001a;
      11'd1555: chunk = 24'h200000;
      11'd1561: chunk = 24'h00000a;
      11'd1562: chunk = 24'h20000a;
      11'd1563: chunk = 24'h440000;
      11'd1569: chunk = 24'h000001;
      11'd1570: chunk = 24'h440001;
      11'd1571: chunk = 24'h440000;
      11'd1577: chunk = 24'h000001;
      11'd1578: chunk = 24'h488001;
      11'd1579: chunk = 24'h488000;
      11'd1585: chunk = 24'h000001;
      11'd1586: chunk = 24'h488001;
      11'd1587: chunk = 24'h491000;
      11'd1593: chunk = 24'h00000a;
      11'd1594: chunk = 24'h4c8001;
      11'd1595: chunk = 24'h491000;
      11'd1596: chunk = 24'h008000;
      11'd1601: chunk = 24'h000052;
      11'd1602: chunk = 24'h64000a;
      11'd1603: chunk = 24'h499000;
      11'd1604: chunk = 24'h048000;
      11'd1609: chunk = 24'h000253;
      11'd1610: chunk = 24'h200052;
      11'd1611: chunk = 24'h499000;
      11'd1612: chunk = 24'h3b1000;
      11'd1617: chunk = 24'h001493;
      11'd1618: chunk = 24'h200052;
      11'd1619: chunk = 24'h4c8000;
      11'd1620: chunk = 24'h3b1000;
      11'd1625: chunk = 24'h00149b;
      11'd1626: chunk = 24'h201292;
      11'd1627: chunk = 24'h6c8000;
      11'd1628: chunk = 24'h3b6200;
      11'd1633: chunk = 24'h00a4c9;
      11'd1634: chunk = 24'h24a492;
      11'd1635: chunk = 24'h640000;
      11'd1636: chunk = 24'h3b6200;
      11'd1641: chunk = 24'h00a664;
      11'd1642: chunk = 24'h90a493;
      11'd1643: chunk = 24'h640000;
      11'd1644: chunk = 24'h3b6c40;
      11'd1649: chunk = 24'h00a664;
      11'd1650: chunk = 24'h90a4db;
      11'd1651: chunk = 24'h209208;
      11'd1652: chunk = 24'h076d88;
      11'd1657: chunk = 24'h049324;
      11'd1658: chunk = 24'h9216db;
      11'd1659: chunk = 24'h264209;
      11'd1660: chunk = 24'h076d88;
      11'd1665: chunk = 24'h064924;
      11'd1666: chunk = 24'h924249;
      11'd1667: chunk = 24'h92420e;
      11'd1668: chunk = 24'h3b5d88;
      11'd1673: chunk = 24'h324924;
      11'd1674: chunk = 24'h92484c;
      11'd1675: chunk = 24'h92420e;
      11'd1676: chunk = 24'hdb5db1;
      11'd1680: chunk = 24'h000001;
      11'd1681: chunk = 24'h924924;
      11'd1682: chunk = 24'h924924;
      11'd1683: chunk = 24'h92100e;
      11'd1684: chunk = 24'hdb5db1;
      11'd1688: chunk = 24'h000001;
      11'd1689: chunk = 24'h924924;
      11'd1690: chunk = 24'h924924;
      11'd1691: chunk = 24'h908076;
      11'd1692: chunk = 24'hdadbb6;
      11'd1693: chunk = 24'h200000;
      11'd1696: chunk = 24'h000001;
      11'd1697: chunk = 24'h924921;
      11'd1698: chunk = 24'h324921;
      11'd1699: chunk = 24'h240076;
      11'd1700: chunk = 24'hdadbb6;
      11'd1701: chunk = 24'h200000;
      11'd1704: chunk = 24'h000001;
      11'd1705: chunk = 24'h924908;
      11'd1706: chunk = 24'h264909;
      11'd1707: chunk = 24'h0003b6;
      11'd1708: chunk = 24'hd6db76;
      11'd1709: chunk = 24'hc40000;
      11'd1712: chunk = 24'h00000c;
      11'd1713: chunk = 24'h924909;
      11'd1714: chunk = 24'h264924;
      11'd1715: chunk = 24'h2483b6;
      11'd1716: chunk = 24'hd6db76;
      11'd1717: chunk = 24'hd88000;
      11'd1720: chunk = 24'h000064;
      11'd1721: chunk = 24'h924909;
      11'd1722: chunk = 24'h324924;
      11'd1723: chunk = 24'h9083b6;
      11'd1724: chunk = 24'hb6db6e;
      11'd1725: chunk = 24'hd88000;
      11'd1728: chunk = 24'h001324;
      11'd1729: chunk = 24'h924924;
      11'd1730: chunk = 24'h924924;
      11'd1731: chunk = 24'h8403b6;
      11'd1732: chunk = 24'hb6db6e;
      11'd1733: chunk = 24'hd88000;
      11'd1736: chunk = 24'h00c924;
      11'd1737: chunk = 24'h924924;
      11'd1738: chunk = 24'h924249;
      11'd1739: chunk = 24'h2403b6;
      11'd1740: chunk = 24'hb6db6e;
      11'd1741: chunk = 24'hd88000;
      11'd1744: chunk = 24'h00c864;
      11'd1745: chunk = 24'h324924;
      11'd1746: chunk = 24'h921321;
      11'd1747: chunk = 24'h000076;
      11'd1748: chunk = 24'hb6d36e;
      11'd1749: chunk = 24'hc40000;
      11'd1752: chunk = 24'h00c924;
      11'd1753: chunk = 24'h924924;
      11'd1754: chunk = 24'h909924;
      11'd1755: chunk = 24'h20004e;
      11'd1756: chunk = 24'hb69376;
      11'd1757: chunk = 24'hc40000;
      11'd1760: chunk = 24'h001324;
      11'd1761: chunk = 24'h924921;
      11'd1762: chunk = 24'h27f924;
      11'd1763: chunk = 24'h20000e;
      11'd1764: chunk = 24'hd4c376;
      11'd1765: chunk = 24'h200000;
      11'd1768: chunk = 24'h00004c;
      11'd1769: chunk = 24'h924249;
      11'd1770: chunk = 24'hffd924;
      11'd1771: chunk = 24'h200001;
      11'd1772: chunk = 24'h264389;
      11'd1776: chunk = 24'h000001;
      11'd1777: chunk = 24'h249001;
      11'd1778: chunk = 24'hfed924;
      11'd1779: chunk = 24'h200000;
      11'd1780: chunk = 24'h324240;
      11'd1785: chunk = 24'h000001;
      11'd1786: chunk = 24'hb6d924;
      11'd1787: chunk = 24'h840000;
      11'd1788: chunk = 24'h324200;
      11'd1793: chunk = 24'h00000d;
      11'd1794: chunk = 24'hb6d924;
      11'd1795: chunk = 24'h840000;
      11'd1796: chunk = 24'h324200;
      11'd1801: chunk = 24'h00006d;
      11'd1802: chunk = 24'hb6d924;
      11'd1803: chunk = 24'h840000;
      11'd1804: chunk = 24'h324200;
      11'd1809: chunk = 24'h00006d;
      11'd1810: chunk = 24'hb6c924;
      11'd1811: chunk = 24'h908000;
      11'd1812: chunk = 24'h324840;
      11'd1817: chunk = 24'h00036d;
      11'd1818: chunk = 24'hb6c924;
      11'd1819: chunk = 24'h908000;
      11'd1820: chunk = 24'h064840;
      11'd1825: chunk = 24'h00036d;
      11'd1826: chunk = 24'hb6c924;
      11'd1827: chunk = 24'h921000;
      11'd1828: chunk = 24'h064908;
      11'd1833: chunk = 24'h00136d;
      11'd1834: chunk = 24'hb6c864;
      11'd1835: chunk = 24'h924200;
      11'd1836: chunk = 24'h00c908;
      11'd1841: chunk = 24'h001b6d;
      11'd1842: chunk = 24'hb6c864;
      11'd1843: chunk = 24'h864840;
      11'd1844: chunk = 24'h00c921;
      11'd1849: chunk = 24'h009b6d;
      11'd1850: chunk = 24'hb6d864;
      11'd1851: chunk = 24'h864840;
      11'd1852: chunk = 24'h00c921;
      11'd1857: chunk = 24'h009b6d;
      11'd1858: chunk = 24'hb6d324;
      11'd1859: chunk = 24'h864840;
      11'd1860: chunk = 24'h001921;
      11'd1865: chunk = 24'h061b6d;
      11'd1866: chunk = 24'hb69924;
      11'd1867: chunk = 24'h324908;
      11'd1868: chunk = 24'h001924;
      11'd1869: chunk = 24'h200000;
      11'd1873: chunk = 24'h321b6d;
      11'd1874: chunk = 24'hb4c921;
      11'd1875: chunk = 24'h324908;
      11'd1876: chunk = 24'h001924;
      11'd1877: chunk = 24'h200000;
      11'd1880: chunk = 24'h000001;
      11'd1881: chunk = 24'h921b6d;
      11'd1882: chunk = 24'hb4d909;
      11'd1883: chunk = 24'h924908;
      11'd1884: chunk = 24'h00c924;
      11'd1885: chunk = 24'h200000;
      11'd1888: chunk = 24'h000001;
      11'd1889: chunk = 24'he61b6d;
      11'd1890: chunk = 24'hb4f3cc;
      11'd1891: chunk = 24'h924908;
      11'd1892: chunk = 24'h264924;
      11'd1893: chunk = 24'h200000;
      11'd1897: chunk = 24'h249b6d;
      11'd1898: chunk = 24'hb49264;
      11'd1899: chunk = 24'h924921;
      11'd1900: chunk = 24'h924921;
      11'd1905: chunk = 24'h001b6d;
      11'd1906: chunk = 24'hb6db64;
      11'd1907: chunk = 24'h924924;
      11'd1908: chunk = 24'h924921;
      11'd1913: chunk = 24'h00196d;
      11'd1914: chunk = 24'hb6db61;
      11'd1915: chunk = 24'h924924;
      11'd1916: chunk = 24'h924908;
      11'd1921: chunk = 24'h00190d;
      11'd1922: chunk = 24'hb6db4c;
      11'd1923: chunk = 24'h924864;
      11'd1924: chunk = 24'h9249c8;
      11'd1929: chunk = 24'h001921;
      11'd1930: chunk = 24'hb6da67;
      11'd1931: chunk = 24'h924864;
      11'd1932: chunk = 24'h927e40;
      11'd1937: chunk = 24'h000321;
      11'd1938: chunk = 24'hb6d33c;
      11'd1939: chunk = 24'h924864;
      11'd1940: chunk = 24'h939200;
      11'd1945: chunk = 24'h000324;
      11'd1946: chunk = 24'h36f33c;
      11'd1947: chunk = 24'h924324;
      11'd1948: chunk = 24'hff9000;
      11'd1953: chunk = 24'h000324;
      11'd1954: chunk = 24'h3ff324;
      11'd1955: chunk = 24'h9243ff;
      11'd1956: chunk = 24'he48000;
      11'd1961: chunk = 24'h000064;
      11'd1962: chunk = 24'h84924c;
      11'd1963: chunk = 24'h909249;
      11'd1964: chunk = 24'h200000;
      11'd1969: chunk = 24'h00000c;
      11'd1970: chunk = 24'h840049;
      11'd1971: chunk = 24'h924240;
      11'd1977: chunk = 24'h000064;
      11'd1978: chunk = 24'h840000;
      11'd1979: chunk = 24'h324840;
      11'd1985: chunk = 24'h000324;
      11'd1986: chunk = 24'h840001;
      11'd1987: chunk = 24'h924840;
      11'd1993: chunk = 24'h001f3c;
      11'd1994: chunk = 24'h20000c;
      11'd1995: chunk = 24'h924200;
      11'd2001: chunk = 24'h001249;
      11'd2002: chunk = 24'h00000f;
      11'd2003: chunk = 24'h9e1000;
      11'd2010: chunk = 24'h000001;
      11'd2011: chunk = 24'h249000;
      default: chunk = 24'd0;
    endcase
  end

  // pixel binnen het blok: 3 bits per pixel, pixel 0 bovenaan
  wire [2:0] k     = 3'd7 - sx[2:0];
  wire [4:0] shift = {k, 1'b0} + {2'b0, k};    // k*3, zonder vermenigvuldiger
  wire [2:0] pixidx = chunk[shift +: 3];

  // ---------------- palet ----------------
  reg [5:0] rgb;
  always @(*) begin
    case (pixidx)
      3'd0: rgb = 6'b11_11_11;
      3'd1: rgb = 6'b00_00_00;
      3'd2: rgb = 6'b10_10_10;
      3'd3: rgb = 6'b01_01_01;
      3'd4: rgb = 6'b01_10_01;
      3'd5: rgb = 6'b10_11_10;
      3'd6: rgb = 6'b01_11_01;
      3'd7: rgb = 6'b10_11_01;
      default: rgb = BG_COLOR;
    endcase
  end

  wire clear = TRANSPARENT && (pixidx == 3'd0);
  wire draw  = in_box && !clear;
  wire [5:0] out = draw ? rgb : BG_COLOR;

  assign R = video_active ? out[5:4] : 2'b00;
  assign G = video_active ? out[3:2] : 2'b00;
  assign B = video_active ? out[1:0] : 2'b00;

endmodule


// ------------------------------------------------------------
// Standaard 640x480 @ 60 Hz timing (ongewijzigd)
// ------------------------------------------------------------
module hvsync_generator (
    input  wire clk,
    input  wire reset,
    output reg  hsync,
    output reg  vsync,
    output wire display_on,
    output reg [9:0] hpos,
    output reg [9:0] vpos
);

  localparam H_DISPLAY = 640, H_BACK = 48, H_FRONT = 16, H_SYNC = 96;
  localparam V_DISPLAY = 480, V_TOP  = 33, V_BOTTOM = 10, V_SYNC =  2;

  localparam H_SYNC_START = H_DISPLAY + H_FRONT;
  localparam H_SYNC_END   = H_DISPLAY + H_FRONT + H_SYNC - 1;
  localparam H_MAX        = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;

  localparam V_SYNC_START = V_DISPLAY + V_BOTTOM;
  localparam V_SYNC_END   = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  localparam V_MAX        = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  wire hmaxxed = (hpos == H_MAX) || reset;
  wire vmaxxed = (vpos == V_MAX) || reset;

  always @(posedge clk) begin
    hsync <= (hpos >= H_SYNC_START) && (hpos <= H_SYNC_END);
    hpos  <= hmaxxed ? 10'd0 : hpos + 1'b1;
  end

  always @(posedge clk) begin
    vsync <= (vpos >= V_SYNC_START) && (vpos <= V_SYNC_END);
    if (hmaxxed) vpos <= vmaxxed ? 10'd0 : vpos + 1'b1;
  end

  assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);

endmodule
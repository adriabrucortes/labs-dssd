module hex2seg(
  input      [3:0] Hex,
  output reg [7:0] Seg
);

  always @(*)
    case(Hex)
      4'd0: Seg[7:0] = ~(8'b00111111);
      4'd1: Seg[7:0] = ~(8'b00000110);
      4'd2: Seg[7:0] = ~(8'b01011011);
      4'd3: Seg[7:0] = ~(8'b01001111);
      4'd4: Seg[7:0] = ~(8'b01100110);
      4'd5: Seg[7:0] = ~(8'b01101101);
      4'd6: Seg[7:0] = ~(8'b01111101);
      4'd7: Seg[7:0] = ~(8'b00000111);
      4'd8: Seg[7:0] = ~(8'b01111111);
      4'd9: Seg[7:0] = ~(8'b01100111);
      4'hA: Seg[7:0] = ~(8'b01110111);
      4'hB: Seg[7:0] = ~(8'b01111100);
      4'hC: Seg[7:0] = ~(8'b00111001);
      4'hD: Seg[7:0] = ~(8'b01011110);
      4'hE: Seg[7:0] = ~(8'b01111001);
      4'hF: Seg[7:0] = ~(8'b01110001);
    endcase

endmodule

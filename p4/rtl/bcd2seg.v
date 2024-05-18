module bcd2seg(
input [3:0] Bcd,
output reg [6:0] Seg
);

always @(*)
  case (Bcd)
   4'b0000 : begin Seg = ~(7'b0111111); end
   4'b0001 : begin Seg = ~(7'b0000110); end
   4'b0010 : begin Seg = ~(7'b1011011); end
   4'b0011 : begin Seg = ~(7'b1001111); end
   4'b0100 : begin Seg = ~(7'b1100110); end
   4'b0101 : begin Seg = ~(7'b1101101); end
   4'b0110 : begin Seg = ~(7'b1111101); end
   4'b0111 : begin Seg = ~(7'b0000111); end
   4'b1000 : begin Seg = ~(7'b1111111); end
   4'b1001 : begin Seg = ~(7'b1100111); end
   default : begin Seg = ~(7'b1111111); end
  endcase
endmodule

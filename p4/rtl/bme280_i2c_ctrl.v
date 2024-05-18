`include "../misc/timescale.v"
`include "./i2c_master/i2c_master_defines.v"

module bme280_i2c_ctrl #(
  parameter DWIDTH = 8,      // bus data size
  parameter AWIDTH = 3,      // bus addres size
  parameter SLADDR = 7'b111_0110
)(
  input  wire Clk,                        // master clock input
  input  wire Rst_n,                      // async active low reset
  output reg  [AWIDTH-1:0] Dbus_addr, // lower address bits
  input  wire [DWIDTH-1:0] Dbus_di,   // databus input
  output reg  [DWIDTH-1:0] Dbus_do,   // databus output
  output reg  Dbus_wr,                    // databus write enable input
  input  wire I2C_start,                  // when high a new transfer starts
  input  wire I2C_rdwr,                   // selects i2c transfer 1=Read 0=Write
  input  wire I2C_last,                   // last transfer
  input  wire [DWIDTH-1:0] I2C_addr,  // slave reg/mem address to Rd/Wr
  input  wire [DWIDTH-1:0] I2C_txd,   // data to tranfer to slave
  output reg  [DWIDTH-1:0] I2C_rxd,   // data received from slave
  output reg  I2C_done                    // I2C transfer done
);

  localparam RD = 1'b1, WR = 1'b0;

  localparam SET_PRER = 4'd0,  // set I2C PRER regiser
             EN_I2C   = 4'd1,  // enable I2c master
             IDLE     = 4'd2,  //
             WR_SADDR = 4'd3,  // write transfer, slave address + RW bit
             CHECK_TIP= 4'd4,  // select SR to monitor TIP flag
             SET_TXR  = 4'd5,  // wait until transfer is completed
             WR_RADDR = 4'd6,  // write transfer, rdwr reg/mem address
             WR_DATA  = 4'd7,  // write transfer, send txdata to slave
             RD_SADDR = 4'd8,  // write transfer, slave address + RD bit
             RD_DATA  = 4'd9,  // read transfer, receive rxdata from slave
             GET_DATA = 4'd10; // read RXR register

  reg [4-1:0] state, next, last;

  wire tip = Dbus_addr==`I2C_SR ? Dbus_di[1]: 1'b1;

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) state <= SET_PRER;
    else       state <= next;

  always @(*)
    case(state)
      SET_PRER : next = EN_I2C;
      EN_I2C   : next = IDLE;

      IDLE     : if(I2C_start) next = WR_SADDR;
                 else          next = IDLE;
      WR_SADDR :               next = CHECK_TIP;

      CHECK_TIP: if(~tip) next = SET_TXR;
                 else     next = CHECK_TIP;
      SET_TXR  : casez({I2C_start,I2C_rdwr,I2C_last,last})
                   {1'b?, 1'b?, 1'b?, WR_SADDR} : next = WR_RADDR;
                   {1'b?, 1'b0, 1'b?, WR_RADDR} : next = WR_DATA;
                   {1'b1, 1'b0, 1'b0, WR_DATA } : next = WR_RADDR;
                   {1'b?, 1'b0, 1'b1, WR_DATA } : next = IDLE;
                   {1'b?, 1'b1, 1'b?, WR_RADDR} : next = RD_SADDR;
                   {1'b?, 1'b1, 1'b?, RD_SADDR} : next = RD_DATA;
                   {1'b?, 1'b1, 1'b?, RD_DATA } : next = GET_DATA;
                   {1'b1, 1'b1, 1'b?, GET_DATA} : next = RD_DATA;
                   default : next = SET_TXR;
                 endcase

      WR_RADDR : next = CHECK_TIP;
      WR_DATA  : next = CHECK_TIP;

      RD_SADDR : next = CHECK_TIP;
      RD_DATA  : next = CHECK_TIP;
      GET_DATA : if(I2C_last) next = IDLE;
                 else         next = SET_TXR;
      default  : next = IDLE;
    endcase

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) begin
      last      <= IDLE;
      Dbus_addr <= {AWIDTH{1'b0}};
      Dbus_do   <= {DWIDTH{1'b0}};
      Dbus_wr   <= 1'b0;
      I2C_rxd   <= {DWIDTH{1'b0}};
      I2C_done  <= 1'b0;
    end else begin
      last      <= last;
      Dbus_addr <= `I2C_SR;
      Dbus_do   <= {DWIDTH{1'b0}};
      Dbus_wr   <= 1'b0;
      I2C_rxd   <= I2C_rxd;
      I2C_done  <= 1'b0;
      case(state)
        SET_PRER : begin
          Dbus_addr <= `I2C_PRER;
          Dbus_do   <= 8'h3D;
          Dbus_wr   <= 1'b1;
        end
        EN_I2C : begin
          Dbus_addr <= `I2C_CTR;
          Dbus_do   <= 8'h80;
          Dbus_wr   <= 1'b1;
        end

        IDLE : begin
          last      <= state;
          Dbus_addr <= `I2C_TXR;
          Dbus_do   <= {SLADDR,WR};
          if(I2C_start) begin
            Dbus_wr   <= 1'b1;
          end
        end
        WR_SADDR : begin
          last      <= state;
          Dbus_addr <= `I2C_CR;
          Dbus_do   <= 8'b1001_0000; // {STA,STO,RD,WR, ACK,0,AL_ACK,IACK}
          Dbus_wr   <= 1'b1;
        end

        CHECK_TIP : begin
          I2C_done  <= ~I2C_rdwr & (last==WR_DATA) & ~tip;
        end
        SET_TXR : begin
          casez({I2C_start,I2C_rdwr,I2C_last,last})
            {1'b?, 1'b?, 1'b?, WR_SADDR} : begin Dbus_addr <= `I2C_TXR; Dbus_do <= I2C_addr; Dbus_wr <= 1'b1; end // next = WR_RADDR;
            {1'b?, 1'b0, 1'b?, WR_RADDR} : begin Dbus_addr <= `I2C_TXR; Dbus_do <= I2C_txd;  Dbus_wr <= 1'b1; end // next = WR_DATA;
            {1'b1, 1'b0, 1'b0, WR_DATA } : begin Dbus_addr <= `I2C_TXR; Dbus_do <= I2C_addr; Dbus_wr <= 1'b1; end // next = WR_RADDR;
            {1'b?, 1'b0, 1'b1, WR_DATA } : ; // next = IDLE;
            {1'b?, 1'b1, 1'b?, WR_RADDR} : begin Dbus_addr <= `I2C_TXR; Dbus_do <= {SLADDR,RD};  Dbus_wr <= 1'b1; end // next = RD_SADDR;
            {1'b?, 1'b1, 1'b?, RD_SADDR} : ; // next = RD_DATA;
            {1'b?, 1'b1, 1'b?, RD_DATA } : begin Dbus_addr <= `I2C_RXR; end // next = GET_DATA;
            {1'b1, 1'b1, 1'b?, GET_DATA} : ; // next = RD_DATA;
            default : ; // next = IDLE;
          endcase
        end

        WR_RADDR : begin
          last      <= state;
          Dbus_addr <= `I2C_CR;
          Dbus_do   <= 8'b0001_0000; // {STA,STO,RD,WR, ACK,0,AL_ACK,IACK}
          Dbus_wr   <= 1'b1;
        end
        WR_DATA  : begin
          last      <= state;
          Dbus_addr <= `I2C_CR;
          Dbus_do   <= {1'b0,I2C_last,6'b01_0000}; // {STA,STO,RD,WR, ACK,0,AL_ACK,IACK}
          Dbus_wr   <= 1'b1;
        end

        RD_SADDR : begin
          last      <= state;
          Dbus_addr <= `I2C_CR;
          Dbus_do   <= 8'b1001_0000; // {STA,STO,RD,WR, ACK,0,AL_ACK,IACK}
          Dbus_wr   <= 1'b1;
        end
        RD_DATA  : begin
          last      <= state;
          Dbus_addr <= `I2C_CR;
          Dbus_do   <= {1'b0,I2C_last,2'b10,I2C_last,3'b000}; // {STA,STO,RD,WR, ACK,0,AL_ACK,IACK}
          Dbus_wr   <= 1'b1;
        end
        GET_DATA : begin
          last      <= state;
          I2C_done  <= 1'b1;
          Dbus_addr <= `I2C_RXR;
          I2C_rxd   <= Dbus_di;
        end

        default : ;
      endcase
    end

  // Transfer end flag

endmodule

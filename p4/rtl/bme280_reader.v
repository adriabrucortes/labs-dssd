`include "../misc/timescale.v"
`include "bme280_defines.v"

module bme280_reader #(
  parameter DWIDTH = 8
)(
  input  wire Clk,
  input  wire Rst_n,
  output reg  I2CC_start,
  output reg  I2CC_rdwr,
  output reg  I2CC_last,
  output reg  [DWIDTH-1:0] I2CC_addr,
  output reg  [DWIDTH-1:0] I2CC_txd,
  input  wire [DWIDTH-1:0] I2CC_rxd,
  input  wire I2CC_done,
  output reg  [20-1:0] TempBin,
  output reg  [20-1:0] PressBin,
  output reg  [16-1:0] HumBin,
  output reg  TimerEn,
  input  wire TimerInt,
  output reg  ErrorFlag,
  output reg  [16-1:0] DigT1,DigT2,DigT3,
  output reg  [16-1:0] DigP1,DigP2,DigP3,DigP4,DigP5,DigP6,DigP7,DigP8,DigP9,
  output reg   [8-1:0] DigH1,DigH3,DigH6,
  output reg  [16-1:0] DigH2,DigH4,DigH5
);

  localparam RD = 1'b1, WR = 1'b0;

  reg [5-1:0] byteCnt;

  reg [4-1:0] state, next, last;

  localparam IDLE     = 4'd0,
             WAIT_1S  = 4'd1,
             RESET    = 4'd2,
             RD_ID    = 4'd3,
             RD_CAL00 = 4'd4,
             RD_CAL26 = 4'd5,
             WR_CFG   = 4'd6,
             WAIT_END = 4'd7,
             STATUS   = 4'd8,
             GET_DATA = 4'd9,
             MEASURE  = 4'd10,
             ERROR    = 4'd11;

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) state <= IDLE;
    else       state <= next;

  always @(*)
    case(state)
      IDLE    : next = WAIT_1S;

      WAIT_1S : if(TimerInt)
                  case(last)
                    IDLE, RESET : next = RD_ID;
                    STATUS  : next = GET_DATA;
                    GET_DATA: next = MEASURE;
                    default : next = STATUS;
                  endcase
                else next = WAIT_1S;

      RESET   : next = WAIT_END;
      RD_ID   : next = WAIT_END;
      RD_CAL00: next = WAIT_END;
      RD_CAL26: next = WAIT_END;
      WR_CFG  : next = WAIT_END;

      WAIT_END: if(I2CC_done)
                  case(last)
                    RESET    : if(byteCnt==5'd3)   next = ERROR;
                               else                next = WAIT_1S;
                    RD_ID    : if(I2CC_rxd==8'h60) next = RD_CAL00;
                               else                next = RESET;
                    RD_CAL00 : if(byteCnt==5'd25)  next = RD_CAL26;
                               else                next = RD_CAL00;
                    RD_CAL26 : if(byteCnt==5'd6)   next = WR_CFG;
                               else                next = RD_CAL26;
                    WR_CFG   : if(byteCnt==5'd1)   next = WAIT_1S;
                               else                next = WR_CFG;
                    STATUS   : if(I2CC_rxd[3])     next = WAIT_1S;
                               else                next = GET_DATA;
                    GET_DATA : if(byteCnt==5'd7)   next = WAIT_1S;
                               else                next = GET_DATA;
                    MEASURE  :                     next = WAIT_1S;
                    default : next = ERROR;
                  endcase
                else next = WAIT_END;

      STATUS  : next = WAIT_END;
      GET_DATA: next = WAIT_END;
      MEASURE : next = WAIT_END;

      ERROR   : next = ERROR;
      default : next = ERROR;
    endcase

  always @(posedge Clk or negedge Rst_n)
    if(!Rst_n) begin
      TimerEn    <= 1'b0;
      byteCnt    <= 5'd0;
      ErrorFlag  <= 1'b0;
      last       <= 4'd0;
      I2CC_start <= 1'b0;
      I2CC_rdwr  <= RD;
      I2CC_last  <= 1'b0;
      I2CC_addr  <= {DWIDTH{1'b0}};
      I2CC_txd   <= {DWIDTH{1'b0}};
      TempBin    <= 20'd0;
      PressBin   <= 20'd0;
      HumBin     <= 16'd0;
      {DigT1,DigT2,DigT3} <= {3{16'd0}};
      {DigP1,DigP2,DigP3,DigP4,DigP5,DigP6,DigP7,DigP8,DigP9} <= {9{16'd0}};
      {DigH1,DigH3,DigH6} <= {3{8'd0}};
      {DigH2,DigH4,DigH5} <= {3{16'd0}};
    end else begin
      TimerEn    <= 1'b0;
      byteCnt    <= byteCnt;
      ErrorFlag  <= 1'b0;
      last       <= last;
      I2CC_start <= 1'b0;
      I2CC_rdwr  <= I2CC_rdwr;
      I2CC_last  <= I2CC_last;
      I2CC_addr  <= I2CC_addr;
      I2CC_txd   <= I2CC_txd;
      TempBin    <= TempBin;
      PressBin   <= PressBin;
      HumBin     <= HumBin;
      {DigT1,DigT2,DigT3} <= {DigT1,DigT2,DigT3};
      {DigP1,DigP2,DigP3,DigP4,DigP5,DigP6,DigP7,DigP8,DigP9} <= {DigP1,DigP2,DigP3,DigP4,DigP5,DigP6,DigP7,DigP8,DigP9} ;
      {DigH1,DigH3,DigH6} <= {DigH1,DigH3,DigH6};
      {DigH2,DigH4,DigH5} <= {DigH2,DigH4,DigH5};
      case(state)
        IDLE : begin
          last <= state;
        end

        WAIT_1S : begin
          TimerEn <= 1'b1;
        end

        RESET : begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= WR;
          I2CC_last  <= 1'b1;
          I2CC_addr  <= `BME_RESET;
          I2CC_txd   <= 8'b1011_0110;
        end

        RD_ID : begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= RD;
          I2CC_last  <= 1'b1;
          I2CC_addr  <= `BME_ID;
          I2CC_txd   <= 8'b0000_0000;
        end

        RD_CAL00 : begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= RD;
          // I2CC_last is set in WAIT_END
          I2CC_addr  <= `BME_CAL00;
          I2CC_txd   <= 8'b0000_0000;
        end

        RD_CAL26 : begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= RD;
          // I2CC_last is set in WAIT_END
          I2CC_addr  <= `BME_CAL26;
          I2CC_txd   <= 8'b0000_0000;
        end

        WR_CFG : begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= WR;
          // I2CC_last is set in WAIT_END
          // I2CC_txd is set in WAIT_END
          // I2CC_addr is set in WAIT_END
        end

        WAIT_END: if(I2CC_done) begin
          byteCnt <= byteCnt + 1'b1;
          case(last)
            RD_ID    : if(I2CC_rxd==8'h60) begin
                         byteCnt <= 5'd0;
                         I2CC_last <= 1'b0; // for RD_CAL00
                       end
            RD_CAL00 : case(byteCnt)
                         5'd0  : DigT1 <= {DigT1[15:8], I2CC_rxd};
                         5'd1  : DigT1 <= {I2CC_rxd   , DigT1[7:0]};
                         5'd2  : DigT2 <= {DigT2[15:8], I2CC_rxd};
                         5'd3  : DigT2 <= {I2CC_rxd   , DigT2[7:0]};
                         5'd4  : DigT3 <= {DigT3[15:8], I2CC_rxd};
                         5'd5  : DigT3 <= {I2CC_rxd   , DigT3[7:0]};
                         5'd6  : DigP1 <= {DigP1[15:8], I2CC_rxd};
                         5'd7  : DigP1 <= {I2CC_rxd   , DigP1[7:0]};
                         5'd8  : DigP2 <= {DigP2[15:8], I2CC_rxd};
                         5'd9  : DigP2 <= {I2CC_rxd   , DigP2[7:0]};
                         5'd10 : DigP3 <= {DigP3[15:8], I2CC_rxd};
                         5'd11 : DigP3 <= {I2CC_rxd   , DigP3[7:0]};
                         5'd12 : DigP4 <= {DigP4[15:8], I2CC_rxd};
                         5'd13 : DigP4 <= {I2CC_rxd   , DigP4[7:0]};
                         5'd14 : DigP5 <= {DigP5[15:8], I2CC_rxd};
                         5'd15 : DigP5 <= {I2CC_rxd   , DigP5[7:0]};
                         5'd16 : DigP6 <= {DigP6[15:8], I2CC_rxd};
                         5'd17 : DigP6 <= {I2CC_rxd   , DigP6[7:0]};
                         5'd18 : DigP7 <= {DigP7[15:8], I2CC_rxd};
                         5'd19 : DigP7 <= {I2CC_rxd   , DigP7[7:0]};
                         5'd20 : DigP8 <= {DigP8[15:8], I2CC_rxd};
                         5'd21 : DigP8 <= {I2CC_rxd   , DigP8[7:0]};
                         5'd22 : DigP9 <= {DigP9[15:8], I2CC_rxd};
                         5'd23 : DigP9 <= {I2CC_rxd   , DigP9[7:0]};
                         5'd24 : I2CC_last <= 1'b1;
                         5'd25 : begin
                                   DigH1 <= I2CC_rxd;
                                   byteCnt <= 5'd0;
                                   I2CC_last <= 1'b0; // for RD_CAL26
                                 end
                         default : ;
                       endcase
            RD_CAL26 : case(byteCnt)
                         5'd0 : DigH2 <= {DigH2[15:8],I2CC_rxd};
                         5'd1 : DigH2 <= {I2CC_rxd   ,DigH2[7:0]};
                         5'd2 : DigH3 <=  I2CC_rxd;
                         5'd3 : DigH4 <= {{4{I2CC_rxd[7]}},I2CC_rxd,DigH4[3:0]};
                         5'd4 : begin
                                  DigH4 <= {DigH4[15:4],I2CC_rxd[3:0]};
                                  DigH5 <= {DigH5[15:4],I2CC_rxd[7:4]};
                                end
                         5'd5 : begin
                                  DigH5 <= {{4{I2CC_rxd[7]}},I2CC_rxd,DigH5[3:0]};
                                  I2CC_last <= 1'b1;
                                end
                         5'd6 : begin
                                  DigH6 <= I2CC_rxd;
                                  byteCnt <= 5'b0;
                                  I2CC_last <= 1'b0; // for WR_CFG
                                  I2CC_addr <= `BME_CONFIG;
                                  I2CC_txd <= 8'b0000_0100;
                                  byteCnt <= 5'd0;
                                end
                         default : ;
                       endcase
            WR_CFG   : case(byteCnt)
                         5'd0 : begin
                                  I2CC_last <= 1'b1;
                                  I2CC_addr <= `BME_CTRL_HUM;
                                  I2CC_txd <= 8'b0000_0001;
                                end
                         5'd1 : begin
                                  I2CC_addr <= `BME_CTRL_MEAS;
                                  I2CC_txd <= 8'b0010_0101;
                                  byteCnt <= 5'd0;
                                end
                         default : ;
                       endcase
            STATUS   : begin
                         byteCnt <= 5'd0;
                         if(~I2CC_rxd[3]) begin
                           I2CC_last <= 1'b0;
                           I2CC_addr  <= `BME_PRESS_MSB;
                         end
                       end
            GET_DATA : case(byteCnt)
                         5'd0 : PressBin <= {I2CC_rxd       , PressBin[11:0]};
                         5'd1 : PressBin <= {PressBin[19:12], I2CC_rxd      ,PressBin[3:0]};
                         5'd2 : PressBin <= {PressBin[19:4] , I2CC_rxd[7:4]};
                         5'd3 : TempBin  <= {I2CC_rxd       , TempBin[11:0]};
                         5'd4 : TempBin  <= {TempBin[19:12] , I2CC_rxd      ,TempBin[3:0]};
                         5'd5 : TempBin  <= {TempBin[19:4]  , I2CC_rxd[7:4]};
                         5'd6 : begin
                                  HumBin   <= {I2CC_rxd       , HumBin[7:0]};
                                  I2CC_last <= 1'b1;
                                end
                         5'd7 : begin
                                  HumBin <= {HumBin[15:8]   , I2CC_rxd};
                                  byteCnt <= 5'd0;
                                end
                         default : ;
                       endcase
            MEASURE  : begin byteCnt <= 5'd0; end
            default  : ;
          endcase
        end

        STATUS : begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= RD;
          I2CC_last  <= 1'b1;
          I2CC_addr  <= `BME_STATUS;
          I2CC_txd   <= 8'b0000_0000;
        end

        GET_DATA : begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= RD;
          // I2CC_last is set in WAIT_END
          // I2CC_addr  <= `BME_PRESS_MSB;
          I2CC_txd <= 8'b0000_0000;
        end

        MEASURE :  begin
          last       <= state;
          I2CC_start <= 1'b1;
          I2CC_rdwr  <= WR;
          I2CC_last  <= 1'b1;
          I2CC_addr  <= `BME_CTRL_MEAS;
          I2CC_txd   <= 8'b0010_0101;
        end

        ERROR   : ErrorFlag <= 1'b1;
        default : ErrorFlag <= 1'b1;
      endcase
    end


// -----------------------------------------------------------------------------
// synopsys translate_off
reg [40-1:0] stateName; // shows the state name during simulation.
always @(state)
  case (state)
    IDLE     : stateName = "IDLE";
    WAIT_1S  : stateName = "WSEC";
    RESET    : stateName = "RST";
    RD_ID    : stateName = "ID";
    RD_CAL00 : stateName = "CAL00";
    RD_CAL26 : stateName = "CAL26";
    WR_CFG   : stateName = "CFG";
    WAIT_END : stateName = "WEND";
    STATUS   : stateName = "ST";
    MEASURE  : stateName = "MEAS";
    GET_DATA : stateName = "DATA";
    ERROR    : stateName = "ERR";
    default  : stateName = "def";
  endcase
reg [40-1:0] nextName; // shows the next name during simulation.
always @(next)
  case (next)
    IDLE     : nextName = "IDLE";
    WAIT_1S  : nextName = "WSEC";
    RESET    : nextName = "RST";
    RD_ID    : nextName = "ID";
    RD_CAL00 : nextName = "CAL00";
    RD_CAL26 : nextName = "CAL26";
    WR_CFG   : nextName = "CFG";
    WAIT_END : nextName = "WEND";
    STATUS   : nextName = "ST";
    MEASURE  : nextName = "MEAS";
    GET_DATA : nextName = "DATA";
    ERROR    : nextName = "ERR";
    default  : nextName = "def";
  endcase
reg [40-1:0] lastName; // shows the next name during simulation.
always @(last)
  case (last)
    IDLE     : lastName = "IDLE";
    WAIT_1S  : lastName = "WSEC";
    RESET    : lastName = "RST";
    RD_ID    : lastName = "ID";
    RD_CAL00 : lastName = "CAL00";
    RD_CAL26 : lastName = "CAL26";
    WR_CFG   : lastName = "CFG";
    WAIT_END : lastName = "WEND";
    STATUS   : lastName = "ST";
    MEASURE  : lastName = "MEAS";
    GET_DATA : lastName = "DATA";
    ERROR    : lastName = "ERR";
    default  : lastName = "def";
  endcase
// synopsys translate_on
endmodule


`include "timescale.v"

module i2c_slave_model #(
  parameter I2C_ADDR = 7'b001_0000,
  parameter WR_BURST = 1'b1,  // 0: disabled
  parameter RD_BURST = 1'b1,  // 0: disabled
  parameter MEM_SIZE = 3,
  parameter MEM_INIT_FILE = ""
)(
  input Scl,
  inout Sda
);

  //
	// Variable declaration
  //
	wire debug = 1'b1;

	reg [7:0] mem [MEM_SIZE-1:0]; // initiate memory
	reg [7:0] mem_adr;   // memory address
	reg [7:0] mem_do;    // memory data output

	reg sta, d_sta;
	reg sto;

	reg [7:0] sr;    // 8bit shift register
	reg       rw;    // read/write direction

	wire      my_adr;    // my address called ??
	wire      i2c_reset; // i2c-statemachine reset
	reg [2:0] bit_cnt; // 3bit downcounter
	wire      acc_done;// 8bits transfered
	reg       ld;        // load downcounter

	reg       sda_o;     // sda-drive level
	wire      sda_dly;   // delayed version of Sda

	reg [2:0] state; // synopsys enum_state
	// statemachine declaration
	localparam IDLE         = 3'b000,
	           SLAVE_ACK    = 3'b001,
	           GET_MEM_ADDR = 3'b010,
	           GMA_ACK      = 3'b011,
	           DATA         = 3'b100,
	           DATA_ACK     = 3'b101;

	//
	// module body
	//
	initial
	begin
	   sda_o = 1'b1;
	   state = IDLE;
     if (MEM_INIT_FILE != "") begin
       $readmemh(MEM_INIT_FILE, mem);
     end
	end

	// generate shift register
	always @(posedge Scl)
	  sr <= #1 {sr[6:0],Sda};

	//detect my_address
	assign my_adr = (sr[7:1] == I2C_ADDR);
	// FIXME: This should not be a generic assign, but rather
	// qualified on address transfer phase and probably reset by stop

	//generate bit-counter
	always @(posedge Scl)
	  if(ld) bit_cnt <= #1 3'b111;
	  else   bit_cnt <= #1 bit_cnt - 3'h1;

	//generate access done signal
	assign acc_done = !(|bit_cnt);

	// generate delayed version of Sda
	// this model assumes a hold time for Sda after the falling edge of Scl.
	// According to the Phillips i2c spec, there s/b a 0 ns hold time for Sda
	// with regards to Scl. If the data changes coincident with the clock, the
	// acknowledge is missed
	// Fix by Michael Sosnoski
	assign #1 sda_dly = Sda;


	//detect start condition
	always @(negedge Sda)
	  if(Scl) begin
	    sta   <= #1 1'b1;
		d_sta <= #1 1'b0;
		sto   <= #1 1'b0;
	    if(debug)
	      $display("DEBUG i2c_slave; start condition detected at %t", $time);
    end else begin
	    sta   <= #1 1'b0;
    end

	always @(posedge Scl)
	  d_sta <= #1 sta;

	// detect stop condition
	always @(posedge Sda)
	  if(Scl) begin
	    sta <= #1 1'b0;
	    sto <= #1 1'b1;
	    if(debug)
	      $display("DEBUG i2c_slave; stop condition detected at %t", $time);
	  end else begin
	    sto <= #1 1'b0;
    end

	//generate i2c_reset signal
	assign i2c_reset = sta || sto;

	// generate statemachine


	always @(negedge Scl or posedge sto)
	  if(sto || (sta && !d_sta))begin
	    state <= #1 IDLE; // reset statemachine
	    sda_o <= #1 1'b1;
	    ld    <= #1 1'b1;
	  end else begin
	    // initial settings
	    sda_o <= #1 1'b1;
	    ld    <= #1 1'b0;
	    case(state) // synopsys full_case parallel_case
        IDLE: begin // IDLE state
	        if(acc_done && my_adr) begin
	          state <= #1 SLAVE_ACK;
	          rw    <= #1 sr[0];
	          sda_o <= #1 1'b0; // generate i2c_ack

	          #2;
	          if(debug && rw)
	            $display("DEBUG i2c_slave; command byte received (read) at %t", $time);
	          if(debug && !rw)
	            $display("DEBUG i2c_slave; command byte received (write) at %t", $time);

	          if(rw) begin
	            mem_do <= #1 mem[mem_adr];
	            if(debug)	begin
	              #2 $display("DEBUG i2c_slave; data block read %x from address %x (1)", mem_do, mem_adr);
	              #2 $display("DEBUG i2c_slave; memcheck [0]=%x, [1]=%x, [2]=%x", mem[4'h0], mem[4'h1], mem[4'h2]);
	            end
	          end
	        end
        end

	      SLAVE_ACK: begin
          if(rw) begin
            state <= #1 DATA;
            sda_o <= #1 mem_do[7];
          end else begin
            state <= #1 GET_MEM_ADDR;
          end
	        ld <= #1 1'b1;
	      end

        GET_MEM_ADDR: begin // wait for memory address
	        if(acc_done) begin
	          state <= #1 GMA_ACK;
	          mem_adr <= #1 sr; // store memory address
	          sda_o <= #1 !(sr <= 15); // generate i2c_ack, for valid address
	          if(debug)
	            #1 $display("DEBUG i2c_slave; address received. adr=%x, ack=%b", sr, sda_o);
	        end
        end

	      GMA_ACK: begin
          state <= #1 DATA;
          ld    <= #1 1'b1;
        end

        DATA: begin  // receive or drive data
          if(rw)
            sda_o <= #1 mem_do[7];
          if(acc_done) begin
            state <= #1 DATA_ACK;
            if(rw)
              mem_adr <= #2 mem_adr + RD_BURST;
            else
              mem_adr <= #2 mem_adr + WR_BURST;
            sda_o <= #1 (rw && (mem_adr <= 8'hff) ); // send ack on write, receive ack on read
            if(rw) begin
              #3 mem_do <= mem[mem_adr];
              if(debug)
                #5 $display("DEBUG i2c_slave; data block read %x from address %x (2)", mem_do, mem_adr);
            end
            if(!rw) begin
              mem[ mem_adr[MEM_SIZE-1:0] ] <= #1 sr; // store data in memory
              if(debug)
                #2 $display("DEBUG i2c_slave; data block write %x to address %x", sr, mem_adr);
            end
          end
        end

	      DATA_ACK: begin
          ld <= #1 1'b1;
          if(rw) begin
            if(sr[0]) begin // read operation && master send NACK
	            state <= #1 IDLE;
              sda_o <= #1 1'b1;
            end else begin
              if(RD_BURST)
                state <= #1 DATA;
              else
                state <= #1 GET_MEM_ADDR;
              sda_o <= #1 mem_do[7];
            end
          end else begin
            if(WR_BURST)
              state <= #1 DATA;
            else
              state <= #1 GET_MEM_ADDR;
            sda_o <= #1 1'b1;
          end
        end
      endcase
    end

	// read data from memory
	always @(posedge Scl)
	  if(!acc_done && rw)
	    mem_do <= #1 {mem_do[6:0], 1'b1}; // insert 1'b1 for host ack generation

	// generate tri-states
	assign Sda = sda_o ? 1'bz : 1'b0;


  //
	// Timing checks
  //
	wire tst_sto = sto;
	wire tst_sta = sta;

	specify
    // https://www.analog.com/en/technical-articles/i2c-timing-definition-and-specification-guide-part-2.html
	  specparam nxp_normal_scl_low  = 4700, // Based on NXP I2C Timing Specification
	            nxp_normal_scl_high = 4000, // 100k
	            nxp_normal_tsu_sta  = 4700,
	            nxp_normal_thd_sta  = 4000,
	            nxp_normal_tsu_sto  = 4000,
	            nxp_normal_tbuf     = 4700,

	            nxp_fast_scl_low  = 1300, // 400K
	            nxp_fast_scl_high =  600,
	            nxp_fast_tsu_sta  = 1300,
	            nxp_fast_thd_sta  =  600,
	            nxp_fast_tsu_sto  =  600,
	            nxp_fast_tbuf     = 1300,

	            nxp_hs_scl_low  = 500, // 1MHz
	            nxp_hs_scl_high = 260,
	            nxp_hs_tsu_sta  = 260,
	            nxp_hs_thd_sta  = 260,
	            nxp_hs_tsu_sto  = 260,
	            nxp_hs_tbuf     = 500;

    specparam bme_hs_scl_low  = 160, // BME280 Bosh
	            bme_hs_scl_high = 160,
	            bme_hs_tsu_sta  = 160,
	            bme_hs_thd_sta  = 150,
	            bme_hs_tsu_sto  = 160,
	            bme_hs_tbuf     = 210;

	  $width(negedge Scl, bme_hs_scl_low);  // Scl low time
	  $width(posedge Scl, bme_hs_scl_high); // Scl high time

	  $setup(posedge Scl, negedge Sda &&& Scl, bme_hs_tsu_sta); // setup start
	  $setup(negedge Sda &&& Scl, negedge Scl, bme_hs_thd_sta); // hold start
	  $setup(posedge Scl, posedge Sda &&& Scl, bme_hs_tsu_sto); // setup stop

	  $setup(posedge tst_sta, posedge tst_sto, bme_hs_tbuf); // stop to start time
	endspecify

endmodule



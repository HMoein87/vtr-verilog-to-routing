
/* define all the parameters here */

`define ALTERA

//codeword length, which is the interleaver length
`define CODE_SIZE 1024
`define CODE_ADD_WIDTH 10


//encoder state number
`define STATE_NUM 4
`define ALL_STATE 16
//`define G1 ('o5)
//`define G2 ('o7)
//Note*: change pre_state and pre_p in ASOVA.v if STATE_NUM changes
`define G1 ('o31)
`define G2 ('o27)


/**********************/
/* Channel Parameters */
/**********************/
// the bitwidth of channal input data, 2's complement format
`define NOISE_BITWIDTH 4
// the decimal point position of channel input data
// BIT_WIDTH=5, FIX_POINT=2 =>  xxx.xx
`define FIX_POINT 0

/**********************/
/* Decoder Parameters */
/**********************/
// MEMSIZE>TRACE_SIZE+UPDATE_SIZE
`define MEM_SIZE 64
`define MEM_ADDWIDTH 6
`define TRACE_SIZE 32
`define UPDATE_SIZE 16


`define N_MAX 4
// NMAX_WIDTH should always be log2(N_MAX)
`define NMAX_WIDTH 2


/*	Lc = 4/(sigma^2)
	used in BMU for branch matric generation
*/
`define LC_VALUE (3'b011)

// the (max metric - THRESHOLD_BASE) will be the threshold for each level
`define THRESHOLD_BASE 3
// if survivor path outnumber Nmax, how much threshold increase
`define THRESHOLD_STEP 2




`define PROBE
/*
	Branch Metric Gengerate Unit
	it generates branch metric for input 00,01,10,11
	it works for rate 2 codes only

	bm(uk,pk) = (1/2) uk*L(uk) + Lc/2 * (y*uk+p*pk)
		(uk,pk) = {-1,1}

	??? should I take (uk,pk)={0,1}??
		then in the branch (ukpk)=(00), bm0=0;

	input:
		u,p: signed BIT_WIDTH with DECIMAL_POINT
		Li: signed BIT_WIDTH reg [32:0]
	output:
		bm0,1,2,3: signed
			bitwidth=2*BIT_WIDTH
			decial point = 2*DECIMAL_POINT+1, 1 because of (1/2)
*/

module BMU ( clk, en,
	u, p, Li,
	bm0,bm1,bm2,bm3,
	product0,product1,product2,product3
`ifdef PROBE
	,probe0,probe1,probe2,probe3
`endif
	);

	parameter BIT_WIDTH=`NOISE_BITWIDTH;
	parameter DECIMAL_POINT = `FIX_POINT;

	input clk,en;
	input [BIT_WIDTH-1:0] u, p, Li;
	output [BIT_WIDTH-1:0] bm0,bm1,bm2,bm3;
	//output [2*BIT_WIDTH-1:0] out;
`ifdef PROBE
	output [BIT_WIDTH:0] probe0,probe1,probe2,probe3;
`endif

	wire [2*BIT_WIDTH:0] Lc;

	// to prevent overflow, bitwidth increase 1
	wire [BIT_WIDTH:0] ui,pi;
	output [2*BIT_WIDTH:0] product0, product1, product2,product3;
	// Note!!: BIT_WIDTH+1
	wire [BIT_WIDTH:0] a0,a1,a2,a3;  //(y*uk+p*pk),
	reg [2*BIT_WIDTH-2*DECIMAL_POINT-1:0] re0,re1,re2,re3;  // results


	reg  [BIT_WIDTH-1:0] bmr0,bmr1,bmr2,bmr3;
	assign bm0 = bmr0;
	assign bm1 = bmr1;
	assign bm2 = bmr2;
	assign bm3 = bmr3;

	assign Lc=`LC_VALUE;
	assign ui={u[BIT_WIDTH-1],u};
	assign pi={p[BIT_WIDTH-1],p};

	assign a0 = TCAdder(-ui,-pi);
	assign a1 = -ui+pi;
	assign a2 = ui-pi;
	assign a3 = ui+pi;


	DW02_mult  mult0 (Lc, a0, 1'b1, product0);
		defparam mult0.A_width=BIT_WIDTH, mult0.B_width=BIT_WIDTH+1;
	DW02_mult  mult1 (Lc, a1, 1'b1, product1);
		defparam mult1.A_width=BIT_WIDTH, mult1.B_width=BIT_WIDTH+1;
	DW02_mult  mult2 (Lc, a2, 1'b1, product2);
		defparam mult2.A_width=BIT_WIDTH, mult2.B_width=BIT_WIDTH+1;
	DW02_mult  mult3 (Lc, a3, 1'b1, product3);
		defparam mult3.A_width=BIT_WIDTH, mult3.B_width=BIT_WIDTH+1;

	always @ ( posedge clk )
//	if ( en )
	begin
		// uk,pk = 0,0
		re0 = product0[2*BIT_WIDTH:2*DECIMAL_POINT] - Li;
		re1 = product1[2*BIT_WIDTH:2*DECIMAL_POINT] - Li;
		re2 = product2[2*BIT_WIDTH:2*DECIMAL_POINT] + Li;
		re3 = product3[2*BIT_WIDTH:2*DECIMAL_POINT] + Li;

		if (2*BIT_WIDTH-2*DECIMAL_POINT > BIT_WIDTH ) begin
			bmr0= re0[2*BIT_WIDTH-2*DECIMAL_POINT-1:2*BIT_WIDTH-2*DECIMAL_POINT-BIT_WIDTH];
			bmr1= re1[2*BIT_WIDTH-2*DECIMAL_POINT-1:2*BIT_WIDTH-2*DECIMAL_POINT-BIT_WIDTH];
			bmr2= re2[2*BIT_WIDTH-2*DECIMAL_POINT-1:2*BIT_WIDTH-2*DECIMAL_POINT-BIT_WIDTH];
			bmr3= re3[2*BIT_WIDTH-2*DECIMAL_POINT-1:2*BIT_WIDTH-2*DECIMAL_POINT-BIT_WIDTH];
		end else begin
			bmr0=re0;
			bmr1=re1;
			bmr2=re2;
			bmr3=re3;
		end
	end


/*
	The overcome the overflow of -(-4)-(-4)=8
*/
	function [`NOISE_BITWIDTH:0] TCAdder;
		input [`NOISE_BITWIDTH:0] A;
		input [`NOISE_BITWIDTH:0] B;

		reg [`NOISE_BITWIDTH:0] tcsum;
		reg [32:0] TCi;

	begin
//		wire [`NOISE_BITWIDTH-1:0] temp_s;
		tcsum = A + B;


		if ( A[`NOISE_BITWIDTH] ^ B[`NOISE_BITWIDTH] ) begin  // + and -
			TCAdder = tcsum;
		end else
			if ( A[`NOISE_BITWIDTH] )	begin  // - and -
				if ( tcsum[`NOISE_BITWIDTH])
					TCAdder=tcsum;
				else begin
					for (TCi=0;TCi<`NOISE_BITWIDTH;TCi=TCi+1)
						TCAdder[TCi]=0;
					TCAdder[BIT_WIDTH]=1;
				end
			end else // + and +
				if ( tcsum[`NOISE_BITWIDTH] ) begin
					for (TCi=0;TCi<`NOISE_BITWIDTH;TCi=TCi+1)
						TCAdder[TCi] = 1;
					TCAdder[`NOISE_BITWIDTH]=0;
				end	else
					TCAdder = tcsum;
	end
	endfunction

`ifdef PROBE
	assign probe0 = a0;
	assign probe1 = a1;
	assign probe2 = a2;
	assign probe3 = a3;
`endif

endmodule


module Decider ( clk,reset, d1en, d1out, Lo12, Li21, out_en,ou);
	parameter CHANNEL_WIDTH=`NOISE_BITWIDTH;
	input clk,reset, d1en, d1out;
	input [CHANNEL_WIDTH-1:0] Lo12,Li21;
	output out_en,ou;

	reg [CHANNEL_WIDTH-1:0] data;
	reg t;
	always @ (posedge clk)
	if (d1out) begin
		t<=~t;
		data = Lo12 + Li21;
	end

	assign out_en=d1out;
	assign ou = Lo12[CHANNEL_WIDTH-1];
endmodule

// megafunction wizard: %LPM_RAM_DP+%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: altdpram0.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2003 Altera Corporation
//Any  megafunction  design,  and related netlist (encrypted  or  decrypted),
//support information,  device programming or simulation file,  and any other
//associated  documentation or information  provided by  Altera  or a partner
//under  Altera's   Megafunction   Partnership   Program  may  be  used  only
//to program  PLD  devices (but not masked  PLD  devices) from  Altera.   Any
//other  use  of such  megafunction  design,  netlist,  support  information,
//device programming or simulation file,  or any other  related documentation
//or information  is prohibited  for  any  other purpose,  including, but not
//limited to  modification,  reverse engineering,  de-compiling, or use  with
//any other  silicon devices,  unless such use is  explicitly  licensed under
//a separate agreement with  Altera  or a megafunction partner.  Title to the
//intellectual property,  including patents,  copyrights,  trademarks,  trade
//secrets,  or maskworks,  embodied in any such megafunction design, netlist,
//support  information,  device programming or simulation file,  or any other
//related documentation or information provided by  Altera  or a megafunction
//partner, remains with Altera, the megafunction partner, or their respective
//licensors. No other licenses, including any licenses needed under any third
//party's intellectual property, are provided herein.


module dpram (
	data,
	wren,
	wraddress,
	rdaddress,
	clock,
	q);

	parameter DATA_WIDTH=8, ADD_WIDTH=6, MEM_SIZE=64;

	input	[DATA_WIDTH-1:0]  data;
	input	  wren;
	input	[ADD_WIDTH-1:0]  wraddress;
	input	[ADD_WIDTH-1:0]  rdaddress;
	input	  clock;
	output	[DATA_WIDTH-1:0]  q;

	wire [DATA_WIDTH-1:0] sub_wire0;
	wire [DATA_WIDTH-1:0] q = sub_wire0[DATA_WIDTH-1:0];

	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = DATA_WIDTH,
		altsyncram_component.widthad_a = ADD_WIDTH,
		altsyncram_component.numwords_a = MEM_SIZE,
		altsyncram_component.width_b = DATA_WIDTH,
		altsyncram_component.widthad_b = ADD_WIDTH,
		altsyncram_component.numwords_b = MEM_SIZE,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "0"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_ENABLE_A NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_ENABLE_B NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_SIZE NUMERIC "8"
// Retrieval info: PRIVATE: Clock_A NUMERIC "0"
// Retrieval info: PRIVATE: Clock_B NUMERIC "0"
// Retrieval info: PRIVATE: REGdata NUMERIC "1"
// Retrieval info: PRIVATE: REGwraddress NUMERIC "1"
// Retrieval info: PRIVATE: REGwren NUMERIC "1"
// Retrieval info: PRIVATE: REGrdaddress NUMERIC "1"
// Retrieval info: PRIVATE: REGrren NUMERIC "1"
// Retrieval info: PRIVATE: REGq NUMERIC "0"
// Retrieval info: PRIVATE: INDATA_REG_B NUMERIC "0"
// Retrieval info: PRIVATE: WRADDR_REG_B NUMERIC "0"
// Retrieval info: PRIVATE: OUTDATA_REG_B NUMERIC "0"
// Retrieval info: PRIVATE: CLRdata NUMERIC "0"
// Retrieval info: PRIVATE: CLRwren NUMERIC "0"
// Retrieval info: PRIVATE: CLRwraddress NUMERIC "0"
// Retrieval info: PRIVATE: CLRrdaddress NUMERIC "0"
// Retrieval info: PRIVATE: CLRrren NUMERIC "0"
// Retrieval info: PRIVATE: CLRq NUMERIC "0"
// Retrieval info: PRIVATE: BYTEENA_ACLR_A NUMERIC "0"
// Retrieval info: PRIVATE: INDATA_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: WRCTRL_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: WRADDR_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: OUTDATA_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: BYTEENA_ACLR_B NUMERIC "0"
// Retrieval info: PRIVATE: enable NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
// Retrieval info: PRIVATE: MIFfilename STRING ""
// Retrieval info: PRIVATE: UseLCs NUMERIC "0"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "256"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "5"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "32"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "5"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "32"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

/*********************************
	 mode block interleaver
input original address, output the interleaved address
all combitional logic, no clock
input sequence: 	000 001
					010 011
					100	101
					110 100
output sequnce:		001 011 101 100
					000	010 100 110

msb half of address: inverse, move to lsb
lsb half of address: move to msb
*/

module interleaver ( inadd, outadd );
parameter BIT_WIDTH=`NOISE_BITWIDTH;
parameter ROW=(BIT_WIDTH/2);
	input [BIT_WIDTH-1:0] inadd;
	output [BIT_WIDTH-1:0] outadd;

	assign outadd[ROW-1:0] = ~inadd[BIT_WIDTH-1:BIT_WIDTH-ROW];
	assign outadd[BIT_WIDTH-1:ROW] = inadd[BIT_WIDTH-ROW-1:0];

endmodule


module de_interleaver ( inadd, outadd );
parameter BIT_WIDTH=3;
parameter ROW=(BIT_WIDTH/2);
	input [BIT_WIDTH-1:0] inadd;
	output [BIT_WIDTH-1:0] outadd;

	assign outadd[BIT_WIDTH-1:BIT_WIDTH-ROW] = ~inadd[ROW-1:0];
	assign outadd[BIT_WIDTH-ROW-1:0] = inadd[BIT_WIDTH-1:ROW];

endmodule



/* interleaver buffer from D1 to D2
	when d1out, read from d1 and write into mem
	when d2en, read from mem and send data to d2
	pingpang

	*NOTE: data0 is always presenting on the read port;
		when d2en=1, data1 will apear after the first clk posedge
*/
module InterBuffer ( clk, reset, d1out, Lo12, d2en, Li12, pingpang );
	parameter BIT_WIDTH=`NOISE_BITWIDTH,
		ADD_WIDTH=`CODE_ADD_WIDTH;
	input clk,reset,d2en,d1out,pingpang;
	input [BIT_WIDTH-1:0] Lo12;
	output [BIT_WIDTH-1:0] Li12;

	reg pDelay;  //pingpang delay
	reg stateAB;
	wire a_wen, b_wen;

	always @ (posedge clk ) pDelay <= pingpang;
    always @ (posedge clk)
		//if ( reset==0 )	stateAB=0; else
		if (pingpang & (~pDelay) ) stateAB <= ~stateAB;  // if posedge pingpang
	assign a_wen=d1out & (~stateAB);
	assign b_wen=d1out & stateAB;


	reg [ADD_WIDTH-1:0] wadd, radd;
	wire [ADD_WIDTH-1:0] raddi; // output of interleaver
	wire [BIT_WIDTH-1:0] outa,outb;

	MEM mema ( clk, wadd, a_wen, Lo12, raddi, outa );
	MEM memb ( clk, wadd, b_wen, Lo12, raddi, outb);

	always @ (posedge clk)
	if ( (reset==0)| pingpang ) begin
		wadd<=0; radd<=0;
	end else begin
		if ( d2en== 1'b1 )	radd<=radd+1;
		if ( d1out== 1'b1 ) wadd<=wadd+1;
	end

	interleaver inter1 ( radd, raddi );

	assign Li12 = stateAB ? outa : outb;

endmodule

/* interleaver buffer from D2 to D1
*/
module DeInterBuffer ( clk, reset, d2out, Lo21, d1en, Li21, pingpang );
	parameter BIT_WIDTH=`NOISE_BITWIDTH,
		ADD_WIDTH=`CODE_ADD_WIDTH;
	input clk,reset,d1en,d2out,pingpang;
	input [BIT_WIDTH-1:0] Lo21;
	output [BIT_WIDTH-1:0] Li21;

	reg pDelay;  //pingpang delay
	reg stateAB;
	wire a_wen, b_wen;

	always @ (posedge clk ) pDelay <= pingpang;
    always @ (posedge clk)
		//if ( reset==0 )	stateAB=0; else
	    if (pingpang & (~pDelay) ) stateAB <= ~stateAB;  // if posedge pingpang
	assign a_wen=d2out & (~stateAB);
	assign b_wen=d2out & stateAB;

	reg [ADD_WIDTH-1:0] wadd, radd;
	wire [ADD_WIDTH-1:0] raddi; // output of interleaver
	wire [BIT_WIDTH-1:0] outa,outb;

	MEM mema ( clk, wadd, a_wen, Lo21, raddi, outa );
	MEM memb ( clk, wadd, b_wen, Lo21, raddi, outb);

	always @ (posedge clk)
	if ( (reset==0) | pingpang ) begin
		wadd<=0; radd<=0;
	end else begin
		if ( d1en== 1'b1 )	radd<=radd+1;
		if ( d2out== 1'b1 ) wadd<=wadd+1;
	end

	de_interleaver inter1 ( radd, raddi );
		defparam inter1.BIT_WIDTH = BIT_WIDTH;

	assign Li21 = stateAB ? outa : outb;

endmodule


// two ports memory block

module MEM ( clk, wadd, wen, data, radd, q );
parameter BIT_WIDTH=`NOISE_BITWIDTH, ADD_WIDTH = `CODE_ADD_WIDTH, MEM_SIZE = `CODE_SIZE;

	input clk, wen;
	input [ADD_WIDTH-1:0] wadd, radd;
	input [BIT_WIDTH-1:0] data;
	output [BIT_WIDTH-1:0] q;
//	output [BIT_WIDTH-1:0] m_test ;

`ifdef ALTERA  // if it is Quartus Altera chip
	dpram amem (
	.data(data),
	.wren(wen),
	.wraddress(wadd),
	.rdaddress(radd),
	.clock(clk),
	.q(q));

	defparam amem.DATA_WIDTH=BIT_WIDTH,
		amem.ADD_WIDTH=ADD_WIDTH,
		amem.MEM_SIZE=MEM_SIZE;

`else
	reg [BIT_WIDTH-1:0] memory [MEM_SIZE-1:0];

	always @ ( posedge clk )
	begin
		if ( wen ) begin
			memory[wadd] <= data;
$display ( "memory[%d]=%d\n",wadd,memory[wadd]);
		end
	end

	assign q = memory[radd];
//	assign m_test = memory[0];
`endif

endmodule


/* 2 read ports memory */
module MEM2R ( clk, wadd, wen, data, radda, qa, raddb, qb );
parameter BIT_WIDTH=`NOISE_BITWIDTH, ADD_WIDTH = `CODE_ADD_WIDTH,
	MEM_SIZE = `CODE_SIZE;

	input clk, wen;
	input [ADD_WIDTH-1:0] wadd, radda, raddb;
	input [BIT_WIDTH-1:0] data;
	output [BIT_WIDTH-1:0] qa, qb;


`ifdef ALTERA
	tpram amem (
	.data(data),
	.wraddress(wadd),
	.rdaddress_a(radda),
	.rdaddress_b(raddb),
	.wren(wen),
	.clock(clk),
	.qa(qa),
	.qb(qb));

	defparam	amem.DATA_WIDTH=BIT_WIDTH,
		amem.ADD_WIDTH=ADD_WIDTH,
		amem.MEM_SIZE=MEM_SIZE;

`else
	reg [BIT_WIDTH-1:0] memory [MEM_SIZE-1:0];

	always @ ( posedge clk )
	begin
		if ( wen ) begin
			memory[wadd] <= data;
		end
	end

	assign qa = memory[radda];
	assign qb = memory[raddb];
`endif
endmodule

//-----------------------------------------------------------------------------
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 1994 - 2002   SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    KB WSFDB          June 30, 1994
//
// VERSION:   Simulation Architecture
//
// DesignWare_version: 82259444
// DesignWare_release: 2002.05-DWF_0205
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
//
// ABSTRACT:  Multiplier
//           A_width-Bits * B_width-Bits => A_width+B_width Bits
//           Operands A and B can be either both signed (two's complement) or
//           both unsigned numbers. TC determines the coding of the input operands.
//           ie. TC = '1' => signed multiplication
//               TC = '0' => unsigned multiplication
//
//      FIXED: by replacement with A tested working version
//              that not only doesn't multiplies right it does it
//              two times faster!

//------------------------------------------------------------------------------

module DW02_mult(A,B,TC,PRODUCT);
parameter       A_width = 8;
parameter       B_width = 8;
input   [A_width-1:0]   A;
input   [B_width-1:0]   B;
input                   TC;
output  [A_width+B_width-1:0]   PRODUCT;

wire    [A_width+B_width-1:0]   PRODUCT;

wire    [A_width-1:0]   temp_a;
wire    [B_width-1:0]   temp_b;
wire    [A_width+B_width-2:0]   long_temp1,long_temp2;

assign  temp_a = (A[A_width-1])? (~A + 1'b1) : A;
assign  temp_b = (B[B_width-1])? (~B + 1'b1) : B;

assign  long_temp1 = temp_a * temp_b;
assign  long_temp2 = ~(long_temp1 - 1'b1);

assign  PRODUCT = (TC)? (((A[A_width-1] ^ B[B_width-1]) && (|long_temp1))?
                                {1'b1,long_temp2} : {1'b0,long_temp1})
                        : A * B;

endmodule



/* RSC encoder
	Given the u, and pre-state, generate the next state and p
*/

module RSC (u, ps, ns, p);
parameter STATE_NUM=`STATE_NUM;
input u;
input [STATE_NUM-1:0] ps;
output [STATE_NUM-1:0] ns;
output p;

	reg p;
	wire [STATE_NUM-1:0] ps;
	reg [STATE_NUM-1:0] ns;
	reg [32:0] i,j;
	reg s0;
	wire [STATE_NUM:0] rg1;
	wire [STATE_NUM:0] rg2;
	reg [STATE_NUM:0] g1;
	reg [STATE_NUM:0] g2;

	assign rg1 = `G1;
	assign rg2 = `G2;
	always for (j=0;j<=STATE_NUM;j=j+1) begin
		g1[j]<=rg1[STATE_NUM-j];
		g2[j]<=rg2[STATE_NUM-j];
	end

	always @ (u or ps) begin
		s0 = g1[0] & u;

		for (i=0;i<STATE_NUM;i=i+1) begin
			s0 = s0 ^ ( g1[i+1] & ps[i]);
		end

		p = g2 & s0;
		for (i=0;i<STATE_NUM;i=i+1) begin
			p = p ^ (g2[i+1] & ps[i]);
		end

		for (i=1;i<STATE_NUM;i=i+1)
			ns[i] = ps[i-1];
		ns[0] = s0;
	end


endmodule

`define PROBE

/* when start goes high, start to computer one path metric at each cycle */
module SEQ_ACS (clk,reset,u,p,Li,start,
	pointer, decision, metric_diff, md_valid,
	sur_pointer, dis_pointer, dis_valid, done, out_en
`ifdef PROBE
	, pre_add, probe0,probe1,probe2,probe3
`endif
	);
parameter BIT_WIDTH=`NOISE_BITWIDTH, POINTER_WIDTH=`NMAX_WIDTH,
	NMAX=`N_MAX;
input clk, reset;
input [BIT_WIDTH-1:0] u,p,Li;
input start; // start to compute, one cycle high
output [POINTER_WIDTH-1:0] pointer; // current output row address
output decision; // decision bit
output [BIT_WIDTH-1:0] metric_diff;
output md_valid, dis_valid;  // metric difference valid, discarded path pointer valid
output [POINTER_WIDTH-1:0] sur_pointer, dis_pointer; // survivor path pointer, discarded path pointer
output done;
output out_en;

`ifdef PROBE
output [POINTER_WIDTH:0] pre_add;
output [3:0] probe0,probe1,probe2,probe3;
`endif


/* --------------- variables ------------------- */
	reg [POINTER_WIDTH-1:0] pointer; // current output row address
	// previous path metric
	reg [BIT_WIDTH-1:0] pre_metric [NMAX-1:0];
	// current path metric
	reg [BIT_WIDTH-1:0] metric [NMAX-1:0];
	// path valid and pre-path valid
	reg [NMAX-1:0] path_valid, pre_valid;
	// indicate if the path has been used to compute next metric
	// each state can generate two paths
	reg [2*NMAX-1:0] path_used;
	// indicate if the state is stored in the memory
	reg [`ALL_STATE-1:0] pre_state_valid, state_valid;

	// obtain the path state from the current path address
	reg [`STATE_NUM-1:0] path_state [NMAX-1:0];
	reg [`STATE_NUM-1:0] pre_path_state [NMAX-1:0];

	// threshold of metric to prune path, update every level
	reg [BIT_WIDTH-1:0] Threshold;
	// state of the two merging paths for each ACS block
	// these should be a fixed number of a given code
	reg [`STATE_NUM-1:0] path0 [`ALL_STATE-1:0];
	reg [`STATE_NUM-1:0] path1 [`ALL_STATE-1:0];
	// obtain the path address from the current path state
	reg [POINTER_WIDTH-1:0] path_id [`ALL_STATE-1:0];
	reg [POINTER_WIDTH-1:0] new_path_id [`ALL_STATE-1:0];

	wire [BIT_WIDTH-1:0] bm0,bm1,bm2,bm3;  // branch metric 00,01,10,11

	reg [`STATE_NUM-1:0] cstate_delay;
	wire [`STATE_NUM-1:0] current_state;
	wire current_p;


	// interface for ACS BLOCK
        wire [BIT_WIDTH-1:0] metric_out;
	reg [BIT_WIDTH-1:0] m0, m1, p0,p1, old_metric0, old_metric1;
	reg valid0, valid1;
	wire m_valid;
	wire [POINTER_WIDTH-1:0] p0_add, p1_add;
	reg [POINTER_WIDTH-1:0] p0add_delay, p1add_delay;
	reg m0_valid, m1_valid;
	wire less; // metric < Threshold
	wire acs_decision;
	wire [`STATE_NUM-1:0] other_path_state; // the state of the merging path

	/* ------- control signals ----------*/
	reg [32:0] i,j,k;
	// the number of paths that meet the Threshold
	// need one more bit than NMAX since it counts up to NMAX
	reg [POINTER_WIDTH:0] count;
	// address of pre_path
	reg [POINTER_WIDTH:0] pre_add;
	// count>NMAX, need to increase threshold and start over
	wire over_count;
	wire all_invalid; // no path valid after check all states
	reg working;

	// current output meet the requirement of validility and threshold
	wire output_valid;
	reg acsin_valid;
	wire fnsh_cond;  // possible finish condition: all pre-paths have been checked
	reg finish, finish_delay;  // finish current column
	wire finish_pulse;


/* ----------- Procedure ---------------------*/

`ifdef PROBE
	assign probe0[0]=m0_valid;
	assign probe0[1]=m1_valid;
	assign probe0[2]=working;
	assign probe0[3]=out_en;
	assign probe1=p1_add;
	assign probe2=Threshold;
	assign probe3=over_count;
`endif

	always @ (posedge clk) acsin_valid = working & (!path_used[pre_add]);
	assign out_en = output_valid;
	assign output_valid =  acsin_valid & m_valid & less;
	assign sur_pointer = acs_decision ? p1add_delay : p0add_delay;
	assign dis_pointer = acs_decision ? p0add_delay : p1add_delay;
	// the path from the previous metric is always valid. Only need to look at the merging path
	assign dis_valid = m1_valid;
	assign done = finish_pulse;

	/* locate the path state for each ACS */
/*	always for ( k=0;k<`ALL_STATE;k=k+1) begin
		path0[k] <= pre_state (k,0);
		path1[k] <= pre_state (k,1);
	end
*/

	/* BMU generate branch metric for (00,01,10,11) */
	BMU bmu ( clk, 1, u, p, Li, bm0,bm1,bm2,bm3);


	// working condition
	// finish condition
	assign fnsh_cond = (pre_add==2*NMAX-1) | (pre_valid[pre_add[POINTER_WIDTH:1]]==0);
	always @ (posedge clk)
	if ( reset== 1'b0 ) begin
		finish <= 0;
		working <= 0;
	end else if ( fnsh_cond	& (~over_count)) begin
			finish <= 1;
			working <= 0;
	end else begin
		finish <= 0;
		if (start) working <= 1;
	end
	always @ (posedge clk) finish_delay <= finish;
	assign finish_pulse = finish & ~finish_delay;


	always @ (posedge clk)
	if ( reset== 1'b0 ) begin
		pointer <= 0;
		pre_add <= 0;

		for(i=0;i<NMAX;i=i+1) path_valid[i]<=0;
		for(i=0;i<`ALL_STATE;i=i+1) state_valid[i]<=1'b0;
	end else if ( finish_pulse | over_count ) begin
		for(i=0;i<NMAX;i=i+1) path_valid<=0;
		for(i=0;i<`ALL_STATE;i=i+1) state_valid[i]<=0;
		pre_add <= 0;
		pointer <= 0;
	end else begin
		if ( working ) begin
			pre_add <= pre_add + 1;
		end
		if ( output_valid ) begin
			// if Threshold>0, metric=metric_out--;
			metric[pointer] <= Threshold[BIT_WIDTH-1] ? metric_out : metric_out-Threshold;
			path_valid[pointer]<=1;
			path_state[pointer] <= cstate_delay;
			state_valid[cstate_delay] <= 1'b1;
			new_path_id[cstate_delay] <= pointer;
			pointer <= pointer + 1;
		end
	end


	// ACS input
	assign p0_add = pre_add[POINTER_WIDTH:1];
	assign p1_add = path_id[other_path_state];
	always @ (posedge clk) begin
		old_metric0 = pre_metric[p0_add];
		old_metric1 = pre_metric[p1_add];
		m0_valid = pre_valid[p0_add];
		m1_valid = pre_valid[p1_add] & pre_state_valid[other_path_state];
		p0 = bm_choice(pre_add[0],current_p);
		p1 = bm_choice(~pre_add[0],~current_p); // the p of the merging paths are always odd?
	end
	// ACS output
	assign decision = ~pre_add[0] ^ acs_decision;  // it is (pre_add[0]_delay^acs_decision
	always @ (posedge clk) begin
		cstate_delay = current_state;
		p0add_delay = p0_add;
		p1add_delay = p1_add;
	end

	RSC rsc0 (pre_add[0],pre_path_state[pre_add[POINTER_WIDTH:1]],current_state, current_p);
	PRESTATE prestate0 ( current_state, ~pre_add[0], other_path_state);
	// path0 is always from pre_metric, and path1 is always from indexing
	ACS_BLOCK acsblock (old_metric0, old_metric1,
		m0_valid, m1_valid, p0, p1,
		acs_decision, metric_out, metric_diff, m_valid, md_valid);
	IS_LESS comparotor (Threshold,metric_out,1, less);

	// pruning
	always @ (posedge clk)
	if ( (reset=='b0) | finish_pulse | over_count )
		count<=0;
	else if (output_valid)
		count<=count+1;
	assign over_count = (count==NMAX) & (output_valid) | all_invalid;
	assign all_invalid =  fnsh_cond &(count==0);
	always @ (posedge clk)
	if ( (reset=='b0) | finish )
		Threshold <= 0 - `THRESHOLD_BASE;
	else if (all_invalid)
		Threshold = Threshold - 1;
	else if ( over_count )
		Threshold = Threshold + `THRESHOLD_STEP;
	IS_LESS thresholdLess (0,Threshold,1,Threshold_greater_0);

	// update column
	always @ (posedge clk)
	if ( reset=='b0 ) begin
		for (i=1;i<NMAX;i=i+1)	pre_valid[i] <= 0;
		pre_valid[0] <= 1;
		pre_metric[0] <= 0;
		pre_path_state[0] <= 0;
		for (i=0;i<2*NMAX;i=i+1) path_used[i] <= 0;
		path_id[0] <= 0;
	end else if ( finish_pulse ) begin
		for (i=0;i<`ALL_STATE;i=i+1) begin
			path_id[i] <= new_path_id[i];
			pre_state_valid[i]<=state_valid[i];
		end

		for (i=0;i<NMAX;i=i+1) begin
			pre_valid[i] <= path_valid[i];
			pre_metric[i] <= metric[i];
			pre_path_state[i] <= path_state[i];
		end
		for (i=0;i<2*NMAX;i=i+1) path_used[i] <= 0;
	end else if ( over_count ) begin
		for (i=0;i<2*NMAX;i=i+1) path_used[i] <= 0;

	end else if (working) begin
		if (m0_valid) path_used[pre_add] <= 1;
		if (m1_valid) path_used[{p1_add,pre_add[0]}] <= 1;
	end


/* ----------------- Functions and Tasks --------------- */


	// given current u and p
	// decide which bm should be used for ACS
	function [BIT_WIDTH-1:0] bm_choice;
		input u,p;

		begin case ({u,p})
			'b00:	bm_choice=bm0;
			'b01:	bm_choice=bm1;
			'b10:	bm_choice=bm2;
			'b11:	bm_choice=bm3;
		endcase
		end
	endfunction

endmodule


/*
	ACS: select the survivor from the merging two paths
	input:
		path0: u=0
		path1: u=1
	output:
		survivor=0 means path0 wins, otherwise path1
	metric_i: metric of current node
		valid_i: the validity of metric
		mdiff: the metric difference of the two paths, always positive
		md_valid: the validity of mdiff
*/
module ACS_BLOCK (old_metric0, old_metric1, valid0, valid1, p0, p1,
	surviv, metric_i, mdiff_i, valid_i, md_valid_i);
parameter BIT_WIDTH=`NOISE_BITWIDTH;
	input [BIT_WIDTH-1:0] old_metric0,old_metric1;
	input valid0, valid1;
	input [BIT_WIDTH-1:0] p0, p1;
	output surviv;
	output [BIT_WIDTH-1:0] metric_i, mdiff_i;
	output valid_i, md_valid_i;
	//output [BIT_WIDTH-1:0] probea,probeb;

	reg [BIT_WIDTH-1:0] loc_diff;
	reg [BIT_WIDTH-1:0] new_metric0, new_metric1;
	reg valid_i, md_valid_i;
	reg [BIT_WIDTH-1:0] metric_i, mdiff_i;
	reg surviv;

	always begin
	//probea=old_metric0;probeb=old_metric1;
		new_metric0 = TCAdder2(p0,old_metric0);
		new_metric1 = TCAdder2(p1,old_metric1);
		loc_diff = new_metric0 - new_metric1;

		case ({valid0,valid1})
		'b00: begin valid_i<=0; md_valid_i<=0; end
		'b01: begin
				metric_i <= new_metric1;
				valid_i<=1;
				md_valid_i <=0;
				surviv<=1;
		end
		'b10: begin
			metric_i <= new_metric0;
			valid_i<=1;
			md_valid_i <=0;
			surviv <= 0;
		end
		'b11:
			if ( loc_diff[BIT_WIDTH-1] ) begin  //p0<p1
				surviv<=1; valid_i<=1;
				metric_i <= new_metric1;
				mdiff_i <= ~loc_diff +1; // make it positive
				md_valid_i <=1;
			end else begin				// p0>p1
				surviv<=0; valid_i<=1;
				metric_i <= new_metric0;
				mdiff_i <= loc_diff;
				md_valid_i <=1;
			end
		endcase
	end



/* 	No overflow Two's Complement Adder
	if the result is too small to represent by the given bitwidth, the smallest value will be returned
	The same thing for too big numbers
*/
	function [BIT_WIDTH-1:0] TCAdder2;
		input [BIT_WIDTH-1:0] A;
		input [BIT_WIDTH-1:0] B;

		reg [BIT_WIDTH-1:0] tcsum;
		reg [32:0] TCi;

	begin
//		wire [BIT_WIDTH-1:0] temp_s;
		tcsum = A + B;

		if ( A[BIT_WIDTH-1] ^ B[BIT_WIDTH-1] ) begin  // + and -
			TCAdder2 = tcsum;
		end else
			if ( A[BIT_WIDTH-1] )	begin  // - and -
				if ( tcsum[BIT_WIDTH-1])
					TCAdder2=tcsum;
				else begin
					for (TCi=0;TCi<BIT_WIDTH-1;TCi=TCi+1)
						TCAdder2[TCi]=0;
					TCAdder2[BIT_WIDTH-1]=1;
				end
			end else // + and +
				if ( tcsum[BIT_WIDTH-1] ) begin
					for (TCi=0;TCi<BIT_WIDTH-1;TCi=TCi+1)
						TCAdder2[TCi] = 1;
					TCAdder2[BIT_WIDTH-1]=0;
				end	else
					TCAdder2 = tcsum;
	end
	endfunction

endmodule



// ABSTRACT:  2-Function Comparator
//           When is_less = 1   A < B
//                is_less = 0   A >= B
//           When TC  = 0   Unsigned numbers
//           When TC  = 1   Two's - complement numbers
module IS_LESS (A,B,TC, less);
	parameter BIT_WIDTH=`NOISE_BITWIDTH, sign = BIT_WIDTH - 1;
    input [BIT_WIDTH-1 : 0]  A, B;
    input TC; //Flag of Signed
	output less;

    reg less;
	reg a_is_0, b_is_1, result ;
    reg [32:0] i;

	always begin
        if ( TC === 1'b0 ) begin  // unsigned numbers
          result = 0;
          for (i = 0; i <= sign; i = i + 1) begin
              a_is_0 = A[i] === 1'b0;
              b_is_1 = B[i] === 1'b1;
              result = (a_is_0 & b_is_1) |
                        (a_is_0 & result) |
                        (b_is_1 & result);
          end // loop
        end else begin  // signed numbers
          if ( A[sign] !== B[sign] ) begin
              result = A[sign] === 1'b1;
          end else begin
              result = 0;
              for (i = 0; i <= sign-1; i = i + 1) begin
                  a_is_0 = A[i] === 1'b0;
                  b_is_1 = B[i] === 1'b1;
                  result = (a_is_0 & b_is_1) |
                            (a_is_0 & result) |
                            (b_is_1 & result);
              end // loop
          end // if
        end // if
        less = result;
    end
endmodule //


/* given the current state and u
	return the previous state */
module  PRESTATE (state,u_in, pre_state);
input [`STATE_NUM-1:0] state;
input u_in;
output [`STATE_NUM-1:0] pre_state;
reg	[`STATE_NUM-1:0] pre_state;

	// based on (7,5) code and trellis of proposal Fig. 6.5
	always if ( `STATE_NUM==2 )  // (5,7)
			case ({state,u_in})
                0,3     : pre_state=0;
                4,7     : pre_state=1;
                2,1     : pre_state=2;
                6,5     : pre_state=3;
			endcase
		else if (`STATE_NUM==3) //(15,13)
			case ({state,u_in})
                0,3     : pre_state=0;
                6,5     : pre_state=1;
                8,11    : pre_state=2;
                14,13   : pre_state=3;
                2,1     : pre_state=4;
                4,7     : pre_state=5;
                10,9    : pre_state=6;
                12,15   : pre_state=7;
			endcase
		else if (`STATE_NUM==4) //(31,27)
			case ({state,u_in})
				// run davis:comm/src/rsccoder.cc for the following data
                0,3     : pre_state=0;
                6,5     : pre_state=1;
                8,11    : pre_state=2;
                14,13   : pre_state=3;
                16,19   : pre_state=4;
                22,21   : pre_state=5;
                24,27   : pre_state=6;
                30,29   : pre_state=7;
                2,1     : pre_state=8;
                4,7     : pre_state=9;
                10,9    : pre_state=10;
                12,15   : pre_state=11;
                18,17   : pre_state=12;
                20,23   : pre_state=13;
                26,25   : pre_state=14;
                28,31   : pre_state=15;
			endcase
		else if (`STATE_NUM==5) //(65,57)
			case ({state,u_in})
                0,3     : pre_state=0;
                6,5     : pre_state=1;
                8,11    : pre_state=2;
                14,13   : pre_state=3;
                18,17   : pre_state=4;
                20,23   : pre_state=5;
                26,25   : pre_state=6;
                28,31   : pre_state=7;
                32,35   : pre_state=8;
                38,37   : pre_state=9;
                40,43   : pre_state=10;
                46,45   : pre_state=11;
                50,49   : pre_state=12;
                52,55   : pre_state=13;
                58,57   : pre_state=14;
                60,63   : pre_state=15;
                2,1     : pre_state=16;
                4,7     : pre_state=17;
                10,9    : pre_state=18;
                12,15   : pre_state=19;
                16,19   : pre_state=20;
                22,21   : pre_state=21;
                24,27   : pre_state=22;
                30,29   : pre_state=23;
                34,33   : pre_state=24;
                36,39   : pre_state=25;
                42,41   : pre_state=26;
                44,47   : pre_state=27;
                48,51   : pre_state=28;
                54,53   : pre_state=29;
                56,59   : pre_state=30;
                62,61   : pre_state=31;
			endcase
endmodule


/* 2 write port, 3 read port memory, for ASOVA survivor memory only
	Clocked memmory. Data will apprear on the output port after clk edge.
 */
/*
  	data1: {pointer to survivor,
		pointer to competitive, vlaid_bit of comptetive pointer,
		decision bit,
		delta valid, delta}
  	data2: {deltat valid, updated delta}
	q1: traceback data
	q2: delta to be updated and its pointers
	q3: competitive decision bit and pointer
*/
module W2R3MEM (clk,reset, data1, wr_add, wen1,
				data2, wadd2, wen2,
				q1, radd1, q2, radd2, q3, radd3);
parameter DELTA_WIDTH=`NOISE_BITWIDTH,
		NMAX=`N_MAX,
		POINTER_WIDTH=`NMAX_WIDTH,
		MEM_SIZE=`MEM_SIZE,
		ADD_SIZE=`MEM_ADDWIDTH+`NMAX_WIDTH;
input clk,reset;
input wen1,wen2;
input [(DELTA_WIDTH+2*POINTER_WIDTH+3)-1:0] data1;
input [DELTA_WIDTH:0] data2; // delat valid, update delta only
input [ADD_SIZE-1:0] wr_add,wadd2,radd1,radd2,radd3;
output [(DELTA_WIDTH+2*POINTER_WIDTH+3)-1:0] q2;
output [(2*POINTER_WIDTH+2)-1:0] q1,q3;

	// memory bank # for write new data
	wire [1:0] bank, up_bank, tr_bank, re_bank;
	reg [1:0] rd1_de, rd2_de, rd3_de;  // delay of the bank-bits of radd1,radd2,radd3
	wire [ADD_SIZE-1:0] wr_add, tc_add, up_addr, up_addo, up_addw;


/* ---------- interface variables ------------*/
	// write address of 4 memory banks
	wire [ADD_SIZE-3:0] wadda,waddb,waddc,waddd;
	// write enable for delta memory banks
	wire wena, wenb, wenc, wend;
	// input data of the delta memory banks
	wire [DELTA_WIDTH:0] da, db, dc, dd;
	// read address of delta memory banks
	wire [ADD_SIZE-3:0] radd;
	// output data of the delta memory banks
	wire [DELTA_WIDTH:0] delta0, delta1, delta2, delta3;

	// write enable for pointer memory banks
	wire wenpa, wenpb, wenpc, wenpd;
	// input data of pointer memory: two pointers, one decision bit and dis_valid
	wire [(2*POINTER_WIDTH+2)-1:0] dp;
	// read address of delta memory banks
	wire [ADD_SIZE-3:0] radda, raddb, raddc, raddd;
	// output data of pointer memory
	wire [(2*POINTER_WIDTH+2)-1:0] q0a,q1a,q2a,q3a,q0b,q1b,q2b,q3b;


	// 4 memory bank for delta
	MEM md0 ( clk, wadda, wena, da, radd, delta0 );
	MEM md1 ( clk, waddb, wenb, db, radd, delta1 );
	MEM md2 ( clk, waddc, wenc, dc, radd, delta2 );
	MEM md3 ( clk, waddd, wend, dd, radd, delta3 );
	defparam md0.BIT_WIDTH=DELTA_WIDTH+1,
		md0.ADD_WIDTH = ADD_SIZE-2, md0.MEM_SIZE = NMAX*MEM_SIZE/4;
	defparam md1.BIT_WIDTH=DELTA_WIDTH+1,
		md1.ADD_WIDTH = ADD_SIZE-2, md1.MEM_SIZE = NMAX*MEM_SIZE/4;
	defparam md2.BIT_WIDTH=DELTA_WIDTH+1,
		md2.ADD_WIDTH = ADD_SIZE-2, md2.MEM_SIZE = NMAX*MEM_SIZE/4;
	defparam md3.BIT_WIDTH=DELTA_WIDTH+1,
		md3.ADD_WIDTH = ADD_SIZE-2, md3.MEM_SIZE = NMAX*MEM_SIZE/4;

	// 4 memory banks for decision, pointers
	// they need two read ports when updating
	MEM2R m0( clk, wadda, wenpa, dp, radda, q0a, radd3, q0b );
	MEM2R m1( clk, waddb, wenpb, dp, raddb, q1a, radd3, q1b );
	MEM2R m2( clk, waddc, wenpc, dp, raddc, q2a, radd3, q2b );
	MEM2R m3( clk, waddd, wenpd, dp, raddd, q3a, radd3, q3b );
	defparam m0.BIT_WIDTH=2*POINTER_WIDTH+2,
		m0.ADD_WIDTH = ADD_SIZE-2, m0.MEM_SIZE = NMAX*MEM_SIZE/4;
	defparam m1.BIT_WIDTH=2*POINTER_WIDTH+2,
		m1.ADD_WIDTH = ADD_SIZE-2, m1.MEM_SIZE = NMAX*MEM_SIZE/4;
	defparam m2.BIT_WIDTH=2*POINTER_WIDTH+2,
		m2.ADD_WIDTH = ADD_SIZE-2, m2.MEM_SIZE = NMAX*MEM_SIZE/4;
	defparam m3.BIT_WIDTH=2*POINTER_WIDTH+2,
		m3.ADD_WIDTH = ADD_SIZE-2, m3.MEM_SIZE = NMAX*MEM_SIZE/4;

	assign bank = wr_add[ADD_SIZE-1:ADD_SIZE-2];
	assign up_bank = wadd2[ADD_SIZE-1:ADD_SIZE-2];
	assign tr_bank = radd1[ADD_SIZE-1:ADD_SIZE-2];
	assign re_bank = radd2[ADD_SIZE-1:ADD_SIZE-2];

	// write address
	assign wadda= ( bank=='b00) ? wr_add[ADD_SIZE-3:0] : wadd2[ADD_SIZE-3:0];
	assign waddb= ( bank=='b01) ? wr_add[ADD_SIZE-3:0] : wadd2[ADD_SIZE-3:0];
	assign waddc= ( bank=='b10) ? wr_add[ADD_SIZE-3:0] : wadd2[ADD_SIZE-3:0];
	assign waddd= ( bank=='b11) ? wr_add[ADD_SIZE-3:0] : wadd2[ADD_SIZE-3:0];

	// write enable
	assign wena= ((bank=='b00) & wen1) | ((up_bank=='b00) & wen2);
	assign wenb= ((bank=='b01) & wen1) | ((up_bank=='b01) & wen2);
	assign wenc= ((bank=='b10) & wen1) | ((up_bank=='b10) & wen2);
	assign wend= ((bank=='b11) & wen1) | ((up_bank=='b11) & wen2);

	// pointer memory will not be written when updating
	assign wenpa= (bank=='b00)  ? wen1 : 0;
	assign wenpb= (bank=='b01)  ? wen1 : 0;
	assign wenpc= (bank=='b10)  ? wen1 : 0;
	assign wenpd= (bank=='b11)  ? wen1 : 0;

	// write data
	assign da= ( bank=='b00) ? data1[DELTA_WIDTH:0] : data2;
	assign db= ( bank=='b01) ? data1[DELTA_WIDTH:0] : data2;
	assign dc= ( bank=='b10) ? data1[DELTA_WIDTH:0] : data2;
	assign dd= ( bank=='b11) ? data1[DELTA_WIDTH:0] : data2;
	assign dp= data1[(DELTA_WIDTH+2*POINTER_WIDTH+3)-1 : (DELTA_WIDTH+1)];

	// read address
	assign radd = radd2[ADD_SIZE-3:0];
	assign radda = (tr_bank=='b00) ? radd1[ADD_SIZE-3:0] : radd2[ADD_SIZE-3:0];
	assign raddb = (tr_bank=='b01) ? radd1[ADD_SIZE-3:0] : radd2[ADD_SIZE-3:0];
	assign raddc = (tr_bank=='b10) ? radd1[ADD_SIZE-3:0] : radd2[ADD_SIZE-3:0];
	assign raddd = (tr_bank=='b11) ? radd1[ADD_SIZE-3:0] : radd2[ADD_SIZE-3:0];

	// read data is one cycle after the address is given
	always @ (posedge clk) begin
		rd1_de<=radd1[ADD_SIZE-1:ADD_SIZE-2];
		rd2_de<=radd2[ADD_SIZE-1:ADD_SIZE-2];
		rd3_de<=radd3[ADD_SIZE-1:ADD_SIZE-2];
	end
	assign q1 = (rd1_de[1]) ?
		(rd1_de[0] ? q3a : q2a) :  (rd1_de[0] ? q1a : q0a);
	assign q2 = (rd2_de[1]) ?
		(rd2_de[0] ? {q3a,delta3} : {q2a,delta2})
			: (rd2_de[0] ? {q1a,delta1} : {q0a,delta0});
	assign q3 = (rd3_de[1]) ? (rd3_de[0] ? q3b : q2b) :  (rd3_de[0] ? q1b : q0b);

endmodule

// megafunction wizard: %ALT3PRAM%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: alt3pram

// ============================================================
// File Name: alt3pram0.v
// Megafunction Name(s):
// 			alt3pram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2003 Altera Corporation
//Any  megafunction  design,  and related netlist (encrypted  or  decrypted),
//support information,  device programming or simulation file,  and any other
//associated  documentation or information  provided by  Altera  or a partner
//under  Altera's   Megafunction   Partnership   Program  may  be  used  only
//to program  PLD  devices (but not masked  PLD  devices) from  Altera.   Any
//other  use  of such  megafunction  design,  netlist,  support  information,
//device programming or simulation file,  or any other  related documentation
//or information  is prohibited  for  any  other purpose,  including, but not
//limited to  modification,  reverse engineering,  de-compiling, or use  with
//any other  silicon devices,  unless such use is  explicitly  licensed under
//a separate agreement with  Altera  or a megafunction partner.  Title to the
//intellectual property,  including patents,  copyrights,  trademarks,  trade
//secrets,  or maskworks,  embodied in any such megafunction design, netlist,
//support  information,  device programming or simulation file,  or any other
//related documentation or information provided by  Altera  or a megafunction
//partner, remains with Altera, the megafunction partner, or their respective
//licensors. No other licenses, including any licenses needed under any third
//party's intellectual property, are provided herein.


module tpram (
	data,
	wraddress,
	rdaddress_a,
	rdaddress_b,
	wren,
	clock,
	qa,
	qb);

	parameter	DATA_WIDTH=8, ADD_WIDTH=6, MEM_SIZE=64;

	input	[DATA_WIDTH-1:0]  data;
	input	[ADD_WIDTH-1:0]  wraddress;
	input	[ADD_WIDTH-1:0]  rdaddress_a;
	input	[ADD_WIDTH-1:0]  rdaddress_b;
	input	  wren,clock;
	output	[DATA_WIDTH-1:0]  qa;
	output	[DATA_WIDTH-1:0]  qb;

	wire [DATA_WIDTH-1:0] sub_wire0;
	wire [DATA_WIDTH-1:0] sub_wire1;
	wire [DATA_WIDTH-1:0] qa = sub_wire0[DATA_WIDTH-1:0];
	wire [DATA_WIDTH-1:0] qb = sub_wire1[DATA_WIDTH-1:0];

	alt3pram	alt3pram_component (
				.wren (wren),
				.inclock (clock),
				.data (data),
				.rdaddress_a (rdaddress_a),
				.wraddress (wraddress),
				.rdaddress_b (rdaddress_b),
				.qa (sub_wire0),
				.qb (sub_wire1));
	defparam
		alt3pram_component.width = DATA_WIDTH,
		alt3pram_component.widthad = ADD_WIDTH,
		alt3pram_component.indata_reg = "INCLOCK",
		alt3pram_component.write_reg = "INCLOCK",
		alt3pram_component.rdaddress_reg_a = "INCLOCK",
		alt3pram_component.rdaddress_reg_b = "INCLOCK",
		alt3pram_component.rdcontrol_reg_a = "UNREGISTERED",
		alt3pram_component.rdcontrol_reg_b = "UNREGISTERED",
		alt3pram_component.outdata_reg_a = "UNREGISTERED",
		alt3pram_component.outdata_reg_b = "UNREGISTERED",
		alt3pram_component.indata_aclr = "OFF",
		alt3pram_component.write_aclr = "OFF",
		alt3pram_component.rdaddress_aclr_a = "OFF",
		alt3pram_component.rdaddress_aclr_b = "OFF",
		alt3pram_component.rdcontrol_aclr_a = "OFF",
		alt3pram_component.rdcontrol_aclr_b = "OFF",
		alt3pram_component.outdata_aclr_a = "OFF",
		alt3pram_component.outdata_aclr_b = "OFF",
		alt3pram_component.lpm_type = "alt3pram",
		alt3pram_component.lpm_hint = "USE_EAB=ON";


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthData NUMERIC "8"
// Retrieval info: PRIVATE: WidthAddr NUMERIC "6"
// Retrieval info: PRIVATE: Clock NUMERIC "3"
// Retrieval info: PRIVATE: rden_a NUMERIC "0"
// Retrieval info: PRIVATE: rden_b NUMERIC "0"
// Retrieval info: PRIVATE: REGdata NUMERIC "1"
// Retrieval info: PRIVATE: REGwrite NUMERIC "1"
// Retrieval info: PRIVATE: REGrdaddress_a NUMERIC "1"
// Retrieval info: PRIVATE: REGrdaddress_b NUMERIC "1"
// Retrieval info: PRIVATE: REGrren_a NUMERIC "1"
// Retrieval info: PRIVATE: REGrren_b NUMERIC "1"
// Retrieval info: PRIVATE: REGqa NUMERIC "1"
// Retrieval info: PRIVATE: REGqb NUMERIC "1"
// Retrieval info: PRIVATE: enable NUMERIC "0"
// Retrieval info: PRIVATE: CLRdata NUMERIC "0"
// Retrieval info: PRIVATE: CLRwrite NUMERIC "0"
// Retrieval info: PRIVATE: CLRrdaddress_a NUMERIC "0"
// Retrieval info: PRIVATE: CLRrdaddress_b NUMERIC "0"
// Retrieval info: PRIVATE: CLRrren_a NUMERIC "0"
// Retrieval info: PRIVATE: CLRrren_b NUMERIC "0"
// Retrieval info: PRIVATE: CLRqa NUMERIC "0"
// Retrieval info: PRIVATE: CLRqb NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
// Retrieval info: PRIVATE: MIFfilename STRING ""
// Retrieval info: PRIVATE: UseLCs NUMERIC "0"
// Retrieval info: CONSTANT: WIDTH NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD NUMERIC "6"
// Retrieval info: CONSTANT: INDATA_REG STRING "UNREGISTERED"
// Retrieval info: CONSTANT: WRITE_REG STRING "UNREGISTERED"
// Retrieval info: CONSTANT: RDADDRESS_REG_A STRING "UNREGISTERED"
// Retrieval info: CONSTANT: RDADDRESS_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: RDCONTROL_REG_A STRING "UNREGISTERED"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: OUTDATA_REG_A STRING "UNREGISTERED"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR STRING "OFF"
// Retrieval info: CONSTANT: WRITE_ACLR STRING "OFF"
// Retrieval info: CONSTANT: RDADDRESS_ACLR_A STRING "OFF"
// Retrieval info: CONSTANT: RDADDRESS_ACLR_B STRING "OFF"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_A STRING "OFF"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "OFF"
// Retrieval info: CONSTANT: OUTDATA_ACLR_A STRING "OFF"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "OFF"
// Retrieval info: CONSTANT: LPM_TYPE STRING "alt3pram"
// Retrieval info: CONSTANT: LPM_HINT STRING "USE_EAB=ON"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: qa 0 0 8 0 OUTPUT NODEFVAL qa[7..0]
// Retrieval info: USED_PORT: qb 0 0 8 0 OUTPUT NODEFVAL qb[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 6 0 INPUT NODEFVAL wraddress[5..0]
// Retrieval info: USED_PORT: rdaddress_a 0 0 6 0 INPUT NODEFVAL rdaddress_a[5..0]
// Retrieval info: USED_PORT: rdaddress_b 0 0 6 0 INPUT NODEFVAL rdaddress_b[5..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: CONNECT: @data 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: qa 0 0 8 0 @qa 0 0 8 0
// Retrieval info: CONNECT: qb 0 0 8 0 @qb 0 0 8 0
// Retrieval info: CONNECT: @wraddress 0 0 6 0 wraddress 0 0 6 0
// Retrieval info: CONNECT: @rdaddress_a 0 0 6 0 rdaddress_a 0 0 6 0
// Retrieval info: CONNECT: @rdaddress_b 0 0 6 0 rdaddress_b 0 0 6 0
// Retrieval info: CONNECT: @wren 0 0 0 0 wren 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

/* Taceback ASOVA Decoder

	In each period, the following will happen:
	1. read in a combo of u,p,Li
	2. write 1 column of trellis
	3. traceback T columns
	4. update D columns of reliability infomation
	5. output 1 Lo

	The delay will be T+D periods. Throughput will be at least T cycles (T>D)

	data port distribution = {sur_p,dis_p,new_dec,metric_diff};

*/

//`define PROBE
`undef PROBE

module TraceBack (clk, reset, u,p, Li, read, lo_en, Lo, done
`ifdef PROBE
	,level,pr0, pr1, pr2, pr3, pr4,pr5,pr6,pr7
`endif
);
	parameter BIT_WIDTH=`NOISE_BITWIDTH,
		WIN_SIZE=`MEM_SIZE,
		Nmax = `N_MAX,
		ADD_SIZE = `MEM_ADDWIDTH+`NMAX_WIDTH,
		POINTER_WIDTH = `NMAX_WIDTH,
		TSIZE = `TRACE_SIZE, DSIZE=`UPDATE_SIZE;

	input clk,reset;
	input [BIT_WIDTH-1:0] u,p,Li;
	output read,lo_en,done;
	output [BIT_WIDTH-1:0] Lo;
`ifdef PROBE
	//output [`MEM_ADDWIDTH+1:0] level;
	output [`CODE_ADD_WIDTH+1:0] level;
	output [ADD_SIZE-1:0] pr0,pr1,pr2,pr3;
	output [(BIT_WIDTH+2*POINTER_WIDTH+3)-1:0] pr4,pr5,pr6,pr7;
`endif
	wire [BIT_WIDTH-1:0] Lo;

/* -------------variables--------- */
	// write row pointer
	wire [POINTER_WIDTH-1:0] wrp;
	// write column pointer, wcp-1
	reg [`MEM_ADDWIDTH-1:0] wcp, wcp_one;
	// traceback row pointer
	wire [POINTER_WIDTH-1:0] tcrp;
	// traceback column pointer
	reg [`MEM_ADDWIDTH-1:0] tccp;
	// update write row pointer
	reg [POINTER_WIDTH-1:0] udrp;
	// update write column pointer
	reg [`MEM_ADDWIDTH-1:0] udcp;
	// update read column pointer
	reg [`MEM_ADDWIDTH-1:0] re_cp;
	// update read row pointer
	wire [POINTER_WIDTH-1:0] re_rp;
	// update read competitive path row pointer
	wire [POINTER_WIDTH-1:0] cmp_rp;

	// new input metric difference
	wire [BIT_WIDTH-1:0] metric_diff;
	wire md_valid;  // metric difference validity
	// new input survivor pointer and discarded path pointer
	wire [POINTER_WIDTH-1:0] sur_p, dis_p;
	wire dis_valid;  // discared path pointer valid
	// new input decision bit;
	wire new_dec;

	// traceback path pointer
	wire [POINTER_WIDTH-1:0] tr_pointer;

	// read delta, updated delta and the metric difference to be compared with all delta
	wire [BIT_WIDTH-1:0] rdel, updel;
	reg  [BIT_WIDTH-1:0] delta;
	wire redel_valid, upmd_valid; // read delta valid, updated delta valid
	// update delta pointer, competitive path pointer
	wire [POINTER_WIDTH-1:0] up_pointer, cmp_pointer;
	reg [ADD_SIZE-1:0] up_start_point;  // update start address, obtained by traceback
	reg cmp_valid; // competitive pointer valid
	// decision bit of competitive path and ML path
	wire cmp_dec, ml_dec;


	/* -------- Control Signals ----------- */
	reg [`CODE_ADD_WIDTH+1:0] level;
	// enable signals for new data write, traceback and delta update
	reg write_en, tr_en, update_en;
	// all of the three procedures are not working
	wire idle;
	reg idle_delay;
	wire idle_pulse; // raising edge of idle;

	// cycle count for each stage
	reg [`MEM_ADDWIDTH+1:0] step;
	// ACS block start and finish
	wire acs_start, acs_finish;

	reg done;



	/*--------- Survivor Memory Interface ----- */
	wire wr_en;
        reg up_write;
	wire [(BIT_WIDTH+2*POINTER_WIDTH+3)-1:0] data1,data2;
	wire [ADD_SIZE-1:0] wr_add,up_wadd,radd1,radd2,radd3;
	wire [(BIT_WIDTH+2*POINTER_WIDTH+3)-1:0] q2;
	wire [(2*POINTER_WIDTH+2)-1:0] q1,q3;

	/* -------- output -----------*/
`ifdef PROBE
	assign pr0 = wr_add;
	assign pr1 = radd1;
	assign pr2 = radd2;
	assign pr3 = radd3;
	assign pr4 = data1;
	assign pr5 = q1;
	assign pr6 = q2;
	assign pr7 = q3;
`endif

	assign read = acs_start;
	assign lo_en = (level>TSIZE+DSIZE+1) & (step==DSIZE);
	assign Lo = {ml_dec,updel[BIT_WIDTH-1:1]};

	always @ (posedge clk)
		if ( ~reset ) done <= 0; else
		if ( level == WIN_SIZE + `CODE_SIZE ) done <= 1;

	/*--------- survivor memory ----------- */
	W2R3MEM sur_mem (clk,reset, data1, wr_add, wr_en, data2, up_wadd, update_en,
				q1, radd1, q2, radd2, q3, radd3);
	assign wr_add = {wcp,wrp};
	assign radd1 = {tccp,tcrp};
	assign up_wadd = {udcp,udrp};
	assign radd2 = {re_cp,re_rp};
	assign radd3 = {re_cp,cmp_rp};

	assign data1 = {sur_p,dis_p,dis_valid,new_dec,md_valid,metric_diff};
	assign data2 = {upmd_valid,updel};

	assign tr_pointer = q1[(2*POINTER_WIDTH+2)-1:(POINTER_WIDTH+2)];

	assign rdel = q2[BIT_WIDTH-1:0];
	assign redel_valid = q2[BIT_WIDTH];
	assign ml_dec = q2[BIT_WIDTH+1];
	assign up_pointer = q2[(BIT_WIDTH+2*POINTER_WIDTH+3)-1:(BIT_WIDTH+POINTER_WIDTH+3)];
	assign cmp_dec = q3[0];
	assign cmp_pointer = q3[(POINTER_WIDTH+2)-1:2];

	// stage start and finish control
	assign idle = ~(write_en | tr_en | update_en);
	always @ (posedge clk) idle_delay <= idle;
	assign idle_pulse = (~idle_delay) & idle;
	always @ (posedge clk)
	if ((reset=='b0) | done) begin
		level=0;
		step<=0;
	end else if ( idle_pulse ) begin
		// stage finish when all 3 procedures finish
		step<=0;
		// make sure that it is only cycle each time
		level<=level+1;
	end else begin // any procedure is still working
		step<=step+1;
	end

	// traceback control
	always @ (posedge clk)
	if ( reset=='b0 | done) begin
		tr_en<=0;
	end else if ( (step==0) & (level>TSIZE+DSIZE) ) begin
		// start
		tr_en<=1;
		tccp<=tccp-1;
	end else if ( step== TSIZE ) begin
		// finish
		tr_en<=0;
		up_start_point <= {tccp,tcrp};
	end else if ( step>TSIZE) begin
		tccp<=wcp_one;  // after wcp increase one, wcp might be updated after traceback finishes
	end else if ( tr_en) begin// working
		tccp<=tccp-1;
	end
	assign tcrp = (step==0) ? 0 : tr_pointer;

	// update control
	//assign update_en = cmp_valid | (q2[BIT_WIDTH+2]& (step==0) & (level>TSIZE+DSIZE));
	always @ (posedge clk)
	if ( (reset=='b0)|done ) begin
		update_en<=0;
		up_write<=0;
	end else if ( (step==1) & (level>TSIZE+DSIZE+1) ) begin
		// setup new delta
		update_en <= q2[BIT_WIDTH+2];
		delta <= rdel;
		re_cp <= re_cp -1;
		up_write <= 1;
	end else if ( step >= DSIZE ) begin
		// finish
		update_en <= 0;
		up_write <=0 ;

		re_cp <= up_start_point[ADD_SIZE-1:POINTER_WIDTH];  // obtain update start column
	end else begin// working
		re_cp <= re_cp -1;
	end
	assign re_rp = (step==0) ? up_start_point[POINTER_WIDTH-1:0] : up_pointer;
	assign cmp_rp = (step==1) ? q2[(POINTER_WIDTH+BIT_WIDTH+3)-1:(BIT_WIDTH+3)] : cmp_pointer;

	NEW_DELTA update_delta ( delta, rdel, redel_valid, ml_dec, cmp_dec, updel);
	assign upmd_valid=1; // the updated delta must be valid if writing

	// write new data.
	// Sub module generate row address and finish signal
	SEQ_ACS acs0 (clk,reset,u,p,Li, acs_start,
		wrp, new_dec,metric_diff, md_valid,
		sur_p, dis_p, dis_valid, acs_finish, wr_en
//		, pr0,pr1,pr2,pr3,pr4
		);
	assign acs_start = (step==0) & (level<`CODE_SIZE) & (~done);
	always @ (posedge clk)
	if ((reset=='b0)|done)  begin // reset
		write_en <= 0;
		wcp <= 0;  // +1 before starting
	end else if ( (step==0) & (level<`CODE_SIZE) ) begin // start
		write_en <= 1;
	end else if (acs_finish) begin // finish
		wcp_one = wcp;
		wcp <= wcp + 1;  // start from 0
		write_en <= 0;
	end

endmodule




// obtain the updated delta
module NEW_DELTA ( me_diff, old_delta, old_delta_valid, ua, ub, new_delta);
parameter BIT_WIDTH=`NOISE_BITWIDTH;
input [BIT_WIDTH-1:0] me_diff, old_delta;
input old_delta_valid;
input ua, ub;
output [BIT_WIDTH-1:0] new_delta;


	assign new_delta = ( ((ua^ub) & (me_diff<old_delta)) | (~old_delta_valid) ) ?
		me_diff : new_delta;

endmodule

/*
   The Turbo Decoder System using SRAM port to communicate with Nios
	That is the version to work with Nios Standard_32
	The SRAM has two banks.
	The reading from these two banks are controlled by the highest bit of the read_address

	Each bank has 4 memory blocks for u,p,q and o respectively.
	Block u has two read ports because it needs to provide both u and iu.
	Address: Block u and p use in_add, and block iu and q use in_iadd.
	Block o is the decoded bits. Its write port is 1-bit wide and read port is 8-bit wide for Nios.
*/
//`define PROBE
module turboSram ( clk,reset, up_in, iuq_in, in_add, in_iadd,
	decoded, out_add, out_en,
	pingpang,bank,all_done
`ifdef PROBE
	,probe1, probe2,probe3
`endif
	);
	parameter CHANNEL_WIDTH=`NOISE_BITWIDTH, ADD_WIDTH=`CODE_ADD_WIDTH;
	input clk,reset;
    input [2*CHANNEL_WIDTH-1:0] up_in, iuq_in;
	output [ADD_WIDTH:0] in_add, in_iadd;
    output decoded;
	output [9:0] out_add;
	output out_en;
	output pingpang;
`ifdef PROBE
	output [CHANNEL_WIDTH-1:0] probe1;
	wire [CHANNEL_WIDTH-1:0] probe1;
	output [`CODE_ADD_WIDTH+1:0] probe2, probe3;
	wire [`CODE_ADD_WIDTH+1:0] probe2, probe3;
`endif
	output bank;
	output [3:0] all_done;
	reg [3:0] all_done;

	wire reset,lreset;
	wire done1, done2;
	wire [CHANNEL_WIDTH-1:0] u,p,q;
	wire [CHANNEL_WIDTH-1:0] ub;   /* interleaved u */
	wire d1en,d2en;
	wire d1out,d2out;

	wire [CHANNEL_WIDTH-1:0] Li12, Lo12, Li21, Lo21;
	wire decided_bit;

	reg [ADD_WIDTH-1:0] radd, iradd;
	reg [9:0] wadd;
	reg bank;
	reg ppd; //pingpang delay
	reg outenr; //out_en delay

	// sram addresses
	assign in_add[ADD_WIDTH-1:0]=radd;
	assign in_iadd[ADD_WIDTH-1:0]=iradd;
	assign in_add[ADD_WIDTH] = bank;
	assign in_iadd[ADD_WIDTH] = bank;

	assign out_add = wadd;
//	assign out_add[ADD_WIDTH] = bank;

	always @ (posedge clk) outenr<=out_en;

	always @ (posedge clk)
		if ( lreset == 1'b0 ) begin
			radd<=0; iradd<=0;
		end else begin
			if (d1en) radd<=radd+1;
			if (d2en) iradd<=iradd+1;
		end
	always @ (posedge clk)
		if ( lreset == 1'b0 ) wadd<=0;
		else  begin
			//if (wadd == `CODE_SIZE) wadd<=0;
			if ( out_en&!outenr ) wadd<=wadd+1;
		end

	always @ (posedge clk)
		if ( reset == 1'b0 ) begin bank<=0;
		end else begin
			ppd <= pingpang;
			if ( ~ppd & pingpang ) begin
				bank<=~bank;  // flap when postedge of pingpang
			end
		end

	always @ (posedge clk)
	if (~reset) all_done<=1;
	else if ( ~ppd & pingpang ) all_done<=all_done+1;

	// SRAM data port
	assign u = up_in[2*CHANNEL_WIDTH-1:CHANNEL_WIDTH];
	assign ub = iuq_in[2*CHANNEL_WIDTH-1:CHANNEL_WIDTH];
	assign p = up_in[CHANNEL_WIDTH-1:0];
	assign q = iuq_in[CHANNEL_WIDTH-1:0];


	/* two turbo decoders
	  when d1en, read u,p,Li12
	  when d1out, write Lo21
    */
//	ASOVA d1 (clk,reset, u,p, Li21, d1en, d1out, Lo12, done1);
//	ASOVA d2 (clk,reset, ub,q, Li12, d2en, d2out, Lo21,done2);
	TraceBack d1 (clk,lreset, u,p, Li21, d1en, d1out, Lo12, done1);
	TraceBack d2 (clk,lreset, ub,q, Li12, d2en, d2out, Lo21, done2);


	/* interleaver and deinterleaver between d1 and d2 */
	InterBuffer inter12 ( clk, reset, d1out, Lo12, d2en, Li12, pingpang );
		defparam inter12.BIT_WIDTH=`NOISE_BITWIDTH,
			inter12.ADD_WIDTH=`CODE_ADD_WIDTH;

	DeInterBuffer inter21 ( clk, reset, d2out, Lo21, d1en, Li21, pingpang );
		defparam inter21.BIT_WIDTH=`NOISE_BITWIDTH,
			inter21.ADD_WIDTH=`CODE_ADD_WIDTH;
	//assign Li12=Lo12;
	//assign Li21=Lo21;

	Decider decider1 ( clk,reset, d1en, d1out, Lo12, Li21, out_en,decided_bit);
	assign decoded = decided_bit;


	/* decide when to switch pingpang */
	assign pingpang = done1 & done2;
	//greset is global reset, use "reset" to clear Decoder buffer for every iteration
	assign lreset = reset & ~pingpang;

`ifdef PROBE
	assign probe1[0]=done1;
	assign probe1[1]=done2;
always @(posedge clk)
	if ( out_add==24 & out_en) begin
	//probe2[0]=1;
	 //probe3[0]=out_en;
	 //probe3[1]=decoded;
	end
`endif
endmodule

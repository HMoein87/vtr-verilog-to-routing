

/*
 *
 * RAW Benchmark Suite main defines
 *
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */

`define GlobalDataWidth 32	    /* Global data bus width    */
`define GlobalAddrWidth 15	    /* Global address bus width */
				    /* Global data bus high impedance */
`define GlobalDataHighZ 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz

/*
 * $Header: /projects/raw/cvsroot/benchmark/suites/bheap/src/library.v,v 1.4 1997/08/09 05:56:52 jbabb Exp $
 *
 * Library for Binary Heap Benchmark
 *
 * Authors: Elliot Waingold         (elliotw@lcs.mit.edu)
 *          Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */



/*
 * BHeap_Node is the basic three-way compare node (fully combinational)
 */

module BHeap_Node(Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		  Enable, P_WR, P_In, P_Out,
		  L_WR, L_In, L_Out, R_WR, R_In, R_Out);

   parameter			 WIDTH=8;


   /* global connections */

   input			 Clk, Reset, RD, WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;


   /* local connections */

   input			 Enable;
   output			 P_WR;
   input [WIDTH-1:0]		 P_In;
   output [WIDTH-1:0]		 P_Out;
   output			 L_WR;
   input [WIDTH-1:0]		 L_In;
   output [WIDTH-1:0]		 L_Out;
   output			 R_WR;
   input [WIDTH-1:0]		 R_In;
   output [WIDTH-1:0]		 R_Out;

   assign L_WR = (Enable && (L_In > P_In) && (L_In >= R_In));
   assign R_WR = (Enable && (R_In > P_In) && (R_In > L_In));
   assign P_WR = (L_WR || R_WR);

   assign P_Out = L_WR ? L_In : (R_WR ? R_In : `GlobalDataHighZ);
   assign L_Out = L_WR ? P_In : `GlobalDataHighZ;
   assign R_Out = R_WR ? P_In : `GlobalDataHighZ;

endmodule

/*
 * BHeap_Reg is a register with two inputs and two enables
 */

module BHeap_Reg(Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		 ScanIn, ScanOut, ScanEnable,
		 Id, Out, Enable1, Enable2, In1, In2);

   parameter			 WIDTH=8,
	     IDWIDTH=8,
	     SCAN=1;


   /* global connections */

   input			 Clk, Reset, RD, WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;


   /* global connections for scan path (scan = 1) */

   input [WIDTH-1:0]		 ScanIn;
   output [WIDTH-1:0]		 ScanOut;
   input			 ScanEnable;


   /* local connections */

   input [IDWIDTH-1:0]		 Id;
   output [WIDTH-1:0]		 Out;
   reg [WIDTH-1:0]		 Out;
   input			 Enable1;
   input			 Enable2;
   input [WIDTH-1:0]		 In1;
   input [WIDTH-1:0]		 In2;


   /* support reading of the node data value (non-scan only) */

   assign 	DataOut[`GlobalDataWidth-1:0] =
      (!SCAN && Addr[IDWIDTH-1:0] == Id) ? Out : `GlobalDataHighZ;


   /* support scan out of the node data value */

   assign ScanOut = SCAN ? Out: 0;

   always @(posedge Clk)
      begin


	 /* reset will initialize the entire array to zero */

	 if (Reset)
	    Out = 0;


	 /* support scan in */

	 else if  (SCAN && ScanEnable)
	    Out = ScanIn[WIDTH-1:0];


	 /* support writing of the node data value (non-scan only) */

	 else if (!SCAN && WR && (Addr[IDWIDTH-1:0] == Id))
	    Out = DataIn[WIDTH-1:0];


	 /* heap operation */

	 else if (Enable1)
	    Out = In1;
	 else if (Enable2)
	    Out = In2;
      end
endmodule


/*
 * BHeap_CtrlReg is a one-bit register used in shifting control from
 * level to level
 */

module BHeap_CtrlReg(Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		     In, Out, Enable);

   parameter			 WIDTH=8;


   /* global connections */

   input			 Clk, Reset, RD, WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;


   /* local connections */

   input			 In;
   output			 Out;
   reg				 Out;
   output			 Enable;

   assign Enable = Out;

   always @(posedge Clk)
      begin
	 if (Reset)
	    Out = 0;
	 else
	    Out = In;
      end
endmodule


/*
 * BHeap_Control is the controller node
 */

module BHeap_Control(Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		     ScanIn, ScanOut, ScanEnable, ScanId,
		     Id, Go, Done);

   parameter			 CWIDTH=8,
				 IDWIDTH=8,
				 WIDTH=8,
				 SCAN=1;


   /* global connections */

   input			 Clk, Reset, RD, WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;


   /* global connections for scan path (scan = 1) */

   input [WIDTH-1:0]		 ScanIn;
   output [WIDTH-1:0]		 ScanOut;
   output			 ScanEnable;
   input [IDWIDTH-1:0]		 ScanId;


   /* local connections */

   input [IDWIDTH-1:0]		 Id;
   output			 Go;
   reg				 Go;
   input			 Done;


   /* a register for the counter and scan */

   reg [CWIDTH-1:0]		 Count;
   reg [WIDTH-1:0]		 ScanReg;


   /* support writing scan input */

   assign ScanEnable=(SCAN && (RD || WR) && Addr[IDWIDTH-1:0]==ScanId);
   assign ScanOut= WR ? DataIn[WIDTH-1:0]: 0;


   /* support reading of the counter and scan output */

   assign DataOut[`GlobalDataWidth-1:0] =
      (Addr[IDWIDTH-1:0] == Id) ? Count :
         (ScanEnable && RD) ? ScanReg: `GlobalDataHighZ;

   always @(posedge Clk)
      begin
	 ScanReg = ScanIn;

	 Go = 0;
	 if (Reset)
	    begin
	       Count = 0;
	    end
	 else if (WR && (Addr[IDWIDTH-1:0] == Id))
	    begin
	       Count = DataIn[CWIDTH-1:0];
	       if (Count)
		  Go = 1;
	    end
	 else if (Done)
	    begin
	       Count = Count-1;
	       if (Count)
		  Go = 1;
	    end
      end
endmodule

/*
 *
 * RAW Benchmark Suite main module header
 *
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


module main (
             Clk,
             Reset,
             RD,
             WR,
             Addr,
             DataIn,
             DataOut
            );

/* global connections */
input  Clk,Reset,RD,WR;
input  [`GlobalAddrWidth-1:0] Addr;
input  [`GlobalDataWidth-1:0] DataIn;
output [`GlobalDataWidth-1:0] DataOut;

wire [0:0] wCtrlOut_0;
wire [0:0] wEnable_0;
wire [31:0] wRegInBot_0_0;
wire [0:0] wRegEnBot_0_0;
wire [31:0] wRegOut_0_0;
wire [0:0] wCtrlOut_1;
wire [0:0] wEnable_1;
wire [31:0] wRegInTop_1_0;
wire [0:0] wRegEnTop_1_0;
wire [31:0] wRegInBot_1_0;
wire [0:0] wRegEnBot_1_0;
wire [31:0] wRegOut_1_0;
wire [31:0] wRegInTop_1_1;
wire [0:0] wRegEnTop_1_1;
wire [31:0] wRegInBot_1_1;
wire [0:0] wRegEnBot_1_1;
wire [31:0] wRegOut_1_1;
wire [0:0] wCtrlOut_2;
wire [0:0] wEnable_2;
wire [31:0] wRegInTop_2_0;
wire [0:0] wRegEnTop_2_0;
wire [31:0] wRegInBot_2_0;
wire [0:0] wRegEnBot_2_0;
wire [31:0] wRegOut_2_0;
wire [31:0] wRegInTop_2_1;
wire [0:0] wRegEnTop_2_1;
wire [31:0] wRegInBot_2_1;
wire [0:0] wRegEnBot_2_1;
wire [31:0] wRegOut_2_1;
wire [31:0] wRegInTop_2_2;
wire [0:0] wRegEnTop_2_2;
wire [31:0] wRegInBot_2_2;
wire [0:0] wRegEnBot_2_2;
wire [31:0] wRegOut_2_2;
wire [31:0] wRegInTop_2_3;
wire [0:0] wRegEnTop_2_3;
wire [31:0] wRegInBot_2_3;
wire [0:0] wRegEnBot_2_3;
wire [31:0] wRegOut_2_3;
wire [0:0] wCtrlOut_3;
wire [0:0] wEnable_3;
wire [31:0] wRegInTop_3_0;
wire [0:0] wRegEnTop_3_0;
wire [31:0] wRegInBot_3_0;
wire [0:0] wRegEnBot_3_0;
wire [31:0] wRegOut_3_0;
wire [31:0] wRegInTop_3_1;
wire [0:0] wRegEnTop_3_1;
wire [31:0] wRegInBot_3_1;
wire [0:0] wRegEnBot_3_1;
wire [31:0] wRegOut_3_1;
wire [31:0] wRegInTop_3_2;
wire [0:0] wRegEnTop_3_2;
wire [31:0] wRegInBot_3_2;
wire [0:0] wRegEnBot_3_2;
wire [31:0] wRegOut_3_2;
wire [31:0] wRegInTop_3_3;
wire [0:0] wRegEnTop_3_3;
wire [31:0] wRegInBot_3_3;
wire [0:0] wRegEnBot_3_3;
wire [31:0] wRegOut_3_3;
wire [31:0] wRegInTop_3_4;
wire [0:0] wRegEnTop_3_4;
wire [31:0] wRegInBot_3_4;
wire [0:0] wRegEnBot_3_4;
wire [31:0] wRegOut_3_4;
wire [31:0] wRegInTop_3_5;
wire [0:0] wRegEnTop_3_5;
wire [31:0] wRegInBot_3_5;
wire [0:0] wRegEnBot_3_5;
wire [31:0] wRegOut_3_5;
wire [31:0] wRegInTop_3_6;
wire [0:0] wRegEnTop_3_6;
wire [31:0] wRegInBot_3_6;
wire [0:0] wRegEnBot_3_6;
wire [31:0] wRegOut_3_6;
wire [31:0] wRegInTop_3_7;
wire [0:0] wRegEnTop_3_7;
wire [31:0] wRegInBot_3_7;
wire [0:0] wRegEnBot_3_7;
wire [31:0] wRegOut_3_7;
wire [0:0] wCtrlOut_4;
wire [0:0] wEnable_4;
wire [31:0] wRegInTop_4_0;
wire [0:0] wRegEnTop_4_0;
wire [31:0] wRegInBot_4_0;
wire [0:0] wRegEnBot_4_0;
wire [31:0] wRegOut_4_0;
wire [31:0] wRegInTop_4_1;
wire [0:0] wRegEnTop_4_1;
wire [31:0] wRegInBot_4_1;
wire [0:0] wRegEnBot_4_1;
wire [31:0] wRegOut_4_1;
wire [31:0] wRegInTop_4_2;
wire [0:0] wRegEnTop_4_2;
wire [31:0] wRegInBot_4_2;
wire [0:0] wRegEnBot_4_2;
wire [31:0] wRegOut_4_2;
wire [31:0] wRegInTop_4_3;
wire [0:0] wRegEnTop_4_3;
wire [31:0] wRegInBot_4_3;
wire [0:0] wRegEnBot_4_3;
wire [31:0] wRegOut_4_3;
wire [31:0] wRegInTop_4_4;
wire [0:0] wRegEnTop_4_4;
wire [31:0] wRegInBot_4_4;
wire [0:0] wRegEnBot_4_4;
wire [31:0] wRegOut_4_4;
wire [31:0] wRegInTop_4_5;
wire [0:0] wRegEnTop_4_5;
wire [31:0] wRegInBot_4_5;
wire [0:0] wRegEnBot_4_5;
wire [31:0] wRegOut_4_5;
wire [31:0] wRegInTop_4_6;
wire [0:0] wRegEnTop_4_6;
wire [31:0] wRegInBot_4_6;
wire [0:0] wRegEnBot_4_6;
wire [31:0] wRegOut_4_6;
wire [31:0] wRegInTop_4_7;
wire [0:0] wRegEnTop_4_7;
wire [31:0] wRegInBot_4_7;
wire [0:0] wRegEnBot_4_7;
wire [31:0] wRegOut_4_7;
wire [31:0] wRegInTop_4_8;
wire [0:0] wRegEnTop_4_8;
wire [31:0] wRegInBot_4_8;
wire [0:0] wRegEnBot_4_8;
wire [31:0] wRegOut_4_8;
wire [31:0] wRegInTop_4_9;
wire [0:0] wRegEnTop_4_9;
wire [31:0] wRegInBot_4_9;
wire [0:0] wRegEnBot_4_9;
wire [31:0] wRegOut_4_9;
wire [31:0] wRegInTop_4_10;
wire [0:0] wRegEnTop_4_10;
wire [31:0] wRegInBot_4_10;
wire [0:0] wRegEnBot_4_10;
wire [31:0] wRegOut_4_10;
wire [31:0] wRegInTop_4_11;
wire [0:0] wRegEnTop_4_11;
wire [31:0] wRegInBot_4_11;
wire [0:0] wRegEnBot_4_11;
wire [31:0] wRegOut_4_11;
wire [31:0] wRegInTop_4_12;
wire [0:0] wRegEnTop_4_12;
wire [31:0] wRegInBot_4_12;
wire [0:0] wRegEnBot_4_12;
wire [31:0] wRegOut_4_12;
wire [31:0] wRegInTop_4_13;
wire [0:0] wRegEnTop_4_13;
wire [31:0] wRegInBot_4_13;
wire [0:0] wRegEnBot_4_13;
wire [31:0] wRegOut_4_13;
wire [31:0] wRegInTop_4_14;
wire [0:0] wRegEnTop_4_14;
wire [31:0] wRegInBot_4_14;
wire [0:0] wRegEnBot_4_14;
wire [31:0] wRegOut_4_14;
wire [31:0] wRegInTop_4_15;
wire [0:0] wRegEnTop_4_15;
wire [31:0] wRegInBot_4_15;
wire [0:0] wRegEnBot_4_15;
wire [31:0] wRegOut_4_15;
wire [0:0] wCtrlOut_5;
wire [0:0] wEnable_5;
wire [31:0] wRegInTop_5_0;
wire [0:0] wRegEnTop_5_0;
wire [31:0] wRegOut_5_0;
wire [31:0] wRegInTop_5_1;
wire [0:0] wRegEnTop_5_1;
wire [31:0] wRegOut_5_1;
wire [31:0] wRegInTop_5_2;
wire [0:0] wRegEnTop_5_2;
wire [31:0] wRegOut_5_2;
wire [31:0] wRegInTop_5_3;
wire [0:0] wRegEnTop_5_3;
wire [31:0] wRegOut_5_3;
wire [31:0] wRegInTop_5_4;
wire [0:0] wRegEnTop_5_4;
wire [31:0] wRegOut_5_4;
wire [31:0] wRegInTop_5_5;
wire [0:0] wRegEnTop_5_5;
wire [31:0] wRegOut_5_5;
wire [31:0] wRegInTop_5_6;
wire [0:0] wRegEnTop_5_6;
wire [31:0] wRegOut_5_6;
wire [31:0] wRegInTop_5_7;
wire [0:0] wRegEnTop_5_7;
wire [31:0] wRegOut_5_7;
wire [31:0] wRegInTop_5_8;
wire [0:0] wRegEnTop_5_8;
wire [31:0] wRegOut_5_8;
wire [31:0] wRegInTop_5_9;
wire [0:0] wRegEnTop_5_9;
wire [31:0] wRegOut_5_9;
wire [31:0] wRegInTop_5_10;
wire [0:0] wRegEnTop_5_10;
wire [31:0] wRegOut_5_10;
wire [31:0] wRegInTop_5_11;
wire [0:0] wRegEnTop_5_11;
wire [31:0] wRegOut_5_11;
wire [31:0] wRegInTop_5_12;
wire [0:0] wRegEnTop_5_12;
wire [31:0] wRegOut_5_12;
wire [31:0] wRegInTop_5_13;
wire [0:0] wRegEnTop_5_13;
wire [31:0] wRegOut_5_13;
wire [31:0] wRegInTop_5_14;
wire [0:0] wRegEnTop_5_14;
wire [31:0] wRegOut_5_14;
wire [31:0] wRegInTop_5_15;
wire [0:0] wRegEnTop_5_15;
wire [31:0] wRegOut_5_15;
wire [31:0] wRegInTop_5_16;
wire [0:0] wRegEnTop_5_16;
wire [31:0] wRegOut_5_16;
wire [31:0] wRegInTop_5_17;
wire [0:0] wRegEnTop_5_17;
wire [31:0] wRegOut_5_17;
wire [31:0] wRegInTop_5_18;
wire [0:0] wRegEnTop_5_18;
wire [31:0] wRegOut_5_18;
wire [31:0] wRegInTop_5_19;
wire [0:0] wRegEnTop_5_19;
wire [31:0] wRegOut_5_19;
wire [31:0] wRegInTop_5_20;
wire [0:0] wRegEnTop_5_20;
wire [31:0] wRegOut_5_20;
wire [31:0] wRegInTop_5_21;
wire [0:0] wRegEnTop_5_21;
wire [31:0] wRegOut_5_21;
wire [31:0] wRegInTop_5_22;
wire [0:0] wRegEnTop_5_22;
wire [31:0] wRegOut_5_22;
wire [31:0] wRegInTop_5_23;
wire [0:0] wRegEnTop_5_23;
wire [31:0] wRegOut_5_23;
wire [31:0] wRegInTop_5_24;
wire [0:0] wRegEnTop_5_24;
wire [31:0] wRegOut_5_24;
wire [31:0] wRegInTop_5_25;
wire [0:0] wRegEnTop_5_25;
wire [31:0] wRegOut_5_25;
wire [31:0] wRegInTop_5_26;
wire [0:0] wRegEnTop_5_26;
wire [31:0] wRegOut_5_26;
wire [31:0] wRegInTop_5_27;
wire [0:0] wRegEnTop_5_27;
wire [31:0] wRegOut_5_27;
wire [31:0] wRegInTop_5_28;
wire [0:0] wRegEnTop_5_28;
wire [31:0] wRegOut_5_28;
wire [31:0] wRegInTop_5_29;
wire [0:0] wRegEnTop_5_29;
wire [31:0] wRegOut_5_29;
wire [31:0] wRegInTop_5_30;
wire [0:0] wRegEnTop_5_30;
wire [31:0] wRegOut_5_30;
wire [31:0] wRegInTop_5_31;
wire [0:0] wRegEnTop_5_31;
wire [31:0] wRegOut_5_31;
wire [0:0] ScanEnable;
wire [31:0] ScanLink0;
wire [31:0] ScanLink1;
wire [31:0] ScanLink2;
wire [31:0] ScanLink3;
wire [31:0] ScanLink4;
wire [31:0] ScanLink5;
wire [31:0] ScanLink6;
wire [31:0] ScanLink7;
wire [31:0] ScanLink8;
wire [31:0] ScanLink9;
wire [31:0] ScanLink10;
wire [31:0] ScanLink11;
wire [31:0] ScanLink12;
wire [31:0] ScanLink13;
wire [31:0] ScanLink14;
wire [31:0] ScanLink15;
wire [31:0] ScanLink16;
wire [31:0] ScanLink17;
wire [31:0] ScanLink18;
wire [31:0] ScanLink19;
wire [31:0] ScanLink20;
wire [31:0] ScanLink21;
wire [31:0] ScanLink22;
wire [31:0] ScanLink23;
wire [31:0] ScanLink24;
wire [31:0] ScanLink25;
wire [31:0] ScanLink26;
wire [31:0] ScanLink27;
wire [31:0] ScanLink28;
wire [31:0] ScanLink29;
wire [31:0] ScanLink30;
wire [31:0] ScanLink31;
wire [31:0] ScanLink32;
wire [31:0] ScanLink33;
wire [31:0] ScanLink34;
wire [31:0] ScanLink35;
wire [31:0] ScanLink36;
wire [31:0] ScanLink37;
wire [31:0] ScanLink38;
wire [31:0] ScanLink39;
wire [31:0] ScanLink40;
wire [31:0] ScanLink41;
wire [31:0] ScanLink42;
wire [31:0] ScanLink43;
wire [31:0] ScanLink44;
wire [31:0] ScanLink45;
wire [31:0] ScanLink46;
wire [31:0] ScanLink47;
wire [31:0] ScanLink48;
wire [31:0] ScanLink49;
wire [31:0] ScanLink50;
wire [31:0] ScanLink51;
wire [31:0] ScanLink52;
wire [31:0] ScanLink53;
wire [31:0] ScanLink54;
wire [31:0] ScanLink55;
wire [31:0] ScanLink56;
wire [31:0] ScanLink57;
wire [31:0] ScanLink58;
wire [31:0] ScanLink59;
wire [31:0] ScanLink60;
wire [31:0] ScanLink61;
wire [31:0] ScanLink62;
wire [31:0] ScanLink63;
BHeap_Reg #( 32, 1, 1 ) BHR_0_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_0_0), .Enable1(1'b0), .In1(32'b0), .Enable2(wRegEnBot_0_0), .In2(wRegInBot_0_0), .ScanIn(ScanLink1), .ScanOut(ScanLink0), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_1_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_1_0), .Enable1(wRegEnTop_1_0), .In1(wRegInTop_1_0), .Enable2(wRegEnBot_1_0), .In2(wRegInBot_1_0), .ScanIn(ScanLink2), .ScanOut(ScanLink1), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_1_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_1_1), .Enable1(wRegEnTop_1_1), .In1(wRegInTop_1_1), .Enable2(wRegEnBot_1_1), .In2(wRegInBot_1_1), .ScanIn(ScanLink3), .ScanOut(ScanLink2), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_0), .Enable1(wRegEnTop_2_0), .In1(wRegInTop_2_0), .Enable2(wRegEnBot_2_0), .In2(wRegInBot_2_0), .ScanIn(ScanLink4), .ScanOut(ScanLink3), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_1), .Enable1(wRegEnTop_2_1), .In1(wRegInTop_2_1), .Enable2(wRegEnBot_2_1), .In2(wRegInBot_2_1), .ScanIn(ScanLink5), .ScanOut(ScanLink4), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_2), .Enable1(wRegEnTop_2_2), .In1(wRegInTop_2_2), .Enable2(wRegEnBot_2_2), .In2(wRegInBot_2_2), .ScanIn(ScanLink6), .ScanOut(ScanLink5), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_3), .Enable1(wRegEnTop_2_3), .In1(wRegInTop_2_3), .Enable2(wRegEnBot_2_3), .In2(wRegInBot_2_3), .ScanIn(ScanLink7), .ScanOut(ScanLink6), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_0), .Enable1(wRegEnTop_3_0), .In1(wRegInTop_3_0), .Enable2(wRegEnBot_3_0), .In2(wRegInBot_3_0), .ScanIn(ScanLink8), .ScanOut(ScanLink7), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_1), .Enable1(wRegEnTop_3_1), .In1(wRegInTop_3_1), .Enable2(wRegEnBot_3_1), .In2(wRegInBot_3_1), .ScanIn(ScanLink9), .ScanOut(ScanLink8), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_2), .Enable1(wRegEnTop_3_2), .In1(wRegInTop_3_2), .Enable2(wRegEnBot_3_2), .In2(wRegInBot_3_2), .ScanIn(ScanLink10), .ScanOut(ScanLink9), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_3), .Enable1(wRegEnTop_3_3), .In1(wRegInTop_3_3), .Enable2(wRegEnBot_3_3), .In2(wRegInBot_3_3), .ScanIn(ScanLink11), .ScanOut(ScanLink10), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_4), .Enable1(wRegEnTop_3_4), .In1(wRegInTop_3_4), .Enable2(wRegEnBot_3_4), .In2(wRegInBot_3_4), .ScanIn(ScanLink12), .ScanOut(ScanLink11), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_5), .Enable1(wRegEnTop_3_5), .In1(wRegInTop_3_5), .Enable2(wRegEnBot_3_5), .In2(wRegInBot_3_5), .ScanIn(ScanLink13), .ScanOut(ScanLink12), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_6), .Enable1(wRegEnTop_3_6), .In1(wRegInTop_3_6), .Enable2(wRegEnBot_3_6), .In2(wRegInBot_3_6), .ScanIn(ScanLink14), .ScanOut(ScanLink13), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_7), .Enable1(wRegEnTop_3_7), .In1(wRegInTop_3_7), .Enable2(wRegEnBot_3_7), .In2(wRegInBot_3_7), .ScanIn(ScanLink15), .ScanOut(ScanLink14), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_0), .Enable1(wRegEnTop_4_0), .In1(wRegInTop_4_0), .Enable2(wRegEnBot_4_0), .In2(wRegInBot_4_0), .ScanIn(ScanLink16), .ScanOut(ScanLink15), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_1), .Enable1(wRegEnTop_4_1), .In1(wRegInTop_4_1), .Enable2(wRegEnBot_4_1), .In2(wRegInBot_4_1), .ScanIn(ScanLink17), .ScanOut(ScanLink16), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_2), .Enable1(wRegEnTop_4_2), .In1(wRegInTop_4_2), .Enable2(wRegEnBot_4_2), .In2(wRegInBot_4_2), .ScanIn(ScanLink18), .ScanOut(ScanLink17), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_3), .Enable1(wRegEnTop_4_3), .In1(wRegInTop_4_3), .Enable2(wRegEnBot_4_3), .In2(wRegInBot_4_3), .ScanIn(ScanLink19), .ScanOut(ScanLink18), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_4), .Enable1(wRegEnTop_4_4), .In1(wRegInTop_4_4), .Enable2(wRegEnBot_4_4), .In2(wRegInBot_4_4), .ScanIn(ScanLink20), .ScanOut(ScanLink19), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_5), .Enable1(wRegEnTop_4_5), .In1(wRegInTop_4_5), .Enable2(wRegEnBot_4_5), .In2(wRegInBot_4_5), .ScanIn(ScanLink21), .ScanOut(ScanLink20), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_6), .Enable1(wRegEnTop_4_6), .In1(wRegInTop_4_6), .Enable2(wRegEnBot_4_6), .In2(wRegInBot_4_6), .ScanIn(ScanLink22), .ScanOut(ScanLink21), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_7), .Enable1(wRegEnTop_4_7), .In1(wRegInTop_4_7), .Enable2(wRegEnBot_4_7), .In2(wRegInBot_4_7), .ScanIn(ScanLink23), .ScanOut(ScanLink22), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_8), .Enable1(wRegEnTop_4_8), .In1(wRegInTop_4_8), .Enable2(wRegEnBot_4_8), .In2(wRegInBot_4_8), .ScanIn(ScanLink24), .ScanOut(ScanLink23), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_9), .Enable1(wRegEnTop_4_9), .In1(wRegInTop_4_9), .Enable2(wRegEnBot_4_9), .In2(wRegInBot_4_9), .ScanIn(ScanLink25), .ScanOut(ScanLink24), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_10), .Enable1(wRegEnTop_4_10), .In1(wRegInTop_4_10), .Enable2(wRegEnBot_4_10), .In2(wRegInBot_4_10), .ScanIn(ScanLink26), .ScanOut(ScanLink25), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_11), .Enable1(wRegEnTop_4_11), .In1(wRegInTop_4_11), .Enable2(wRegEnBot_4_11), .In2(wRegInBot_4_11), .ScanIn(ScanLink27), .ScanOut(ScanLink26), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_12), .Enable1(wRegEnTop_4_12), .In1(wRegInTop_4_12), .Enable2(wRegEnBot_4_12), .In2(wRegInBot_4_12), .ScanIn(ScanLink28), .ScanOut(ScanLink27), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_13), .Enable1(wRegEnTop_4_13), .In1(wRegInTop_4_13), .Enable2(wRegEnBot_4_13), .In2(wRegInBot_4_13), .ScanIn(ScanLink29), .ScanOut(ScanLink28), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_14), .Enable1(wRegEnTop_4_14), .In1(wRegInTop_4_14), .Enable2(wRegEnBot_4_14), .In2(wRegInBot_4_14), .ScanIn(ScanLink30), .ScanOut(ScanLink29), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_4_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_4_15), .Enable1(wRegEnTop_4_15), .In1(wRegInTop_4_15), .Enable2(wRegEnBot_4_15), .In2(wRegInBot_4_15), .ScanIn(ScanLink31), .ScanOut(ScanLink30), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_0), .Enable1(wRegEnTop_5_0), .In1(wRegInTop_5_0), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink32), .ScanOut(ScanLink31), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_1), .Enable1(wRegEnTop_5_1), .In1(wRegInTop_5_1), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink33), .ScanOut(ScanLink32), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_2), .Enable1(wRegEnTop_5_2), .In1(wRegInTop_5_2), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink34), .ScanOut(ScanLink33), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_3), .Enable1(wRegEnTop_5_3), .In1(wRegInTop_5_3), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink35), .ScanOut(ScanLink34), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_4), .Enable1(wRegEnTop_5_4), .In1(wRegInTop_5_4), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink36), .ScanOut(ScanLink35), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_5), .Enable1(wRegEnTop_5_5), .In1(wRegInTop_5_5), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink37), .ScanOut(ScanLink36), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_6), .Enable1(wRegEnTop_5_6), .In1(wRegInTop_5_6), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink38), .ScanOut(ScanLink37), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_7), .Enable1(wRegEnTop_5_7), .In1(wRegInTop_5_7), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink39), .ScanOut(ScanLink38), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_8), .Enable1(wRegEnTop_5_8), .In1(wRegInTop_5_8), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink40), .ScanOut(ScanLink39), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_9), .Enable1(wRegEnTop_5_9), .In1(wRegInTop_5_9), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink41), .ScanOut(ScanLink40), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_10), .Enable1(wRegEnTop_5_10), .In1(wRegInTop_5_10), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink42), .ScanOut(ScanLink41), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_11), .Enable1(wRegEnTop_5_11), .In1(wRegInTop_5_11), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink43), .ScanOut(ScanLink42), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_12), .Enable1(wRegEnTop_5_12), .In1(wRegInTop_5_12), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink44), .ScanOut(ScanLink43), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_13), .Enable1(wRegEnTop_5_13), .In1(wRegInTop_5_13), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink45), .ScanOut(ScanLink44), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_14), .Enable1(wRegEnTop_5_14), .In1(wRegInTop_5_14), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink46), .ScanOut(ScanLink45), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_15), .Enable1(wRegEnTop_5_15), .In1(wRegInTop_5_15), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink47), .ScanOut(ScanLink46), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_16 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_16), .Enable1(wRegEnTop_5_16), .In1(wRegInTop_5_16), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink48), .ScanOut(ScanLink47), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_17 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_17), .Enable1(wRegEnTop_5_17), .In1(wRegInTop_5_17), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink49), .ScanOut(ScanLink48), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_18 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_18), .Enable1(wRegEnTop_5_18), .In1(wRegInTop_5_18), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink50), .ScanOut(ScanLink49), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_19 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_19), .Enable1(wRegEnTop_5_19), .In1(wRegInTop_5_19), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink51), .ScanOut(ScanLink50), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_20 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_20), .Enable1(wRegEnTop_5_20), .In1(wRegInTop_5_20), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink52), .ScanOut(ScanLink51), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_21 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_21), .Enable1(wRegEnTop_5_21), .In1(wRegInTop_5_21), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink53), .ScanOut(ScanLink52), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_22 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_22), .Enable1(wRegEnTop_5_22), .In1(wRegInTop_5_22), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink54), .ScanOut(ScanLink53), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_23 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_23), .Enable1(wRegEnTop_5_23), .In1(wRegInTop_5_23), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink55), .ScanOut(ScanLink54), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_24 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_24), .Enable1(wRegEnTop_5_24), .In1(wRegInTop_5_24), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink56), .ScanOut(ScanLink55), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_25 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_25), .Enable1(wRegEnTop_5_25), .In1(wRegInTop_5_25), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink57), .ScanOut(ScanLink56), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_26 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_26), .Enable1(wRegEnTop_5_26), .In1(wRegInTop_5_26), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink58), .ScanOut(ScanLink57), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_27 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_27), .Enable1(wRegEnTop_5_27), .In1(wRegInTop_5_27), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink59), .ScanOut(ScanLink58), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_28 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_28), .Enable1(wRegEnTop_5_28), .In1(wRegInTop_5_28), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink60), .ScanOut(ScanLink59), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_29 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_29), .Enable1(wRegEnTop_5_29), .In1(wRegInTop_5_29), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink61), .ScanOut(ScanLink60), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_30 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_30), .Enable1(wRegEnTop_5_30), .In1(wRegInTop_5_30), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink62), .ScanOut(ScanLink61), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_5_31 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_5_31), .Enable1(wRegEnTop_5_31), .In1(wRegInTop_5_31), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink63), .ScanOut(ScanLink62), .ScanEnable(ScanEnable) );
BHeap_Node #( 32 ) BHN_0_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_0), .P_WR(wRegEnBot_0_0), .P_In(wRegOut_0_0), .P_Out(wRegInBot_0_0), .L_WR(wRegEnTop_1_0), .L_In(wRegOut_1_0), .L_Out(wRegInTop_1_0), .R_WR(wRegEnTop_1_1), .R_In(wRegOut_1_1), .R_Out(wRegInTop_1_1) );
BHeap_Node #( 32 ) BHN_1_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_1), .P_WR(wRegEnBot_1_0), .P_In(wRegOut_1_0), .P_Out(wRegInBot_1_0), .L_WR(wRegEnTop_2_0), .L_In(wRegOut_2_0), .L_Out(wRegInTop_2_0), .R_WR(wRegEnTop_2_1), .R_In(wRegOut_2_1), .R_Out(wRegInTop_2_1) );
BHeap_Node #( 32 ) BHN_1_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_1), .P_WR(wRegEnBot_1_1), .P_In(wRegOut_1_1), .P_Out(wRegInBot_1_1), .L_WR(wRegEnTop_2_2), .L_In(wRegOut_2_2), .L_Out(wRegInTop_2_2), .R_WR(wRegEnTop_2_3), .R_In(wRegOut_2_3), .R_Out(wRegInTop_2_3) );
BHeap_Node #( 32 ) BHN_2_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_0), .P_In(wRegOut_2_0), .P_Out(wRegInBot_2_0), .L_WR(wRegEnTop_3_0), .L_In(wRegOut_3_0), .L_Out(wRegInTop_3_0), .R_WR(wRegEnTop_3_1), .R_In(wRegOut_3_1), .R_Out(wRegInTop_3_1) );
BHeap_Node #( 32 ) BHN_2_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_1), .P_In(wRegOut_2_1), .P_Out(wRegInBot_2_1), .L_WR(wRegEnTop_3_2), .L_In(wRegOut_3_2), .L_Out(wRegInTop_3_2), .R_WR(wRegEnTop_3_3), .R_In(wRegOut_3_3), .R_Out(wRegInTop_3_3) );
BHeap_Node #( 32 ) BHN_2_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_2), .P_In(wRegOut_2_2), .P_Out(wRegInBot_2_2), .L_WR(wRegEnTop_3_4), .L_In(wRegOut_3_4), .L_Out(wRegInTop_3_4), .R_WR(wRegEnTop_3_5), .R_In(wRegOut_3_5), .R_Out(wRegInTop_3_5) );
BHeap_Node #( 32 ) BHN_2_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_3), .P_In(wRegOut_2_3), .P_Out(wRegInBot_2_3), .L_WR(wRegEnTop_3_6), .L_In(wRegOut_3_6), .L_Out(wRegInTop_3_6), .R_WR(wRegEnTop_3_7), .R_In(wRegOut_3_7), .R_Out(wRegInTop_3_7) );
BHeap_Node #( 32 ) BHN_3_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_0), .P_In(wRegOut_3_0), .P_Out(wRegInBot_3_0), .L_WR(wRegEnTop_4_0), .L_In(wRegOut_4_0), .L_Out(wRegInTop_4_0), .R_WR(wRegEnTop_4_1), .R_In(wRegOut_4_1), .R_Out(wRegInTop_4_1) );
BHeap_Node #( 32 ) BHN_3_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_1), .P_In(wRegOut_3_1), .P_Out(wRegInBot_3_1), .L_WR(wRegEnTop_4_2), .L_In(wRegOut_4_2), .L_Out(wRegInTop_4_2), .R_WR(wRegEnTop_4_3), .R_In(wRegOut_4_3), .R_Out(wRegInTop_4_3) );
BHeap_Node #( 32 ) BHN_3_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_2), .P_In(wRegOut_3_2), .P_Out(wRegInBot_3_2), .L_WR(wRegEnTop_4_4), .L_In(wRegOut_4_4), .L_Out(wRegInTop_4_4), .R_WR(wRegEnTop_4_5), .R_In(wRegOut_4_5), .R_Out(wRegInTop_4_5) );
BHeap_Node #( 32 ) BHN_3_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_3), .P_In(wRegOut_3_3), .P_Out(wRegInBot_3_3), .L_WR(wRegEnTop_4_6), .L_In(wRegOut_4_6), .L_Out(wRegInTop_4_6), .R_WR(wRegEnTop_4_7), .R_In(wRegOut_4_7), .R_Out(wRegInTop_4_7) );
BHeap_Node #( 32 ) BHN_3_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_4), .P_In(wRegOut_3_4), .P_Out(wRegInBot_3_4), .L_WR(wRegEnTop_4_8), .L_In(wRegOut_4_8), .L_Out(wRegInTop_4_8), .R_WR(wRegEnTop_4_9), .R_In(wRegOut_4_9), .R_Out(wRegInTop_4_9) );
BHeap_Node #( 32 ) BHN_3_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_5), .P_In(wRegOut_3_5), .P_Out(wRegInBot_3_5), .L_WR(wRegEnTop_4_10), .L_In(wRegOut_4_10), .L_Out(wRegInTop_4_10), .R_WR(wRegEnTop_4_11), .R_In(wRegOut_4_11), .R_Out(wRegInTop_4_11) );
BHeap_Node #( 32 ) BHN_3_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_6), .P_In(wRegOut_3_6), .P_Out(wRegInBot_3_6), .L_WR(wRegEnTop_4_12), .L_In(wRegOut_4_12), .L_Out(wRegInTop_4_12), .R_WR(wRegEnTop_4_13), .R_In(wRegOut_4_13), .R_Out(wRegInTop_4_13) );
BHeap_Node #( 32 ) BHN_3_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_3), .P_WR(wRegEnBot_3_7), .P_In(wRegOut_3_7), .P_Out(wRegInBot_3_7), .L_WR(wRegEnTop_4_14), .L_In(wRegOut_4_14), .L_Out(wRegInTop_4_14), .R_WR(wRegEnTop_4_15), .R_In(wRegOut_4_15), .R_Out(wRegInTop_4_15) );
BHeap_Node #( 32 ) BHN_4_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_0), .P_In(wRegOut_4_0), .P_Out(wRegInBot_4_0), .L_WR(wRegEnTop_5_0), .L_In(wRegOut_5_0), .L_Out(wRegInTop_5_0), .R_WR(wRegEnTop_5_1), .R_In(wRegOut_5_1), .R_Out(wRegInTop_5_1) );
BHeap_Node #( 32 ) BHN_4_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_1), .P_In(wRegOut_4_1), .P_Out(wRegInBot_4_1), .L_WR(wRegEnTop_5_2), .L_In(wRegOut_5_2), .L_Out(wRegInTop_5_2), .R_WR(wRegEnTop_5_3), .R_In(wRegOut_5_3), .R_Out(wRegInTop_5_3) );
BHeap_Node #( 32 ) BHN_4_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_2), .P_In(wRegOut_4_2), .P_Out(wRegInBot_4_2), .L_WR(wRegEnTop_5_4), .L_In(wRegOut_5_4), .L_Out(wRegInTop_5_4), .R_WR(wRegEnTop_5_5), .R_In(wRegOut_5_5), .R_Out(wRegInTop_5_5) );
BHeap_Node #( 32 ) BHN_4_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_3), .P_In(wRegOut_4_3), .P_Out(wRegInBot_4_3), .L_WR(wRegEnTop_5_6), .L_In(wRegOut_5_6), .L_Out(wRegInTop_5_6), .R_WR(wRegEnTop_5_7), .R_In(wRegOut_5_7), .R_Out(wRegInTop_5_7) );
BHeap_Node #( 32 ) BHN_4_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_4), .P_In(wRegOut_4_4), .P_Out(wRegInBot_4_4), .L_WR(wRegEnTop_5_8), .L_In(wRegOut_5_8), .L_Out(wRegInTop_5_8), .R_WR(wRegEnTop_5_9), .R_In(wRegOut_5_9), .R_Out(wRegInTop_5_9) );
BHeap_Node #( 32 ) BHN_4_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_5), .P_In(wRegOut_4_5), .P_Out(wRegInBot_4_5), .L_WR(wRegEnTop_5_10), .L_In(wRegOut_5_10), .L_Out(wRegInTop_5_10), .R_WR(wRegEnTop_5_11), .R_In(wRegOut_5_11), .R_Out(wRegInTop_5_11) );
BHeap_Node #( 32 ) BHN_4_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_6), .P_In(wRegOut_4_6), .P_Out(wRegInBot_4_6), .L_WR(wRegEnTop_5_12), .L_In(wRegOut_5_12), .L_Out(wRegInTop_5_12), .R_WR(wRegEnTop_5_13), .R_In(wRegOut_5_13), .R_Out(wRegInTop_5_13) );
BHeap_Node #( 32 ) BHN_4_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_7), .P_In(wRegOut_4_7), .P_Out(wRegInBot_4_7), .L_WR(wRegEnTop_5_14), .L_In(wRegOut_5_14), .L_Out(wRegInTop_5_14), .R_WR(wRegEnTop_5_15), .R_In(wRegOut_5_15), .R_Out(wRegInTop_5_15) );
BHeap_Node #( 32 ) BHN_4_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_8), .P_In(wRegOut_4_8), .P_Out(wRegInBot_4_8), .L_WR(wRegEnTop_5_16), .L_In(wRegOut_5_16), .L_Out(wRegInTop_5_16), .R_WR(wRegEnTop_5_17), .R_In(wRegOut_5_17), .R_Out(wRegInTop_5_17) );
BHeap_Node #( 32 ) BHN_4_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_9), .P_In(wRegOut_4_9), .P_Out(wRegInBot_4_9), .L_WR(wRegEnTop_5_18), .L_In(wRegOut_5_18), .L_Out(wRegInTop_5_18), .R_WR(wRegEnTop_5_19), .R_In(wRegOut_5_19), .R_Out(wRegInTop_5_19) );
BHeap_Node #( 32 ) BHN_4_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_10), .P_In(wRegOut_4_10), .P_Out(wRegInBot_4_10), .L_WR(wRegEnTop_5_20), .L_In(wRegOut_5_20), .L_Out(wRegInTop_5_20), .R_WR(wRegEnTop_5_21), .R_In(wRegOut_5_21), .R_Out(wRegInTop_5_21) );
BHeap_Node #( 32 ) BHN_4_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_11), .P_In(wRegOut_4_11), .P_Out(wRegInBot_4_11), .L_WR(wRegEnTop_5_22), .L_In(wRegOut_5_22), .L_Out(wRegInTop_5_22), .R_WR(wRegEnTop_5_23), .R_In(wRegOut_5_23), .R_Out(wRegInTop_5_23) );
BHeap_Node #( 32 ) BHN_4_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_12), .P_In(wRegOut_4_12), .P_Out(wRegInBot_4_12), .L_WR(wRegEnTop_5_24), .L_In(wRegOut_5_24), .L_Out(wRegInTop_5_24), .R_WR(wRegEnTop_5_25), .R_In(wRegOut_5_25), .R_Out(wRegInTop_5_25) );
BHeap_Node #( 32 ) BHN_4_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_13), .P_In(wRegOut_4_13), .P_Out(wRegInBot_4_13), .L_WR(wRegEnTop_5_26), .L_In(wRegOut_5_26), .L_Out(wRegInTop_5_26), .R_WR(wRegEnTop_5_27), .R_In(wRegOut_5_27), .R_Out(wRegInTop_5_27) );
BHeap_Node #( 32 ) BHN_4_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_14), .P_In(wRegOut_4_14), .P_Out(wRegInBot_4_14), .L_WR(wRegEnTop_5_28), .L_In(wRegOut_5_28), .L_Out(wRegInTop_5_28), .R_WR(wRegEnTop_5_29), .R_In(wRegOut_5_29), .R_Out(wRegInTop_5_29) );
BHeap_Node #( 32 ) BHN_4_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_4), .P_WR(wRegEnBot_4_15), .P_In(wRegOut_4_15), .P_Out(wRegInBot_4_15), .L_WR(wRegEnTop_5_30), .L_In(wRegOut_5_30), .L_Out(wRegInTop_5_30), .R_WR(wRegEnTop_5_31), .R_In(wRegOut_5_31), .R_Out(wRegInTop_5_31) );
BHeap_CtrlReg #( 32 ) BHCR_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_1), .Out(wCtrlOut_0), .Enable(wEnable_0) );
BHeap_CtrlReg #( 32 ) BHCR_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_2), .Out(wCtrlOut_1), .Enable(wEnable_1) );
BHeap_CtrlReg #( 32 ) BHCR_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_3), .Out(wCtrlOut_2), .Enable(wEnable_2) );
BHeap_CtrlReg #( 32 ) BHCR_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_4), .Out(wCtrlOut_3), .Enable(wEnable_3) );
BHeap_CtrlReg #( 32 ) BHCR_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_5), .Out(wCtrlOut_4), .Enable(wEnable_4) );
BHeap_Control #( 3, 1, 32, 1 ) BHC ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd1), .Go(wCtrlOut_5), .Done(wCtrlOut_0), .ScanIn(ScanLink0), .ScanOut(ScanLink63), .ScanEnable(ScanEnable), .ScanId(1'd0) );

/*
 *
 * RAW Benchmark Suite main module trailer
 *
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


endmodule



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
wire [31:0] wRegOut_3_0;
wire [31:0] wRegInTop_3_1;
wire [0:0] wRegEnTop_3_1;
wire [31:0] wRegOut_3_1;
wire [31:0] wRegInTop_3_2;
wire [0:0] wRegEnTop_3_2;
wire [31:0] wRegOut_3_2;
wire [31:0] wRegInTop_3_3;
wire [0:0] wRegEnTop_3_3;
wire [31:0] wRegOut_3_3;
wire [31:0] wRegInTop_3_4;
wire [0:0] wRegEnTop_3_4;
wire [31:0] wRegOut_3_4;
wire [31:0] wRegInTop_3_5;
wire [0:0] wRegEnTop_3_5;
wire [31:0] wRegOut_3_5;
wire [31:0] wRegInTop_3_6;
wire [0:0] wRegEnTop_3_6;
wire [31:0] wRegOut_3_6;
wire [31:0] wRegInTop_3_7;
wire [0:0] wRegEnTop_3_7;
wire [31:0] wRegOut_3_7;
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
BHeap_Reg #( 32, 1, 1 ) BHR_0_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_0_0), .Enable1(1'b0), .In1(32'b0), .Enable2(wRegEnBot_0_0), .In2(wRegInBot_0_0), .ScanIn(ScanLink1), .ScanOut(ScanLink0), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_1_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_1_0), .Enable1(wRegEnTop_1_0), .In1(wRegInTop_1_0), .Enable2(wRegEnBot_1_0), .In2(wRegInBot_1_0), .ScanIn(ScanLink2), .ScanOut(ScanLink1), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_1_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_1_1), .Enable1(wRegEnTop_1_1), .In1(wRegInTop_1_1), .Enable2(wRegEnBot_1_1), .In2(wRegInBot_1_1), .ScanIn(ScanLink3), .ScanOut(ScanLink2), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_0), .Enable1(wRegEnTop_2_0), .In1(wRegInTop_2_0), .Enable2(wRegEnBot_2_0), .In2(wRegInBot_2_0), .ScanIn(ScanLink4), .ScanOut(ScanLink3), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_1), .Enable1(wRegEnTop_2_1), .In1(wRegInTop_2_1), .Enable2(wRegEnBot_2_1), .In2(wRegInBot_2_1), .ScanIn(ScanLink5), .ScanOut(ScanLink4), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_2), .Enable1(wRegEnTop_2_2), .In1(wRegInTop_2_2), .Enable2(wRegEnBot_2_2), .In2(wRegInBot_2_2), .ScanIn(ScanLink6), .ScanOut(ScanLink5), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_2_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_2_3), .Enable1(wRegEnTop_2_3), .In1(wRegInTop_2_3), .Enable2(wRegEnBot_2_3), .In2(wRegInBot_2_3), .ScanIn(ScanLink7), .ScanOut(ScanLink6), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_0), .Enable1(wRegEnTop_3_0), .In1(wRegInTop_3_0), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink8), .ScanOut(ScanLink7), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_1), .Enable1(wRegEnTop_3_1), .In1(wRegInTop_3_1), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink9), .ScanOut(ScanLink8), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_2), .Enable1(wRegEnTop_3_2), .In1(wRegInTop_3_2), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink10), .ScanOut(ScanLink9), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_3), .Enable1(wRegEnTop_3_3), .In1(wRegInTop_3_3), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink11), .ScanOut(ScanLink10), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_4), .Enable1(wRegEnTop_3_4), .In1(wRegInTop_3_4), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink12), .ScanOut(ScanLink11), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_5), .Enable1(wRegEnTop_3_5), .In1(wRegInTop_3_5), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink13), .ScanOut(ScanLink12), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_6), .Enable1(wRegEnTop_3_6), .In1(wRegInTop_3_6), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink14), .ScanOut(ScanLink13), .ScanEnable(ScanEnable) );
BHeap_Reg #( 32, 1, 1 ) BHR_3_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(wRegOut_3_7), .Enable1(wRegEnTop_3_7), .In1(wRegInTop_3_7), .Enable2(1'b0), .In2(32'b0), .ScanIn(ScanLink15), .ScanOut(ScanLink14), .ScanEnable(ScanEnable) );
BHeap_Node #( 32 ) BHN_0_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_0), .P_WR(wRegEnBot_0_0), .P_In(wRegOut_0_0), .P_Out(wRegInBot_0_0), .L_WR(wRegEnTop_1_0), .L_In(wRegOut_1_0), .L_Out(wRegInTop_1_0), .R_WR(wRegEnTop_1_1), .R_In(wRegOut_1_1), .R_Out(wRegInTop_1_1) );
BHeap_Node #( 32 ) BHN_1_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_1), .P_WR(wRegEnBot_1_0), .P_In(wRegOut_1_0), .P_Out(wRegInBot_1_0), .L_WR(wRegEnTop_2_0), .L_In(wRegOut_2_0), .L_Out(wRegInTop_2_0), .R_WR(wRegEnTop_2_1), .R_In(wRegOut_2_1), .R_Out(wRegInTop_2_1) );
BHeap_Node #( 32 ) BHN_1_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_1), .P_WR(wRegEnBot_1_1), .P_In(wRegOut_1_1), .P_Out(wRegInBot_1_1), .L_WR(wRegEnTop_2_2), .L_In(wRegOut_2_2), .L_Out(wRegInTop_2_2), .R_WR(wRegEnTop_2_3), .R_In(wRegOut_2_3), .R_Out(wRegInTop_2_3) );
BHeap_Node #( 32 ) BHN_2_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_0), .P_In(wRegOut_2_0), .P_Out(wRegInBot_2_0), .L_WR(wRegEnTop_3_0), .L_In(wRegOut_3_0), .L_Out(wRegInTop_3_0), .R_WR(wRegEnTop_3_1), .R_In(wRegOut_3_1), .R_Out(wRegInTop_3_1) );
BHeap_Node #( 32 ) BHN_2_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_1), .P_In(wRegOut_2_1), .P_Out(wRegInBot_2_1), .L_WR(wRegEnTop_3_2), .L_In(wRegOut_3_2), .L_Out(wRegInTop_3_2), .R_WR(wRegEnTop_3_3), .R_In(wRegOut_3_3), .R_Out(wRegInTop_3_3) );
BHeap_Node #( 32 ) BHN_2_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_2), .P_In(wRegOut_2_2), .P_Out(wRegInBot_2_2), .L_WR(wRegEnTop_3_4), .L_In(wRegOut_3_4), .L_Out(wRegInTop_3_4), .R_WR(wRegEnTop_3_5), .R_In(wRegOut_3_5), .R_Out(wRegInTop_3_5) );
BHeap_Node #( 32 ) BHN_2_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Enable(wEnable_2), .P_WR(wRegEnBot_2_3), .P_In(wRegOut_2_3), .P_Out(wRegInBot_2_3), .L_WR(wRegEnTop_3_6), .L_In(wRegOut_3_6), .L_Out(wRegInTop_3_6), .R_WR(wRegEnTop_3_7), .R_In(wRegOut_3_7), .R_Out(wRegInTop_3_7) );
BHeap_CtrlReg #( 32 ) BHCR_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_1), .Out(wCtrlOut_0), .Enable(wEnable_0) );
BHeap_CtrlReg #( 32 ) BHCR_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_2), .Out(wCtrlOut_1), .Enable(wEnable_1) );
BHeap_CtrlReg #( 32 ) BHCR_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .In(wCtrlOut_3), .Out(wCtrlOut_2), .Enable(wEnable_2) );
BHeap_Control #( 3, 1, 32, 1 ) BHC ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd1), .Go(wCtrlOut_3), .Done(wCtrlOut_0), .ScanIn(ScanLink0), .ScanOut(ScanLink15), .ScanEnable(ScanEnable), .ScanId(1'd0) );

/*
 *
 * RAW Benchmark Suite main module trailer
 *
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


endmodule

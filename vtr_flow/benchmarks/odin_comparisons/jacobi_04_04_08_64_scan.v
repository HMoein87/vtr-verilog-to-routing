

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
 * $Header: /projects/raw/cvsroot/benchmark/suites/jacobi/src/library.v,v 1.5 1997/08/09 05:57:41 jbabb Exp $
 *
 * Library for Jacobi benchmark
 *
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */



/*
 * This is the behavioral verilog library for this benchmark.
 * By convention, all module names start with the benchmark name.
 * All top-level modules must have the global connections:
 *   Clk, Reset, RD, WR, Addr, DataIn, DataOut
 * Modules may also have any number of local connections or
 * sub-modules without restriction.
 *
 */


/* The basic array node */

module Jacobi_Node (Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		    ScanIn, ScanOut, ScanEnable,
		    Id, Enable, NorthIn, SouthIn, EastIn, WestIn, Out);
   
   parameter WIDTH    = 8,
	     IDWIDTH  = 8,
	     BOUNDARY = 0,
	     SCAN     = 1;
   
   
   /* global connections */
   
   input			 Clk,Reset,RD,WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;


   /* global connections for scan path (scan = 1) */

   input [WIDTH-1:0]		 ScanIn;
   output [WIDTH-1:0]		 ScanOut;
   input			 ScanEnable;   


   /* local connections */
   
   input			 Enable;
   input [IDWIDTH-1:0]		 Id;
   input [WIDTH-1:0]		 NorthIn,SouthIn,EastIn,WestIn;
   output [WIDTH-1:0]		 Out;
   
   reg [WIDTH-1:0]		 Out;
   
   
   /* support reading of the node data value (non-scan only) */
   
   assign DataOut[`GlobalDataWidth-1:0] =
      (!SCAN && Addr[IDWIDTH-1:0] == Id) ? Out: `GlobalDataHighZ;


   /* support scan out of the node data value */

   assign ScanOut = SCAN ? Out: 0;

   
   always @(posedge Clk)
      begin	

	 
	 /* reset will initialize the entire array to zero */
	 
	 if (Reset)
	    Out=0;	 


	 /* support scan in */

	 else if (SCAN && ScanEnable)
	    Out=ScanIn[WIDTH-1:0];
	 

	 /* support writing of the node data value (non-scan only) */
	 
	 else if (!SCAN && WR && (Addr[IDWIDTH-1:0]==Id))
	    Out=DataIn[WIDTH-1:0];
	 

	 /* for non-boundary nodes, do the Jacobi computation when enabled */
	 
	 else if (!BOUNDARY && Enable)
	    Out=(NorthIn+SouthIn+EastIn+WestIn) >> 2;

      end
endmodule


/* 
 * A control module to count iterations.
 *
 * Writing to Address==ID will set a counter.
 *
 * The other Jacobi nodes will be enabled by this module when 
 * count is greater than zero.
 *
 * The counter will decrement every cycle down to zero.
 *
 * This module also handles scan control.
 */

module Jacobi_Control (Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		       ScanIn, ScanOut, ScanEnable,
		       Id,ScanId,Enable);
   
   parameter WIDTH   = 8,
	     CWIDTH  = 8,
	     IDWIDTH = 8,
	     SCAN    = 1;
   
   
   /* global connections */
   
   input			 Clk,Reset,RD,WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;


   /* global connections for scan path (scan = 1) */

   input [IDWIDTH-1:0]		 ScanId;
   input [WIDTH-1:0]		 ScanIn;
   output [WIDTH-1:0]		 ScanOut;
   output			 ScanEnable;   


   /* local connections */
   
   input [IDWIDTH-1:0]		 Id;
   output			 Enable;
   
   
   /* a register for the counter and scan */

   reg [CWIDTH-1:0]		 count;
   reg [WIDTH-1:0]		 ScanReg;

   
   /* support writing scan input */

   assign ScanEnable=(SCAN && (RD || WR) && Addr[IDWIDTH-1:0]==ScanId);
   assign ScanOut= WR ? DataIn[WIDTH-1:0]: 0;


   /* support reading of the counter and scan output */

   assign DataOut[`GlobalDataWidth-1:0] =
      (Addr[IDWIDTH-1:0] == Id) ? count:
      (ScanEnable && RD) ? ScanReg: `GlobalDataHighZ;
   
   
   /* enable when count is active */
   
   assign Enable = !(count==0);

   
   always @(posedge Clk)
      begin

	 
	 /* store current scan output */

	 ScanReg=ScanIn;


	 /* Logic to reset, write, and decrement the counter */
	 
	 if (Reset)
	    count=0;
	 else if (WR && (Addr[IDWIDTH-1:0]==Id))
	    count=DataIn[CWIDTH-1:0];
	 else if(count) 
	    count=count-1;
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

wire [7:0] nOut0_0;
wire [7:0] nScanOut0;
wire [7:0] nOut0_1;
wire [7:0] nScanOut1;
wire [7:0] nOut0_2;
wire [7:0] nScanOut2;
wire [7:0] nOut0_3;
wire [7:0] nScanOut3;
wire [7:0] nOut1_0;
wire [7:0] nScanOut4;
wire [7:0] nOut1_1;
wire [7:0] nScanOut5;
wire [7:0] nOut1_2;
wire [7:0] nScanOut6;
wire [7:0] nOut1_3;
wire [7:0] nScanOut7;
wire [7:0] nOut2_0;
wire [7:0] nScanOut8;
wire [7:0] nOut2_1;
wire [7:0] nScanOut9;
wire [7:0] nOut2_2;
wire [7:0] nScanOut10;
wire [7:0] nOut2_3;
wire [7:0] nScanOut11;
wire [7:0] nOut3_0;
wire [7:0] nScanOut12;
wire [7:0] nOut3_1;
wire [7:0] nScanOut13;
wire [7:0] nOut3_2;
wire [7:0] nScanOut14;
wire [7:0] nOut3_3;
wire [7:0] nScanOut15;
wire [0:0] nEnable;
wire [0:0] nScanEnable;
wire [7:0] nScanOut16;
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut0_0), .ScanIn(nScanOut1), .ScanOut(nScanOut0), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut0_1), .ScanIn(nScanOut2), .ScanOut(nScanOut1), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut0_2), .ScanIn(nScanOut3), .ScanOut(nScanOut2), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut0_3), .ScanIn(nScanOut4), .ScanOut(nScanOut3), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut1_0), .ScanIn(nScanOut5), .ScanOut(nScanOut4), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 0, 1 ) U_Jacobi_Node_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .Out(nOut1_1), .NorthIn(nOut1_0), .SouthIn(nOut1_2), .EastIn(nOut2_1), .WestIn(nOut0_1), .ScanIn(nScanOut6), .ScanOut(nScanOut5), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 0, 1 ) U_Jacobi_Node_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .Out(nOut1_2), .NorthIn(nOut1_1), .SouthIn(nOut1_3), .EastIn(nOut2_2), .WestIn(nOut0_2), .ScanIn(nScanOut7), .ScanOut(nScanOut6), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut1_3), .ScanIn(nScanOut8), .ScanOut(nScanOut7), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut2_0), .ScanIn(nScanOut9), .ScanOut(nScanOut8), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 0, 1 ) U_Jacobi_Node_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .Out(nOut2_1), .NorthIn(nOut2_0), .SouthIn(nOut2_2), .EastIn(nOut3_1), .WestIn(nOut1_1), .ScanIn(nScanOut10), .ScanOut(nScanOut9), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 0, 1 ) U_Jacobi_Node_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .Out(nOut2_2), .NorthIn(nOut2_1), .SouthIn(nOut2_3), .EastIn(nOut3_2), .WestIn(nOut1_2), .ScanIn(nScanOut11), .ScanOut(nScanOut10), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut2_3), .ScanIn(nScanOut12), .ScanOut(nScanOut11), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut3_0), .ScanIn(nScanOut13), .ScanOut(nScanOut12), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut3_1), .ScanIn(nScanOut14), .ScanOut(nScanOut13), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut3_2), .ScanIn(nScanOut15), .ScanOut(nScanOut14), .ScanEnable(nScanEnable) );
Jacobi_Node #( 8, 1, 1, 1 ) U_Jacobi_Node_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Out(nOut3_3), .ScanIn(nScanOut16), .ScanOut(nScanOut15), .ScanEnable(nScanEnable) );
Jacobi_Control #( 8, 7, 1, 1 ) U_Jacobi_Control ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd1), .Enable(nEnable), .ScanId(1'd0), .ScanEnable(nScanEnable), .ScanIn(nScanOut0), .ScanOut(nScanOut16) );

/*
 *
 * RAW Benchmark Suite main module trailer
 * 
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


endmodule

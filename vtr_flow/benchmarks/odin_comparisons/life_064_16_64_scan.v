

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
 * $Header: /projects/raw/cvsroot/benchmark/suites/life/src/library.v,v 1.5 1997/08/09 21:04:55 jbabb Exp $
 *
 * Library for Life benchmark
 *
 * Authors: Rajeev Kumar Barua      (barua@lcs.mit.edu)
 *          Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


/*
  This is the behavioral verilog library for this benchmark. By
  convention, all module names start with the benchmark name.
  All top-level modules must have the global connections:
    Clk, Reset, RD, WR, Addr, DataIn, DataOut
  Modules may also have any number of local connections or
  sub-modules without restriction.
*/

// Defines one cell of the game of life program.

module CELL ( DATA_IN, cell_value, Reset, WR, Enable,
                Clk, NEIGHBORS);

   // add a dummy parameter to keep template logic from breaking */
   parameter DUMMY=0;

   input       DATA_IN;         // for loading in initial data
   output      cell_value;      // current cell contents
   input       Reset;
   input       WR;              // load cell with DATA_IN data
   input       Enable;          // modify cell based on neighbor cells
   input       Clk;

   input [7:0] NEIGHBORS;       // 8 neighboring values, clockwise from North=0

   reg	       cell_value;      // Current value of cell

   reg [32:0]     i, count;


   always @(posedge Clk)
      begin
	 // Reset will initialize the entire array to zero
	 if (Reset)
	    begin
	       cell_value=0;
	    end

	 // Condition to write to node
	 else if (WR)
	    begin
	       cell_value = DATA_IN;
	    end
	 // Condition to do the work
	 else if (Enable) begin
	    count = 0;
	    for (i=0; i < 8; i = i + 1) begin
	       count = count + NEIGHBORS[i];
	    end
	    if (cell_value) begin
	       if ((count != 2) & (count != 3))
		  cell_value = 1'b0;
	    end
	    else
	       if (count == 3)
		  begin
		     cell_value = 1'b1;
		  end
	 end
      end
endmodule


/* defines a block GlobalDataWidth bits by 1 bit,
 * corresp. to one word in host program */

module Life_Block ( Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		   ScanIn, ScanOut, ScanEnable,
		   Id, Enable, BLOCK_VALUE,
		   NORTH_EDGE, SOUTH_EDGE, EAST_EDGE, WEST_EDGE,
		   NW_EDGE, SW_EDGE, NE_EDGE, SE_EDGE);

   parameter IDWIDTH  = 8,
	     SCAN   = 1;


   /* global connections */

   input			 Clk;
   input			 Reset;

   input			 RD, WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;


   /* global connections for scan path (scan = 1) */

   input [`GlobalDataWidth-1:0]	 ScanIn;
   output [`GlobalDataWidth-1:0] ScanOut;
   input			 ScanEnable;



   /* local connections */

   input [IDWIDTH-1:0]     Id;          // This block's id number
   input		     Enable;     // modify cells based on neighbor values
   output [`GlobalDataWidth-1:0] BLOCK_VALUE; // Current value of all cells
   input [`GlobalDataWidth-1:0]  NORTH_EDGE;
   input [`GlobalDataWidth-1:0]  SOUTH_EDGE;
   input		     EAST_EDGE;
   input		     WEST_EDGE;
   input		     NW_EDGE;
   input		     SW_EDGE;
   input		     NE_EDGE;
   input		     SE_EDGE;


   // Neighbor names to make wiring easier :
   // 8 neighboring values, clockwise from North=n0

   wire [`GlobalDataWidth-1:0]    n0;
   wire [`GlobalDataWidth-1:0]    n1;
   wire [`GlobalDataWidth-1:0]    n2;
   wire [`GlobalDataWidth-1:0]    n3;
   wire [`GlobalDataWidth-1:0]    n4;
   wire [`GlobalDataWidth-1:0]    n5;
   wire [`GlobalDataWidth-1:0]    n6;
   wire [`GlobalDataWidth-1:0]    n7;

   wire CELL_WR; // Set when address check succeeds in this block

   wire [`GlobalDataWidth-1:0]	 DIN; // either scan or non-scan input


   // Declaration of `GlobalDataWidth cells

// This file automatically generated by generate_aux.c
CELL #(0) cell_0 (.DATA_IN(DIN[0]), .cell_value(BLOCK_VALUE[0]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[0],n6[0],n5[0],n4[0],n3[0],n2[0],n1[0],n0[0]}));

CELL #(0) cell_1 (.DATA_IN(DIN[1]), .cell_value(BLOCK_VALUE[1]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[1],n6[1],n5[1],n4[1],n3[1],n2[1],n1[1],n0[1]}));

CELL #(0) cell_2 (.DATA_IN(DIN[2]), .cell_value(BLOCK_VALUE[2]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[2],n6[2],n5[2],n4[2],n3[2],n2[2],n1[2],n0[2]}));

CELL #(0) cell_3 (.DATA_IN(DIN[3]), .cell_value(BLOCK_VALUE[3]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[3],n6[3],n5[3],n4[3],n3[3],n2[3],n1[3],n0[3]}));

CELL #(0) cell_4 (.DATA_IN(DIN[4]), .cell_value(BLOCK_VALUE[4]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[4],n6[4],n5[4],n4[4],n3[4],n2[4],n1[4],n0[4]}));

CELL #(0) cell_5 (.DATA_IN(DIN[5]), .cell_value(BLOCK_VALUE[5]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[5],n6[5],n5[5],n4[5],n3[5],n2[5],n1[5],n0[5]}));

CELL #(0) cell_6 (.DATA_IN(DIN[6]), .cell_value(BLOCK_VALUE[6]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[6],n6[6],n5[6],n4[6],n3[6],n2[6],n1[6],n0[6]}));

CELL #(0) cell_7 (.DATA_IN(DIN[7]), .cell_value(BLOCK_VALUE[7]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[7],n6[7],n5[7],n4[7],n3[7],n2[7],n1[7],n0[7]}));

CELL #(0) cell_8 (.DATA_IN(DIN[8]), .cell_value(BLOCK_VALUE[8]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[8],n6[8],n5[8],n4[8],n3[8],n2[8],n1[8],n0[8]}));

CELL #(0) cell_9 (.DATA_IN(DIN[9]), .cell_value(BLOCK_VALUE[9]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[9],n6[9],n5[9],n4[9],n3[9],n2[9],n1[9],n0[9]}));

CELL #(0) cell_10 (.DATA_IN(DIN[10]), .cell_value(BLOCK_VALUE[10]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[10],n6[10],n5[10],n4[10],n3[10],n2[10],n1[10],n0[10]}));

CELL #(0) cell_11 (.DATA_IN(DIN[11]), .cell_value(BLOCK_VALUE[11]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[11],n6[11],n5[11],n4[11],n3[11],n2[11],n1[11],n0[11]}));

CELL #(0) cell_12 (.DATA_IN(DIN[12]), .cell_value(BLOCK_VALUE[12]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[12],n6[12],n5[12],n4[12],n3[12],n2[12],n1[12],n0[12]}));

CELL #(0) cell_13 (.DATA_IN(DIN[13]), .cell_value(BLOCK_VALUE[13]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[13],n6[13],n5[13],n4[13],n3[13],n2[13],n1[13],n0[13]}));

CELL #(0) cell_14 (.DATA_IN(DIN[14]), .cell_value(BLOCK_VALUE[14]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[14],n6[14],n5[14],n4[14],n3[14],n2[14],n1[14],n0[14]}));

CELL #(0) cell_15 (.DATA_IN(DIN[15]), .cell_value(BLOCK_VALUE[15]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[15],n6[15],n5[15],n4[15],n3[15],n2[15],n1[15],n0[15]}));

CELL #(0) cell_16 (.DATA_IN(DIN[16]), .cell_value(BLOCK_VALUE[16]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[16],n6[16],n5[16],n4[16],n3[16],n2[16],n1[16],n0[16]}));

CELL #(0) cell_17 (.DATA_IN(DIN[17]), .cell_value(BLOCK_VALUE[17]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[17],n6[17],n5[17],n4[17],n3[17],n2[17],n1[17],n0[17]}));

CELL #(0) cell_18 (.DATA_IN(DIN[18]), .cell_value(BLOCK_VALUE[18]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[18],n6[18],n5[18],n4[18],n3[18],n2[18],n1[18],n0[18]}));

CELL #(0) cell_19 (.DATA_IN(DIN[19]), .cell_value(BLOCK_VALUE[19]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[19],n6[19],n5[19],n4[19],n3[19],n2[19],n1[19],n0[19]}));

CELL #(0) cell_20 (.DATA_IN(DIN[20]), .cell_value(BLOCK_VALUE[20]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[20],n6[20],n5[20],n4[20],n3[20],n2[20],n1[20],n0[20]}));

CELL #(0) cell_21 (.DATA_IN(DIN[21]), .cell_value(BLOCK_VALUE[21]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[21],n6[21],n5[21],n4[21],n3[21],n2[21],n1[21],n0[21]}));

CELL #(0) cell_22 (.DATA_IN(DIN[22]), .cell_value(BLOCK_VALUE[22]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[22],n6[22],n5[22],n4[22],n3[22],n2[22],n1[22],n0[22]}));

CELL #(0) cell_23 (.DATA_IN(DIN[23]), .cell_value(BLOCK_VALUE[23]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[23],n6[23],n5[23],n4[23],n3[23],n2[23],n1[23],n0[23]}));

CELL #(0) cell_24 (.DATA_IN(DIN[24]), .cell_value(BLOCK_VALUE[24]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[24],n6[24],n5[24],n4[24],n3[24],n2[24],n1[24],n0[24]}));

CELL #(0) cell_25 (.DATA_IN(DIN[25]), .cell_value(BLOCK_VALUE[25]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[25],n6[25],n5[25],n4[25],n3[25],n2[25],n1[25],n0[25]}));

CELL #(0) cell_26 (.DATA_IN(DIN[26]), .cell_value(BLOCK_VALUE[26]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[26],n6[26],n5[26],n4[26],n3[26],n2[26],n1[26],n0[26]}));

CELL #(0) cell_27 (.DATA_IN(DIN[27]), .cell_value(BLOCK_VALUE[27]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[27],n6[27],n5[27],n4[27],n3[27],n2[27],n1[27],n0[27]}));

CELL #(0) cell_28 (.DATA_IN(DIN[28]), .cell_value(BLOCK_VALUE[28]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[28],n6[28],n5[28],n4[28],n3[28],n2[28],n1[28],n0[28]}));

CELL #(0) cell_29 (.DATA_IN(DIN[29]), .cell_value(BLOCK_VALUE[29]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[29],n6[29],n5[29],n4[29],n3[29],n2[29],n1[29],n0[29]}));

CELL #(0) cell_30 (.DATA_IN(DIN[30]), .cell_value(BLOCK_VALUE[30]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[30],n6[30],n5[30],n4[30],n3[30],n2[30],n1[30],n0[30]}));

CELL #(0) cell_31 (.DATA_IN(DIN[31]), .cell_value(BLOCK_VALUE[31]),
             .Reset(Reset),.WR(CELL_WR), .Enable(Enable), .Clk(Clk),
         .NEIGHBORS({n7[31],n6[31],n5[31],n4[31],n3[31],n2[31],n1[31],n0[31]}));




   // Make wiring connections

   assign n0[30:1] = NORTH_EDGE[30:1];
   assign n1[30:1] = NORTH_EDGE[29:0];
   assign n2[30:1] = BLOCK_VALUE[29:0];
   assign n3[30:1] = SOUTH_EDGE[29:0];
   assign n4[30:1] = SOUTH_EDGE[30:1];
   assign n5[30:1] = SOUTH_EDGE[31:2];
   assign n6[30:1] = BLOCK_VALUE[31:2];
   assign n7[30:1] = NORTH_EDGE[31:2];

   // Two end points, cells 0 and `GlobalDataWidth-1
   assign n0[`GlobalDataWidth-1] = NORTH_EDGE[`GlobalDataWidth-1];
   assign n1[`GlobalDataWidth-1] = NORTH_EDGE[`GlobalDataWidth-2];
   assign n2[`GlobalDataWidth-1] = BLOCK_VALUE[`GlobalDataWidth-2];
   assign n3[`GlobalDataWidth-1] = SOUTH_EDGE[`GlobalDataWidth-2];
   assign n4[`GlobalDataWidth-1] = SOUTH_EDGE[`GlobalDataWidth-1];
   assign n5[`GlobalDataWidth-1] = SW_EDGE;
   assign n6[`GlobalDataWidth-1] = WEST_EDGE;
   assign n7[`GlobalDataWidth-1] = NW_EDGE;

   assign n0[0] = NORTH_EDGE[0];
   assign n1[0] = NE_EDGE;
   assign n2[0] = EAST_EDGE;
   assign n3[0] = SE_EDGE;
   assign n4[0] = SOUTH_EDGE[0];
   assign n5[0] = SOUTH_EDGE[1];
   assign n6[0] = BLOCK_VALUE[1];
   assign n7[0] = NORTH_EDGE[1];


   // For handling writes / scan in

   assign CELL_WR = SCAN ? ScanEnable : WR && (Id==Addr[IDWIDTH-1:0]);


   // For handling reads (non-scan only)

   assign DataOut = (!SCAN && Id==Addr[IDWIDTH-1:0]) ?
      BLOCK_VALUE : `GlobalDataHighZ;


   /* support scan out of the node data value */

   assign ScanOut = SCAN ? BLOCK_VALUE: 0;


   // hookup scan path or not:

   assign DIN = SCAN ? ScanIn: DataIn;

endmodule


/*
  A control module to count iterations. Writing to Address==Id will
  set a counter. The other Life blocks will be enabled by this
  module when count is greater than zero. The counter will decrement
  every cycle down to zero.
*/

module Life_Control (Clk, Reset, RD, WR, Addr, DataIn, DataOut,
		       ScanIn, ScanOut, ScanEnable,
		       Id,ScanId,Enable);

   parameter WIDTH = 8,
	     CWIDTH = 8,
	     IDWIDTH = 8,
	     SCAN   = 1;


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
	 else
	    if(count)
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

wire [31:0] nOut0_0;
wire [31:0] nScanOut0;
wire [31:0] nOut0_1;
wire [31:0] nScanOut1;
wire [31:0] nOut0_2;
wire [31:0] nScanOut2;
wire [31:0] nOut0_3;
wire [31:0] nScanOut3;
wire [31:0] nOut0_4;
wire [31:0] nScanOut4;
wire [31:0] nOut0_5;
wire [31:0] nScanOut5;
wire [31:0] nOut0_6;
wire [31:0] nScanOut6;
wire [31:0] nOut0_7;
wire [31:0] nScanOut7;
wire [31:0] nOut0_8;
wire [31:0] nScanOut8;
wire [31:0] nOut0_9;
wire [31:0] nScanOut9;
wire [31:0] nOut0_10;
wire [31:0] nScanOut10;
wire [31:0] nOut0_11;
wire [31:0] nScanOut11;
wire [31:0] nOut0_12;
wire [31:0] nScanOut12;
wire [31:0] nOut0_13;
wire [31:0] nScanOut13;
wire [31:0] nOut0_14;
wire [31:0] nScanOut14;
wire [31:0] nOut0_15;
wire [31:0] nScanOut15;
wire [31:0] nOut1_0;
wire [31:0] nScanOut16;
wire [31:0] nOut1_1;
wire [31:0] nScanOut17;
wire [31:0] nOut1_2;
wire [31:0] nScanOut18;
wire [31:0] nOut1_3;
wire [31:0] nScanOut19;
wire [31:0] nOut1_4;
wire [31:0] nScanOut20;
wire [31:0] nOut1_5;
wire [31:0] nScanOut21;
wire [31:0] nOut1_6;
wire [31:0] nScanOut22;
wire [31:0] nOut1_7;
wire [31:0] nScanOut23;
wire [31:0] nOut1_8;
wire [31:0] nScanOut24;
wire [31:0] nOut1_9;
wire [31:0] nScanOut25;
wire [31:0] nOut1_10;
wire [31:0] nScanOut26;
wire [31:0] nOut1_11;
wire [31:0] nScanOut27;
wire [31:0] nOut1_12;
wire [31:0] nScanOut28;
wire [31:0] nOut1_13;
wire [31:0] nScanOut29;
wire [31:0] nOut1_14;
wire [31:0] nScanOut30;
wire [31:0] nOut1_15;
wire [31:0] nScanOut31;
wire [0:0] nEnable;
wire [0:0] nScanEnable;
wire [31:0] nScanOut32;
Life_Block #( 1, 1 ) U_Life_Block_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_0), .NORTH_EDGE(32'd0), .SOUTH_EDGE(nOut0_1), .EAST_EDGE(nOut1_0[31]), .NE_EDGE(1'd0), .SE_EDGE(nOut1_1[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut1), .ScanOut(nScanOut0), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_1), .NORTH_EDGE(nOut0_0), .SOUTH_EDGE(nOut0_2), .EAST_EDGE(nOut1_1[31]), .NE_EDGE(nOut1_0[31]), .SE_EDGE(nOut1_2[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut2), .ScanOut(nScanOut1), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_2), .NORTH_EDGE(nOut0_1), .SOUTH_EDGE(nOut0_3), .EAST_EDGE(nOut1_2[31]), .NE_EDGE(nOut1_1[31]), .SE_EDGE(nOut1_3[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut3), .ScanOut(nScanOut2), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_3), .NORTH_EDGE(nOut0_2), .SOUTH_EDGE(nOut0_4), .EAST_EDGE(nOut1_3[31]), .NE_EDGE(nOut1_2[31]), .SE_EDGE(nOut1_4[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut4), .ScanOut(nScanOut3), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_4), .NORTH_EDGE(nOut0_3), .SOUTH_EDGE(nOut0_5), .EAST_EDGE(nOut1_4[31]), .NE_EDGE(nOut1_3[31]), .SE_EDGE(nOut1_5[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut5), .ScanOut(nScanOut4), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_5), .NORTH_EDGE(nOut0_4), .SOUTH_EDGE(nOut0_6), .EAST_EDGE(nOut1_5[31]), .NE_EDGE(nOut1_4[31]), .SE_EDGE(nOut1_6[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut6), .ScanOut(nScanOut5), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_6), .NORTH_EDGE(nOut0_5), .SOUTH_EDGE(nOut0_7), .EAST_EDGE(nOut1_6[31]), .NE_EDGE(nOut1_5[31]), .SE_EDGE(nOut1_7[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut7), .ScanOut(nScanOut6), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_7), .NORTH_EDGE(nOut0_6), .SOUTH_EDGE(nOut0_8), .EAST_EDGE(nOut1_7[31]), .NE_EDGE(nOut1_6[31]), .SE_EDGE(nOut1_8[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut8), .ScanOut(nScanOut7), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_8), .NORTH_EDGE(nOut0_7), .SOUTH_EDGE(nOut0_9), .EAST_EDGE(nOut1_8[31]), .NE_EDGE(nOut1_7[31]), .SE_EDGE(nOut1_9[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut9), .ScanOut(nScanOut8), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_9), .NORTH_EDGE(nOut0_8), .SOUTH_EDGE(nOut0_10), .EAST_EDGE(nOut1_9[31]), .NE_EDGE(nOut1_8[31]), .SE_EDGE(nOut1_10[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut10), .ScanOut(nScanOut9), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_10), .NORTH_EDGE(nOut0_9), .SOUTH_EDGE(nOut0_11), .EAST_EDGE(nOut1_10[31]), .NE_EDGE(nOut1_9[31]), .SE_EDGE(nOut1_11[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut11), .ScanOut(nScanOut10), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_11), .NORTH_EDGE(nOut0_10), .SOUTH_EDGE(nOut0_12), .EAST_EDGE(nOut1_11[31]), .NE_EDGE(nOut1_10[31]), .SE_EDGE(nOut1_12[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut12), .ScanOut(nScanOut11), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_12), .NORTH_EDGE(nOut0_11), .SOUTH_EDGE(nOut0_13), .EAST_EDGE(nOut1_12[31]), .NE_EDGE(nOut1_11[31]), .SE_EDGE(nOut1_13[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut13), .ScanOut(nScanOut12), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_13), .NORTH_EDGE(nOut0_12), .SOUTH_EDGE(nOut0_14), .EAST_EDGE(nOut1_13[31]), .NE_EDGE(nOut1_12[31]), .SE_EDGE(nOut1_14[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut14), .ScanOut(nScanOut13), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_14), .NORTH_EDGE(nOut0_13), .SOUTH_EDGE(nOut0_15), .EAST_EDGE(nOut1_14[31]), .NE_EDGE(nOut1_13[31]), .SE_EDGE(nOut1_15[31]), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut15), .ScanOut(nScanOut14), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut0_15), .NORTH_EDGE(nOut0_14), .SOUTH_EDGE(32'd0), .EAST_EDGE(nOut1_15[31]), .NE_EDGE(nOut1_14[31]), .SE_EDGE(1'd0), .WEST_EDGE(1'd0), .NW_EDGE(1'd0), .SW_EDGE(1'd0), .ScanIn(nScanOut16), .ScanOut(nScanOut15), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_16 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_0), .NORTH_EDGE(32'd0), .SOUTH_EDGE(nOut1_1), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_0[0]), .NW_EDGE(1'd0), .SW_EDGE(nOut0_1[0]), .ScanIn(nScanOut17), .ScanOut(nScanOut16), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_17 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_1), .NORTH_EDGE(nOut1_0), .SOUTH_EDGE(nOut1_2), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_1[0]), .NW_EDGE(nOut0_0[0]), .SW_EDGE(nOut0_2[0]), .ScanIn(nScanOut18), .ScanOut(nScanOut17), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_18 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_2), .NORTH_EDGE(nOut1_1), .SOUTH_EDGE(nOut1_3), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_2[0]), .NW_EDGE(nOut0_1[0]), .SW_EDGE(nOut0_3[0]), .ScanIn(nScanOut19), .ScanOut(nScanOut18), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_19 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_3), .NORTH_EDGE(nOut1_2), .SOUTH_EDGE(nOut1_4), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_3[0]), .NW_EDGE(nOut0_2[0]), .SW_EDGE(nOut0_4[0]), .ScanIn(nScanOut20), .ScanOut(nScanOut19), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_20 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_4), .NORTH_EDGE(nOut1_3), .SOUTH_EDGE(nOut1_5), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_4[0]), .NW_EDGE(nOut0_3[0]), .SW_EDGE(nOut0_5[0]), .ScanIn(nScanOut21), .ScanOut(nScanOut20), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_21 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_5), .NORTH_EDGE(nOut1_4), .SOUTH_EDGE(nOut1_6), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_5[0]), .NW_EDGE(nOut0_4[0]), .SW_EDGE(nOut0_6[0]), .ScanIn(nScanOut22), .ScanOut(nScanOut21), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_22 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_6), .NORTH_EDGE(nOut1_5), .SOUTH_EDGE(nOut1_7), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_6[0]), .NW_EDGE(nOut0_5[0]), .SW_EDGE(nOut0_7[0]), .ScanIn(nScanOut23), .ScanOut(nScanOut22), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_23 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_7), .NORTH_EDGE(nOut1_6), .SOUTH_EDGE(nOut1_8), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_7[0]), .NW_EDGE(nOut0_6[0]), .SW_EDGE(nOut0_8[0]), .ScanIn(nScanOut24), .ScanOut(nScanOut23), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_24 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_8), .NORTH_EDGE(nOut1_7), .SOUTH_EDGE(nOut1_9), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_8[0]), .NW_EDGE(nOut0_7[0]), .SW_EDGE(nOut0_9[0]), .ScanIn(nScanOut25), .ScanOut(nScanOut24), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_25 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_9), .NORTH_EDGE(nOut1_8), .SOUTH_EDGE(nOut1_10), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_9[0]), .NW_EDGE(nOut0_8[0]), .SW_EDGE(nOut0_10[0]), .ScanIn(nScanOut26), .ScanOut(nScanOut25), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_26 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_10), .NORTH_EDGE(nOut1_9), .SOUTH_EDGE(nOut1_11), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_10[0]), .NW_EDGE(nOut0_9[0]), .SW_EDGE(nOut0_11[0]), .ScanIn(nScanOut27), .ScanOut(nScanOut26), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_27 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_11), .NORTH_EDGE(nOut1_10), .SOUTH_EDGE(nOut1_12), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_11[0]), .NW_EDGE(nOut0_10[0]), .SW_EDGE(nOut0_12[0]), .ScanIn(nScanOut28), .ScanOut(nScanOut27), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_28 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_12), .NORTH_EDGE(nOut1_11), .SOUTH_EDGE(nOut1_13), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_12[0]), .NW_EDGE(nOut0_11[0]), .SW_EDGE(nOut0_13[0]), .ScanIn(nScanOut29), .ScanOut(nScanOut28), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_29 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_13), .NORTH_EDGE(nOut1_12), .SOUTH_EDGE(nOut1_14), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_13[0]), .NW_EDGE(nOut0_12[0]), .SW_EDGE(nOut0_14[0]), .ScanIn(nScanOut30), .ScanOut(nScanOut29), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_30 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_14), .NORTH_EDGE(nOut1_13), .SOUTH_EDGE(nOut1_15), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_14[0]), .NW_EDGE(nOut0_13[0]), .SW_EDGE(nOut0_15[0]), .ScanIn(nScanOut31), .ScanOut(nScanOut30), .ScanEnable(nScanEnable) );
Life_Block #( 1, 1 ) U_Life_Block_31 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .BLOCK_VALUE(nOut1_15), .NORTH_EDGE(nOut1_14), .SOUTH_EDGE(32'd0), .EAST_EDGE(1'd0), .NE_EDGE(1'd0), .SE_EDGE(1'd0), .WEST_EDGE(nOut0_15[0]), .NW_EDGE(nOut0_14[0]), .SW_EDGE(1'd0), .ScanIn(nScanOut32), .ScanOut(nScanOut31), .ScanEnable(nScanEnable) );
Life_Control #( 32, 7, 1, 1 ) U_Life_Control ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd1), .Enable(nEnable), .ScanId(1'd0), .ScanEnable(nScanEnable), .ScanIn(nScanOut0), .ScanOut(nScanOut32) );

/*
 *
 * RAW Benchmark Suite main module trailer
 *
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


endmodule

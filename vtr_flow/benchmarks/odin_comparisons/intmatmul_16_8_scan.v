

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
 * $Header: /projects/raw/cvsroot/benchmark/suites/intmatmul/src/library.v,v 1.8 1997/08/10 01:23:09 jbabb Exp $
 *
 * Library for Matrix Multiply Benchmark
 *
 * Authors: Michael B. Taylor       (mtaylor@lcs.mit.edu)
 *          Jonathan Babb           (jbabb@lcs.mit.edu)
 * *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */



module VectorDotProduct (Clk, Reset, RD, WR, Addr, DataIn, DataOut,
			 vectorAInput, vectorBInput, cOutput);

   parameter pVectorSize = 4,
	     pWordSize = 4;

   input				 Clk,Reset,RD,WR;
   input [`GlobalAddrWidth-1:0]		 Addr;
   input [`GlobalDataWidth-1:0]		 DataIn;
   output [`GlobalDataWidth-1:0]	 DataOut;

   input [pVectorSize * pWordSize - 1:0] vectorAInput;
   input [pVectorSize * pWordSize - 1:0] vectorBInput;
   output [pWordSize - 1:0]		 cOutput;
   reg [pWordSize - 1:0]		 cOutput;

   reg [32:0]				 i,j;

   reg [pWordSize-1:0]			 tempA;
   reg [pWordSize-1:0]			 tempB;
   reg [pWordSize-1:0]			 result;

   always @(posedge Clk)
   begin
	 result = 0;

	 for (i = 0; i < pVectorSize; i = i + 1)
	    begin
		  for (j = 0; j < pWordSize; j = j + 1)
			   begin
				 tempA[j] = vectorAInput[i*pWordSize + j];
				 tempB[j] = vectorBInput[i*pWordSize + j];
			   end
		  result = result + tempA * tempB;
	    end
	 cOutput = result;
   end
endmodule


module IntMatMul_Control(Clk, Reset, RD, WR, Addr, DataIn, DataOut,
			 vectorInput, matrixInput, cOutput);

   parameter pVectorSize = 4,
	     pWordSize   = 4,
	     pScan       = 1;

   /* global connections */

   input						Clk,Reset,RD,WR;
   input [`GlobalAddrWidth-1:0]				Addr;
   input [`GlobalDataWidth-1:0]				DataIn;
   output [`GlobalDataWidth-1:0]			DataOut;
   output [pVectorSize * pWordSize - 1:0]		vectorInput;
   output [pVectorSize * pVectorSize * pWordSize - 1:0]	matrixInput;
   input [pVectorSize * pWordSize - 1:0]		cOutput;


   /* local connections */

   reg [pVectorSize * pWordSize - 1:0]			vectorInput;
   reg [pVectorSize * pVectorSize * pWordSize - 1:0]	matrixInput;


   /* note: there is a read bus timing problem with this being a register */

   reg [pWordSize - 1:0]				holder;

   integer						i;

   assign DataOut = ((RD == 1) ? holder :  `GlobalDataHighZ);

   always @(posedge Clk)
      begin
	 if (pScan)
	    begin
	       if (WR && (Addr[1:0] == 0))
		  begin


		     /* shift the register over */

		     for (i = 0; i < pWordSize*(pVectorSize*pVectorSize - 1);
			  i= i + 1)
			begin
			   matrixInput[i] = matrixInput[i+pWordSize];
			end


		     /* insert the data word */

		     for (i = 0; i < pWordSize; i = i + 1)
			begin
			   matrixInput[i+(pVectorSize*pVectorSize - 1)
				       *pWordSize] = DataIn[i];
			end
		  end
	       else
		  if (WR && (Addr[1:0] == 1))
		     begin


			/* shift the register over */

			for (i = 0; i < pWordSize*(pVectorSize - 1); i = i + 1)
			   begin
			      vectorInput[i] = vectorInput[i+pWordSize];
			   end
			for (i = 0; i < pWordSize; i = i + 1)
			   begin
			      vectorInput[i+pWordSize*(pVectorSize - 1)] =
				 DataIn[i];
			   end
		     end
		  else
		     if (RD && (Addr < pVectorSize))
			begin
			   for (i = 0; i < pWordSize; i = i + 1)
			      begin
				 holder[i] = cOutput[i + Addr*pWordSize];
			      end
			end
	    end
	 else
	    begin

	       if (WR && Addr < pVectorSize*pVectorSize)
		  begin
		     for (i = 0; i < pWordSize; i = i+1)
			matrixInput[Addr * pWordSize + i] = DataIn[i];
		     $display("WriteMatrix *(%h) = %h\n",Addr,DataIn);
		  end
	       else
		  if (WR && Addr < pVectorSize*(pVectorSize+1))
		     begin
			for (i = 0; i < pWordSize; i=i+1)
			   vectorInput[(Addr - pVectorSize*pVectorSize)
				       * pWordSize + i] = DataIn[i];
			$display("WriteVector *(%h) = %h\n",Addr,DataIn);
		     end
		  else
		     if (RD && Addr < pVectorSize)
			begin
			   for (i = 0; i < pWordSize; i=i+1)
			      holder[i] = cOutput[Addr * pWordSize + i];
			   $display("ReadVector *(%h) -> %h\n",Addr,holder);
			end
	    end

	 /* might eventually have a ready flag */

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

wire [127:0] vectorInput;
wire [2047:0] matrixInput;
wire [127:0] cOutput;
IntMatMul_Control #( 16, 8, 1 ) U_IntMatMul_Control ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorInput(vectorInput), .matrixInput(matrixInput), .cOutput(cOutput) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[127:0]), .cOutput(cOutput[7:0]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[255:128]), .cOutput(cOutput[15:8]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[383:256]), .cOutput(cOutput[23:16]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[511:384]), .cOutput(cOutput[31:24]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[639:512]), .cOutput(cOutput[39:32]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[767:640]), .cOutput(cOutput[47:40]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[895:768]), .cOutput(cOutput[55:48]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1023:896]), .cOutput(cOutput[63:56]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1151:1024]), .cOutput(cOutput[71:64]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1279:1152]), .cOutput(cOutput[79:72]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1407:1280]), .cOutput(cOutput[87:80]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1535:1408]), .cOutput(cOutput[95:88]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1663:1536]), .cOutput(cOutput[103:96]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1791:1664]), .cOutput(cOutput[111:104]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[1919:1792]), .cOutput(cOutput[119:112]) );
VectorDotProduct #( 16, 8 ) VectorDotProduct_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .vectorAInput(vectorInput), .vectorBInput(matrixInput[2047:1920]), .cOutput(cOutput[127:120]) );

/*
 *
 * RAW Benchmark Suite main module trailer
 *
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


endmodule

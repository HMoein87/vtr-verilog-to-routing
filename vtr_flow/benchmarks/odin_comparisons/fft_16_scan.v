

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
 * $Header: /projects/raw/cvsroot/benchmark/suites/fft/src/library.v,v 1.4 1997/08/09 05:57:22 jbabb Exp $
 *
 * Library for Integer FFT benchmark
 *
 * Authors: Devabhaktuni Srikrishna (chinnama@lcs.mit.edu)
 *          Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */



/*
 The numbers will be represented by N/2 + 1 bits. 
 The first bit is the sign bit. The remainin bits represent
 the numerical value. The highest bit is one if the number 
 represents minus one and zero otherwise.
 */

module FFT_Node(Clk, Reset, RD, WR, Addr, DataIn, DataOut, 
                ScanIn, ScanOut, ScanEnable, 
                Idl, Idr, Ids, Enable, 
                inleft, inright, outleft, outright);

   /*
    * We use three Id's:
    * one each for specifying left, right, and sign bits
    * The two least significant bits differentiate
    * between l,r,s (3=11=s, 1=01=l, 2=10=r)
    * When the left is being written, the first SIZE bits of
    * DataIn are the data bits, and similarly for right
    * When the sign is beig written, the first and second least
    * significant bits are the left and right sgn bits, resp.
    */

   parameter SIZE    = 4,
             IDWIDTH = 8,
             s       = 0,
             SCAN    = 1;
   
   
   /* global connections */
   
   input			 Clk,Reset,RD,WR;
   input [`GlobalAddrWidth-1:0]	 Addr;
   input [`GlobalDataWidth-1:0]	 DataIn;
   output [`GlobalDataWidth-1:0] DataOut;
   
   
   /* global scan connection */

   input [SIZE-1:0]                 ScanIn;
   output [SIZE-1:0]                ScanOut;
   input                            ScanEnable;
   reg [SIZE-1:2]                   ScanReg;
   

   /* local connections*/

   input [IDWIDTH-1:0]              Idl;
   input [IDWIDTH-1:0]              Idr;
   input [IDWIDTH-1:0]              Ids;
   input                            Enable;

   input [SIZE:0]                   inleft;
   input [SIZE:0]                   inright;
   output [SIZE:0]                  outleft;
   output [SIZE:0]                  outright;

   reg [SIZE:0]                     outleft;
   reg [SIZE:0]                     outright;

   wire [SIZE:0]                    comleft;
   wire [SIZE:0]                    comright;

   
   /* instantiate FFT butterfly node */
   
   COMBINATIONAL #(SIZE, s) com(inleft,inright,comleft,comright);
   
   
   /* assigns the outputs - left, right, or sign bits */
   
   assign DataOut[`GlobalDataWidth-1:0] = 
      (!SCAN && (Addr[IDWIDTH-1:0] == Idl) ? outleft[SIZE-1:0] :
       !SCAN && (Addr[IDWIDTH-1:0] == Idr) ? outright[SIZE-1:0] : 
       !SCAN && (Addr[IDWIDTH-1:0] == Ids) ? {outright[SIZE],outleft[SIZE]} :
       `GlobalDataHighZ);
   
   assign ScanOut[SIZE-1:0] = outleft[SIZE-1:0];
   
   
   always @(posedge Clk)
      begin

 	 if(Reset)
	    begin
	       outleft = 0;
	       outright = 0;
	       ScanReg = 0;
	    end

         else if (SCAN && ScanEnable)
            begin
	       outleft[SIZE-1:0] = outright[SIZE-1:0];

               outright[SIZE-1:0] = 
                  {ScanReg[SIZE-1:2], outright[SIZE], outleft[SIZE]};

               {ScanReg[SIZE-1:2], outright[SIZE], outleft[SIZE]} = 
               ScanIn[SIZE-1:0];
            end 
         
         else if (!SCAN && WR && (Addr[IDWIDTH-1:0]==Idl))
               outleft[SIZE-1:0] = DataIn[SIZE-1:0];
	 
         else if (!SCAN && WR && (Addr[IDWIDTH-1:0]==Idr))
               outright[SIZE-1:0] = DataIn[SIZE-1:0];
         
	 else if (!SCAN && WR && (Addr[IDWIDTH-1:0]==Ids))
	    {outright[SIZE],outleft[SIZE]} = DataIn[1:0];

         else if(Enable)
            begin
               outleft[SIZE:0]  = comleft[SIZE:0];
               outright[SIZE:0] = comright[SIZE:0];
	    end
      end
   
endmodule /*FFT_Node*/


module FFT_Control(Clk, Reset, RD, WR, Addr, DataIn, DataOut,   
                   ScanIn, ScanOut, ScanEnable, ScanId,
                   Id,Enable);

   parameter SIZE    = 4,
             IDWIDTH = 8,
             SCAN    = 1;

   input                         Clk,Reset,RD,WR;
   input [`GlobalAddrWidth-1:0]  Addr;
   input [`GlobalDataWidth-1:0]  DataIn;
   output [`GlobalDataWidth-1:0] DataOut;
   
   input [IDWIDTH-1:0]           Id;
   output                        Enable;
   
   
   /* global connections for scan path (scan = 1) */
   
   input [IDWIDTH-1:0]           ScanId;
   input [SIZE-1:0]              ScanIn;
   output [SIZE-1:0]             ScanOut;
   output                        ScanEnable;   

   reg [`GlobalDataWidth-1:0]    count;
   reg [SIZE-1:0]                ScanReg;
   

   /* support for the scan interface */

   assign ScanEnable = (SCAN && (RD || WR) && (Addr[IDWIDTH-1:0]==ScanId));
   assign ScanOut[SIZE-1:0] = DataIn[SIZE-1:0];
   
   assign DataOut[`GlobalDataWidth-1:0] = 
      (Addr[IDWIDTH-1:0] == Id) ? count: 
      ((ScanEnable && RD) ? ScanReg : `GlobalDataHighZ);

   assign Enable = !(count==0);

   always @(posedge Clk)
      begin
         ScanReg = ScanIn;
         
         if (Reset)
            count=0;
         else if (WR && (Addr[IDWIDTH-1:0]==Id))
            count=DataIn;
         else if(count)
            count = count-1;
      end

endmodule /*FFT_Control*/


module ADD_MINUS_1(a, b);

   parameter SIZE = 4;

   input [SIZE:0]  a;
   output [SIZE:0] b;
   
   wire [SIZE-1:0] ALL_ONES = ~0;

   assign b[SIZE]     = (!a[SIZE] && a[SIZE-1:0] == 0) ? 1 : 0;
   assign b[SIZE-1:0] = (a[SIZE]) ? ALL_ONES : a[SIZE-1:0] - 1;

endmodule /*ADD_MINUS_1*/


/*subtracts one from a if sgn_bit is one does nothing otherwise*/

module NORMALIZE(a,b);
   
   parameter SIZE = 4;

   input [SIZE:0]  a;
   output [SIZE:0] b;

   assign b[SIZE] = 
      (a[SIZE] && a[SIZE-1:0] == 0) ? 1 : 0;    

   assign b[SIZE-1:0] =
      (a[SIZE] && a[SIZE-1:0] != 0) ? a[SIZE-1:0]-1 : a[SIZE-1:0];

endmodule /*NORMALIZE*/


/* a and b have to have their sign bits zero */

module ADD_NN(a, b, c);

   parameter SIZE = 4;

   input [SIZE:0]  a;
   input [SIZE:0]  b;
   output [SIZE:0] c;

   wire [SIZE:0]   sum;

   assign sum[SIZE-1:0] = a[SIZE-1:0]+b[SIZE-1:0];
   assign sum[SIZE] = (a[SIZE-1] & b[SIZE-1]) | ((~sum[SIZE-1]) & (a[SIZE-1] | b[SIZE-1]));

   NORMALIZE    #(SIZE) norm(sum, c);

endmodule /*ADD_NN*/


module ADD(a, b, c);

   parameter SIZE = 4;

   input [SIZE:0]  a;
   input [SIZE:0]  b;

   output [SIZE:0] c;

   wire [SIZE:0]   sum1, sum2, sum3;

   ADD_NN        #(SIZE) add_nn(a,b,sum1);

   ADD_MINUS_1 #(SIZE) am1(a,sum2);
   ADD_MINUS_1 #(SIZE) am2(b,sum3);
   
   assign c[SIZE:0] = (a[SIZE] || b[SIZE]) ? (a[SIZE] ? sum3 : sum2) : sum1;

endmodule /*ADD*/


/*negates the number a */

module NEGATE(a, b);

   parameter SIZE = 4;

   input [SIZE:0]  a;
   output [SIZE:0] b;

   wire [SIZE:0]   minus1 = (1 << SIZE), ozzo = (1 << SIZE) + 1;

   assign b[SIZE:0] = 
      a[SIZE] ? 1 : ((a[SIZE-1:0] == 0) ? 0 : ((a[SIZE-1:0] == 1) ? 
					       minus1 : ozzo-a));

endmodule /*NEGATE*/


/* shifts up a by s bits 0 <= s <= N */

module SHIFT_UP(a, c);

   parameter SIZE = 4,
	     s    = 0;
   
   input [SIZE:0]  a;
   output [SIZE:0] c;

   wire [SIZE:0]   a_norm, b1, b2, b3, nb2, sum1, sum2; 
   

   assign       a_norm[SIZE] = a[SIZE];



   assign       a_norm[SIZE-1:0] = a[SIZE] ? 0 : a[SIZE-1:0];

   /* if a is -1, then makes all other bits zero */

   
   assign       b1[SIZE:0] = (a_norm[SIZE:0] << s) & (~(1 << SIZE));
   assign       b2[SIZE:0] = 0;

   /* ((s <= SIZE) ? (a_norm[SIZE:0] >> ((s <= SIZE) ? SIZE-s: 0)) :
    (a_norm[SIZE:0] << ((s > SIZE) ? s-SIZE : 0))) & (~(1 << SIZE)); */

   
   assign       b3[SIZE:0] = 0;
   
   /* ((s <= SIZE) ? 0 : (a_norm[SIZE:0] >> ((s <= 2*SIZE) ? 2*SIZE-s : 0)))
    & (~(1 << SIZE));*/

   
   NEGATE #(SIZE) negate(b2,nb2);
   ADD    #(SIZE) add1(b1,nb2,sum1);
   ADD    #(SIZE) add2(sum1,b3,sum2);

   /*SIZE << 1 == N*/
   assign c[SIZE:0] = (s == 0 || s == (SIZE << 1)) ? a[SIZE:0] : sum2[SIZE:0]; 

endmodule /*SHIFT_UP*/


module COMBINATIONAL(a,b,x,y); /*The node in the butterfly network*/ 

   parameter SIZE = 4,
	     s    = 0;
   
   /*s is usually between 0 and N, but is eq. to N+1 when we require 
    * it to equate input and outputs */

   input [SIZE:0]  a;
   input [SIZE:0]  b;
   output [SIZE:0] x;
   output [SIZE:0] y;

   wire [SIZE:0]   t1, t2, t3, t4;

   assign x = 
      (s == (SIZE << 1) +1) ? a : ((t3[SIZE]) ? t3 & (1 << SIZE) : t3); 

   assign y = 
      (s == (SIZE << 1) +1) ? b : ((t4[SIZE]) ? t4 & (1 << SIZE) : t4); 

   SHIFT_UP  #(SIZE, s) shift(b,t1);
   NEGATE    #(SIZE)    neg(t1,t2);
   
   ADD       #(SIZE)    add1(a,t1,t3);
   ADD       #(SIZE)    add2(a,t2,t4);

endmodule /*COMBINATIONAL*/

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

wire [8:0] nLeftOut_0;
wire [8:0] nRightOut_0;
wire [8:0] nLeftOut_1;
wire [8:0] nRightOut_1;
wire [8:0] nLeftOut_2;
wire [8:0] nRightOut_2;
wire [8:0] nLeftOut_3;
wire [8:0] nRightOut_3;
wire [8:0] nLeftOut_4;
wire [8:0] nRightOut_4;
wire [8:0] nLeftOut_5;
wire [8:0] nRightOut_5;
wire [8:0] nLeftOut_6;
wire [8:0] nRightOut_6;
wire [8:0] nLeftOut_7;
wire [8:0] nRightOut_7;
wire [8:0] nLeftOut_8;
wire [8:0] nRightOut_8;
wire [8:0] nLeftOut_9;
wire [8:0] nRightOut_9;
wire [8:0] nLeftOut_10;
wire [8:0] nRightOut_10;
wire [8:0] nLeftOut_11;
wire [8:0] nRightOut_11;
wire [8:0] nLeftOut_12;
wire [8:0] nRightOut_12;
wire [8:0] nLeftOut_13;
wire [8:0] nRightOut_13;
wire [8:0] nLeftOut_14;
wire [8:0] nRightOut_14;
wire [8:0] nLeftOut_15;
wire [8:0] nRightOut_15;
wire [8:0] nLeftOut_16;
wire [8:0] nRightOut_16;
wire [8:0] nLeftOut_17;
wire [8:0] nRightOut_17;
wire [8:0] nLeftOut_18;
wire [8:0] nRightOut_18;
wire [8:0] nLeftOut_19;
wire [8:0] nRightOut_19;
wire [8:0] nLeftOut_20;
wire [8:0] nRightOut_20;
wire [8:0] nLeftOut_21;
wire [8:0] nRightOut_21;
wire [8:0] nLeftOut_22;
wire [8:0] nRightOut_22;
wire [8:0] nLeftOut_23;
wire [8:0] nRightOut_23;
wire [8:0] nLeftOut_24;
wire [8:0] nRightOut_24;
wire [8:0] nLeftOut_25;
wire [8:0] nRightOut_25;
wire [8:0] nLeftOut_26;
wire [8:0] nRightOut_26;
wire [8:0] nLeftOut_27;
wire [8:0] nRightOut_27;
wire [8:0] nLeftOut_28;
wire [8:0] nRightOut_28;
wire [8:0] nLeftOut_29;
wire [8:0] nRightOut_29;
wire [8:0] nLeftOut_30;
wire [8:0] nRightOut_30;
wire [8:0] nLeftOut_31;
wire [8:0] nRightOut_31;
wire [8:0] nLeftOut_32;
wire [8:0] nRightOut_32;
wire [8:0] nLeftOut_33;
wire [8:0] nRightOut_33;
wire [8:0] nLeftOut_34;
wire [8:0] nRightOut_34;
wire [8:0] nLeftOut_35;
wire [8:0] nRightOut_35;
wire [8:0] nLeftOut_36;
wire [8:0] nRightOut_36;
wire [8:0] nLeftOut_37;
wire [8:0] nRightOut_37;
wire [8:0] nLeftOut_38;
wire [8:0] nRightOut_38;
wire [8:0] nLeftOut_39;
wire [8:0] nRightOut_39;
wire [8:0] nLeftOut_40;
wire [8:0] nRightOut_40;
wire [8:0] nLeftOut_41;
wire [8:0] nRightOut_41;
wire [8:0] nLeftOut_42;
wire [8:0] nRightOut_42;
wire [8:0] nLeftOut_43;
wire [8:0] nRightOut_43;
wire [8:0] nLeftOut_44;
wire [8:0] nRightOut_44;
wire [8:0] nLeftOut_45;
wire [8:0] nRightOut_45;
wire [8:0] nLeftOut_46;
wire [8:0] nRightOut_46;
wire [8:0] nLeftOut_47;
wire [8:0] nRightOut_47;
wire [8:0] nLeftOut_48;
wire [8:0] nRightOut_48;
wire [0:0] nEnable;
wire [0:0] ScanEnable;
wire [7:0] ScanLink0;
wire [7:0] ScanLink1;
wire [7:0] ScanLink2;
wire [7:0] ScanLink3;
wire [7:0] ScanLink4;
wire [7:0] ScanLink5;
wire [7:0] ScanLink6;
wire [7:0] ScanLink7;
wire [7:0] ScanLink8;
wire [7:0] ScanLink9;
wire [7:0] ScanLink10;
wire [7:0] ScanLink11;
wire [7:0] ScanLink12;
wire [7:0] ScanLink13;
wire [7:0] ScanLink14;
wire [7:0] ScanLink15;
wire [7:0] ScanLink16;
FFT_Node #( 8, 1, 17, 1 ) node_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_0), .inright(nRightOut_0), .outleft(nLeftOut_0), .outright(nRightOut_0), .ScanIn(ScanLink0), .ScanOut(ScanLink1), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_1), .inright(nRightOut_1), .outleft(nLeftOut_1), .outright(nRightOut_1), .ScanIn(ScanLink1), .ScanOut(ScanLink2), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_2), .inright(nRightOut_2), .outleft(nLeftOut_2), .outright(nRightOut_2), .ScanIn(ScanLink2), .ScanOut(ScanLink3), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_3), .inright(nRightOut_3), .outleft(nLeftOut_3), .outright(nRightOut_3), .ScanIn(ScanLink3), .ScanOut(ScanLink4), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_4), .inright(nRightOut_4), .outleft(nLeftOut_4), .outright(nRightOut_4), .ScanIn(ScanLink4), .ScanOut(ScanLink5), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_5), .inright(nRightOut_5), .outleft(nLeftOut_5), .outright(nRightOut_5), .ScanIn(ScanLink5), .ScanOut(ScanLink6), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_6), .inright(nRightOut_6), .outleft(nLeftOut_6), .outright(nRightOut_6), .ScanIn(ScanLink6), .ScanOut(ScanLink7), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_7), .inright(nRightOut_7), .outleft(nLeftOut_7), .outright(nRightOut_7), .ScanIn(ScanLink7), .ScanOut(ScanLink8), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 0, 1 ) node_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_0), .inright(nRightOut_0), .outleft(nLeftOut_8), .outright(nRightOut_8), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_1), .inright(nRightOut_1), .outleft(nLeftOut_9), .outright(nRightOut_9), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_2), .inright(nRightOut_2), .outleft(nLeftOut_10), .outright(nRightOut_10), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_3), .inright(nRightOut_3), .outleft(nLeftOut_11), .outright(nRightOut_11), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_4), .inright(nRightOut_4), .outleft(nLeftOut_12), .outright(nRightOut_12), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_5), .inright(nRightOut_5), .outleft(nLeftOut_13), .outright(nRightOut_13), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_6), .inright(nRightOut_6), .outleft(nLeftOut_14), .outright(nRightOut_14), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_7), .inright(nRightOut_7), .outleft(nLeftOut_15), .outright(nRightOut_15), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_16 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_8), .inright(nLeftOut_9), .outleft(nLeftOut_16), .outright(nRightOut_16), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 4, 1 ) node_17 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_8), .inright(nRightOut_9), .outleft(nLeftOut_17), .outright(nRightOut_17), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_18 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_10), .inright(nLeftOut_11), .outleft(nLeftOut_18), .outright(nRightOut_18), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 4, 1 ) node_19 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_10), .inright(nRightOut_11), .outleft(nLeftOut_19), .outright(nRightOut_19), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_20 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_12), .inright(nLeftOut_13), .outleft(nLeftOut_20), .outright(nRightOut_20), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 4, 1 ) node_21 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_12), .inright(nRightOut_13), .outleft(nLeftOut_21), .outright(nRightOut_21), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_22 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_14), .inright(nLeftOut_15), .outleft(nLeftOut_22), .outright(nRightOut_22), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 4, 1 ) node_23 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_14), .inright(nRightOut_15), .outleft(nLeftOut_23), .outright(nRightOut_23), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_24 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_16), .inright(nLeftOut_18), .outleft(nLeftOut_24), .outright(nRightOut_24), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 2, 1 ) node_25 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_17), .inright(nLeftOut_19), .outleft(nLeftOut_25), .outright(nRightOut_25), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 4, 1 ) node_26 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_16), .inright(nRightOut_18), .outleft(nLeftOut_26), .outright(nRightOut_26), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 6, 1 ) node_27 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_17), .inright(nRightOut_19), .outleft(nLeftOut_27), .outright(nRightOut_27), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_28 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_20), .inright(nLeftOut_22), .outleft(nLeftOut_28), .outright(nRightOut_28), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 2, 1 ) node_29 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_21), .inright(nLeftOut_23), .outleft(nLeftOut_29), .outright(nRightOut_29), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 4, 1 ) node_30 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_20), .inright(nRightOut_22), .outleft(nLeftOut_30), .outright(nRightOut_30), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 6, 1 ) node_31 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_21), .inright(nRightOut_23), .outleft(nLeftOut_31), .outright(nRightOut_31), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 0, 1 ) node_32 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_24), .inright(nLeftOut_28), .outleft(nLeftOut_32), .outright(nRightOut_32), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 1, 1 ) node_33 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_25), .inright(nLeftOut_29), .outleft(nLeftOut_33), .outright(nRightOut_33), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 2, 1 ) node_34 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_26), .inright(nLeftOut_30), .outleft(nLeftOut_34), .outright(nRightOut_34), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 3, 1 ) node_35 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_27), .inright(nLeftOut_31), .outleft(nLeftOut_35), .outright(nRightOut_35), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 4, 1 ) node_36 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_24), .inright(nRightOut_28), .outleft(nLeftOut_36), .outright(nRightOut_36), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 5, 1 ) node_37 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_25), .inright(nRightOut_29), .outleft(nLeftOut_37), .outright(nRightOut_37), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 6, 1 ) node_38 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_26), .inright(nRightOut_30), .outleft(nLeftOut_38), .outright(nRightOut_38), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 7, 1 ) node_39 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_27), .inright(nRightOut_31), .outleft(nLeftOut_39), .outright(nRightOut_39), .ScanIn(8'd0), .ScanEnable(1'b0) );
FFT_Node #( 8, 1, 17, 1 ) node_40 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_32), .inright(nLeftOut_33), .outleft(nLeftOut_40), .outright(nRightOut_40), .ScanIn(ScanLink8), .ScanOut(ScanLink9), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_41 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_34), .inright(nLeftOut_35), .outleft(nLeftOut_41), .outright(nRightOut_41), .ScanIn(ScanLink9), .ScanOut(ScanLink10), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_42 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_36), .inright(nLeftOut_37), .outleft(nLeftOut_42), .outright(nRightOut_42), .ScanIn(ScanLink10), .ScanOut(ScanLink11), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_43 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_38), .inright(nLeftOut_39), .outleft(nLeftOut_43), .outright(nRightOut_43), .ScanIn(ScanLink11), .ScanOut(ScanLink12), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_44 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_32), .inright(nRightOut_33), .outleft(nLeftOut_44), .outright(nRightOut_44), .ScanIn(ScanLink12), .ScanOut(ScanLink13), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_45 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_34), .inright(nRightOut_35), .outleft(nLeftOut_45), .outright(nRightOut_45), .ScanIn(ScanLink13), .ScanOut(ScanLink14), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_46 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_36), .inright(nRightOut_37), .outleft(nLeftOut_46), .outright(nRightOut_46), .ScanIn(ScanLink14), .ScanOut(ScanLink15), .ScanEnable(ScanEnable) );
FFT_Node #( 8, 1, 17, 1 ) node_47 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_38), .inright(nRightOut_39), .outleft(nLeftOut_47), .outright(nRightOut_47), .ScanIn(ScanLink15), .ScanOut(ScanLink16), .ScanEnable(ScanEnable) );
FFT_Control #( 8, 1, 1 ) node_Control ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .ScanIn(ScanLink16), .ScanOut(ScanLink0), .ScanEnable(ScanEnable), .ScanId(1'd1) );

/*
 *
 * RAW Benchmark Suite main module trailer
 * 
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


endmodule

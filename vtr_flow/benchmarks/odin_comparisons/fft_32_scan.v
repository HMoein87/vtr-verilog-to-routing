

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

wire [16:0] nLeftOut_0;
wire [16:0] nRightOut_0;
wire [16:0] nLeftOut_1;
wire [16:0] nRightOut_1;
wire [16:0] nLeftOut_2;
wire [16:0] nRightOut_2;
wire [16:0] nLeftOut_3;
wire [16:0] nRightOut_3;
wire [16:0] nLeftOut_4;
wire [16:0] nRightOut_4;
wire [16:0] nLeftOut_5;
wire [16:0] nRightOut_5;
wire [16:0] nLeftOut_6;
wire [16:0] nRightOut_6;
wire [16:0] nLeftOut_7;
wire [16:0] nRightOut_7;
wire [16:0] nLeftOut_8;
wire [16:0] nRightOut_8;
wire [16:0] nLeftOut_9;
wire [16:0] nRightOut_9;
wire [16:0] nLeftOut_10;
wire [16:0] nRightOut_10;
wire [16:0] nLeftOut_11;
wire [16:0] nRightOut_11;
wire [16:0] nLeftOut_12;
wire [16:0] nRightOut_12;
wire [16:0] nLeftOut_13;
wire [16:0] nRightOut_13;
wire [16:0] nLeftOut_14;
wire [16:0] nRightOut_14;
wire [16:0] nLeftOut_15;
wire [16:0] nRightOut_15;
wire [16:0] nLeftOut_16;
wire [16:0] nRightOut_16;
wire [16:0] nLeftOut_17;
wire [16:0] nRightOut_17;
wire [16:0] nLeftOut_18;
wire [16:0] nRightOut_18;
wire [16:0] nLeftOut_19;
wire [16:0] nRightOut_19;
wire [16:0] nLeftOut_20;
wire [16:0] nRightOut_20;
wire [16:0] nLeftOut_21;
wire [16:0] nRightOut_21;
wire [16:0] nLeftOut_22;
wire [16:0] nRightOut_22;
wire [16:0] nLeftOut_23;
wire [16:0] nRightOut_23;
wire [16:0] nLeftOut_24;
wire [16:0] nRightOut_24;
wire [16:0] nLeftOut_25;
wire [16:0] nRightOut_25;
wire [16:0] nLeftOut_26;
wire [16:0] nRightOut_26;
wire [16:0] nLeftOut_27;
wire [16:0] nRightOut_27;
wire [16:0] nLeftOut_28;
wire [16:0] nRightOut_28;
wire [16:0] nLeftOut_29;
wire [16:0] nRightOut_29;
wire [16:0] nLeftOut_30;
wire [16:0] nRightOut_30;
wire [16:0] nLeftOut_31;
wire [16:0] nRightOut_31;
wire [16:0] nLeftOut_32;
wire [16:0] nRightOut_32;
wire [16:0] nLeftOut_33;
wire [16:0] nRightOut_33;
wire [16:0] nLeftOut_34;
wire [16:0] nRightOut_34;
wire [16:0] nLeftOut_35;
wire [16:0] nRightOut_35;
wire [16:0] nLeftOut_36;
wire [16:0] nRightOut_36;
wire [16:0] nLeftOut_37;
wire [16:0] nRightOut_37;
wire [16:0] nLeftOut_38;
wire [16:0] nRightOut_38;
wire [16:0] nLeftOut_39;
wire [16:0] nRightOut_39;
wire [16:0] nLeftOut_40;
wire [16:0] nRightOut_40;
wire [16:0] nLeftOut_41;
wire [16:0] nRightOut_41;
wire [16:0] nLeftOut_42;
wire [16:0] nRightOut_42;
wire [16:0] nLeftOut_43;
wire [16:0] nRightOut_43;
wire [16:0] nLeftOut_44;
wire [16:0] nRightOut_44;
wire [16:0] nLeftOut_45;
wire [16:0] nRightOut_45;
wire [16:0] nLeftOut_46;
wire [16:0] nRightOut_46;
wire [16:0] nLeftOut_47;
wire [16:0] nRightOut_47;
wire [16:0] nLeftOut_48;
wire [16:0] nRightOut_48;
wire [16:0] nLeftOut_49;
wire [16:0] nRightOut_49;
wire [16:0] nLeftOut_50;
wire [16:0] nRightOut_50;
wire [16:0] nLeftOut_51;
wire [16:0] nRightOut_51;
wire [16:0] nLeftOut_52;
wire [16:0] nRightOut_52;
wire [16:0] nLeftOut_53;
wire [16:0] nRightOut_53;
wire [16:0] nLeftOut_54;
wire [16:0] nRightOut_54;
wire [16:0] nLeftOut_55;
wire [16:0] nRightOut_55;
wire [16:0] nLeftOut_56;
wire [16:0] nRightOut_56;
wire [16:0] nLeftOut_57;
wire [16:0] nRightOut_57;
wire [16:0] nLeftOut_58;
wire [16:0] nRightOut_58;
wire [16:0] nLeftOut_59;
wire [16:0] nRightOut_59;
wire [16:0] nLeftOut_60;
wire [16:0] nRightOut_60;
wire [16:0] nLeftOut_61;
wire [16:0] nRightOut_61;
wire [16:0] nLeftOut_62;
wire [16:0] nRightOut_62;
wire [16:0] nLeftOut_63;
wire [16:0] nRightOut_63;
wire [16:0] nLeftOut_64;
wire [16:0] nRightOut_64;
wire [16:0] nLeftOut_65;
wire [16:0] nRightOut_65;
wire [16:0] nLeftOut_66;
wire [16:0] nRightOut_66;
wire [16:0] nLeftOut_67;
wire [16:0] nRightOut_67;
wire [16:0] nLeftOut_68;
wire [16:0] nRightOut_68;
wire [16:0] nLeftOut_69;
wire [16:0] nRightOut_69;
wire [16:0] nLeftOut_70;
wire [16:0] nRightOut_70;
wire [16:0] nLeftOut_71;
wire [16:0] nRightOut_71;
wire [16:0] nLeftOut_72;
wire [16:0] nRightOut_72;
wire [16:0] nLeftOut_73;
wire [16:0] nRightOut_73;
wire [16:0] nLeftOut_74;
wire [16:0] nRightOut_74;
wire [16:0] nLeftOut_75;
wire [16:0] nRightOut_75;
wire [16:0] nLeftOut_76;
wire [16:0] nRightOut_76;
wire [16:0] nLeftOut_77;
wire [16:0] nRightOut_77;
wire [16:0] nLeftOut_78;
wire [16:0] nRightOut_78;
wire [16:0] nLeftOut_79;
wire [16:0] nRightOut_79;
wire [16:0] nLeftOut_80;
wire [16:0] nRightOut_80;
wire [16:0] nLeftOut_81;
wire [16:0] nRightOut_81;
wire [16:0] nLeftOut_82;
wire [16:0] nRightOut_82;
wire [16:0] nLeftOut_83;
wire [16:0] nRightOut_83;
wire [16:0] nLeftOut_84;
wire [16:0] nRightOut_84;
wire [16:0] nLeftOut_85;
wire [16:0] nRightOut_85;
wire [16:0] nLeftOut_86;
wire [16:0] nRightOut_86;
wire [16:0] nLeftOut_87;
wire [16:0] nRightOut_87;
wire [16:0] nLeftOut_88;
wire [16:0] nRightOut_88;
wire [16:0] nLeftOut_89;
wire [16:0] nRightOut_89;
wire [16:0] nLeftOut_90;
wire [16:0] nRightOut_90;
wire [16:0] nLeftOut_91;
wire [16:0] nRightOut_91;
wire [16:0] nLeftOut_92;
wire [16:0] nRightOut_92;
wire [16:0] nLeftOut_93;
wire [16:0] nRightOut_93;
wire [16:0] nLeftOut_94;
wire [16:0] nRightOut_94;
wire [16:0] nLeftOut_95;
wire [16:0] nRightOut_95;
wire [16:0] nLeftOut_96;
wire [16:0] nRightOut_96;
wire [16:0] nLeftOut_97;
wire [16:0] nRightOut_97;
wire [16:0] nLeftOut_98;
wire [16:0] nRightOut_98;
wire [16:0] nLeftOut_99;
wire [16:0] nRightOut_99;
wire [16:0] nLeftOut_100;
wire [16:0] nRightOut_100;
wire [16:0] nLeftOut_101;
wire [16:0] nRightOut_101;
wire [16:0] nLeftOut_102;
wire [16:0] nRightOut_102;
wire [16:0] nLeftOut_103;
wire [16:0] nRightOut_103;
wire [16:0] nLeftOut_104;
wire [16:0] nRightOut_104;
wire [16:0] nLeftOut_105;
wire [16:0] nRightOut_105;
wire [16:0] nLeftOut_106;
wire [16:0] nRightOut_106;
wire [16:0] nLeftOut_107;
wire [16:0] nRightOut_107;
wire [16:0] nLeftOut_108;
wire [16:0] nRightOut_108;
wire [16:0] nLeftOut_109;
wire [16:0] nRightOut_109;
wire [16:0] nLeftOut_110;
wire [16:0] nRightOut_110;
wire [16:0] nLeftOut_111;
wire [16:0] nRightOut_111;
wire [16:0] nLeftOut_112;
wire [16:0] nRightOut_112;
wire [0:0] nEnable;
wire [0:0] ScanEnable;
wire [15:0] ScanLink0;
wire [15:0] ScanLink1;
wire [15:0] ScanLink2;
wire [15:0] ScanLink3;
wire [15:0] ScanLink4;
wire [15:0] ScanLink5;
wire [15:0] ScanLink6;
wire [15:0] ScanLink7;
wire [15:0] ScanLink8;
wire [15:0] ScanLink9;
wire [15:0] ScanLink10;
wire [15:0] ScanLink11;
wire [15:0] ScanLink12;
wire [15:0] ScanLink13;
wire [15:0] ScanLink14;
wire [15:0] ScanLink15;
wire [15:0] ScanLink16;
wire [15:0] ScanLink17;
wire [15:0] ScanLink18;
wire [15:0] ScanLink19;
wire [15:0] ScanLink20;
wire [15:0] ScanLink21;
wire [15:0] ScanLink22;
wire [15:0] ScanLink23;
wire [15:0] ScanLink24;
wire [15:0] ScanLink25;
wire [15:0] ScanLink26;
wire [15:0] ScanLink27;
wire [15:0] ScanLink28;
wire [15:0] ScanLink29;
wire [15:0] ScanLink30;
wire [15:0] ScanLink31;
wire [15:0] ScanLink32;
FFT_Node #( 16, 1, 33, 1 ) node_0 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_0), .inright(nRightOut_0), .outleft(nLeftOut_0), .outright(nRightOut_0), .ScanIn(ScanLink0), .ScanOut(ScanLink1), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_1 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_1), .inright(nRightOut_1), .outleft(nLeftOut_1), .outright(nRightOut_1), .ScanIn(ScanLink1), .ScanOut(ScanLink2), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_2 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_2), .inright(nRightOut_2), .outleft(nLeftOut_2), .outright(nRightOut_2), .ScanIn(ScanLink2), .ScanOut(ScanLink3), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_3 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_3), .inright(nRightOut_3), .outleft(nLeftOut_3), .outright(nRightOut_3), .ScanIn(ScanLink3), .ScanOut(ScanLink4), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_4 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_4), .inright(nRightOut_4), .outleft(nLeftOut_4), .outright(nRightOut_4), .ScanIn(ScanLink4), .ScanOut(ScanLink5), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_5 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_5), .inright(nRightOut_5), .outleft(nLeftOut_5), .outright(nRightOut_5), .ScanIn(ScanLink5), .ScanOut(ScanLink6), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_6 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_6), .inright(nRightOut_6), .outleft(nLeftOut_6), .outright(nRightOut_6), .ScanIn(ScanLink6), .ScanOut(ScanLink7), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_7 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_7), .inright(nRightOut_7), .outleft(nLeftOut_7), .outright(nRightOut_7), .ScanIn(ScanLink7), .ScanOut(ScanLink8), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_8 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_8), .inright(nRightOut_8), .outleft(nLeftOut_8), .outright(nRightOut_8), .ScanIn(ScanLink8), .ScanOut(ScanLink9), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_9 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_9), .inright(nRightOut_9), .outleft(nLeftOut_9), .outright(nRightOut_9), .ScanIn(ScanLink9), .ScanOut(ScanLink10), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_10 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_10), .inright(nRightOut_10), .outleft(nLeftOut_10), .outright(nRightOut_10), .ScanIn(ScanLink10), .ScanOut(ScanLink11), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_11 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_11), .inright(nRightOut_11), .outleft(nLeftOut_11), .outright(nRightOut_11), .ScanIn(ScanLink11), .ScanOut(ScanLink12), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_12 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_12), .inright(nRightOut_12), .outleft(nLeftOut_12), .outright(nRightOut_12), .ScanIn(ScanLink12), .ScanOut(ScanLink13), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_13 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_13), .inright(nRightOut_13), .outleft(nLeftOut_13), .outright(nRightOut_13), .ScanIn(ScanLink13), .ScanOut(ScanLink14), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_14 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_14), .inright(nRightOut_14), .outleft(nLeftOut_14), .outright(nRightOut_14), .ScanIn(ScanLink14), .ScanOut(ScanLink15), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_15 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_15), .inright(nRightOut_15), .outleft(nLeftOut_15), .outright(nRightOut_15), .ScanIn(ScanLink15), .ScanOut(ScanLink16), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 0, 1 ) node_16 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_0), .inright(nRightOut_0), .outleft(nLeftOut_16), .outright(nRightOut_16), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_17 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_1), .inright(nRightOut_1), .outleft(nLeftOut_17), .outright(nRightOut_17), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_18 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_2), .inright(nRightOut_2), .outleft(nLeftOut_18), .outright(nRightOut_18), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_19 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_3), .inright(nRightOut_3), .outleft(nLeftOut_19), .outright(nRightOut_19), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_20 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_4), .inright(nRightOut_4), .outleft(nLeftOut_20), .outright(nRightOut_20), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_21 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_5), .inright(nRightOut_5), .outleft(nLeftOut_21), .outright(nRightOut_21), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_22 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_6), .inright(nRightOut_6), .outleft(nLeftOut_22), .outright(nRightOut_22), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_23 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_7), .inright(nRightOut_7), .outleft(nLeftOut_23), .outright(nRightOut_23), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_24 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_8), .inright(nRightOut_8), .outleft(nLeftOut_24), .outright(nRightOut_24), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_25 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_9), .inright(nRightOut_9), .outleft(nLeftOut_25), .outright(nRightOut_25), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_26 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_10), .inright(nRightOut_10), .outleft(nLeftOut_26), .outright(nRightOut_26), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_27 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_11), .inright(nRightOut_11), .outleft(nLeftOut_27), .outright(nRightOut_27), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_28 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_12), .inright(nRightOut_12), .outleft(nLeftOut_28), .outright(nRightOut_28), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_29 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_13), .inright(nRightOut_13), .outleft(nLeftOut_29), .outright(nRightOut_29), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_30 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_14), .inright(nRightOut_14), .outleft(nLeftOut_30), .outright(nRightOut_30), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_31 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_15), .inright(nRightOut_15), .outleft(nLeftOut_31), .outright(nRightOut_31), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_32 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_16), .inright(nLeftOut_17), .outleft(nLeftOut_32), .outright(nRightOut_32), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_33 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_16), .inright(nRightOut_17), .outleft(nLeftOut_33), .outright(nRightOut_33), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_34 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_18), .inright(nLeftOut_19), .outleft(nLeftOut_34), .outright(nRightOut_34), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_35 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_18), .inright(nRightOut_19), .outleft(nLeftOut_35), .outright(nRightOut_35), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_36 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_20), .inright(nLeftOut_21), .outleft(nLeftOut_36), .outright(nRightOut_36), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_37 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_20), .inright(nRightOut_21), .outleft(nLeftOut_37), .outright(nRightOut_37), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_38 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_22), .inright(nLeftOut_23), .outleft(nLeftOut_38), .outright(nRightOut_38), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_39 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_22), .inright(nRightOut_23), .outleft(nLeftOut_39), .outright(nRightOut_39), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_40 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_24), .inright(nLeftOut_25), .outleft(nLeftOut_40), .outright(nRightOut_40), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_41 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_24), .inright(nRightOut_25), .outleft(nLeftOut_41), .outright(nRightOut_41), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_42 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_26), .inright(nLeftOut_27), .outleft(nLeftOut_42), .outright(nRightOut_42), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_43 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_26), .inright(nRightOut_27), .outleft(nLeftOut_43), .outright(nRightOut_43), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_44 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_28), .inright(nLeftOut_29), .outleft(nLeftOut_44), .outright(nRightOut_44), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_45 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_28), .inright(nRightOut_29), .outleft(nLeftOut_45), .outright(nRightOut_45), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_46 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_30), .inright(nLeftOut_31), .outleft(nLeftOut_46), .outright(nRightOut_46), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_47 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_30), .inright(nRightOut_31), .outleft(nLeftOut_47), .outright(nRightOut_47), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_48 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_32), .inright(nLeftOut_34), .outleft(nLeftOut_48), .outright(nRightOut_48), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 4, 1 ) node_49 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_33), .inright(nLeftOut_35), .outleft(nLeftOut_49), .outright(nRightOut_49), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_50 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_32), .inright(nRightOut_34), .outleft(nLeftOut_50), .outright(nRightOut_50), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 12, 1 ) node_51 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_33), .inright(nRightOut_35), .outleft(nLeftOut_51), .outright(nRightOut_51), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_52 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_36), .inright(nLeftOut_38), .outleft(nLeftOut_52), .outright(nRightOut_52), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 4, 1 ) node_53 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_37), .inright(nLeftOut_39), .outleft(nLeftOut_53), .outright(nRightOut_53), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_54 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_36), .inright(nRightOut_38), .outleft(nLeftOut_54), .outright(nRightOut_54), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 12, 1 ) node_55 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_37), .inright(nRightOut_39), .outleft(nLeftOut_55), .outright(nRightOut_55), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_56 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_40), .inright(nLeftOut_42), .outleft(nLeftOut_56), .outright(nRightOut_56), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 4, 1 ) node_57 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_41), .inright(nLeftOut_43), .outleft(nLeftOut_57), .outright(nRightOut_57), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_58 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_40), .inright(nRightOut_42), .outleft(nLeftOut_58), .outright(nRightOut_58), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 12, 1 ) node_59 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_41), .inright(nRightOut_43), .outleft(nLeftOut_59), .outright(nRightOut_59), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_60 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_44), .inright(nLeftOut_46), .outleft(nLeftOut_60), .outright(nRightOut_60), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 4, 1 ) node_61 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_45), .inright(nLeftOut_47), .outleft(nLeftOut_61), .outright(nRightOut_61), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_62 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_44), .inright(nRightOut_46), .outleft(nLeftOut_62), .outright(nRightOut_62), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 12, 1 ) node_63 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_45), .inright(nRightOut_47), .outleft(nLeftOut_63), .outright(nRightOut_63), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_64 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_48), .inright(nLeftOut_52), .outleft(nLeftOut_64), .outright(nRightOut_64), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 2, 1 ) node_65 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_49), .inright(nLeftOut_53), .outleft(nLeftOut_65), .outright(nRightOut_65), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 4, 1 ) node_66 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_50), .inright(nLeftOut_54), .outleft(nLeftOut_66), .outright(nRightOut_66), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 6, 1 ) node_67 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_51), .inright(nLeftOut_55), .outleft(nLeftOut_67), .outright(nRightOut_67), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_68 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_48), .inright(nRightOut_52), .outleft(nLeftOut_68), .outright(nRightOut_68), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 10, 1 ) node_69 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_49), .inright(nRightOut_53), .outleft(nLeftOut_69), .outright(nRightOut_69), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 12, 1 ) node_70 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_50), .inright(nRightOut_54), .outleft(nLeftOut_70), .outright(nRightOut_70), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 14, 1 ) node_71 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_51), .inright(nRightOut_55), .outleft(nLeftOut_71), .outright(nRightOut_71), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_72 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_56), .inright(nLeftOut_60), .outleft(nLeftOut_72), .outright(nRightOut_72), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 2, 1 ) node_73 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_57), .inright(nLeftOut_61), .outleft(nLeftOut_73), .outright(nRightOut_73), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 4, 1 ) node_74 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_58), .inright(nLeftOut_62), .outleft(nLeftOut_74), .outright(nRightOut_74), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 6, 1 ) node_75 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_59), .inright(nLeftOut_63), .outleft(nLeftOut_75), .outright(nRightOut_75), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_76 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_56), .inright(nRightOut_60), .outleft(nLeftOut_76), .outright(nRightOut_76), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 10, 1 ) node_77 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_57), .inright(nRightOut_61), .outleft(nLeftOut_77), .outright(nRightOut_77), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 12, 1 ) node_78 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_58), .inright(nRightOut_62), .outleft(nLeftOut_78), .outright(nRightOut_78), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 14, 1 ) node_79 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_59), .inright(nRightOut_63), .outleft(nLeftOut_79), .outright(nRightOut_79), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 0, 1 ) node_80 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_64), .inright(nLeftOut_72), .outleft(nLeftOut_80), .outright(nRightOut_80), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 1, 1 ) node_81 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_65), .inright(nLeftOut_73), .outleft(nLeftOut_81), .outright(nRightOut_81), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 2, 1 ) node_82 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_66), .inright(nLeftOut_74), .outleft(nLeftOut_82), .outright(nRightOut_82), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 3, 1 ) node_83 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_67), .inright(nLeftOut_75), .outleft(nLeftOut_83), .outright(nRightOut_83), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 4, 1 ) node_84 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_68), .inright(nLeftOut_76), .outleft(nLeftOut_84), .outright(nRightOut_84), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 5, 1 ) node_85 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_69), .inright(nLeftOut_77), .outleft(nLeftOut_85), .outright(nRightOut_85), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 6, 1 ) node_86 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_70), .inright(nLeftOut_78), .outleft(nLeftOut_86), .outright(nRightOut_86), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 7, 1 ) node_87 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_71), .inright(nLeftOut_79), .outleft(nLeftOut_87), .outright(nRightOut_87), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 8, 1 ) node_88 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_64), .inright(nRightOut_72), .outleft(nLeftOut_88), .outright(nRightOut_88), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 9, 1 ) node_89 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_65), .inright(nRightOut_73), .outleft(nLeftOut_89), .outright(nRightOut_89), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 10, 1 ) node_90 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_66), .inright(nRightOut_74), .outleft(nLeftOut_90), .outright(nRightOut_90), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 11, 1 ) node_91 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_67), .inright(nRightOut_75), .outleft(nLeftOut_91), .outright(nRightOut_91), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 12, 1 ) node_92 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_68), .inright(nRightOut_76), .outleft(nLeftOut_92), .outright(nRightOut_92), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 13, 1 ) node_93 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_69), .inright(nRightOut_77), .outleft(nLeftOut_93), .outright(nRightOut_93), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 14, 1 ) node_94 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_70), .inright(nRightOut_78), .outleft(nLeftOut_94), .outright(nRightOut_94), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 15, 1 ) node_95 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_71), .inright(nRightOut_79), .outleft(nLeftOut_95), .outright(nRightOut_95), .ScanIn(16'd0), .ScanEnable(1'b0) );
FFT_Node #( 16, 1, 33, 1 ) node_96 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_80), .inright(nLeftOut_81), .outleft(nLeftOut_96), .outright(nRightOut_96), .ScanIn(ScanLink16), .ScanOut(ScanLink17), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_97 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_82), .inright(nLeftOut_83), .outleft(nLeftOut_97), .outright(nRightOut_97), .ScanIn(ScanLink17), .ScanOut(ScanLink18), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_98 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_84), .inright(nLeftOut_85), .outleft(nLeftOut_98), .outright(nRightOut_98), .ScanIn(ScanLink18), .ScanOut(ScanLink19), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_99 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_86), .inright(nLeftOut_87), .outleft(nLeftOut_99), .outright(nRightOut_99), .ScanIn(ScanLink19), .ScanOut(ScanLink20), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_100 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_88), .inright(nLeftOut_89), .outleft(nLeftOut_100), .outright(nRightOut_100), .ScanIn(ScanLink20), .ScanOut(ScanLink21), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_101 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_90), .inright(nLeftOut_91), .outleft(nLeftOut_101), .outright(nRightOut_101), .ScanIn(ScanLink21), .ScanOut(ScanLink22), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_102 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_92), .inright(nLeftOut_93), .outleft(nLeftOut_102), .outright(nRightOut_102), .ScanIn(ScanLink22), .ScanOut(ScanLink23), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_103 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nLeftOut_94), .inright(nLeftOut_95), .outleft(nLeftOut_103), .outright(nRightOut_103), .ScanIn(ScanLink23), .ScanOut(ScanLink24), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_104 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_80), .inright(nRightOut_81), .outleft(nLeftOut_104), .outright(nRightOut_104), .ScanIn(ScanLink24), .ScanOut(ScanLink25), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_105 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_82), .inright(nRightOut_83), .outleft(nLeftOut_105), .outright(nRightOut_105), .ScanIn(ScanLink25), .ScanOut(ScanLink26), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_106 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_84), .inright(nRightOut_85), .outleft(nLeftOut_106), .outright(nRightOut_106), .ScanIn(ScanLink26), .ScanOut(ScanLink27), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_107 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_86), .inright(nRightOut_87), .outleft(nLeftOut_107), .outright(nRightOut_107), .ScanIn(ScanLink27), .ScanOut(ScanLink28), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_108 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_88), .inright(nRightOut_89), .outleft(nLeftOut_108), .outright(nRightOut_108), .ScanIn(ScanLink28), .ScanOut(ScanLink29), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_109 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_90), .inright(nRightOut_91), .outleft(nLeftOut_109), .outright(nRightOut_109), .ScanIn(ScanLink29), .ScanOut(ScanLink30), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_110 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_92), .inright(nRightOut_93), .outleft(nLeftOut_110), .outright(nRightOut_110), .ScanIn(ScanLink30), .ScanOut(ScanLink31), .ScanEnable(ScanEnable) );
FFT_Node #( 16, 1, 33, 1 ) node_111 ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Idl(1'd0), .Idr(1'd0), .Ids(1'd0), .Enable(nEnable), .inleft(nRightOut_94), .inright(nRightOut_95), .outleft(nLeftOut_111), .outright(nRightOut_111), .ScanIn(ScanLink31), .ScanOut(ScanLink32), .ScanEnable(ScanEnable) );
FFT_Control #( 16, 1, 1 ) node_Control ( .Clk(Clk), .Reset(Reset), .RD(RD), .WR(WR), .Addr(Addr), .DataIn(DataIn), .DataOut(DataOut), .Id(1'd0), .Enable(nEnable), .ScanIn(ScanLink32), .ScanOut(ScanLink0), .ScanEnable(ScanEnable), .ScanId(1'd1) );

/*
 *
 * RAW Benchmark Suite main module trailer
 * 
 * Authors: Jonathan Babb           (jbabb@lcs.mit.edu)
 *
 * Copyright @ 1997 MIT Laboratory for Computer Science, Cambridge, MA 02129
 */


endmodule

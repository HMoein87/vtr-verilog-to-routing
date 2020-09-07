
/*
*DDR3 Simple Synthesizable Memory BFM
*2010-2011 sclai <laikos@yahoo.com>
*
*This library is free software; you can redistribute it and/or modify it
* under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation; either version 2.1 of the License,
* or (at your option) any later version.
*
* This library is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this library; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
* USA
*
*
*  Simple implementation of DDR3 Memory
*  will only reponse to write and read request
*  parameter
*  count start from t0,t2,t2...
*  ck _|-|_|-|_|-|_|-|_
*
*  cs#---|___|---------
*
*        |   |    |
*        t0  t1  t2 ....
*
*
*/

`timescale 1ps / 1ps

module ddr3_simple4#(
parameter MEM_DQ_WIDTH 		=8,
parameter MEM_BA_WIDTH 		=3,
parameter MEM_ROW_WIDTH 	=13,
parameter MEM_COL_WIDTH		=13,
parameter AL		=3,
parameter CWL		=5, //CWL
parameter CL		=5  //CL=6 -> pass
)(
input wire [MEM_ROW_WIDTH-1:0]	a,
input wire [ MEM_BA_WIDTH-1:0]	ba,
input wire			ck,
input wire 			ck_n,
input wire 			cke,
input wire			cs_n,
input wire			dm,
input wire			ras_n,
input wire			cas_n,
input wire			we_n,
input wire			reset_n,
inout wire [MEM_DQ_WIDTH-1:0]	dq,
inout wire			dqs,
inout wire			dqs_n,
input wire			odt
);

//convert actual CL and CWL parameter to
localparam  MEM_CWL=CWL+AL;
localparam  MEM_CL =CL+AL;

//definitions
localparam	OPCODE_PRECHARGE = 4'b0010;
localparam	OPCODE_ACTIVATE  = 4'b0011;
localparam	OPCODE_WRITE 	 = 4'b0100;
localparam	OPCODE_READ 	 = 4'b0101;
localparam	OPCODE_MRS 	 = 4'b0000;
localparam	OPCODE_REFRESH 	 = 4'b0001;
localparam	OPCODE_DES 	 = 4'b1000;
localparam	OPCODE_ZQC 	 = 4'b0110;
localparam	OPCODE_NOP 	 = 4'b0111;

//mode registers
reg [31:0] mr0;
reg [31:0] mr2;
reg [31:0] mr3;


wire [35:0] write_add;
wire [35:0] read_add;
wire [3:0]  write_cmd;
wire [3:0]  read_cmd;
wire [(MEM_DQ_WIDTH*2)-1:0] read_data;

reg [ 2:0] last_bank;
reg [15:0] last_row;
reg [3:0] last_write_cmd;
reg [3:0] last_read_cmd;
reg [35:0] last_write_add;
reg [35:0] last_read_add;

reg        write_address12;
reg        read_address12;

//bank tracker
reg [MEM_ROW_WIDTH-1:0]opened_row[(2**MEM_BA_WIDTH)-1:0];
//row  tracker

wire [MEM_DQ_WIDTH-1:0]  dq_out;
reg  [MEM_DQ_WIDTH-1:0]  dq_in0;

wire [MEM_DQ_WIDTH-1:0] data_hi;
wire [MEM_DQ_WIDTH-1:0] data_lo;
wire			  data_hi_dm;
wire 		  data_lo_dm;
//IDDR
my_iddrx8 iddrx8_inst(
	.clk(ck),
	.io(dq),
	.d0(data_lo),
	.d1(data_hi)
);

my_iddrx8 iddrx8_dm_inst(
	.clk(ck),
	.io(dm),
	.d0(data_lo_dm),
	.d1(data_hi_dm)
);

//ODDR
my_oddrx8 oddrx8_inst(
.clk(ck),
.d0(read_data[ MEM_DQ_WIDTH-1:0              ]),
.d1(read_data[(MEM_DQ_WIDTH*2)-1:MEM_DQ_WIDTH]),
.io(dq_out)
);

//double data rate
always @(posedge ck )
begin
if(reset_n==1'b0)
	begin
		last_bank     <=4'h0;
		last_row      <=16'h0000;
	end
else
begin
	case({cs_n,ras_n,cas_n,we_n})
	/*
	OPCODE_PRECHARGE	:begin
					$display("t=%d,PRECHARGE",vip_clk);
				end
	*/
	OPCODE_ACTIVATE  	:begin
					opened_row [ba] <={{(16-MEM_ROW_WIDTH){1'b0}},a[MEM_ROW_WIDTH-1:0]};
				end
	/*
	OPCODE_DES		:begin
					$display("t=%d,DES",vip_clk);
				end
	OPCODE_MRS  		:begin
					$display("t=%d,MRS",vip_clk);
				end
	OPCODE_NOP  		:begin
					//$display("t=%d,NOP",vip_clk);
				end
	*/
	OPCODE_READ  		:begin
	                case(ba)
	                3'h0:begin
					last_read_add 	<={ba,opened_row[0],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
	                3'h1:begin
					last_read_add 	<={ba,opened_row[1],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
	                3'h2:begin
					last_read_add 	<={ba,opened_row[2],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
	                3'h3:begin
					last_read_add 	<={ba,opened_row[3],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
	                3'h4:begin
					last_read_add 	<={ba,opened_row[4],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
	                3'h5:begin
					last_read_add 	<={ba,opened_row[5],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
	                3'h6:begin
					last_read_add 	<={ba,opened_row[6],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
	                3'h7:begin
					last_read_add 	<={ba,opened_row[7],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
					end
					endcase

					last_read_cmd 	<=OPCODE_READ;
				end
	OPCODE_WRITE  		:begin
		                case(ba)
    	                3'h0:begin
    					last_write_add 	<={ba,opened_row[0],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    	                3'h1:begin
    					last_write_add 	<={ba,opened_row[1],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    	                3'h2:begin
    					last_write_add 	<={ba,opened_row[2],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    	                3'h3:begin
    					last_write_add 	<={ba,opened_row[3],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    	                3'h4:begin
    					last_write_add 	<={ba,opened_row[4],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    	                3'h5:begin
    					last_write_add 	<={ba,opened_row[5],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    	                3'h6:begin
    					last_write_add 	<={ba,opened_row[6],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    	                3'h7:begin
    					last_write_add 	<={ba,opened_row[7],{{(16-MEM_COL_WIDTH){1'b0}},a[MEM_COL_WIDTH-1:0]}};
    					end
    					endcase
					last_write_cmd  <=OPCODE_WRITE;
				end
							/*
	OPCODE_ZQC		:begin
				$display("t=%d,ZQC",vip_clk);
					end*/
		default:begin
				last_read_cmd 	<=OPCODE_NOP;
				last_write_cmd <=OPCODE_NOP;
			end
	endcase
end // end reset
end // end always@(*)



//cmd
//read
ddr3_sr4 #(
.PIPE_LEN(MEM_CL)
)ddr3_read_cmd_sr(
	.clk(ck),
	.shift_in(last_read_cmd),
	.shift_out(read_cmd)
);
//bank, row, col
ddr3_sr36 #(
.PIPE_LEN(MEM_CL+1)
)ddr3_read_add_sr(
	.clk(ck),
	.shift_in(last_read_add),
	.shift_out(read_add)
);

//cmd
//write
ddr3_sr4#(
.PIPE_LEN(MEM_CWL)
)ddr3_write_cmd_sr(
	.clk(ck),
	.shift_in(last_write_cmd),
	.shift_out(write_cmd)
);

//bank, row, col
ddr3_sr36#(
.PIPE_LEN(MEM_CWL+1) //have to be a cycle late to wait for IDDR latency
) ddr3_write_add_sr(
	.clk(ck),
	.shift_in(last_write_add),
	.shift_out(write_add)
);


//write fsm
localparam WR_D0	=4'd0;
localparam WR_D1	=4'd1;
localparam WR_D2	=4'd2;
localparam WR_D3	=4'd3;
localparam WR_IDLE	=4'd5;
reg [3:0] write_state;
reg 		 mem_we;
reg [2:0] write_col;
always@(posedge ck)
begin
	if(reset_n==1'b0)
		begin
			write_state<=WR_IDLE;
			mem_we<=1'b0;
			write_col<=0;
		end
	else
		begin
		case(write_state)
			WR_IDLE:begin
			write_col<=0;
			if(write_cmd==OPCODE_WRITE)
				begin
					write_state<=WR_D0;
					mem_we<=1'b1;
				end
			else
				begin
					write_state<=WR_IDLE;
					mem_we<=1'b0;
				end
			end
			WR_D0:begin
				write_address12<=write_add[12];
				write_state<=WR_D1;
				write_col<=write_col+1'b1;
			end
			WR_D1:begin
				if(write_address12==1'b1)
					begin
						write_state<=WR_D2;
						write_col<=write_col+1'b1;
					end
				else if (write_cmd==OPCODE_WRITE)
					begin
						write_state<=WR_D0;
						write_col<=0;
					end
				else
					begin
						write_state<=WR_IDLE;
						mem_we<=1'b0;
					end
			end
			WR_D2:begin
				write_state<=WR_D3;
				write_col<=write_col+1'b1;
			end
			WR_D3:begin
				//write_col<=write_col+1'b1;
				if (write_cmd==OPCODE_WRITE)
					begin
						write_state<=WR_D0;
						write_col<=0;
					end
				else
					begin
						write_state<=WR_IDLE;
						mem_we<=1'b0;
					end
			end
		endcase
		end //endif
end


//read fsm
localparam RD_D0	=4'd0;
localparam RD_D1	=4'd1;
localparam RD_D2	=4'd2;
localparam RD_D3  	=4'd3;
localparam RD_IDLE	=4'd5;

reg [3:0] read_state;
reg [2:0] read_col;
reg		 send_dq;
reg		 send_dqs0;
reg		 send_dqs1;

always@(posedge ck)
begin
	if(reset_n==1'b0)
		begin
			read_state<=RD_IDLE;
			read_col	 <=0;
			send_dq	 <=0;
		end
	else
		begin
			case(read_state)
			RD_IDLE:begin
			read_col<=0;
			send_dq<=0;
			if(read_cmd==OPCODE_READ)
				begin
					read_state<=RD_D0;
				end
			else
				begin
					read_state<=RD_IDLE;
				end
			end
			RD_D0:begin
				read_address12<=read_add[12];
				read_state<=RD_D1;
				read_col<=read_col+1'b1;
				send_dq	 <=1'b1;
			end
			RD_D1:begin
				if(read_address12==1'b1)
					begin
						read_state<=RD_D2;
						read_col<=read_col+1'b1;
					end
				else if (read_cmd==OPCODE_READ)
					begin
						read_state<=RD_D0;
						read_col<=0;
						send_dq	 <=1'b1;
					end
				else
					begin
						read_state<=RD_IDLE;
						//send_dq	 <=1'b0;
					end
			end
			RD_D2:begin
				read_state<=RD_D3;
				read_col<=read_col+1'b1;
				send_dq	 <=1'b1;
			end
			RD_D3:begin
				//write_col<=write_col+1'b1;
				if (read_cmd==OPCODE_READ)
					begin
						read_state<=RD_D0;
						read_col<=0;
						send_dq	 <=1'b1;
					end
				else
					begin
						read_state<=RD_IDLE;
						read_col<=0;
						//send_dq	 <=1'b0;
					end
			end
			endcase
		end

end //end always

//dqs fsm
always @(posedge ck_n)
begin
if(reset_n==1'b0)
	begin
		send_dqs1<=0;
		send_dqs0<=0;
	end
else
	begin
		if(read_cmd==OPCODE_READ)
			begin
				send_dqs1<=1'b1;
			end
		else
			begin
				send_dqs1<=1'b0;
			end
	end
send_dqs0<=send_dqs1;
end//end always

wire we_lo = mem_we & data_lo_dm;
wire we_hi = mem_we & data_hi_dm;
wire[35:0] read_addr = read_add+read_col;
wire[35:0] write_addr = write_add+write_col;
//ram here
dport_ram  #(
	.DATA_WIDTH(MEM_DQ_WIDTH), //data_hi,data_lo
	.ADDR_WIDTH(36)
)dport_ram_hi(
	.clk			(ck),
	.di			(data_hi),
	.read_addr	(read_addr),
	.write_addr (write_addr),
	.we			(we_hi),
	.do			(read_data[15:8])
);

dport_ram  #(
	.DATA_WIDTH(MEM_DQ_WIDTH), //data_hi,data_lo
	.ADDR_WIDTH(36)
)dport_ram_lo(
	.clk			(ck),
	.di			(data_lo),
	.read_addr	(read_addr),
	.write_addr (write_addr),
	.we			(we_lo),
	.do			(read_data[7:0])
);
assign dqs  =((send_dqs0==1'b1) || (send_dq==1'b1))?ck:1'bz;
assign dqs_n=((send_dqs0==1'b1) || (send_dq==1'b1))?ck_n:1'bz;
assign dq   = (send_dq==1'b1)?dq_out:8'hZZ;

endmodule

/*
Multibits Shift Register
2010-2011 sclai <laikos@yahoo.com>

This library is free software; you can redistribute it and/or modify it
 under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation; either version 2.1 of the License,
 or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 USA
*/
module ddr3_sr36 #(
parameter PIPE_LEN=7
)(
input wire        clk,
input wire [35:0] shift_in,
output wire [35:0]shift_out
);
//register to hold value
reg [PIPE_LEN-1:0] d0;
reg [PIPE_LEN-1:0] d1;
reg [PIPE_LEN-1:0] d2;
reg [PIPE_LEN-1:0] d3;
reg [PIPE_LEN-1:0] d4;
reg [PIPE_LEN-1:0] d5;
reg [PIPE_LEN-1:0] d6;
reg [PIPE_LEN-1:0] d7;
reg [PIPE_LEN-1:0] d8;
reg [PIPE_LEN-1:0] d9;
reg [PIPE_LEN-1:0] d10;
reg [PIPE_LEN-1:0] d11;
reg [PIPE_LEN-1:0] d12;
reg [PIPE_LEN-1:0] d13;
reg [PIPE_LEN-1:0] d14;
reg [PIPE_LEN-1:0] d15;
reg [PIPE_LEN-1:0] d16;
reg [PIPE_LEN-1:0] d17;
reg [PIPE_LEN-1:0] d18;
reg [PIPE_LEN-1:0] d19;
reg [PIPE_LEN-1:0] d20;
reg [PIPE_LEN-1:0] d21;
reg [PIPE_LEN-1:0] d22;
reg [PIPE_LEN-1:0] d23;
reg [PIPE_LEN-1:0] d24;
reg [PIPE_LEN-1:0] d25;
reg [PIPE_LEN-1:0] d26;
reg [PIPE_LEN-1:0] d27;
reg [PIPE_LEN-1:0] d28;
reg [PIPE_LEN-1:0] d29;
reg [PIPE_LEN-1:0] d30;
reg [PIPE_LEN-1:0] d31;
reg [PIPE_LEN-1:0] d32;
reg [PIPE_LEN-1:0] d33;
reg [PIPE_LEN-1:0] d34;
reg [PIPE_LEN-1:0] d35;
always @(posedge clk)
begin
  d35 <={shift_in[35],d35[PIPE_LEN-1:1]};
  d34 <={shift_in[34],d34[PIPE_LEN-1:1]};
  d33 <={shift_in[33],d33[PIPE_LEN-1:1]};
  d32 <={shift_in[32],d32[PIPE_LEN-1:1]};
  d31 <={shift_in[31],d31[PIPE_LEN-1:1]};
  d30 <={shift_in[30],d30[PIPE_LEN-1:1]};
  d29 <={shift_in[29],d29[PIPE_LEN-1:1]};
  d28 <={shift_in[28],d28[PIPE_LEN-1:1]};
  d27 <={shift_in[27],d27[PIPE_LEN-1:1]};
  d26 <={shift_in[26],d26[PIPE_LEN-1:1]};
  d25 <={shift_in[25],d25[PIPE_LEN-1:1]};
  d24 <={shift_in[24],d24[PIPE_LEN-1:1]};
  d23 <={shift_in[23],d23[PIPE_LEN-1:1]};
  d22 <={shift_in[22],d22[PIPE_LEN-1:1]};
  d21 <={shift_in[21],d21[PIPE_LEN-1:1]};
  d20 <={shift_in[20],d20[PIPE_LEN-1:1]};
  d19 <={shift_in[19],d19[PIPE_LEN-1:1]};
  d18 <={shift_in[18],d18[PIPE_LEN-1:1]};
  d17 <={shift_in[17],d17[PIPE_LEN-1:1]};
  d16 <={shift_in[16],d16[PIPE_LEN-1:1]};
  d15 <={shift_in[15],d15[PIPE_LEN-1:1]};
  d14 <={shift_in[14],d14[PIPE_LEN-1:1]};
  d13 <={shift_in[13],d13[PIPE_LEN-1:1]};
  d12 <={shift_in[12],d12[PIPE_LEN-1:1]};
  d11 <={shift_in[11],d11[PIPE_LEN-1:1]};
  d10 <={shift_in[10],d10[PIPE_LEN-1:1]};
  d9  <={shift_in[ 9], d9[PIPE_LEN-1:1]};
  d8  <={shift_in[ 8], d8[PIPE_LEN-1:1]};
  d7  <={shift_in[ 7], d7[PIPE_LEN-1:1]};
  d6  <={shift_in[ 6], d6[PIPE_LEN-1:1]};
  d5  <={shift_in[ 5], d5[PIPE_LEN-1:1]};
  d4  <={shift_in[ 4], d4[PIPE_LEN-1:1]};
  d3  <={shift_in[ 3], d3[PIPE_LEN-1:1]};
  d2  <={shift_in[ 2], d2[PIPE_LEN-1:1]};
  d1  <={shift_in[ 1], d1[PIPE_LEN-1:1]};
  d0  <={shift_in[ 0], d0[PIPE_LEN-1:1]};
end

assign shift_out={d35[0],d34[0],d33[0],d32[0],
d31[0],d30[0],d29[0],d28[0],d27[0],d26[0],d25[0],d24[0],
d23[0],d22[0],d21[0],d20[0],d19[0],d18[0],d17[0],d16[0],
d15[0],d14[0],d13[0],d12[0],d11[0],d10[0],d9[0],d8[0],
d7[0],d6[0],d5[0],d4[0],d3[0],d2[0],d1[0],d0[0]
};
endmodule




/*
Multibits Shift Register
2010-2011 sclai <laikos@yahoo.com>

This library is free software; you can redistribute it and/or modify it
 under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation; either version 2.1 of the License,
 or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 USA
*/
module ddr3_sr4 #(
parameter PIPE_LEN=7
)(
input wire        clk,
input wire [3:0] shift_in,
output wire[3:0] shift_out
);
//register to hold value
reg [PIPE_LEN-1:0] d0;
reg [PIPE_LEN-1:0] d1;
reg [PIPE_LEN-1:0] d2;
reg [PIPE_LEN-1:0] d3;

always @(posedge clk)
begin
  d3  <={shift_in[ 3],d3[PIPE_LEN-1:1]};
  d2  <={shift_in[ 2],d2[PIPE_LEN-1:1]};
  d1  <={shift_in[ 1],d1[PIPE_LEN-1:1]};
  d0  <={shift_in[ 0],d0[PIPE_LEN-1:1]};
end

assign shift_out={d3[0],d2[0],d1[0],d0[0]};
endmodule




/*single clock dual port ram
2010-2011 sclai <laikos@yahoo.com>

This library is free software; you can redistribute it and/or modify it
 under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation; either version 2.1 of the License,
 or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 USA


Example:
Desity     Bank     Row    Col
-----------------------------
   64MB    2:0      12:0   9:0
  128MB    2:0      13:0   9:0
  512MB    2:0      13:0  10:0
    1GB    2:0      15:0  10:0
*/

module dport_ram
#(
	parameter DATA_WIDTH=8,
	parameter ADDR_WIDTH=36
)(
	input 						 clk,
	input [(DATA_WIDTH-1):0] di,
	input [(ADDR_WIDTH-1):0] read_addr,
	input [(ADDR_WIDTH-1):0] write_addr,
	input 						 we,
	output reg [(DATA_WIDTH-1):0] do
);
localparam ACTUAL_ADDR_WIDTH=16; //due to small size of internal memory
//localparam ACTUAL_ADDR_WIDTH=26; //due to small size of internal memory
wire [ACTUAL_ADDR_WIDTH-1:0]ACTUAL_WRITE_ADDR;
wire [ACTUAL_ADDR_WIDTH-1:0]ACTUAL_READ_ADDR;
												//bank            row               col
//assign ACTUAL_WRITE_ADDR={write_addr[34:32],write_addr[25:16],write_addr[7:0]};
//assign ACTUAL_READ_ADDR ={ read_addr[34:32], read_addr[25:16], read_addr[7:0]};
assign ACTUAL_WRITE_ADDR={write_addr[34:32],write_addr[28:16],write_addr[9:0]};
assign ACTUAL_READ_ADDR ={ read_addr[34:32], read_addr[28:16], read_addr[9:0]};
//8196Kbytes RAM
reg [DATA_WIDTH-1:0] ram[2**ACTUAL_ADDR_WIDTH-1:0];

	always @ (posedge clk)
	begin
		if (we==1'b1)
			begin
				ram[ACTUAL_WRITE_ADDR] <= di;
			end
		else
			begin
				do <= ram[ACTUAL_READ_ADDR];
			end
	end
endmodule

/*
Double Data to Single Data Rate Input Register
2010-2011 sclai <laikos@yahoo.com>

This library is free software; you can redistribute it and/or modify it
 under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation; either version 2.1 of the License,
 or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 USA
*/
module my_iddrx8(
input wire 			clk,
input wire 	[7:0]	io,
output reg [7:0] d0,
output reg [7:0] d1
);

reg[7:0] dp0;
reg[7:0] dn0;
always@(posedge clk)
begin
	dp0<=io;
end

always@(negedge clk)
begin
	dn0=io;
end

always@(posedge clk)
begin
	d0<=dp0;
	d1<=dn0;
end

endmodule

/*
Single Data Rate to Double Data Rate Output Register
2010-2011 sclai <laikos@yahoo.com>

This library is free software; you can redistribute it and/or modify it
 under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation; either version 2.1 of the License,
 or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 USA
*/
module my_oddrx8(
input wire 			clk,
input wire [7:0] 	d0,
input wire [7:0] 	d1,
output reg [7:0]  io
);



always@(*)
begin
	case(clk)
	1'b0:io<=d1;
	1'b1:io<=d0;
	endcase
end

endmodule


/*Derivatives computation, Error-&-erasures (errata) location and magnitude computation, and error corrector units*/
module chien_search_alg(
						clock,
						reset,
						no_of_parity,
						errata_loc_coefs_0,
						errata_loc_coefs_1,
						errata_loc_coefs_2,
						errata_magnitude_coefs_0,
						errata_magnitude_coefs_1,
						errata_magnitude_coefs_2,
						send_loc_errata_coefs_0,
						send_loc_errata_coefs_1,
						send_loc_errata_coefs_2,
						send_magnitude_errata_coefs_0,
						send_magnitude_errata_coefs_1,
						send_magnitude_errata_coefs_2,
						errata_loc_coef_ready_0,
						errata_loc_coef_ready_1,
						errata_loc_coef_ready_2,
						errata_magnitude_coef_ready_0,
						errata_magnitude_coef_ready_1,
						errata_magnitude_coef_ready_2,
						error_location_0,
						error_location_1,
						error_location_2,
						derivative_error_location,
						error_magnitude,
						MEA_compute_done_0,
						MEA_compute_done_1,
						MEA_compute_done_2,
						locator_degree_0,
						locator_degree_1,
						locator_degree_2,
						deactivate_chien_serach,//triggered if codeword is error-free
						corrected_error_count,
						cycle,
						errata_loc_addr_0,
						errata_loc_addr_1,
						errata_loc_addr_2,
						errata_magnitude_addr_0,
						errata_magnitude_addr_1,
						errata_magnitude_addr_2,
						alpha_inverse,
						err_loc_derivativative,
						read_alpha_inverse,
						gf_table_ready,
						corrected_cw,
						rdaddress,
						rden_delay_buffer,
						q,
						chien_wraddress,
						chien_rdaddress,
						delayed_chien_rdaddress,
						chien_wren,
						chien_rden_0,
						chien_rden_1,
						chien_rden_2,
						chien_rden_omega,
						decoder_fail_flag,
						corrected_cword_ready,
						chien_regs_initialized_0,
						chien_regs_initialized_1,
						chien_regs_initialized_2,
						chien_wraddress_omega,
						chien_rdaddress_omega,
						chien_wren_omega
						);


parameter width = 5;
parameter number_of_coefs = 16;
parameter number_of_even_roots = 8;

input clock, reset;
input errata_loc_coef_ready_0,errata_magnitude_coef_ready_0;
input errata_loc_coef_ready_1,errata_magnitude_coef_ready_1;
input errata_loc_coef_ready_2,errata_magnitude_coef_ready_2;
input [7:0] errata_loc_coefs_0, errata_magnitude_coefs_0;
input [7:0] errata_loc_coefs_1, errata_magnitude_coefs_1;
input [7:0] errata_loc_coefs_2, errata_magnitude_coefs_2;
input [width-1:0]no_of_parity;
input [width-1:0]errata_loc_addr_0,errata_magnitude_addr_0;
input [width-1:0]errata_loc_addr_1,errata_magnitude_addr_1;
input [width-1:0]errata_loc_addr_2,errata_magnitude_addr_2;
input [width-1:0] locator_degree_0;
input [width-1:0] locator_degree_1;
input [width-1:0] locator_degree_2;
input MEA_compute_done_0;
input MEA_compute_done_1;
input MEA_compute_done_2;
input deactivate_chien_serach;
input [7:0] q;
input [7:0] alpha_inverse;
input gf_table_ready;

output corrected_cword_ready;
output reg send_loc_errata_coefs_0,send_magnitude_errata_coefs_0;//send_chien_roots,
output reg send_loc_errata_coefs_1,send_magnitude_errata_coefs_1;
output reg send_loc_errata_coefs_2,send_magnitude_errata_coefs_2;
output [7:0] error_location_0,error_location_1,error_location_2,error_magnitude;
output [7:0] derivative_error_location;
output [7:0] corrected_error_count;
output [8:0] cycle;

output reg read_alpha_inverse;
output reg [7:0] err_loc_derivativative,corrected_cw;
output reg [7:0] rdaddress,chien_wraddress,chien_rdaddress,chien_wraddress_omega,chien_rdaddress_omega;
output reg [7:0] delayed_chien_rdaddress;
output reg decoder_fail_flag,rden_delay_buffer,chien_wren,chien_wren_omega;
output reg chien_rden_0,chien_rden_1,chien_rden_2,chien_rden_omega;
output reg chien_regs_initialized_0,chien_regs_initialized_1,chien_regs_initialized_2;

wire [7:0] q_sigma_0,q_sigma_1,q_sigma_2;
wire [7:0] q_sigma_derivative_0,q_sigma_derivative_1,q_sigma_derivative_2;
wire [7:0] q_omega;
reg [7:0] q_sigma;
//define galois field multiplier
task gf_multiplier_chien;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















reg [7:0] temp_error_loc_0 [0:number_of_coefs];
reg [7:0] temp_error_loc_1 [0:number_of_coefs];
reg [7:0] temp_error_loc_2 [0:number_of_coefs];
reg [7:0] temp_error_magnitude_0[0:number_of_coefs];
reg [7:0] temp_error_magnitude_1 [0:number_of_coefs];
reg [7:0] temp_error_magnitude_2 [0:number_of_coefs];
reg [7:0] chien_roots [0:number_of_even_roots];
reg [7:0] alpha_1_mult_sigma_deriv_0,alpha_1_mult_sigma_deriv_1,alpha_1_mult_sigma_deriv_2;
reg [7:0] alpha_1_mult_odd_omega;
reg [7:0] sigma_0,sigma_1,sigma_2,sigma_derivative_0,sigma_derivative_1,sigma_derivative_2;
reg [7:0] even_omega,odd_omega,omega,chien_odd_reg,chien_odd_reg_out;
reg [7:0] even_sum_of_sigma_0, sum_of_sigma_derivative_0,sum_of_omega;
reg [7:0] even_sum_of_sigma_1, sum_of_sigma_derivative_1;
reg [7:0] even_sum_of_sigma_2, sum_of_sigma_derivative_2;

reg start_chien_alg,start_forney_and_err_corrector,chien_search_done;
wire chien_regs_initialized;
reg [8:0]chien_clock_cycle,symbol_cycle,addr,delay_addr,decoder_output_cycle,output_cycle;
reg [width-1:0] error_counter_0,error_counter_1,error_counter_2;
reg [7:0] cw_error;
reg zero_sigma_derv;
reg corrected_cw_ready;

reg[31:0] j,k,m;

//DPRAM stores the 255 evaluated values of the errata (error and erasure) magnitude polynomial
omega_buffer		buffer0(
							.wraddress		(chien_wraddress_omega),
							.wren			(chien_wren_omega),
							.data			(omega),
							.rden			(chien_rden_omega),
							.rdaddress		(chien_rdaddress_omega),
							.clock			(clock),
							.q				(q_omega)
							);

//DPRAM stores the 255 evaluated values of the errata(error and erasure) locator polynomial for DECODER 0
sigma_buffer		buffer1_0(
							.wraddress		(chien_wraddress),
							.wren			(chien_wren),
							.data			(sigma_0),
							.rden			(chien_rden_0),
							.rdaddress		(chien_rdaddress),
							.clock			(clock),
							.q				(q_sigma_0)
							);

//DPRAM stores the 255 evaluated values of the errata(error and erasure) locator polynomial for DECODER 1
sigma_buffer_1		buffer1_1(
							.wraddress		(chien_wraddress),
							.wren			(chien_wren),
							.data			(sigma_1),
							.rden			(chien_rden_1),
							.rdaddress		(chien_rdaddress),
							.clock			(clock),
							.q				(q_sigma_1)
							);

//DPRAM stores the 255 evaluated values of the errata(error and erasure) locator polynomial for DECODER 2
sigma_buffer_2		buffer1_2(
							.wraddress		(chien_wraddress),
							.wren			(chien_wren),
							.data			(sigma_2),
							.rden			(chien_rden_2),
							.rdaddress		(chien_rdaddress),
							.clock			(clock),
							.q				(q_sigma_2)
							);

//DPRAM stores the 255 evaluated values of the derivative of errata(error and erasure) locator polynomial for DECODER 0
derivative_buffer	buffer3_0(
							.wraddress		(chien_wraddress),
							.wren			(chien_wren),
							.data			(sigma_derivative_0),
							.rden			(chien_rden_0),
							.rdaddress		(delayed_chien_rdaddress),
							.clock			(clock),
							.q				(q_sigma_derivative_0)
							);

//DPRAM stores the 255 evaluated values of the derivative of errata(error and erasure) locator polynomial for DECODER 1
derivative_buffer_1		buffer3_1(
							.wraddress		(chien_wraddress),
							.wren			(chien_wren),
							.data			(sigma_derivative_1),
							.rden			(chien_rden_1),
							.rdaddress		(delayed_chien_rdaddress),
							.clock			(clock),
							.q				(q_sigma_derivative_1)
							);

//DPRAM stores the 255 evaluated values of the derivative of errata(error and erasure) locator polynomial for DECODER 2
derivative_buffer_2		buffer3_2(
							.wraddress		(chien_wraddress),
							.wren			(chien_wren),
							.data			(sigma_derivative_2),
							.rden			(chien_rden_2),
							.rdaddress		(delayed_chien_rdaddress),
							.clock			(clock),
							.q				(q_sigma_derivative_2)
							);

/**handshaking requesting for the coefficients of errata magnitude & errata locator polynomial**/
always @(posedge clock)
begin
if (reset==1)
begin
send_magnitude_errata_coefs_0=1'b0;
send_loc_errata_coefs_0=1'b0;
chien_regs_initialized_0 = 1'b0;

send_magnitude_errata_coefs_1=1'b0;
send_loc_errata_coefs_1=1'b0;
chien_regs_initialized_1 = 1'b0;

send_magnitude_errata_coefs_2=1'b0;
send_loc_errata_coefs_2=1'b0;
chien_regs_initialized_2 = 1'b0;
end
else begin
		if(MEA_compute_done_0==1'b1 && errata_loc_addr_0 <= locator_degree_0)//load_chien_regs
			begin
				send_magnitude_errata_coefs_0 = 1'b1;
				send_loc_errata_coefs_0 = 1'b1;
			end
		else if (errata_loc_addr_0 > locator_degree_0)
			begin
				chien_regs_initialized_0 = 1'b1;
				send_magnitude_errata_coefs_0 = 1'b0;
				send_loc_errata_coefs_0 = 1'b0;
			end

		if(MEA_compute_done_1==1'b1 && errata_loc_addr_1 <= locator_degree_1)//load_chien_regs
			begin
				send_magnitude_errata_coefs_1 = 1'b1;
				send_loc_errata_coefs_1 = 1'b1;
			end
		else if (errata_loc_addr_1 > locator_degree_1)
			begin
				chien_regs_initialized_1 = 1'b1;
				send_magnitude_errata_coefs_1 = 1'b0;
				send_loc_errata_coefs_1 = 1'b0;
			end

		if(MEA_compute_done_2==1'b1 && errata_loc_addr_2 <= locator_degree_2)//load_chien_regs
			begin
				send_magnitude_errata_coefs_2 = 1'b1;
				send_loc_errata_coefs_2 = 1'b1;
			end
		else if (errata_loc_addr_2 > locator_degree_2)
			begin
				chien_regs_initialized_2 = 1'b1;
				send_magnitude_errata_coefs_2 = 1'b0;
				send_loc_errata_coefs_2 = 1'b0;
			end
		end
end

/******Loading the roots and coefs of the errata polynomials********/
always @(posedge clock)
begin
if (reset==1'b1)
begin
	chien_search_done=1'b0;
	read_alpha_inverse =1'b0;
	corrected_cw_ready =1'b0;
	rdaddress = 8'd0;
	rden_delay_buffer = 1'b0;
	zero_sigma_derv = 1'b0;
	decoder_fail_flag = 1'b0;
	start_forney_and_err_corrector = 1'b0;
	chien_clock_cycle = 0;
	symbol_cycle =0;

	/*chien roots are the generator polynomial roots with even powers  */
	/*Refer to a Galois field table GF(256) to find the values of the roots*/
	/*The GF table is generated by primitive polynomial p(x)= 1 + x^2 + x^3 + x^4 + x^8*/
	chien_roots[0]= 1;chien_roots[1]= 4;chien_roots[2]= 16;chien_roots[3]= 64;chien_roots[4]= 29;
	chien_roots[5]= 116;chien_roots[6]= 205;chien_roots[7]= 19;chien_roots[8]= 76;
end
else begin
	if(errata_loc_coef_ready_0==1'b1)//loading errors-&-erasure locator polynomial
		begin
		temp_error_loc_0[errata_loc_addr_0]= errata_loc_coefs_0;
		end
	if(errata_magnitude_coef_ready_0==1'b1)//loading error-&-erasure magnitude polynomial
		begin
		temp_error_magnitude_0[errata_magnitude_addr_0]= errata_magnitude_coefs_0;
		end

	if(errata_loc_coef_ready_1==1'b1)//loading errors-&-erasure locator polynomial
		begin
		temp_error_loc_1[errata_loc_addr_1]= errata_loc_coefs_1;
		end
	if(errata_magnitude_coef_ready_1==1'b1)//loading error-&-erasure magnitude polynomial
		begin
		temp_error_magnitude_1[errata_magnitude_addr_1]=errata_magnitude_coefs_1;
		end

	if(errata_loc_coef_ready_2==1'b1)//loading errors-&-erasure locator polynomial
		begin
		temp_error_loc_2[errata_loc_addr_2]= errata_loc_coefs_2;
		end
	if(errata_magnitude_coef_ready_2==1'b1)//loading error-&-erasure magnitude polynomial
		begin
		temp_error_magnitude_2[errata_magnitude_addr_2]=errata_magnitude_coefs_2;
		end
/************************** chien search algorithm**************************/
/*1.Determine the roots of the errata locator polynomial (codeword error locations)
  2. Determine and evaluate the derivative of errata locator polynomial
  3. Evaluate the errata magnitude polynomial
****************************************************************************/
	if(chien_regs_initialized_0 == 1'b1 && chien_regs_initialized_1 == 1'b1 && chien_regs_initialized_2 == 1'b1)//start_chien_alg==1'b1
		begin
			if(chien_clock_cycle==1'd0)
				chien_odd_reg = 8'd1;
			else if(chien_clock_cycle==1'd1)
				chien_odd_reg = 8'd2;
			else
				gf_multiplier_chien(chien_odd_reg,8'd2,chien_odd_reg);
			if(decoder_output_cycle==1'd0)
				chien_odd_reg_out = 8'd1;
			else if(decoder_output_cycle==1'd1)
				chien_odd_reg_out = 8'd2;
			else
				gf_multiplier_chien(chien_odd_reg_out,8'd2,chien_odd_reg_out);

			/*It takes 255 cycles to evaluate errata locator polynomial and its derivative*/
			if (chien_clock_cycle <= 255 && corrected_cw_ready==1'b0)
				begin
					even_sum_of_sigma_0 = (temp_error_loc_0[0]^temp_error_loc_0[2])^(temp_error_loc_0[4]^temp_error_loc_0[6])^(temp_error_loc_0[8]^temp_error_loc_0[10])^(temp_error_loc_0[12]^temp_error_loc_0[14])^temp_error_loc_0[16];
					even_sum_of_sigma_1 = (temp_error_loc_1[0]^temp_error_loc_1[2])^(temp_error_loc_1[4]^temp_error_loc_1[6])^(temp_error_loc_1[8]^temp_error_loc_1[10])^(temp_error_loc_1[12]^temp_error_loc_1[14])^temp_error_loc_1[16];
					even_sum_of_sigma_2 = (temp_error_loc_2[0]^temp_error_loc_2[2])^(temp_error_loc_2[4]^temp_error_loc_2[6])^(temp_error_loc_2[8]^temp_error_loc_2[10])^(temp_error_loc_2[12]^temp_error_loc_2[14])^temp_error_loc_2[16];
					sigma_derivative_0 = (temp_error_loc_0[1]^temp_error_loc_0[3])^(temp_error_loc_0[5]^temp_error_loc_0[7])^(temp_error_loc_0[9]^temp_error_loc_0[11])^(temp_error_loc_0[13]^temp_error_loc_0[15]);
					sigma_derivative_1 = (temp_error_loc_1[1]^temp_error_loc_1[3])^(temp_error_loc_1[5]^temp_error_loc_1[7])^(temp_error_loc_1[9]^temp_error_loc_1[11])^(temp_error_loc_1[13]^temp_error_loc_1[15]);
					sigma_derivative_2 = (temp_error_loc_2[1]^temp_error_loc_2[3])^(temp_error_loc_2[5]^temp_error_loc_2[7])^(temp_error_loc_2[9]^temp_error_loc_2[11])^(temp_error_loc_2[13]^temp_error_loc_2[15]);

					for(j = 0;j <= number_of_even_roots;j = j + 1)
						begin
							k = j * 2;
							m = k + 1;
							gf_multiplier_chien(chien_roots[j],temp_error_loc_0[k],temp_error_loc_0[k]);
							gf_multiplier_chien(chien_roots[j],temp_error_loc_1[k],temp_error_loc_1[k]);
							gf_multiplier_chien(chien_roots[j],temp_error_loc_2[k],temp_error_loc_2[k]);
							if(j<number_of_even_roots)
								begin
									gf_multiplier_chien(chien_roots[j],temp_error_loc_0[m],temp_error_loc_0[m]);
									gf_multiplier_chien(chien_roots[j],temp_error_loc_1[m],temp_error_loc_1[m]);
									gf_multiplier_chien(chien_roots[j],temp_error_loc_2[m],temp_error_loc_2[m]);
								end
						end

					gf_multiplier_chien(sigma_derivative_0,chien_odd_reg,alpha_1_mult_sigma_deriv_0);
					gf_multiplier_chien(sigma_derivative_1,chien_odd_reg,alpha_1_mult_sigma_deriv_1);
					gf_multiplier_chien(sigma_derivative_2,chien_odd_reg,alpha_1_mult_sigma_deriv_2);

					sigma_0 = alpha_1_mult_sigma_deriv_0 ^ even_sum_of_sigma_0;
					sigma_1 = alpha_1_mult_sigma_deriv_1 ^ even_sum_of_sigma_1;
					sigma_2 = alpha_1_mult_sigma_deriv_2 ^ even_sum_of_sigma_2;
					if(sigma_0 == 8'd0) error_counter_0 = error_counter_0 + 1;
					if(sigma_1 == 8'd0) error_counter_1 = error_counter_1 + 1;
					if(sigma_2 == 8'd0) error_counter_2 = error_counter_2 + 1;
					chien_wren = 1'b1;
					chien_wraddress = chien_clock_cycle; //write the evaluations into the DPRAM
					chien_clock_cycle = chien_clock_cycle + 1;
				end
/*****************************Forney algorithm and Error corrector***************************/
/*1. Determine the error values in each erroneous codeword byte
  2. Correct the erroneous bytes
 ********************************************************************************************/
				/*after 255 cycles of errata locator polyn, compare the number of errors located*/
				/*(error_counter) with the number of expected (locator degree) */
				else
					begin
						if(error_counter_0 != locator_degree_0 && error_counter_1 != locator_degree_1 && error_counter_2 != locator_degree_2)
							decoder_fail_flag = 1'b1;//decoder 0, 1 and 1 error statistics comparison don't match
						else
							begin
								decoder_fail_flag = 1'b0;
								chien_clock_cycle = 9'd257;//chien_clock_cycle + 1;
							end
						if (decoder_fail_flag == 1'b0 && chien_clock_cycle == 257)
							begin
								chien_wren = 1'b0;
								if (error_counter_0 == locator_degree_0)//decoder 0 error statistics comparison
									begin //evaluate errata magnitude polynomial of DECODER 0
										chien_rden_0 = 1'b1;
										q_sigma = q_sigma_0;
										even_omega = (temp_error_magnitude_0[0]^temp_error_magnitude_0[2])^(temp_error_magnitude_0[4]^temp_error_magnitude_0[6])^(temp_error_magnitude_0[8]^temp_error_magnitude_0[10])^(temp_error_magnitude_0[12]^temp_error_magnitude_0[14])^temp_error_magnitude_0[16];
										odd_omega = (temp_error_magnitude_0[1]^temp_error_magnitude_0[3])^(temp_error_magnitude_0[5]^temp_error_magnitude_0[7])^(temp_error_magnitude_0[9]^temp_error_magnitude_0[11])^(temp_error_magnitude_0[13]^temp_error_magnitude_0[15]);

										for(j = 0;j <= number_of_even_roots;j = j + 1)
											begin
												k = j * 2;
												m = k + 1;
												gf_multiplier_chien(chien_roots[j],temp_error_magnitude_0[k],temp_error_magnitude_0[k]);
												if(j<number_of_even_roots)
													begin
														gf_multiplier_chien(chien_roots[j],temp_error_magnitude_0[m],temp_error_magnitude_0[m]);
													end
											end
									end
								else if (error_counter_1 == locator_degree_1)//decoder 1 error statistics comparison
										begin//evaluate errata magnitude polynomial of DECODER 1
											chien_rden_1 = 1'b1;
											q_sigma = q_sigma_1;
											even_omega = (temp_error_magnitude_1[0]^temp_error_magnitude_1[2])^(temp_error_magnitude_1[4]^temp_error_magnitude_1[6])^(temp_error_magnitude_1[8]^temp_error_magnitude_1[10])^(temp_error_magnitude_1[12]^temp_error_magnitude_1[14])^temp_error_magnitude_1[16];
											odd_omega = (temp_error_magnitude_1[1]^temp_error_magnitude_1[3])^(temp_error_magnitude_1[5]^temp_error_magnitude_1[7])^(temp_error_magnitude_1[9]^temp_error_magnitude_1[11])^(temp_error_magnitude_1[13]^temp_error_magnitude_1[15]);

											for(j = 0;j <= number_of_even_roots;j = j + 1)
												begin
													k = j * 2;
													m = k + 1;
													gf_multiplier_chien(chien_roots[j],temp_error_magnitude_1[k],temp_error_magnitude_1[k]);
													if(j<number_of_even_roots)
														begin
															gf_multiplier_chien(chien_roots[j],temp_error_magnitude_1[m],temp_error_magnitude_1[m]);
														end
												end
										end
									else //If DECODER 0 and 1 comparisons don't match, evaluate errata magnitude polynomial of DECODER 1
										begin
											chien_rden_2 = 1'b1;
											q_sigma = q_sigma_2;
											even_omega = (temp_error_magnitude_2[0]^temp_error_magnitude_2[2])^(temp_error_magnitude_2[4]^temp_error_magnitude_2[6])^(temp_error_magnitude_2[8]^temp_error_magnitude_2[10])^(temp_error_magnitude_2[12]^temp_error_magnitude_2[14])^temp_error_magnitude_2[16];
											odd_omega = (temp_error_magnitude_2[1]^temp_error_magnitude_2[3])^(temp_error_magnitude_2[5]^temp_error_magnitude_2[7])^(temp_error_magnitude_2[9]^temp_error_magnitude_2[11])^(temp_error_magnitude_2[13]^temp_error_magnitude_2[15]);

											for(j = 0;j <= number_of_even_roots;j = j + 1)
												begin
													k = j * 2;
													m = k + 1;
													gf_multiplier_chien(chien_roots[j],temp_error_magnitude_2[k],temp_error_magnitude_2[k]);
													if(j<number_of_even_roots)
														begin
															gf_multiplier_chien(chien_roots[j],temp_error_magnitude_2[m],temp_error_magnitude_2[m]);
														end
												end
										end

									gf_multiplier_chien(odd_omega,chien_odd_reg_out,alpha_1_mult_odd_omega);
									omega = alpha_1_mult_odd_omega ^ even_omega;//omega is the error magnitude

									chien_wren_omega = 1'b1;
									chien_wraddress_omega = decoder_output_cycle;
									decoder_output_cycle = decoder_output_cycle + 1;
							end //end of decoder_fail_flag == 1'b0 && chien_clock_cycle > 255

						/*Forney and error correction (occurs every clock cycle)*/
						/*1. Read the evaluated derivatives (q_sigma_derivative) from the DPRAM*/
						/*2. Send derivative to GF(256) lookup table to retrieve it's inverse (alpha_inverse)*/
						/*3. Multiply alpha_inverse by the evaluated errata magnitude value (q_omega)from DPRAM  to find the error value (cw_error)*/
						/*4. Read the evaluated errata locator value (q_sigma) from DPRAM*/
						/* 				i) If q_sigma = 0 , it means that the codeword symbol in that location is erroneous*/
						/*					therefore read the symbol (q) from the delay buffer FIFO and XOR it with the error value*/
						/*					This is the corrected codeword symbol which is the decoder output.
						/*				ii) If q_sigma = 1 , it means that the codeword symbol in that location correct.*/
						/*					The read symbol (q) from the delay buffer FIFO is left unchanged and output as is*/

						if (chien_search_done==1'b0 && decoder_output_cycle >= 8'd2)
							begin
								chien_rden_omega = 1'b1;
								rden_delay_buffer = 1'b1;
								read_alpha_inverse = 1'b1;
								delayed_chien_rdaddress = decoder_output_cycle-2;//clock_cycle - 2;
								if(decoder_output_cycle >= 8'd4)
									begin
										output_cycle = decoder_output_cycle-4;
										chien_rdaddress_omega = output_cycle;
										chien_rdaddress = output_cycle;
										rdaddress = output_cycle;
									end

								if (error_counter_0 == locator_degree_0)
									err_loc_derivativative = q_sigma_derivative_0;
								else if(error_counter_1 == locator_degree_1)
									err_loc_derivativative = q_sigma_derivative_1;
								else
									err_loc_derivativative = q_sigma_derivative_2;

								if (output_cycle>8'd6)
									corrected_cw_ready = 1'b1;
								if(gf_table_ready==1'b1)
									begin
										gf_multiplier_chien(alpha_inverse,q_omega,cw_error);
											if(q_sigma==8'd0)
												corrected_cw = q ^ cw_error;
											else if(q_sigma!=8'd0)
												corrected_cw = q;
									end
							end
						if (decoder_output_cycle > 9'd260)
							chien_search_done=1'b1;
					end//end else
			end//end of start_chien_alg

/**1. If the syndrome==0, the recieved codeword in FIFO is error free therefore Chien search algorithm and the succeding computations are not executed.**/
/**2. If both the decoders fail to locate all the errors during the evaluation of errata locator polynomial,**/
/**		all the succeeding computions are skipped**/
/** In both (1) and (2) the codeword in the FIFO is left as is and sent to the output**/
		if (deactivate_chien_serach==1'b1 || decoder_fail_flag == 1'b1)//cw is error free or decoder failed
			begin
				rden_delay_buffer = 1'b1;//rden
				rdaddress = symbol_cycle;
				symbol_cycle = symbol_cycle + 1;
				corrected_cw = q;
				if(symbol_cycle > 256)rden_delay_buffer = 1'b0;
			end

	end
end

assign error_location_0 = sigma_0;//q_sigma_0;
assign error_location_1 = sigma_1;//sigma_2;q_sigma_1;
assign error_location_2 = sigma_2;//q_sigma_0;
assign derivative_error_location = alpha_inverse;//sigma_derivative;
assign error_magnitude = q_omega;
assign corrected_cword_ready = gf_table_ready;//corrected_cw_ready;
assign corrected_error_count = error_counter_0;
assign cycle = decoder_output_cycle;//clock_cycle;
assign chien_regs_initialized = chien_regs_initialized_0;

endmodule


/*Error detection unit (Syndrome computation)*/
module syndromes (
				reset,
				clock,
				syndrome,
				new_data,
				recd,
				codeword_end_flag,
				send_syndromes,
				syndrome_ready,
				syndr_coef_addr,
				decoder_rd_addr,
				unmodified_syndrome_ready_0,
				unmodified_syndr_coef_addr_0,
				send_unmodified_syndr_polyn_0,
				unmodified_syndr_polyn_0,
				unmodified_syndrome_ready_1,
				unmodified_syndr_coef_addr_1,
				send_unmodified_syndr_polyn_1,
				unmodified_syndr_polyn_1,
				unmodified_syndrome_ready_2,
				unmodified_syndr_coef_addr_2,
				send_unmodified_syndr_polyn_2,
				unmodified_syndr_polyn_2
				);

parameter width = 5;
parameter number_of_coefs = 16;

input  clock,reset, new_data;
input send_syndromes,send_unmodified_syndr_polyn_0,send_unmodified_syndr_polyn_1,send_unmodified_syndr_polyn_2;
input [7:0] recd,decoder_rd_addr;

output reg codeword_end_flag,syndrome_ready;
output reg unmodified_syndrome_ready_0,unmodified_syndrome_ready_1,unmodified_syndrome_ready_2;
output [7:0] syndrome;
output reg [7:0] unmodified_syndr_polyn_0,unmodified_syndr_polyn_1,unmodified_syndr_polyn_2;
output reg [width-1:0] syndr_coef_addr;
output reg [width-1:0] unmodified_syndr_coef_addr_0,unmodified_syndr_coef_addr_1,unmodified_syndr_coef_addr_2;


reg output_syndrome;
reg[7:0] synd_alpha [1:number_of_coefs];
reg[7:0] data_out [1:number_of_coefs];
reg[7:0] temp_data [1:number_of_coefs];
reg[7:0]syndrom [1:number_of_coefs];
reg[7:0]syndr;
reg[width-1:0]syndrome_addr,unmodified_syndr_addr_0,unmodified_syndr_addr_1,unmodified_syndr_addr_2;

//define galois field multiplier
task gf_multiplier_syndromes;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















reg[31:0] byte_count,count,i,k;

/*synd_alpha[] are the roots of generator polynomial(from alpha_to_power_1 to alpha_to_power_number of parity)*/
/*Refer to a Galois field table GF(256) to find the values of the roots*/
/*The GF table is generated by primitive polynomial p(x)= 1 + x^2 + x^3 + x^4 + x^8*/
always @(posedge clock)
begin
if(reset==1'b1)
begin
synd_alpha[1]<=8'd2;synd_alpha[2]<=8'd4;synd_alpha[3]<=8'd8;synd_alpha[4]<=8'd16;synd_alpha[5]<=8'd32;
synd_alpha[6]<=8'd64;synd_alpha[7]<=8'd128;synd_alpha[8]<=8'd29;synd_alpha[9]<=8'd58;synd_alpha[10]<=8'd116;
synd_alpha[11]<=8'd232;synd_alpha[12]<=8'd205;synd_alpha[13]<=8'd135;synd_alpha[14]<=8'd19;synd_alpha[15]<=8'd38;
synd_alpha[16]<=8'd76;
end
end

always @(posedge clock)
begin
if(reset==1'b1)
	begin
	codeword_end_flag=1'b0;
	end
else
if(reset==1'b0)
begin
	if(new_data==1'b1 && decoder_rd_addr >= 8'd1 &&(byte_count<255))
	begin
	for(i=1;i<=number_of_coefs;i=i+1)//generation of syndrome s(x)
		begin
			gf_multiplier_syndromes(temp_data[i],synd_alpha[i],data_out[i]);
			temp_data[i]<=data_out[i]^recd[7:0];
		end
	byte_count = byte_count+1;
	end
	if(byte_count >= 255)
	begin
		for(k=1;k<=number_of_coefs;k=k+1)
			syndrom[k]<=temp_data[k];
			codeword_end_flag=1'b1;
	end
end
end

always @(posedge clock)
begin
if(reset==1'b0)
begin
output_syndrome=1'b0;
if(codeword_end_flag==1'b1)output_syndrome=1'b1;
end
end

/****Sending out the coefficients of syndrome polynomial--> s(x)*****/
always @(posedge clock)
begin
if(reset==1'b0)
begin
syndrome_ready=1'b0;
	if((output_syndrome==1'b1)&&(send_syndromes==1'b1))
		begin
			syndr_coef_addr = syndrome_addr;
			syndr = syndrom[syndr_coef_addr];
			syndrome_addr = syndrome_addr+1;
			syndrome_ready = 1'b1;
		end
	else if (send_syndromes==1'b0)
		begin
		syndrome_ready = 1'b0;
		end
	if((output_syndrome==1'b1)&&(send_unmodified_syndr_polyn_0==1'b1))
	begin
			unmodified_syndr_coef_addr_0 = unmodified_syndr_addr_0;
			unmodified_syndr_polyn_0 = syndrom[unmodified_syndr_coef_addr_0+1];
			unmodified_syndr_addr_0 = unmodified_syndr_addr_0+1;
			unmodified_syndrome_ready_0 = 1'b1;
	end
	else if (send_unmodified_syndr_polyn_0==1'b0)begin unmodified_syndrome_ready_0 = 1'b0; end

	if((output_syndrome==1'b1)&&(send_unmodified_syndr_polyn_1==1'b1))
	begin
			unmodified_syndr_coef_addr_1 = unmodified_syndr_addr_1;
			unmodified_syndr_polyn_1 = syndrom[unmodified_syndr_coef_addr_1+1];
			unmodified_syndr_addr_1 = unmodified_syndr_addr_1+1;
			unmodified_syndrome_ready_1 = 1'b1;
	end
	else if (send_unmodified_syndr_polyn_1==1'b0)begin unmodified_syndrome_ready_1 = 1'b0; end

	if((output_syndrome==1'b1)&&(send_unmodified_syndr_polyn_2==1'b1))
	begin
			unmodified_syndr_coef_addr_2 = unmodified_syndr_addr_2;
			unmodified_syndr_polyn_2 = syndrom[unmodified_syndr_coef_addr_2+1];
			unmodified_syndr_addr_2 = unmodified_syndr_addr_2+1;
			unmodified_syndrome_ready_2 = 1'b1;
	end
	else if (send_unmodified_syndr_polyn_2==1'b0)begin unmodified_syndrome_ready_2 = 1'b0; end
end
else
	begin
		syndrome_addr = 1;
		unmodified_syndr_addr_0 = 8'd0;
		unmodified_syndrome_ready_0 = 1'b0;
		unmodified_syndr_addr_1 = 8'd0;
		unmodified_syndrome_ready_1 = 1'b0;
		unmodified_syndr_addr_2 = 8'd0;
		unmodified_syndrome_ready_2 = 1'b0;
	end//the addresses of the syndromes begin from addr 1 to addr 32
end

assign 	syndrome = syndr[7:0];

endmodule

/*Syndrome Expansion Unit*/
module modified_syndrome_polyn(
							clock,
							reset,
							start_modified_syndrome_polyn_compute,
							send_syndromes,
							erase_position_0,
							erase_position_1,
							erase_position_2,
							send_erasure_positions_for_synd_0,
							send_erasure_positions_for_synd_1,
							send_erasure_positions_for_synd_2,
							syndrome,
							no_of_parity,
							modified_syndrome_polyn_compute_done_0,
							modified_syndrome_polyn_compute_done_1,
							modified_syndrome_polyn_compute_done_2,
							erasure_ready_0,
							erasure_ready_1,
							erasure_ready_2,
							codeword_end_flag,
							load_non_zero_syndrome_done,
							modified_syndr_polyn_0,
							modified_syndr_polyn_1,
							modified_syndr_polyn_2,
							send_syndr_polyn_0,
							send_syndr_polyn_1,
							send_syndr_polyn_2,
							syndr_coef_ready_0,
							syndr_coef_ready_1,
							syndr_coef_ready_2,
							syndrome_ready,
							syndr_coef_addr,
							number_of_erasures_0,
							number_of_erasures_1,
							number_of_erasures_2,
							modified_syndr_coef_addr_0,
							modified_syndr_coef_addr_1,
							modified_syndr_coef_addr_2,
							erase_pos_done_0,
							erase_pos_done_1,
							erase_pos_done_2,
							error_free_codeword
							);
parameter width = 5;
parameter number_of_coefs = 16;

input clock,reset,start_modified_syndrome_polyn_compute;
input erasure_ready_0,erasure_ready_1,erasure_ready_2;
input codeword_end_flag,syndrome_ready;
input send_syndr_polyn_0,send_syndr_polyn_1,send_syndr_polyn_2;
input erase_pos_done_0,erase_pos_done_1,erase_pos_done_2;
input [7:0] erase_position_0,erase_position_1,erase_position_2;
input [7:0] syndrome;
input [width-1:0] syndr_coef_addr;
input [width-1:0] number_of_erasures_0;
input [width-1:0] number_of_erasures_1;
input [width-1:0] number_of_erasures_2;
input [width-1:0] no_of_parity;

output load_non_zero_syndrome_done;
output reg error_free_codeword;
output modified_syndrome_polyn_compute_done_0,modified_syndrome_polyn_compute_done_1,modified_syndrome_polyn_compute_done_2;
output reg send_syndromes,send_erasure_positions_for_synd_0,send_erasure_positions_for_synd_1,send_erasure_positions_for_synd_2;
output reg syndr_coef_ready_0,syndr_coef_ready_1,syndr_coef_ready_2;
output reg [7:0] modified_syndr_polyn_0,modified_syndr_polyn_1,modified_syndr_polyn_2;
output reg [width-1:0] modified_syndr_coef_addr_0,modified_syndr_coef_addr_1,modified_syndr_coef_addr_2;

reg load_non_zero_syndrome_done;
reg modified_syndrome_polyn_compute_done_reg_0,modified_syndrome_polyn_compute_done_reg_1,modified_syndrome_polyn_compute_done_reg_2;
reg [7:0] syndrom_0[0:number_of_coefs];
reg [7:0] syndrom_1[0:number_of_coefs];
reg [7:0] syndrom_2[0:number_of_coefs];
reg [7:0] current_syndrome_0[1:number_of_coefs+1];
reg [7:0] current_syndrome_1[1:number_of_coefs+1];
reg [7:0] current_syndrome_2[1:number_of_coefs+1];
reg [7:0] temp_polyn;
reg [7:0] erasure_reg_0,prev_erasures_0;
reg [7:0] erasure_reg_1,prev_erasures_1;
reg [7:0] erasure_reg_2,prev_erasures_2;
reg [width-1:0] next_syndr_coef_addr,prev_syndr_coef_addr;
reg [width-1:0] mod_syndrome_addr_counter_0;
reg [width-1:0] mod_syndrome_addr_counter_1;
reg [width-1:0] mod_syndrome_addr_counter_2;

reg [width-1:0]no_of_erasures_0,no_of_erasures_1,no_of_erasures_2,non_zero_coef_count;


reg[31:0] i,count,j,k,m,p,q;

//define galois field multiplier
task gf_multiplier_syndrom_polyn;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















always @(posedge clock)
begin
if(reset==1'b1)
	begin
	current_syndrome_0[1]=8'd0;
	current_syndrome_1[1]=8'd0;
	current_syndrome_2[1]=8'd0;
	end
end

always @(posedge clock)
begin
if(reset==1'b1)
begin
load_non_zero_syndrome_done=1'b0;
send_syndromes=1'b0;
error_free_codeword=1'b0;
end
else//if(reset==1'b0)
begin
	if (codeword_end_flag==1'b1 && syndr_coef_addr <= no_of_parity)//requesting for the syndromes
		begin
			send_syndromes=1'b1;
		end
		else if(syndr_coef_addr > no_of_parity )
			begin
				send_syndromes=1'b0;
				if(non_zero_coef_count != 0)
					load_non_zero_syndrome_done=1'b1;
				else if(non_zero_coef_count == 0)
					error_free_codeword=1'b1;

			 end
end
end

always @(posedge clock)
begin
if(reset==1'b1)
begin
send_erasure_positions_for_synd_0=1'b0;
send_erasure_positions_for_synd_1=1'b0;
send_erasure_positions_for_synd_2=1'b0;
modified_syndrome_polyn_compute_done_reg_0=1'b0;
modified_syndrome_polyn_compute_done_reg_1=1'b0;
modified_syndrome_polyn_compute_done_reg_2=1'b0;

end
else if(reset==1'b0)
begin
	if (start_modified_syndrome_polyn_compute==1'b1)
		begin
			send_erasure_positions_for_synd_0=1'b1;
			send_erasure_positions_for_synd_1=1'b1;
			send_erasure_positions_for_synd_2=1'b1;

			if(no_of_erasures_0 > number_of_erasures_0)//requesting for erasure positions from erasure-position calculator
				begin
				modified_syndrome_polyn_compute_done_reg_0=1'b1;
			 	send_erasure_positions_for_synd_0=1'b0;
				end
			else
				begin
				modified_syndrome_polyn_compute_done_reg_0=1'b0;
				end

			if(no_of_erasures_1 > number_of_erasures_1)//requesting for erasure positions from erasure-position calculator
				begin
				modified_syndrome_polyn_compute_done_reg_1=1'b1;
			 	send_erasure_positions_for_synd_1=1'b0;
				end
			else
				begin
				modified_syndrome_polyn_compute_done_reg_1=1'b0;
				end

			if(no_of_erasures_2 > number_of_erasures_2)//requesting for erasure positions from erasure-position calculator
				begin
				modified_syndrome_polyn_compute_done_reg_2=1'b1;
			 	send_erasure_positions_for_synd_2=1'b0;
				end
			else
				begin
				modified_syndrome_polyn_compute_done_reg_2=1'b0;
				end
		end
end
end

always @(posedge clock)
begin
	if(reset==1'b0)
		begin
			if(syndrome_ready==1'b1)
				begin
					next_syndr_coef_addr = syndr_coef_addr;
					if (prev_syndr_coef_addr != next_syndr_coef_addr)
						begin
							syndrom_0[syndr_coef_addr]=syndrome; //loading the syndromes
							syndrom_1[syndr_coef_addr]=syndrome;
							syndrom_2[syndr_coef_addr]=syndrome;
							if(syndrome != 8'd0)non_zero_coef_count = non_zero_coef_count +1;
							prev_syndr_coef_addr = next_syndr_coef_addr;
						end
				end
			if(erasure_ready_0==1'b1)
				begin
					erasure_reg_0=erase_position_0;
					if (prev_erasures_0 != erasure_reg_0)
						begin
							no_of_erasures_0=no_of_erasures_0+6'd1;
							prev_erasures_0 = erasure_reg_0;
							for(i=1;i<=number_of_coefs;i=i+1)//ARRAY 0 IS NOT BEING USED
								begin
									j = i + 1;
									gf_multiplier_syndrom_polyn(erasure_reg_0,syndrom_0[i],current_syndrome_0[j]);//modifying syndrome using erasures
									syndrom_0[i]<= syndrom_0[i]^current_syndrome_0[i];
								end
			  			end
				end

			if(erasure_ready_1==1'b1)
				begin
					erasure_reg_1=erase_position_1;
					if (prev_erasures_1 != erasure_reg_1)
						begin
							no_of_erasures_1=no_of_erasures_1+6'd1;
							prev_erasures_1 = erasure_reg_1;
							for(k=1;k<=number_of_coefs;k=k+1)//ARRAY 0 IS NOT BEING USED
								begin
									m = k + 1;
									gf_multiplier_syndrom_polyn(erasure_reg_1,syndrom_1[k],current_syndrome_1[m]);//modifying syndrome using erasures
									syndrom_1[k]<= syndrom_1[k]^current_syndrome_1[k];
								end
			  			end
				end

			if(erasure_ready_2==1'b1)
				begin
					erasure_reg_2=erase_position_2;
					if (prev_erasures_2 != erasure_reg_2)
						begin
							no_of_erasures_2=no_of_erasures_2+6'd1;
							prev_erasures_2 = erasure_reg_2;
							for(p=1;p<=number_of_coefs;p=p+1)//ARRAY 0 IS NOT BEING USED
								begin
									q = p + 1;
									gf_multiplier_syndrom_polyn(erasure_reg_2,syndrom_2[p],current_syndrome_2[q]);//modifying syndrome using erasures
									syndrom_2[p]<= syndrom_2[p]^current_syndrome_2[p];
								end
			  			end
				end
		end
	else if(reset==1'b1)
		begin
			next_syndr_coef_addr = 8'd0;
			prev_syndr_coef_addr = 8'd0;
			prev_erasures_0 = 8'd1;
			prev_erasures_1 = 8'd1;
			prev_erasures_2 = 8'd1;
		end
end

/****Sending out the coefficients of modified syndrome polynomial--> T(x)*****/
always @(posedge clock)
begin
	if(reset==1'b0)
		begin
			syndr_coef_ready_0=1'b0;
			syndr_coef_ready_1=1'b0;
			syndr_coef_ready_2=1'b0;
			if(send_syndr_polyn_0==1'b1)
				begin
					modified_syndr_coef_addr_0 = mod_syndrome_addr_counter_0;
					modified_syndr_polyn_0 = syndrom_0[modified_syndr_coef_addr_0+1];//syndrom[0] is empty
					mod_syndrome_addr_counter_0 = mod_syndrome_addr_counter_0 + 1;//8'd1;
					syndr_coef_ready_0=1'b1;
				end
			else if (send_syndr_polyn_0==1'b0)
				begin
					syndr_coef_ready_0 = 1'b0;
				end

			if(send_syndr_polyn_1==1'b1)
				begin
					modified_syndr_coef_addr_1 = mod_syndrome_addr_counter_1;
					modified_syndr_polyn_1 = syndrom_1[modified_syndr_coef_addr_1+1];//syndrom[0] is empty
					mod_syndrome_addr_counter_1 = mod_syndrome_addr_counter_1 + 1;//8'd1;
					syndr_coef_ready_1=1'b1;
				end
			else if (send_syndr_polyn_1==1'b0)
				begin
					syndr_coef_ready_1 = 1'b0;
				end

			if(send_syndr_polyn_2==1'b1)
				begin
					modified_syndr_coef_addr_2 = mod_syndrome_addr_counter_2;
					modified_syndr_polyn_2 = syndrom_2[modified_syndr_coef_addr_2+1];//syndrom[0] is empty
					mod_syndrome_addr_counter_2 = mod_syndrome_addr_counter_2 + 1;//8'd1;
					syndr_coef_ready_2=1'b1;
				end
			else if (send_syndr_polyn_2==1'b0)
				begin
					syndr_coef_ready_2 = 1'b0;
				end
		end
	else
		begin
			mod_syndrome_addr_counter_0 = 0;
			mod_syndrome_addr_counter_1 = 0;
			mod_syndrome_addr_counter_2 = 0;
		end//8'd0;
end

//assign load_non_zero_syndrome_done=load_non_zero_syndrome_done;
assign modified_syndrome_polyn_compute_done_0=modified_syndrome_polyn_compute_done_reg_0;
assign modified_syndrome_polyn_compute_done_1=modified_syndrome_polyn_compute_done_reg_1;
assign modified_syndrome_polyn_compute_done_2=modified_syndrome_polyn_compute_done_reg_2;
endmodule

/*Erasure polynomial Generation*/
module erasure_locator_polyn(
							clock,
							reset,
							start_erasure_polyn_compute,
							erase_position,
							send_erasure_positions_for_loc,
							erasure_loc_polyn,
							no_of_parity,
							no_of_erasure_coefs,
							erasure_polyn_compute_done,
							number_of_erasures,
							erasure_ready,
							erasure_coef_ready,
							send_erasure_polyn,
							erase_coef_addr,
							erase_pos_done);

parameter width = 5;
parameter number_of_coefs = 16;

input clock,reset,start_erasure_polyn_compute,erasure_ready,send_erasure_polyn;
input erase_pos_done;
input [7:0] erase_position;
input [width-1:0]number_of_erasures,no_of_parity;

output erasure_polyn_compute_done;
output reg send_erasure_positions_for_loc,erasure_coef_ready;
output [7:0] erasure_loc_polyn;
output [width-1:0] no_of_erasure_coefs;
output reg [width-1:0] erase_coef_addr;

reg erasure_polyn_compute_done_reg;
reg [7:0] erasure_location_polyn[0:number_of_coefs-1];
reg [7:0] temp_polyn[0:number_of_coefs];
reg [7:0] prev_erasure_location_polyn[0:number_of_coefs];
reg [7:0] current_erasure_location_polyn[0:number_of_coefs];
reg [7:0] temp_reg;
reg [width-1:0] erasure_reg;
reg [width-1:0]erasure_coef_addr;
reg [width-1:0]no_of_erasures;

reg[31:0] i,j;

//define galois field multiplier
task gf_multiplier_locator_polyn;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















always @(posedge clock)
begin
if(reset)
	begin
	current_erasure_location_polyn[0]=8'd1;
	end
end

always @(posedge clock)
begin
if(reset==1'b1)
begin
send_erasure_positions_for_loc=1'b0;
erasure_polyn_compute_done_reg=1'b0;
end
else begin
if (start_erasure_polyn_compute==1'b1)//sending for the erasure positions from erasure-position calculator
	begin
	send_erasure_positions_for_loc = 1'b1;
	if(no_of_erasures >= number_of_erasures && erase_pos_done == 1'b1)
		begin
		erasure_reg=number_of_erasures;
		erasure_polyn_compute_done_reg=1'b1;//keep trck of no of erasure coefs
		send_erasure_positions_for_loc = 1'b0;
		end
	else begin
		erasure_polyn_compute_done_reg=1'b0;
		no_of_erasures=no_of_erasures+1;
		end
	end
end
end

/******************** Computing erasure polynomial*******/

always @(posedge clock)
begin
	if(erasure_ready==1'b1)
		begin
		for(i=1;i<number_of_coefs;i=i+1)
			begin
			j = i - 1;
			current_erasure_location_polyn[i] = erasure_location_polyn[i];
		    gf_multiplier_locator_polyn(erase_position,current_erasure_location_polyn[j],temp_polyn[i]);
			erasure_location_polyn[i]= temp_polyn[i]^prev_erasure_location_polyn[i];
			prev_erasure_location_polyn[i]= erasure_location_polyn[i];
			end
		end
end

/****Sending out the coefficients of erasure locator polynomial--> lambda(x)*****/
always @(posedge clock)
begin
//if(reset==1'b0)
//begin
erasure_coef_ready=1'b0;
if(send_erasure_polyn==1'b1)
	begin
	erasure_coef_ready=1'b0;
	erasure_location_polyn[0]=8'd1;
	erase_coef_addr = erasure_coef_addr;
	temp_reg = erasure_location_polyn[erase_coef_addr];
	erasure_coef_addr = erasure_coef_addr + 1;//8'd1;
	erasure_coef_ready=1'b1;
	end
else if(send_erasure_polyn==1'b0)erasure_coef_ready=1'b0;
end
//end

assign no_of_erasure_coefs = erasure_reg;
assign erasure_loc_polyn = temp_reg;
assign erasure_polyn_compute_done = erasure_polyn_compute_done_reg;
endmodule


/*Erasure polynomial Generation*/
module erasure_locator_polyn_0(
							clock,
							reset,
							start_erasure_polyn_compute,
							erase_position,
							send_erasure_positions_for_loc,
							erasure_loc_polyn,
							no_of_parity,
							no_of_erasure_coefs,
							erasure_polyn_compute_done,
							number_of_erasures,
							erasure_ready,
							erasure_coef_ready,
							send_erasure_polyn,
							erase_coef_addr,
							erase_pos_done);

parameter width = 5;
parameter number_of_coefs = 16;

input clock,reset,start_erasure_polyn_compute,erasure_ready,send_erasure_polyn;
input erase_pos_done;
input [7:0] erase_position;
input [width-1:0]number_of_erasures,no_of_parity;

output erasure_polyn_compute_done;
output reg send_erasure_positions_for_loc,erasure_coef_ready;
output [7:0] erasure_loc_polyn;
output [width-1:0] no_of_erasure_coefs;
output reg [width-1:0] erase_coef_addr;

reg erasure_polyn_compute_done_reg;
reg [7:0] erasure_location_polyn[0:number_of_coefs-1];
reg [7:0] temp_polyn[0:number_of_coefs];
reg [7:0] prev_erasure_location_polyn[0:number_of_coefs];
reg [7:0] current_erasure_location_polyn[0:number_of_coefs];
reg [7:0] temp_reg;
reg [width-1:0] erasure_reg;
reg [width-1:0]erasure_coef_addr;
reg [width-1:0]no_of_erasures;

reg[31:0] i,j;

//define galois field multiplier
task gf_multiplier_locator_polyn_0;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















always @(posedge clock)
begin
if(reset)
	begin
	current_erasure_location_polyn[0]=8'd1;
	end
end

always @(posedge clock)
begin
if(reset==1'b1)
begin
send_erasure_positions_for_loc=1'b0;
erasure_polyn_compute_done_reg=1'b0;
end
else begin
if (start_erasure_polyn_compute==1'b1)//sending for the erasure positions from erasure-position calculator
	begin
	send_erasure_positions_for_loc = 1'b1;
	if(no_of_erasures >= number_of_erasures && erase_pos_done == 1'b1)
		begin
		erasure_reg=number_of_erasures;
		erasure_polyn_compute_done_reg=1'b1;//keep trck of no of erasure coefs
		send_erasure_positions_for_loc = 1'b0;
		end
	else begin
		erasure_polyn_compute_done_reg=1'b0;
		no_of_erasures=no_of_erasures+1;
		end
	end
end
end

/******************** Computing erasure polynomial*******/

always @(posedge clock)
begin
	if(erasure_ready==1'b1)
		begin
		for(i=1;i<number_of_coefs;i=i+1)
			begin
			j = i - 1;
			current_erasure_location_polyn[i] = erasure_location_polyn[i];
		    gf_multiplier_locator_polyn_0(erase_position,current_erasure_location_polyn[j],temp_polyn[i]);
			erasure_location_polyn[i]= temp_polyn[i]^prev_erasure_location_polyn[i];
			prev_erasure_location_polyn[i]= erasure_location_polyn[i];
			end
		end
end

/****Sending out the coefficients of erasure locator polynomial--> lambda(x)*****/
always @(posedge clock)
begin
//if(reset==1'b0)
//begin
erasure_coef_ready=1'b0;
if(send_erasure_polyn==1'b1)
	begin
	erasure_coef_ready=1'b0;
	erasure_location_polyn[0]=8'd1;
	erase_coef_addr = erasure_coef_addr;
	temp_reg = erasure_location_polyn[erase_coef_addr];
	erasure_coef_addr = erasure_coef_addr + 1;//8'd1;
	erasure_coef_ready=1'b1;
	end
else if(send_erasure_polyn==1'b0)erasure_coef_ready=1'b0;
end
//end

assign no_of_erasure_coefs = erasure_reg;
assign erasure_loc_polyn = temp_reg;
assign erasure_polyn_compute_done = erasure_polyn_compute_done_reg;
endmodule


// megafunction wizard: %LPM_ABS%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_abs

// ============================================================
// File Name: absolute_values.v
// Megafunction Name(s):
// 			lpm_abs
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module absolute_values (
	data,
	result);

	input	[9:0]  data;
	output	[9:0]  result;

    assign result = data[9] ? (-data) : data;
endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: nBit NUMERIC "10"
// Retrieval info: PRIVATE: OptionalOverflowOutput NUMERIC "0"
// Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "10"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_ABS"
// Retrieval info: USED_PORT: data 0 0 10 0 INPUT NODEFVAL data[9..0]
// Retrieval info: USED_PORT: result 0 0 10 0 OUTPUT NODEFVAL result[9..0]
// Retrieval info: USED_PORT: overflow 0 0 0 0 OUTPUT NODEFVAL overflow
// Retrieval info: CONNECT: @data 0 0 10 0 data 0 0 10 0
// Retrieval info: CONNECT: result 0 0 10 0 @result 0 0 10 0
// Retrieval info: CONNECT: overflow 0 0 0 0 @overflow 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: decoder_erasure_flags_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module decoder_erasure_flags_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[0:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[0:0]  q;

	wire [0:0] sub_wire0;
	wire [0:0] q = sub_wire0[0:0];

		RAMB18E1 altsyncram_component(
    		.DOBDO(sub_wire0),
    		.DOADO(),
    		.DOPBDOP(),
    		.DOPADOP(),
    		.DIBDI(),
    		.DIADI(data),
    		.DIPBDIP(),
    		.DIPADIP(),

    		.ADDRARDADDR(rdaddress),
    		.CLKARDCLK(clock),
    		.ENARDEN(rden),
    		.REGCEAREGCE(),
    		.RSTRAMARSTRAM(),
    		.RSTREGARSTREG(),
    		.WEA(),

    		.ADDRBWRADDR(wraddress),
    		.CLKBWRCLK(clock),
    		.ENBWREN(wren),
    		.REGCEB(),
    		.RSTRAMB(),
    		.RSTREGB(),
    		.WEBWE()
    	);

	/*altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 1,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 1,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "1"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "1"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "1"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 1 0 INPUT NODEFVAL data[0..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 1 0 OUTPUT NODEFVAL q[0..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 1 0 data 0 0 1 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 1 0 @q_b 0 0 1 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: decoder_erasure_flags_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module decoder_erasure_flags_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[0:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[0:0]  q;

	wire [0:0] sub_wire0;
	wire [0:0] q = sub_wire0[0:0];
	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 1,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 1,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "1"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "1"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "1"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 1 0 INPUT NODEFVAL data[0..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 1 0 OUTPUT NODEFVAL q[0..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 1 0 data 0 0 1 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 1 0 @q_b 0 0 1 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: decoder_erasure_flags.v
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


module decoder_erasure_flags (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[0:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[0:0]  q;

	wire [0:0] sub_wire0;
	wire [0:0] q = sub_wire0[0:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 1,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 1,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "1"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "1"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "1"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "1"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 1 0 INPUT NODEFVAL data[0..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 1 0 OUTPUT NODEFVAL q[0..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 1 0 data 0 0 1 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 1 0 @q_b 0 0 1 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: decoder_input_buffer.v
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


module decoder_input_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: delay_buffer.v
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


module delay_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: derivative_buffer_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module derivative_buffer_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];
	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: derivative_buffer_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module derivative_buffer_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: derivative_buffer.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module derivative_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];
	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

module erasure_generator(
						clk,
						reset,
						erasure_flag_0,
						erasure_flag_1,
						erasure_flag_2,
						sigma_value,
						sigma_square,norm_sigma_square,
						cutoff_threshold_0,
						cutoff_threshold_1,
						cutoff_threshold_2,
						exact_smallest,
						normalized_signal,
						modified_actual_distance,
						channel_char,
						threshold_0,
						threshold_1,
						threshold_2,
						new_channel_char,
						recieved_codeword,
						rdaddress,q,q_fade,rdaddress_fade,rden,
						signal_count,
						send_data//,quotient
						);
parameter width = 10;
parameter num_inputs = 8;
parameter	A_width = 15;
parameter	B_width = 9;
parameter erasure_threshold_value_0 = -9'd94;//T = 0.28
parameter erasure_threshold_value_1 = -9'd173;//T = 0.15
parameter erasure_threshold_value_2 = -9'd75;// T = 0.32

input clk,reset;
input send_data;
input [4:0] sigma_value;

output new_channel_char;
output reg rden;
output reg erasure_flag_0,erasure_flag_1,erasure_flag_2;
output [A_width+B_width-1:0] modified_actual_distance;
output [A_width+B_width-1:0] cutoff_threshold_0,cutoff_threshold_1;
output [A_width+B_width-1:0] cutoff_threshold_2;
output reg [width:0] rdaddress;
output reg [width-1:0] exact_smallest;
output reg [B_width-1:0] threshold_0,threshold_1,threshold_2;
output reg [7:0] rdaddress_fade;
output reg [0:7] recieved_codeword;
output [3:0] signal_count;

output wire [A_width-1:0] normalized_signal;
output wire [A_width-1:0]norm_sigma_square;
reg [A_width-1:0] quotient;
output wire [width-1:0]sigma_square;
output wire [width-1:0]q,q_fade;
wire [width-1:0]absolute_value;

//wire [14:0] channel_char;

/*Approx Data is representaed in signed magnitude. MSB is the sign bit*/

reg second_best_negated_signal;//used as a selector
reg new_channel_char;//erasure_flag,
reg [A_width+B_width-1:0] modified_actual_dist;
reg [A_width+B_width-1:0] cutoff_threshold_reg;
reg [A_width-1:0]norm_variance;
reg [A_width-1:0]quotient_out;
reg [width:0] addr;
reg [width-1:0] exact_signals[0:7];
reg [width-1:0] sorted_exact_signals[0:7];
reg [7:0] best_approx_signal,fading_value;
reg [3:0] signal_count;
reg [width-1:0] minimum_value;
reg [3:0] index;
reg [7:0] addr1;
reg [width-1:0] variance;
reg [width-1:0] unreliable_signal,exact_recvd_signal;
reg [4:0] prev_sigma_value;
output reg [A_width-1:0]channel_char;

reg[31:0] approx_distance,norm_exact_signal,actual_distance;

reg[31:0] i,j,k,m;




//signals for the Dpram storing the 10-bit quantized channel output
//Dpram size = 8 x 255 x 10 bits
input_buffer		buffer(
							.wraddress		(wraddress),//address not used  ;
							.wren			(wren),//write enable not used
							.data			(data),//input data not used
							.rden			(rden),
							.rdaddress		(rdaddress),//[10:0]
							.clock			(clk),
							.q				(q)//;[9:0]
							);

//signals for the Dpram storing the 10-bit quantized channel fading gain
//Dpram size = 255 x 10 bits
fading				fade(
						.wraddress		(wraddress),//address not used  ;
						.wren			(wren),//write enable not used
						.data			(data),//input data not used
						.rden			(rden),
						.rdaddress		(rdaddress_fade),//[10:0]
						.clock			(clk),
						.q				(q_fade)//;[9:0]q_fade
							);


signed_multiplier3	s_mult3	(
							.dataa			(normalized_signal),
							.datab			(approx_distance),
							.result			(modified_actual_dist),
							.clock			(clk)
							);

unsigned_multiplier calc_variance(
							.dataa			(sigma_value),//standard deviation of gaussian noise
							.datab			(sigma_value),
							.result			(sigma_square)//variance of gaussian noise
							);

unsigned_divider	uns_div(
							.numer		(norm_variance),
							.denom		(fading_value),
							.quotient	(quotient),
							.clock		(clk)
							);

mult_by_32			scaled_1(
							.dataa		(unreliable_signal),
							.result		(normalized_signal)
							);

mult_by_32_2			scaled_2(
							.dataa		(variance),
							.result		(norm_sigma_square)
							);

absolute_values		compute_abs(
							.data		(exact_recvd_signal),
							.result		(absolute_value)
							);

signed_multiplier	s_mult1	(
							.dataa			(channel_char),//variance-divide-by-fading gain
							.datab			(threshold_0),//pre-determined erasure threshold values
							.result			(cutoff_threshold_0),//product
							.clock			(clk)
							);

signed_multiplier2		s_mult2	(
								.dataa			(channel_char),//variance-divide-by-fading gain
								.datab			(threshold_1),//pre-determined erasure threshold values
								.result			(cutoff_threshold_1),//
								.clock			(clk)
								);

signed_multiplier4		s_mult4	(
								.dataa			(channel_char),//variance-divide-by-fading gain
								.datab			(threshold_2),//pre-determined erasure threshold values
								.result			(cutoff_threshold_2),//
								.clock			(clk)
								);

/*Erasure generator samples 8 10-bit quantized signals and a 10-bit fading gain for the 8 signals, at a time
  from the input buffers*/
/*recieved signals are quantized with 0.01 precision*/
/* floating point threshold values represented as fixed point values*/
/*Erasure_threshold_value = ln((1/(1-threshold)-1)*/
/*The valid value of threshold is between 0 and 1, however the optimum threshold values, T are
based on the simulations. See the thesis document for T values*/
always @(posedge clk)
begin
if(reset==1'b1)
	begin
	rden=1'b0;
	signal_count=4'd0;
	new_channel_char=1'b0;
	best_approx_signal=8'd0;
	addr1 = 8'd0;
	addr = 10'd0;
	end
else begin
	if(send_data==1'b0)
		begin
			rden=1'b1;
			if(signal_count <= 4'd10)
				begin
					fading_value <= q_fade;
					if (signal_count <= 4'd7)//get the 8 sampled data from the Dpram
						begin
					 		rdaddress <= addr;
					 		addr <= addr+1;
						end
					if(signal_count == 4'd2)//get the fading gain of the 8 sampled signals
						begin
							new_channel_char=1'b0;
							minimum_value = {width{1'b1}};
							rdaddress_fade = addr1;
							addr1 = addr1+1;
						end
					/*finds the smallest signal in magnitude out of the 8 sampled signals*/
					/*This is considered the most unreliable siggnal*/
					if(signal_count >= 4'd3)
						begin
							sorted_exact_signals[signal_count-3] = absolute_value;
							if(absolute_value < minimum_value)
								begin
									minimum_value = absolute_value;
									index = signal_count-3;
								end
						end
					if(rdaddress == 2)//compute the variance of the noise
						begin
							if(sigma_value!=prev_sigma_value)
								begin
									prev_sigma_value<=sigma_value;
									variance <= sigma_square;
								end
						end
					if(rdaddress == 4)
							norm_variance <=norm_sigma_square;
					/*Perform hard decision-estimation to find recieved symbol (byte) estimation*/
					/*The codeword byte estimation determined using the sign bit*/
					if(signal_count >= 4'd2 && signal_count < 4'd10)
						begin
							exact_recvd_signal = q;
							exact_signals[signal_count-2]=q;
							if(q[9]==1'b1)
								best_approx_signal[signal_count-2]=1'b1;
							else if (q[9]==1'b0)
								best_approx_signal[signal_count-2]=1'b0;
						end
				signal_count<=signal_count+4'd1;
			end//best_approx_signal is the most likely byte (MLB)sent to the decoder
		else if(signal_count > 4'd10)//9
			begin
			recieved_codeword = best_approx_signal;//estimated codeword byte
			new_channel_char = 1'b1;
			signal_count = 4'd0;
			end
	end
	else if(send_data==1'b1)
		begin
			rden=1'b0;// stop sampling channel data from the DPRAM
			new_channel_char = 1'b0;
		end
	end
end

always @(posedge clk)
begin
	if(reset==1'b1)
		begin
			erasure_flag_0=1'b0;
			erasure_flag_1=1'b0;
			erasure_flag_2=1'b0;
		end
else begin
	if(new_channel_char==1'b1)
		begin
			channel_char <= quotient;
			threshold_0 <= erasure_threshold_value_0;
			threshold_1 <= erasure_threshold_value_1;
			threshold_2 <= erasure_threshold_value_2;

			exact_smallest = minimum_value;
			unreliable_signal = exact_signals[index];
			second_best_negated_signal= best_approx_signal[index];
			//second_best_negated_signal is the estimation of the unreliable signal (smallest value) of the 8 recvd
			if(second_best_negated_signal==1'b0)//2nd MLS - MLS
				approx_distance = -9'd200;//represent (-1)-(+1)= -2 is quantized as -200 using 0.01 precision
			else if(second_best_negated_signal==1'b1)
				approx_distance = 9'd200;//represent (1)-(-1)= 2 is quantized as 200 using 0.01 precision
			if(rdaddress >= 10)//results of the erasures flag begin here due to pipelining
				begin
					if({~modified_actual_dist[23], modified_actual_dist[22:0]} >= {~cutoff_threshold_0[23],cutoff_threshold_0[22:0]})erasure_flag_0=1'b1;
						else erasure_flag_0=1'b0;//signed comparator
					if({~modified_actual_dist[23], modified_actual_dist[22:0]} >= {~cutoff_threshold_1[23],cutoff_threshold_1[22:0]})erasure_flag_1=1'b1;
						else erasure_flag_1=1'b0;//signed comparator
					if({~modified_actual_dist[23], modified_actual_dist[22:0]} >= {~cutoff_threshold_2[23],cutoff_threshold_2[22:0]})erasure_flag_2=1'b1;
						else erasure_flag_2=1'b0;//signed comparator
				end
		end
	end
end

//assign new_channel_char = new_channel_char;
//assign normalized_signal = normalized_signal;
assign modified_actual_distance = modified_actual_dist;
//assign signal_count = signal_count[3:0];

endmodule

/*Erasure location extraction unit*/
module erasure_position_calc(
						erasure_flag_0,
						erasure_flag_1,
						erasure_flag_2,
						erase_position_0,
						erase_position_1,
						erase_position_2,
						new_data,
						reset,
						clock,
						erasure_ready_0,
						erasure_ready_1,
						erasure_ready_2,
						send_erasure_positions_for_loc_0,
						send_erasure_positions_for_loc_1,
						send_erasure_positions_for_loc_2,
						send_erasure_positions_for_synd_0,
						send_erasure_positions_for_synd_1,
						send_erasure_positions_for_synd_2,
						number_of_erasures_0,
						number_of_erasures_1,
						number_of_erasures_2,
						erase_pos_done_0,
						erase_pos_done_1,
						erase_pos_done_2,
						decoder_rd_addr
						);

parameter width = 5;
parameter max_number_of_erasures = 16;

input erasure_flag_0, erasure_flag_1,erasure_flag_2;
input clock,reset,new_data;
input send_erasure_positions_for_loc_0,send_erasure_positions_for_loc_1,send_erasure_positions_for_loc_2;
input send_erasure_positions_for_synd_0,send_erasure_positions_for_synd_1,send_erasure_positions_for_synd_2;
input [7:0]decoder_rd_addr;

output reg erasure_ready_0;
output reg erasure_ready_1;
output reg erasure_ready_2;
output reg erase_pos_done_0;
output reg erase_pos_done_1;
output reg erase_pos_done_2;
output [7:0] erase_position_0;
output [7:0] erase_position_1;
output [7:0] erase_position_2;
output [width-1:0] number_of_erasures_0;
output [width-1:0] number_of_erasures_1;
output [width-1:0] number_of_erasures_2;

reg [7:0] inverse_alpha_one;
reg [7:0] erase_position_reg_0,erase_position_reg_1,erase_position_reg_2;
reg [width-1:0] no_of_erasures_0,no_of_erasures_1,no_of_erasures_2;
reg [7:0] current_erasure,temp_current_erasure;
reg[7:0] erasures_0[0:max_number_of_erasures-1];
reg[7:0] erasures_1[0:max_number_of_erasures-1];
reg[7:0] erasures_2[0:max_number_of_erasures-1];
reg [width-1:0] erasure_addr_counter_0,erasure_addr_counter_1,erasure_addr_counter_2;

reg [7:0] count_0,count_1,count_2;
reg[31:0] i,cw_byte_count;

//define galois field multiplier
task gf_multiplier_position_calc;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule
















always @(posedge clock)
begin
if(reset==1'b1)
begin
	inverse_alpha_one [7:0]<= 8'b10001110;//this is alpha_to_254
	current_erasure <= 8'd1;
end
else begin
	if (new_data==1'b1 && cw_byte_count<255)
	begin
		gf_multiplier_position_calc(inverse_alpha_one,current_erasure,temp_current_erasure);//determining erasure positions
		current_erasure<=temp_current_erasure;
		cw_byte_count= cw_byte_count+1;//counts the number of codeword bytes
	end
end
end
//end

always @(posedge clock)
begin
if(reset==1'b1)
begin
count_0 =0;
count_1 =0;
count_2 =0;
end
else if(reset==1'b0)
begin
	if(decoder_rd_addr >= 8'd1)
		begin
			if(erasure_flag_0==1'b1)
				begin
					erasures_0[count_0]<=current_erasure;
	 				count_0 <= count_0+1;
	 				no_of_erasures_0 <= count_0 + 1;//count the number of erasures from generator-0
				end
			if(erasure_flag_1==1'b1)
				begin
					erasures_1[count_1]<=current_erasure;
	 				count_1 <= count_1+1;
	 				no_of_erasures_1 <= count_1 + 1;//count the number of erasures from generator-1
				end
			if(erasure_flag_2==1'b1)
				begin
					erasures_2[count_2] <=current_erasure;
	 				count_2 <=count_2+1;
	 				no_of_erasures_2 <= count_2 + 1;//count the number of erasures from generator-2
				end
		end

end
end

/****Sending out the coefficients of erasure positions*****/
always @(posedge clock)
begin
if(reset==1'b0)
begin
	erasure_ready_0=1'b0;
	erasure_ready_1=1'b0;
	erasure_ready_2=1'b0;
	if(send_erasure_positions_for_loc_0==1'b1 && send_erasure_positions_for_synd_0==1'b1)
	begin
		erase_position_reg_0 = erasures_0[erasure_addr_counter_0];
		erasure_addr_counter_0 = erasure_addr_counter_0 + 1;
		if(erasure_addr_counter_0==no_of_erasures_0)erase_pos_done_0=1'b1;
		erasure_ready_0=1'b1;
	end
	else begin erasure_ready_0=1'b0; erase_pos_done_0=1'b0; end

	if(send_erasure_positions_for_loc_1==1'b1 && send_erasure_positions_for_synd_1==1'b1)
	begin
		erase_position_reg_1 = erasures_1[erasure_addr_counter_1];
		erasure_addr_counter_1 = erasure_addr_counter_1 + 1;
		if(erasure_addr_counter_1==no_of_erasures_1)erase_pos_done_1=1'b1;
		erasure_ready_1=1'b1;
	end
	else begin erasure_ready_1=1'b0; erase_pos_done_1=1'b0;end

	if(send_erasure_positions_for_loc_2==1'b1 && send_erasure_positions_for_synd_2==1'b1)
	begin
		erase_position_reg_2 = erasures_2[erasure_addr_counter_2];
		erasure_addr_counter_2 = erasure_addr_counter_2 + 1;
		if(erasure_addr_counter_2==no_of_erasures_2)erase_pos_done_2=1'b1;
		erasure_ready_2=1'b1;
	end
	else begin erasure_ready_2=1'b0; erase_pos_done_2=1'b0;end
end
end

assign number_of_erasures_0 = no_of_erasures_0;
assign number_of_erasures_1 = no_of_erasures_1;
assign number_of_erasures_2 = no_of_erasures_2;
assign erase_position_0 [7:0]= erase_position_reg_0;
assign erase_position_1 [7:0]= erase_position_reg_1;
assign erase_position_2 [7:0]= erase_position_reg_2;
endmodule

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: fading.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module fading (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[9:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[9:0]  q;

	wire [9:0] sub_wire0;
	wire [9:0] q = sub_wire0[9:0];
	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 10,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 10,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "fade.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "10"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "10"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "10"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "10"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2560"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "fade.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "10"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "10"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "fade.mif"
// Retrieval info: USED_PORT: data 0 0 10 0 INPUT NODEFVAL data[9..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 10 0 OUTPUT NODEFVAL q[9..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 10 0 data 0 0 10 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 10 0 @q_b 0 0 10 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL fading.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL fading.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fading.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fading.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL fading_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL fading_bb.v TRUE

//look-up table for GF(256) elements generated by p(x)= 1 + x^2 + x^3 + x^4 + x^8
module GF_256_elements (
						reset,
						read_alpha_inverse,
						gf_table_ready,
						alpha_inverse,
						clock,
						decode_strobe,
						err_loc_derivativative);
parameter width = 5;

output reg gf_table_ready,decode_strobe;
output reg [7:0] alpha_inverse;

input read_alpha_inverse,clock,reset;
input [7:0] err_loc_derivativative;

reg [7:0] alpha_to[0:255];
reg [7:0] mask;
reg [7:0] addr,inverse_addr;
reg [0:8] prim_polyn;
reg gf_flag;

reg[31:0] i,j,k;

always @(posedge reset)
begin
gf_flag=1'b0;
prim_polyn= 9'b101110001; //primitive polynomial p(x)
mask=8'd1;
alpha_to[8]=8'd0;
for(i=0;i<8;i=i+1)
begin
alpha_to[i] = mask;
if(prim_polyn[i] != 1'b0) //if prim_polyn[i]==1 then alpha_to [i] occurs in polynomial rep. of alpha_to[8]
	alpha_to[8]= alpha_to[8]^mask; //generate alpha_to[8]
mask = mask << 1; // left-shift by one bit
end
mask = 8'b10000000;//mask >> 1;
for(i=9; i<255;i=i+1)
	begin
		if(alpha_to[i-1] >= mask)
			alpha_to[i] = alpha_to[8]^((alpha_to[i-1]^mask)<<1);
		else
			alpha_to[i] = alpha_to[i-1]<<1;
	end
alpha_to[255]=alpha_to[0];
gf_flag=1'b1;
decode_strobe=gf_flag;
end

always @(posedge clock)
begin
gf_table_ready = 1'b0;
if((gf_flag==1'b1)&&(reset==1'b0))
begin
	if(read_alpha_inverse==1'b1)//sends the inverse of the recieved derivatives
		begin
			gf_table_ready = 1'b0;
			for(j=0; j<255;j=j+1)
			begin
			 if (err_loc_derivativative==alpha_to[j])
				begin
				inverse_addr = 8'd255 - j;
				alpha_inverse = alpha_to[inverse_addr];
				gf_table_ready = 1'b1;
				end
			else if (err_loc_derivativative== 8'd0)
				begin
				alpha_inverse = 8'd0;
				gf_table_ready = 1'b1;
				end
			end
		end
end
else if(reset==1'b1)
	begin
	gf_table_ready = 1'b0;
	end
end
endmodule

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: input_buffer.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module input_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[9:0]  data;
	input	  wren;
	input	[10:0]  wraddress;
	input	[10:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[9:0]  q;

	wire [9:0] sub_wire0;
	wire [9:0] q = sub_wire0[9:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "10"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "10"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "10"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "10"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "20480"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "erasure_generator.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "10"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "11"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "2048"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "10"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "11"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "2048"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "erasure_generator.mif"
// Retrieval info: USED_PORT: data 0 0 10 0 INPUT NODEFVAL data[9..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 10 0 OUTPUT NODEFVAL q[9..0]
// Retrieval info: USED_PORT: wraddress 0 0 11 0 INPUT NODEFVAL wraddress[10..0]
// Retrieval info: USED_PORT: rdaddress 0 0 11 0 INPUT NODEFVAL rdaddress[10..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 10 0 data 0 0 10 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 10 0 @q_b 0 0 10 0
// Retrieval info: CONNECT: @address_a 0 0 11 0 wraddress 0 0 11 0
// Retrieval info: CONNECT: @address_b 0 0 11 0 rdaddress 0 0 11 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL input_buffer.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL input_buffer.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL input_buffer.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL input_buffer.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL input_buffer_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL input_buffer_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: L_buffer_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module L_buffer_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: L_buffer_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module L_buffer_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);

	/*altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: L_buffer.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module L_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];
	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);

/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_buffer_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: L_Polynomial_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module L_Polynomial_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: L_Polynomial_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module L_Polynomial_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];
	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);*/
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: L_Polynomial.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module L_Polynomial (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL L_Polynomial_bb.v TRUE

/*Errata Polynomials Generator*/
module modified_euclid_alg_0(
						clock,
						reset,
						no_of_parity,
						no_of_erasure_coefs,
						erasure_polyn_compute_done,
						modified_syndr_polyn_compute_done,
						locator_polyn,
						magnitue_polyn,
						erasure_polyn,
						modified_syndr_polyn,
						unmodified_syndr_polyn,
						load_erasure_coef_done,
						load_modified_syndr_coef_done,
						load_unmodified_syndr_coef_done,
						send_erasure_polyn,
						send_syndr_polyn,
						send_unmodified_syndr_polyn,
						erasure_coef_ready,
						syndr_coef_ready,
						unmodified_syndrome_ready,
						MEA_compute_done,
						reg_initialization_complete,
						MEA_iteration,
						reg_init,
						state_case,
						R_degree,leading_R,
						Q_degree,leading_Q,
						L_degree,
						//U,R,Q,L,
						polynomial_compute,
						coef_ready_flag,
						send_magnitude_errata_coefs,send_loc_errata_coefs,
						locator_degree,
						errata_magnitude_coefs,errata_loc_coefs,
						errata_magnitude_coef_ready,errata_loc_coef_ready,
						erase_coef_addr,modified_syndr_coef_addr,unmodified_syndr_coef_addr,
						errata_loc_addr,errata_magnitude_addr,
						//deactivate_chien_serach,
						erasures_absent,
						chien_regs_initialized,
						wren,rden,wraddress_shifted,wraddress,rdaddress,
						wren_polyn,rden_polyn,
						rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U,
						L_dpram_addr,U_dpram_addr,Q_dpram_addr,R_dpram_addr
						//m_counter,test_Q,test_R,test_L,test_U
						);

parameter width = 5;
parameter number_of_coefs = 16;

input clock,reset,erasure_polyn_compute_done,modified_syndr_polyn_compute_done;
input erasure_coef_ready,syndr_coef_ready,unmodified_syndrome_ready;
input send_magnitude_errata_coefs,send_loc_errata_coefs;
input erasures_absent;//when the recieved codeword has no erasure flags asserted
input chien_regs_initialized;
input[width-1:0] no_of_erasure_coefs,no_of_parity;
input [width-1:0] erase_coef_addr,modified_syndr_coef_addr,unmodified_syndr_coef_addr;
input[7:0] modified_syndr_polyn,erasure_polyn,unmodified_syndr_polyn;

output [7:0] magnitue_polyn,locator_polyn;
output [7:0] leading_Q,leading_R;
output reg [7:0] errata_magnitude_coefs,errata_loc_coefs;
output [2:0] state_case;
output [width-1:0] R_degree,Q_degree,L_degree;
output reg [width-1:0] locator_degree;
output reg [width-1:0] errata_loc_addr,errata_magnitude_addr;
output reg errata_magnitude_coef_ready,errata_loc_coef_ready;//load_chien_regs,
//output deactivate_chien_serach;//added when codeword is error-free
output reg load_erasure_coef_done,load_modified_syndr_coef_done,load_unmodified_syndr_coef_done;
output reg send_erasure_polyn,send_syndr_polyn,send_unmodified_syndr_polyn;
output reg reg_initialization_complete,MEA_iteration,reg_init,MEA_compute_done;
output reg polynomial_compute,coef_ready_flag;
output reg wren,rden;
output reg [width-1:0] wraddress_shifted,wraddress,rdaddress;

output reg wren_polyn,rden_polyn;
output reg [width-1:0] L_dpram_addr,U_dpram_addr,Q_dpram_addr,R_dpram_addr;
output reg [width-1:0] rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U;
//output [7:0]Q,R,L,U;
//output [7:0]test_Q,test_R,test_L,test_U;
//output [5:0] m_counter;

wire [7:0] R_out,Q_out,L_out,U_out;
wire [7:0] R_polyn_out,Q_polyn_out,L_polyn_out,U_polyn_out;

//define galois field multiplier
task gf_multiplier_euclid_alg_0;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















reg [7:0] erasure_polyn_U,mod_syndr_polyn_Q,magnitude_polyn_R,locator_polyn_L;
reg [7:0] leading_coef_R, leading_coef_Q;
reg [2:0] state,dpram_read_delay;
reg [width-1:0] degree_L,degree_R,degree_Q,degree_shift,shifted_coef;
reg [width-1:0] multiplier_counter,no_of_mea_iterations,clear_mem;
reg [width-1:0] errata_loc_addr_to_chien,errata_magnitude_addr_to_chien;
reg max_mea_iterations_reached;//,error_free_cw,error_free_codeword
reg syndr_and_erasure_polyn_output,magnitude_and_locator_polyn_output;
reg [7:0] in_R,in_Q,in_L,in_U;
reg swap_signal;
reg [7:0] U_least_coef;//,zero_coef;
reg [width-1:0] U_least_coef_addr;//;
reg[31:0] i,j,k,l;

Q_buffer		buffer0(
							.wraddress		(wraddress_shifted),
							.wren			(wren),
							.data			(in_Q),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(Q_out)
							);

R_buffer		buffer1(
							.wraddress		(wraddress),
							.wren			(wren),
							.data			(in_R),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(R_out)
							);

L_buffer		buffer2(
							.wraddress		(wraddress),
							.wren			(wren),
							.data			(in_L),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(L_out)
							);
U_buffer		buffer3(
							.wraddress		(wraddress_shifted),
							.wren			(wren),
							.data			(in_U),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(U_out)
							);
Q_Polynomial		Dpram0(
							.wraddress		(Q_dpram_addr),
							.wren			(wren_polyn),
							.data			(mod_syndr_polyn_Q),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_Q),
							.clock			(clock),
							.q				(Q_polyn_out)
							);

R_Polynomial		Dpram1(
							.wraddress		(R_dpram_addr),
							.wren			(wren_polyn),
							.data			(magnitude_polyn_R),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_R),
							.clock			(clock),
							.q				(R_polyn_out)
							);

L_Polynomial		Dpram2(
							.wraddress		(L_dpram_addr),
							.wren			(wren_polyn),
							.data			(locator_polyn_L),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_L),
							.clock			(clock),
							.q				(L_polyn_out)
							);
U_Polynomial		Dpram3(
							.wraddress		(U_dpram_addr),
							.wren			(wren_polyn),
							.data			(erasure_polyn_U),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_U),
							.clock			(clock),
							.q				(U_polyn_out)
							);
/*****Handshaking for the transfer the coefficints of erasure polynomial****/
always @(posedge clock)
begin
if(reset==1'b1)load_erasure_coef_done=1'b0;
else begin
	if((erasure_polyn_compute_done==1'b1)&&(erase_coef_addr < no_of_erasure_coefs))
		begin
		send_erasure_polyn=1'b1;
		end
	else if(erase_coef_addr >= no_of_erasure_coefs)
		begin
		send_erasure_polyn=1'b0;
		end
	if(erase_coef_addr > no_of_erasure_coefs)load_erasure_coef_done=1'b1;
	end
end

/*****Handshaking for the transfer coefficients of either:***********************/
/*1. Modified syndrome polynomial if there are erasures
  2. Unmodified (Default)syndrome polynomial if there are no erasures
*/

always @(posedge clock)
begin
if(reset==1'b1)
	begin
	load_modified_syndr_coef_done = 1'b0;
	load_unmodified_syndr_coef_done=1'b0;
	end
else
begin
if((modified_syndr_polyn_compute_done==1'b1)&&( modified_syndr_coef_addr< no_of_parity))
	begin
	send_syndr_polyn=1'b1;
	end
else if((modified_syndr_polyn_compute_done==1'b1)&&(modified_syndr_coef_addr >= no_of_parity))
	begin
	send_syndr_polyn=1'b0;
	load_modified_syndr_coef_done = 1'b1;
	end
if((erasures_absent==1'b1)&&(unmodified_syndr_coef_addr < no_of_parity))
	begin
	send_unmodified_syndr_polyn=1'b1;
	end
else if((erasures_absent==1'b1)&&(unmodified_syndr_coef_addr >= no_of_parity))
	begin
	send_unmodified_syndr_polyn=1'b0;
	load_unmodified_syndr_coef_done = 1'b1;
	end

end
end


always @(posedge clock)
begin
if(reset==1'b1)
	begin
	reg_init =1'b0;
	//deactivate_chien_serach =1'b0;
	MEA_iteration = 1'b0;
	end
else
begin
	if(reg_initialization_complete == 1'b1)
		begin
		MEA_iteration = 1'b1;
		reg_init =1'b1;
		polynomial_compute = 1'b1;
		end
	else if(MEA_compute_done==1'b1)
		begin
		reg_init =1'b1;
		MEA_iteration = 1'b0;
		polynomial_compute = 1'b0;
		end
	//else if(error_free_cw==1'b1)deactivate_chien_serach=1'b1;
end
end

/*Generation of the key polynomials using Modified Euclidean Algorithm (MEA):
			1. Errors-&-erasures location polynomial --> errata_loc_coefs
			2. Errors-&-erasures magnitude polynomial --> errata_magnitude_coefs
 Computation registers U, Q, R and L are initialized as follows:
	U(x) = erasure polynomial(if erasures present) OR 1 (if erasures absent);
	Q(x) = modified syndrome polynoial (if erasures present) OR unmodified syndrome polynomial (if erasures absent);
	R(x) = x^(number of parity)
	L(x) = 0;
*/
always @( posedge clock)
begin
if(reset==1'b1)
	begin
	coef_ready_flag <= 1'b0;
	multiplier_counter<=0;
	//error_free_codeword=1'b0;
	//error_free_cw=1'b0;
	max_mea_iterations_reached=1'b0;
	syndr_and_erasure_polyn_output <= 1'b0;
	magnitude_and_locator_polyn_output <= 1'b0;
	wren = 1'b0;
	rden = 1'b0;
	wraddress_shifted = 0;
	wraddress = 0;
	rdaddress =0;
	swap_signal = 0;
	U_least_coef <= 1;
	U_least_coef_addr <= 0;
	magnitude_polyn_R = 8'd0;
	wren_polyn = 1'b1;
	rden_polyn = 1'b0;
	MEA_compute_done=1'b0;
	errata_magnitude_coef_ready =1'b0;
	errata_loc_coef_ready =1'b0;
	end
else begin
if(erasure_coef_ready==1'b1)//loading the coefficients of erasures polynomial
begin
	U_dpram_addr = erase_coef_addr;
	erasure_polyn_U = erasure_polyn;
end

if(syndr_coef_ready==1'b1 && modified_syndr_coef_addr < no_of_parity)//loading the coefficients of modified syndrome polynomial
begin
	if(modified_syndr_coef_addr == no_of_parity-1 || modified_syndr_coef_addr == no_of_parity)
		begin R_dpram_addr = no_of_parity; magnitude_polyn_R = 8'd1;end
	else magnitude_polyn_R = 8'd0;
	Q_dpram_addr = modified_syndr_coef_addr;
	mod_syndr_polyn_Q = modified_syndr_polyn;
end
else if(unmodified_syndrome_ready==1'b1)//loading syndromes if the codeword has no erasures
begin
	if(unmodified_syndr_coef_addr == no_of_parity-1 || unmodified_syndr_coef_addr == no_of_parity)
		begin R_dpram_addr = no_of_parity; magnitude_polyn_R = 8'd1;end
	else magnitude_polyn_R = 8'd0;
	U_dpram_addr = U_least_coef_addr;
	erasure_polyn_U = U_least_coef;
	Q_dpram_addr = unmodified_syndr_coef_addr;
	mod_syndr_polyn_Q = unmodified_syndr_polyn;
end

if(((load_modified_syndr_coef_done==1'b1 && load_erasure_coef_done==1'b1)||(load_unmodified_syndr_coef_done==1'b1))&&(reg_init ==1'b0))
begin
		degree_R<=no_of_parity;
		degree_Q<=no_of_parity-8'd1;
		degree_L<= 0;
		no_of_mea_iterations<=no_of_erasure_coefs;
		reg_initialization_complete <= 1'b1;
		rden_polyn <= 1'b1;
		wren_polyn = 1'b0;

end
else begin  reg_initialization_complete <= 1'b0; end

if(chien_regs_initialized==1'b1)
	begin
	magnitude_and_locator_polyn_output <= 1'b0;
	syndr_and_erasure_polyn_output <= 1'b0;
	end

/*Modified Euclidean Algorithm (MEA) is an iterative algorithm. States 0-6 are performed
until the stop condition (degree_R<degree_L ) is met, then the algorithm extis at State 3 outputting:
			1. errata_loc_coefs = L(x)
			2. errata_magnitude_coefs = R(x)
			3. Locator deree = degree of L(x) -->expected number of erroneous bytes in the codeword
The maximum number of iterations  = number of parity bytes. If max iterations is reached and
stop condition isn't met, exit at State 3 anyway.
*/

if (MEA_iteration == 1'b1)
	begin
		case(state)
		0:	begin
				rdaddress_Q <= degree_Q;
				rdaddress_R <= degree_R;
				rdaddress_L <= degree_L;
				rdaddress_U <= degree_R;//ADDED
				L_dpram_addr <= {width{1'b1}};
				U_dpram_addr <= {width{1'b1}};
				Q_dpram_addr <= {width{1'b1}};
				R_dpram_addr <= {width{1'b1}};
				state <=1;
			end

		1:	begin
					if(L_polyn_out==8'd0 && degree_L!=0)
						begin
							rdaddress_L <= rdaddress_L - 1; //8'd Update degree of L(x)
							degree_L <= rdaddress_L;
							wraddress_shifted = clear_mem ;
							in_U = 8'd0;
							in_Q = 8'd0;
							clear_mem = clear_mem + 1;
							state <=1;
			 			end
					else begin
						state<=2;
						wren = 0;
						wraddress_shifted = 0;
					end
			end

		2:	begin
					if(Q_polyn_out==8'd0 && degree_Q!=1)//8'd
			 			begin
							rdaddress_Q <= rdaddress_Q - 1;
							degree_Q <= rdaddress_Q;
				 			state<=2;
			 			end
					else begin
						state <= 3;
						leading_coef_Q <= Q_polyn_out;
					end
			end
		3:	begin
					if(R_polyn_out==8'd0 && degree_R!=0)//8'd
			 			begin
							rdaddress_R <= rdaddress_R - 1;
							degree_R <= rdaddress_R;
			   				state <=3;
			 			end
					else begin
						state<=4;
						leading_coef_R <= R_polyn_out;
					end
			end
		4:
			if(degree_R<degree_L || max_mea_iterations_reached ==1'b1)//stop_signal==1'b1 therefore output the magnitude and locator polynomial
				begin
					rdaddress_R <= 0;
					rdaddress_L <= 0;
					magnitude_and_locator_polyn_output <= 1'b1;
					MEA_compute_done<=1'b1;
					locator_degree <= degree_L;
				end
			else if(no_of_erasure_coefs > degree_Q)//erasure generator has captured all errors
				begin
					rdaddress_U <= 0;
					rdaddress_Q <= 0;
					syndr_and_erasure_polyn_output <= 1'b1;
					MEA_compute_done<=1'b1;
					locator_degree <= no_of_erasure_coefs;
				end
			//else if(error_free_codeword==1'b1) error_free_cw =1'b1;//codeword contains no errors
			else state<=5;

		5:
			if(degree_R>=degree_L)//stop_signal==1'b0
				begin
					MEA_compute_done= 1'b0;
					if(degree_R < degree_Q)//swap before computation
						begin
							swap_signal = 1;
							degree_shift = degree_Q - degree_R;
						end
					else if(degree_R >= degree_Q)//no swap just go ahead with computation of L(X) and R(X);  Q(x) and U(X) remain same
 						begin
							swap_signal = 0;
							degree_shift = degree_R - degree_Q;
					end
				//if (degree_shift == number_of_coefs)//syndrome ==0 therefore codeword is error-free
				//	begin
				//		state<=4;
				//		error_free_codeword=1'b1;
				//	end
				state<=6;
 			end//end of degree_R>=degree_L loop

		6:
			if (polynomial_compute == 1'b1)
				begin
					rdaddress_Q <= multiplier_counter;
					rdaddress_U <= multiplier_counter;
					rdaddress_R <= multiplier_counter;
					rdaddress_L <= multiplier_counter;
					if (multiplier_counter >= 1)
						begin
							wren <= 1'b1; //write enable multiply buffers
							wren_polyn = 1'b1;//write enable coef mems
						end
					if (multiplier_counter >=2)
						begin
							if(swap_signal == 1'b1)
								begin
									gf_multiplier_euclid_alg_0(leading_coef_R,Q_polyn_out,in_R);
									gf_multiplier_euclid_alg_0(leading_coef_R,U_polyn_out,in_L);
									gf_multiplier_euclid_alg_0(leading_coef_Q,R_polyn_out,in_Q);
									gf_multiplier_euclid_alg_0(leading_coef_Q,L_polyn_out,in_U);

									Q_dpram_addr <= multiplier_counter - 2;
									U_dpram_addr <= multiplier_counter - 2;
									mod_syndr_polyn_Q <= R_polyn_out;
									erasure_polyn_U <= L_polyn_out;
								end
								else begin
									gf_multiplier_euclid_alg_0(leading_coef_Q,R_polyn_out,in_R);
									gf_multiplier_euclid_alg_0(leading_coef_Q,L_polyn_out,in_L);
									gf_multiplier_euclid_alg_0(leading_coef_R,Q_polyn_out,in_Q);
									gf_multiplier_euclid_alg_0(leading_coef_R,U_polyn_out,in_U);
								end
							wraddress_shifted <= degree_shift + (multiplier_counter-2);
							wraddress <= multiplier_counter-2;
							rden <= 1'b1;//rd enable mult buffers
						end
					multiplier_counter = multiplier_counter + 1;
					if (multiplier_counter >=4)//gf_mult o/p available
						begin
							rdaddress <= multiplier_counter - 4;	//rd multipl buffers
						end
					if (multiplier_counter >= 6)
						begin
							R_dpram_addr <= multiplier_counter - 6;
							L_dpram_addr <= multiplier_counter - 6;
							magnitude_polyn_R <= Q_out^R_out;
							locator_polyn_L <= L_out^U_out;
						end
					if (multiplier_counter == number_of_coefs + 7) state<=7;//6'd39

					end//end of polynomial_compute = 1'b1
		7:
						begin
							no_of_mea_iterations <= no_of_mea_iterations + 1;
							if(no_of_mea_iterations>no_of_parity)
								begin
									state<=4;
									max_mea_iterations_reached =1'b1;
								end
							degree_Q <= no_of_parity;
							degree_R <= no_of_parity;
							degree_L <= no_of_parity;
							rden = 1'b0;
							wren_polyn = 1'b0;
							wraddress_shifted = 0;
							wraddress = 0;
							multiplier_counter =6'd0;
							swap_signal <= 0;
							state<=0;
						end

		endcase

	end//MEA_iteration = 1'b1

/****Sending out the coefficients of errata (errors-&-erasure) magnitude polynomial -->omega(x)*****/

if(send_magnitude_errata_coefs==1'b1)
	begin
		if(magnitude_and_locator_polyn_output == 1'b1)
			begin
				rdaddress_R <= errata_magnitude_addr_to_chien +1;
				errata_magnitude_coefs <= R_polyn_out;

				if(rdaddress_R>=1)errata_magnitude_addr = errata_magnitude_addr_to_chien-1;
				errata_magnitude_addr_to_chien = errata_magnitude_addr_to_chien + 1;
				errata_magnitude_coef_ready=1'b1;
			end
		else if (syndr_and_erasure_polyn_output == 1'b1)
			begin
				rdaddress_Q <= errata_magnitude_addr_to_chien +1;
				errata_magnitude_coefs <= Q_polyn_out;

				if(rdaddress_Q>=1)errata_magnitude_addr = errata_magnitude_addr_to_chien-1;
				errata_magnitude_addr_to_chien = errata_magnitude_addr_to_chien + 1;
				errata_magnitude_coef_ready=1'b1;
			end
	end
	else if(send_magnitude_errata_coefs==1'b0)errata_magnitude_coef_ready=1'b0;

/****Sending out the coefficients of errata (errors-&-erasure) locator polynomial--> psi(x)*****/

if(send_loc_errata_coefs==1'b1)
	begin
		if(magnitude_and_locator_polyn_output == 1'b1)
			begin
			rdaddress_L <= errata_loc_addr_to_chien+1;
			errata_loc_coefs <= L_polyn_out;

			if(rdaddress_L>=1)errata_loc_addr = errata_loc_addr_to_chien-1;
			errata_loc_addr_to_chien = errata_loc_addr_to_chien + 1;
			errata_loc_coef_ready=1'b1;
			end
		else if(syndr_and_erasure_polyn_output == 1'b1)
			begin
			rdaddress_U <= errata_loc_addr_to_chien+1;
			errata_loc_coefs <= U_polyn_out;

			if(rdaddress_U >= 1)errata_loc_addr = errata_loc_addr_to_chien-1;
			errata_loc_addr_to_chien = errata_loc_addr_to_chien + 1;
			errata_loc_coef_ready=1'b1;
			end
	end
	else if(send_loc_errata_coefs==1'b0)errata_loc_coef_ready=1'b0;
end
end

//assign locator_degree = locator_degree;
assign magnitue_polyn = magnitude_polyn_R;
assign locator_polyn = locator_polyn_L;
assign state_case = state;
assign R_degree = degree_R;
assign Q_degree = degree_Q;
assign L_degree = degree_L;
//assign m_counter =multiplier_counter;
//assign R = R_polyn_out;
//assign Q = Q_polyn_out;
//assign L = L_polyn_out;
//assign U = U_polyn_out;
//assign test_R = in_Q;//errata_magnitude_addr;
//assign test_Q = in_Q;
//assign test_L = in_L;
//assign test_U = in_U;
endmodule

/*Errata Polynomials Generator*/
module modified_euclid_alg_1(
						clock,
						reset,
						no_of_parity,
						no_of_erasure_coefs,
						erasure_polyn_compute_done,
						modified_syndr_polyn_compute_done,
						locator_polyn,
						magnitue_polyn,
						erasure_polyn,
						modified_syndr_polyn,
						unmodified_syndr_polyn,
						load_erasure_coef_done,
						load_modified_syndr_coef_done,
						load_unmodified_syndr_coef_done,
						send_erasure_polyn,
						send_syndr_polyn,
						send_unmodified_syndr_polyn,
						erasure_coef_ready,
						syndr_coef_ready,
						unmodified_syndrome_ready,
						MEA_compute_done,
						reg_initialization_complete,
						MEA_iteration,
						reg_init,
						state_case,
						R_degree,leading_R,
						Q_degree,leading_Q,
						L_degree,
						//U,R,Q,L,
						polynomial_compute,
						coef_ready_flag,
						send_magnitude_errata_coefs,send_loc_errata_coefs,
						locator_degree,
						errata_magnitude_coefs,errata_loc_coefs,
						errata_magnitude_coef_ready,errata_loc_coef_ready,
						erase_coef_addr,modified_syndr_coef_addr,unmodified_syndr_coef_addr,
						errata_loc_addr,errata_magnitude_addr,
						//deactivate_chien_serach,
						erasures_absent,
						chien_regs_initialized,
						wren,rden,wraddress_shifted,wraddress,rdaddress,
						wren_polyn,rden_polyn,
						rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U,
						L_dpram_addr,U_dpram_addr,Q_dpram_addr,R_dpram_addr
						//m_counter,test_Q,test_R,test_L,test_U
						);

parameter width = 5;
parameter number_of_coefs = 16;

input clock,reset,erasure_polyn_compute_done,modified_syndr_polyn_compute_done;
input erasure_coef_ready,syndr_coef_ready,unmodified_syndrome_ready;
input send_magnitude_errata_coefs,send_loc_errata_coefs;
input erasures_absent;//when the recieved codeword has no erasure flags asserted
input chien_regs_initialized;
input[width-1:0] no_of_erasure_coefs,no_of_parity;
input [width-1:0] erase_coef_addr,modified_syndr_coef_addr,unmodified_syndr_coef_addr;
input[7:0] modified_syndr_polyn,erasure_polyn,unmodified_syndr_polyn;

output [7:0] magnitue_polyn,locator_polyn;
output [7:0] leading_Q,leading_R;
output reg[7:0] errata_magnitude_coefs,errata_loc_coefs;
output [2:0] state_case;
output [width-1:0] R_degree,Q_degree,L_degree;
output reg [width-1:0] locator_degree;
output reg [width-1:0] errata_loc_addr,errata_magnitude_addr;
output reg errata_magnitude_coef_ready,errata_loc_coef_ready;//load_chien_regs,
//output deactivate_chien_serach;//added when codeword is error-free
output reg load_erasure_coef_done,load_modified_syndr_coef_done,load_unmodified_syndr_coef_done;
output reg send_erasure_polyn,send_syndr_polyn,send_unmodified_syndr_polyn;
output reg reg_initialization_complete,MEA_iteration,reg_init,MEA_compute_done;
output reg polynomial_compute,coef_ready_flag;
output reg wren,rden;
output reg [width-1:0] wraddress_shifted,wraddress,rdaddress;

output reg wren_polyn,rden_polyn;
output reg [width-1:0] L_dpram_addr,U_dpram_addr,Q_dpram_addr,R_dpram_addr;
output reg [width-1:0] rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U;
//output [7:0]Q,R,L,U;
//output [7:0]test_Q,test_R,test_L,test_U;
//output [5:0] m_counter;

wire [7:0] R_out,Q_out,L_out,U_out;
wire [7:0] R_polyn_out,Q_polyn_out,L_polyn_out,U_polyn_out;

//define galois field multiplier
task gf_multiplier_euclid_alg_1;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















reg [7:0] erasure_polyn_U,mod_syndr_polyn_Q,magnitude_polyn_R,locator_polyn_L;
reg [7:0] leading_coef_R, leading_coef_Q;
reg [2:0] state,dpram_read_delay;
reg [width-1:0] degree_L,degree_R,degree_Q,degree_shift,shifted_coef;
reg [width-1:0] multiplier_counter,no_of_mea_iterations,clear_mem;
reg [width-1:0] errata_loc_addr_to_chien,errata_magnitude_addr_to_chien;
reg max_mea_iterations_reached;//error_free_cw,error_free_codeword,
reg syndr_and_erasure_polyn_output,magnitude_and_locator_polyn_output;
reg [7:0] in_R,in_Q,in_L,in_U;
reg swap_signal;
reg [7:0] U_least_coef;//,zero_coef;
reg [width-1:0] U_least_coef_addr;//;
reg[31:0] i,j,k,l;

Q_buffer_1		buffer0(
							.wraddress		(wraddress_shifted),
							.wren			(wren),
							.data			(in_Q),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(Q_out)
							);

R_buffer_1		buffer1(
							.wraddress		(wraddress),
							.wren			(wren),
							.data			(in_R),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(R_out)
							);

L_buffer_1		buffer2(
							.wraddress		(wraddress),
							.wren			(wren),
							.data			(in_L),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(L_out)
							);
U_buffer_1		buffer3(
							.wraddress		(wraddress_shifted),
							.wren			(wren),
							.data			(in_U),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(U_out)
							);
Q_Polynomial_1		Dpram0(
							.wraddress		(Q_dpram_addr),
							.wren			(wren_polyn),
							.data			(mod_syndr_polyn_Q),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_Q),
							.clock			(clock),
							.q				(Q_polyn_out)
							);

R_Polynomial_1		Dpram1(
							.wraddress		(R_dpram_addr),
							.wren			(wren_polyn),
							.data			(magnitude_polyn_R),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_R),
							.clock			(clock),
							.q				(R_polyn_out)
							);

L_Polynomial_1		Dpram2(
							.wraddress		(L_dpram_addr),
							.wren			(wren_polyn),
							.data			(locator_polyn_L),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_L),
							.clock			(clock),
							.q				(L_polyn_out)
							);
U_Polynomial_1		Dpram3(
							.wraddress		(U_dpram_addr),
							.wren			(wren_polyn),
							.data			(erasure_polyn_U),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_U),
							.clock			(clock),
							.q				(U_polyn_out)
							);
/*****Handshaking for the transfer the coefficints of erasure polynomial****/
always @(posedge clock)
begin
if(reset==1'b1)load_erasure_coef_done=1'b0;
else begin
	if((erasure_polyn_compute_done==1'b1)&&(erase_coef_addr < no_of_erasure_coefs))
		begin
		send_erasure_polyn=1'b1;
		end
	else if(erase_coef_addr >= no_of_erasure_coefs)
		begin
		send_erasure_polyn=1'b0;
		end
	if(erase_coef_addr > no_of_erasure_coefs)load_erasure_coef_done=1'b1;
	end
end

/*****Handshaking for the transfer coefficients of either:***********************/
/*1. Modified syndrome polynomial if there are erasures
  2. Unmodified (Default)syndrome polynomial if there are no erasures
*/

always @(posedge clock)
begin
if(reset==1'b1)
	begin
	load_modified_syndr_coef_done = 1'b0;
	load_unmodified_syndr_coef_done=1'b0;
	end
else
begin
if((modified_syndr_polyn_compute_done==1'b1)&&( modified_syndr_coef_addr< no_of_parity))
	begin
	send_syndr_polyn=1'b1;
	end
else if((modified_syndr_polyn_compute_done==1'b1)&&(modified_syndr_coef_addr >= no_of_parity))
	begin
	send_syndr_polyn=1'b0;
	load_modified_syndr_coef_done = 1'b1;
	end
if((erasures_absent==1'b1)&&(unmodified_syndr_coef_addr < no_of_parity))
	begin
	send_unmodified_syndr_polyn=1'b1;
	end
else if((erasures_absent==1'b1)&&(unmodified_syndr_coef_addr >= no_of_parity))
	begin
	send_unmodified_syndr_polyn=1'b0;
	load_unmodified_syndr_coef_done = 1'b1;
	end

end
end


always @(posedge clock)
begin
if(reset==1'b1)
	begin
	reg_init =1'b0;
	//deactivate_chien_serach =1'b0;
	MEA_iteration = 1'b0;
	end
else
begin
	if(reg_initialization_complete == 1'b1)
		begin
		MEA_iteration = 1'b1;
		reg_init =1'b1;
		polynomial_compute = 1'b1;
		end
	else if(MEA_compute_done==1'b1)
		begin
		reg_init =1'b1;
		MEA_iteration = 1'b0;
		polynomial_compute = 1'b0;
		end
	//else if(error_free_cw==1'b1)deactivate_chien_serach=1'b1;
end
end

/*Generation of the key polynomials using Modified Euclidean Algorithm (MEA):
			1. Errors-&-erasures location polynomial --> errata_loc_coefs
			2. Errors-&-erasures magnitude polynomial --> errata_magnitude_coefs
 Computation registers U, Q, R and L are initialized as follows:
	U(x) = erasure polynomial(if erasures present) OR 1 (if erasures absent);
	Q(x) = modified syndrome polynoial (if erasures present) OR unmodified syndrome polynomial (if erasures absent);
	R(x) = x^(number of parity)
	L(x) = 0;
*/
always @( posedge clock)
begin
if(reset==1'b1)
	begin
	coef_ready_flag <= 1'b0;
	multiplier_counter<=0;
	//error_free_codeword=1'b0;
	//error_free_cw=1'b0;
	max_mea_iterations_reached=1'b0;
	syndr_and_erasure_polyn_output <= 1'b0;
	magnitude_and_locator_polyn_output <= 1'b0;
	wren = 1'b0;
	rden = 1'b0;
	wraddress_shifted = 0;
	wraddress = 0;
	rdaddress =0;
	swap_signal = 0;
	U_least_coef <= 1;
	U_least_coef_addr <= 0;
	magnitude_polyn_R = 8'd0;
	wren_polyn = 1'b1;
	rden_polyn = 1'b0;
	MEA_compute_done=1'b0;
	errata_magnitude_coef_ready =1'b0;
	errata_loc_coef_ready =1'b0;
	end
else begin
if(erasure_coef_ready==1'b1)//loading the coefficients of erasures polynomial
begin
	U_dpram_addr = erase_coef_addr;
	erasure_polyn_U = erasure_polyn;
end

if(syndr_coef_ready==1'b1 && modified_syndr_coef_addr < no_of_parity)//loading the coefficients of modified syndrome polynomial
begin
	if(modified_syndr_coef_addr == no_of_parity-1 || modified_syndr_coef_addr == no_of_parity)
		begin R_dpram_addr = no_of_parity; magnitude_polyn_R = 8'd1;end
	else magnitude_polyn_R = 8'd0;
	Q_dpram_addr = modified_syndr_coef_addr;
	mod_syndr_polyn_Q = modified_syndr_polyn;
end
else if(unmodified_syndrome_ready==1'b1)//loading syndromes if the codeword has no erasures
begin
	if(unmodified_syndr_coef_addr == no_of_parity-1 || unmodified_syndr_coef_addr == no_of_parity)
		begin R_dpram_addr = no_of_parity; magnitude_polyn_R = 8'd1;end
	else magnitude_polyn_R = 8'd0;
	U_dpram_addr = U_least_coef_addr;
	erasure_polyn_U = U_least_coef;
	Q_dpram_addr = unmodified_syndr_coef_addr;
	mod_syndr_polyn_Q = unmodified_syndr_polyn;
end

if(((load_modified_syndr_coef_done==1'b1 && load_erasure_coef_done==1'b1)||(load_unmodified_syndr_coef_done==1'b1))&&(reg_init ==1'b0))
begin
		degree_R<=no_of_parity;
		degree_Q<=no_of_parity-8'd1;
		degree_L<= 0;
		no_of_mea_iterations<=no_of_erasure_coefs;
		reg_initialization_complete <= 1'b1;
		rden_polyn <= 1'b1;
		wren_polyn = 1'b0;

end
else begin  reg_initialization_complete <= 1'b0; end

if(chien_regs_initialized==1'b1)
	begin
	magnitude_and_locator_polyn_output <= 1'b0;
	syndr_and_erasure_polyn_output <= 1'b0;
	end

/*Modified Euclidean Algorithm (MEA) is an iterative algorithm. States 0-6 are performed
until the stop condition (degree_R<degree_L ) is met, then the algorithm extis at State 3 outputting:
			1. errata_loc_coefs = L(x)
			2. errata_magnitude_coefs = R(x)
			3. Locator deree = degree of L(x) -->expected number of erroneous bytes in the codeword
The maximum number of iterations  = number of parity bytes. If max iterations is reached and
stop condition isn't met, exit at State 3 anyway.
*/

if (MEA_iteration == 1'b1)
	begin
		case(state)
		0:	begin
				rdaddress_Q <= degree_Q;
				rdaddress_R <= degree_R;
				rdaddress_L <= degree_L;
				rdaddress_U <= degree_R;//ADDED
				L_dpram_addr <= {width{1'b1}};
				U_dpram_addr <= {width{1'b1}};
				Q_dpram_addr <= {width{1'b1}};
				R_dpram_addr <= {width{1'b1}};
				state <=1;
			end

		1:	begin
					if(L_polyn_out==8'd0 && degree_L!=0)
						begin
							rdaddress_L <= rdaddress_L - 1; //8'd Update degree of L(x)
							degree_L <= rdaddress_L;
							wraddress_shifted = clear_mem ;
							in_U = 8'd0;
							in_Q = 8'd0;
							clear_mem = clear_mem + 1;
							state <=1;
			 			end
					else begin
						state<=2;
						wren = 0;
						wraddress_shifted = 0;
					end
			end

		2:	begin
					if(Q_polyn_out==8'd0 && degree_Q!=1)//8'd
			 			begin
							rdaddress_Q <= rdaddress_Q - 1;
							degree_Q <= rdaddress_Q;
				 			state<=2;
			 			end
					else begin
						state <= 3;
						leading_coef_Q <= Q_polyn_out;
					end
			end
		3:	begin
					if(R_polyn_out==8'd0 && degree_R!=0)//8'd
			 			begin
							rdaddress_R <= rdaddress_R - 1;
							degree_R <= rdaddress_R;
			   				state <=3;
			 			end
					else begin
						state<=4;
						leading_coef_R <= R_polyn_out;
					end
			end
		4:
			if(degree_R<degree_L || max_mea_iterations_reached ==1'b1)//stop_signal==1'b1 therefore output the magnitude and locator polynomial
				begin
					rdaddress_R <= 0;
					rdaddress_L <= 0;
					magnitude_and_locator_polyn_output <= 1'b1;
					MEA_compute_done<=1'b1;
					locator_degree <= degree_L;
				end
			else if(no_of_erasure_coefs > degree_Q)//erasure generator has captured all errors
				begin
					rdaddress_U <= 0;
					rdaddress_Q <= 0;
					syndr_and_erasure_polyn_output <= 1'b1;
					MEA_compute_done<=1'b1;
					locator_degree <= no_of_erasure_coefs;
				end
			//else if(error_free_codeword==1'b1) error_free_cw =1'b1;//codeword contains no errors
			else state<=5;

		5:
			if(degree_R>=degree_L)//stop_signal==1'b0
				begin
					MEA_compute_done= 1'b0;
					if(degree_R < degree_Q)//swap before computation
						begin
							swap_signal = 1;
							degree_shift = degree_Q - degree_R;
						end
					else if(degree_R >= degree_Q)//no swap just go ahead with computation of L(X) and R(X);  Q(x) and U(X) remain same
 						begin
							swap_signal = 0;
							degree_shift = degree_R - degree_Q;
					end
				//if (degree_shift == number_of_coefs)//syndrome ==0 therefore codeword is error-free
				//	begin
				//		state<=4;
				//		error_free_codeword=1'b1;
				//	end
				state<=6;
 			end//end of degree_R>=degree_L loop

		6:
			if (polynomial_compute == 1'b1)
				begin
					rdaddress_Q <= multiplier_counter;
					rdaddress_U <= multiplier_counter;
					rdaddress_R <= multiplier_counter;
					rdaddress_L <= multiplier_counter;
					if (multiplier_counter >= 1)
						begin
							wren <= 1'b1; //write enable multiply buffers
							wren_polyn = 1'b1;//write enable coef mems
						end
					if (multiplier_counter >=2)
						begin
							if(swap_signal == 1'b1)
								begin
									gf_multiplier_euclid_alg_1(leading_coef_R,Q_polyn_out,in_R);
									gf_multiplier_euclid_alg_1(leading_coef_R,U_polyn_out,in_L);
									gf_multiplier_euclid_alg_1(leading_coef_Q,R_polyn_out,in_Q);
									gf_multiplier_euclid_alg_1(leading_coef_Q,L_polyn_out,in_U);

									Q_dpram_addr <= multiplier_counter - 2;
									U_dpram_addr <= multiplier_counter - 2;
									mod_syndr_polyn_Q <= R_polyn_out;
									erasure_polyn_U <= L_polyn_out;
								end
								else begin
									gf_multiplier_euclid_alg_1(leading_coef_Q,R_polyn_out,in_R);
									gf_multiplier_euclid_alg_1(leading_coef_Q,L_polyn_out,in_L);
									gf_multiplier_euclid_alg_1(leading_coef_R,Q_polyn_out,in_Q);
									gf_multiplier_euclid_alg_1(leading_coef_R,U_polyn_out,in_U);
								end
							wraddress_shifted <= degree_shift + (multiplier_counter-2);
							wraddress <= multiplier_counter-2;
							rden <= 1'b1;//rd enable mult buffers
						end
					multiplier_counter = multiplier_counter + 1;
					if (multiplier_counter >=4)//gf_mult o/p available
						begin
							rdaddress <= multiplier_counter - 4;	//rd multipl buffers
						end
					if (multiplier_counter >= 6)
						begin
							R_dpram_addr <= multiplier_counter - 6;
							L_dpram_addr <= multiplier_counter - 6;
							magnitude_polyn_R <= Q_out^R_out;
							locator_polyn_L <= L_out^U_out;
						end
					if (multiplier_counter == number_of_coefs + 7) state<=7;//6'd39

					end//end of polynomial_compute = 1'b1
		7:
						begin
							no_of_mea_iterations <= no_of_mea_iterations + 1;
							if(no_of_mea_iterations>no_of_parity)
								begin
									state<=4;
									max_mea_iterations_reached =1'b1;
								end
							degree_Q <= no_of_parity;
							degree_R <= no_of_parity;
							degree_L <= no_of_parity;
							rden = 1'b0;
							wren_polyn = 1'b0;
							wraddress_shifted = 0;
							wraddress = 0;
							multiplier_counter =6'd0;
							swap_signal <= 0;
							state<=0;
						end

		endcase

	end//MEA_iteration = 1'b1

/****Sending out the coefficients of errata (errors-&-erasure) magnitude polynomial -->omega(x)*****/

if(send_magnitude_errata_coefs==1'b1)
	begin
		if(magnitude_and_locator_polyn_output == 1'b1)
			begin
				rdaddress_R <= errata_magnitude_addr_to_chien +1;
				errata_magnitude_coefs <= R_polyn_out;

				if(rdaddress_R>=1)errata_magnitude_addr = errata_magnitude_addr_to_chien-1;
				errata_magnitude_addr_to_chien = errata_magnitude_addr_to_chien + 1;
				errata_magnitude_coef_ready=1'b1;
			end
		else if (syndr_and_erasure_polyn_output == 1'b1)
			begin
				rdaddress_Q <= errata_magnitude_addr_to_chien +1;
				errata_magnitude_coefs <= Q_polyn_out;

				if(rdaddress_Q>=1)errata_magnitude_addr = errata_magnitude_addr_to_chien-1;
				errata_magnitude_addr_to_chien = errata_magnitude_addr_to_chien + 1;
				errata_magnitude_coef_ready=1'b1;
			end
	end
	else if(send_magnitude_errata_coefs==1'b0)errata_magnitude_coef_ready=1'b0;

/****Sending out the coefficients of errata (errors-&-erasure) locator polynomial--> psi(x)*****/

if(send_loc_errata_coefs==1'b1)
	begin
		if(magnitude_and_locator_polyn_output == 1'b1)
			begin
			rdaddress_L <= errata_loc_addr_to_chien+1;
			errata_loc_coefs <= L_polyn_out;

			if(rdaddress_L>=1)errata_loc_addr = errata_loc_addr_to_chien-1;
			errata_loc_addr_to_chien = errata_loc_addr_to_chien + 1;
			errata_loc_coef_ready=1'b1;
			end
		else if(syndr_and_erasure_polyn_output == 1'b1)
			begin
			rdaddress_U <= errata_loc_addr_to_chien+1;
			errata_loc_coefs <= U_polyn_out;

			if(rdaddress_U >= 1)errata_loc_addr = errata_loc_addr_to_chien-1;
			errata_loc_addr_to_chien = errata_loc_addr_to_chien + 1;
			errata_loc_coef_ready=1'b1;
			end
	end
	else if(send_loc_errata_coefs==1'b0)errata_loc_coef_ready=1'b0;
end
end

//assign locator_degree = locator_degree;
assign magnitue_polyn = magnitude_polyn_R;
assign locator_polyn = locator_polyn_L;
assign state_case = state;
assign R_degree = degree_R;
assign Q_degree = degree_Q;
assign L_degree = degree_L;
//assign m_counter =multiplier_counter;
//assign R = R_polyn_out;
//assign Q = Q_polyn_out;
//assign L = L_polyn_out;
//assign U = U_polyn_out;
//assign test_R = in_Q;//errata_magnitude_addr;
//assign test_Q = in_Q;
//assign test_L = in_L;
//assign test_U = in_U;
endmodule

/*Errata Polynomials Generator*/
module modified_euclid_alg_2(
						clock,
						reset,
						no_of_parity,
						no_of_erasure_coefs,
						erasure_polyn_compute_done,
						modified_syndr_polyn_compute_done,
						locator_polyn,
						magnitue_polyn,
						erasure_polyn,
						modified_syndr_polyn,
						unmodified_syndr_polyn,
						load_erasure_coef_done,
						load_modified_syndr_coef_done,
						load_unmodified_syndr_coef_done,
						send_erasure_polyn,
						send_syndr_polyn,
						send_unmodified_syndr_polyn,
						erasure_coef_ready,
						syndr_coef_ready,
						unmodified_syndrome_ready,
						MEA_compute_done,
						reg_initialization_complete,
						MEA_iteration,
						reg_init,
						state_case,
						R_degree,leading_R,
						Q_degree,leading_Q,
						L_degree,
						//U,R,Q,L,
						polynomial_compute,
						coef_ready_flag,
						send_magnitude_errata_coefs,send_loc_errata_coefs,
						locator_degree,
						errata_magnitude_coefs,errata_loc_coefs,
						errata_magnitude_coef_ready,errata_loc_coef_ready,
						erase_coef_addr,modified_syndr_coef_addr,unmodified_syndr_coef_addr,
						errata_loc_addr,errata_magnitude_addr,
						//deactivate_chien_serach,
						erasures_absent,
						chien_regs_initialized,
						wren,rden,wraddress_shifted,wraddress,rdaddress,
						wren_polyn,rden_polyn,
						rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U,
						L_dpram_addr,U_dpram_addr,Q_dpram_addr,R_dpram_addr
						//m_counter,test_Q,test_R,test_L,test_U
						);

parameter width = 5;
parameter number_of_coefs = 16;

input clock,reset,erasure_polyn_compute_done,modified_syndr_polyn_compute_done;
input erasure_coef_ready,syndr_coef_ready,unmodified_syndrome_ready;
input send_magnitude_errata_coefs,send_loc_errata_coefs;
input erasures_absent;//when the recieved codeword has no erasure flags asserted
input chien_regs_initialized;
input[width-1:0] no_of_erasure_coefs,no_of_parity;
input [width-1:0] erase_coef_addr,modified_syndr_coef_addr,unmodified_syndr_coef_addr;
input[7:0] modified_syndr_polyn,erasure_polyn,unmodified_syndr_polyn;

output [7:0] magnitue_polyn,locator_polyn;
output [7:0] leading_Q,leading_R;
output reg [7:0] errata_magnitude_coefs,errata_loc_coefs;
output [2:0] state_case;
output [width-1:0] R_degree,Q_degree,L_degree;
output [width-1:0] locator_degree;
reg [width-1:0] locator_degree;
output reg [width-1:0] errata_loc_addr,errata_magnitude_addr;
output reg errata_magnitude_coef_ready,errata_loc_coef_ready;//load_chien_regs,
//output deactivate_chien_serach;//added when codeword is error-free
output reg load_erasure_coef_done,load_modified_syndr_coef_done,load_unmodified_syndr_coef_done;
output reg send_erasure_polyn,send_syndr_polyn,send_unmodified_syndr_polyn;
output reg reg_initialization_complete,MEA_iteration,reg_init,MEA_compute_done;
output reg polynomial_compute,coef_ready_flag;
output reg wren,rden;
output reg [width-1:0] wraddress_shifted,wraddress,rdaddress;

output reg wren_polyn,rden_polyn;
output reg [width-1:0] L_dpram_addr,U_dpram_addr,Q_dpram_addr,R_dpram_addr;
output reg [width-1:0] rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U;
//output [7:0]Q,R,L,U;
//output [7:0]test_Q,test_R,test_L,test_U;
//output [5:0] m_counter;

wire [7:0] R_out,Q_out,L_out,U_out;
wire [7:0] R_polyn_out,Q_polyn_out,L_polyn_out,U_polyn_out;

//define galois field multiplier
task gf_multiplier_euclid_alg_2;

input[7:0] a,b;
output[7:0] y;
//inout b; // clock;

//wire[0:7] a, b;
//reg[0:7] y;
reg[23:0] c;

//multiplication matrix
begin

c[0]=a[3]^a[7];
c[1]=a[1]^a[2];
c[2]=a[1]^a[5]^a[6]^a[7];
c[3]=a[2]^a[6]^a[7];
c[4]=a[0]^a[4]^a[5]^a[6];
c[5]=a[3]^a[4]^a[5];
c[6]=a[2]^a[3]^a[4];

c[14]=a[2]^a[7];
c[15]=a[1]^a[7];
c[16]=a[0]^a[6];
c[17]=a[5]^a[7];
c[18]=a[6]^a[4];
c[21]=a[3]^a[7];

c[23]=a[3]^a[5]^a[6];

c[19]=c[17]^a[3];
c[20]=c[3]^a[4];
c[22]=c[23]^a[1];
c[13]=c[15]^a[6];
c[12]=c[16]^a[5];
c[11]=c[17]^a[4];
c[10]=c[18]^c[0];
c[9]=c[23]^a[2];
c[8]=c[1]^a[4]^a[5];
c[7]=c[1]^c[21];

y[0]=(a[0]&b[0])^(a[7]&b[1])^(a[6]&b[2])^(a[5]&b[3])^(a[4]&b[4])^(c[21]&b[5])^(c[3]&b[6])^(c[2]&b[7]);
y[1]=(a[1]&b[0])^(a[0]&b[1])^(a[7]&b[2])^(a[6]&b[3])^(a[5]&b[4])^(a[4]&b[5])^(c[21]&b[6])^(c[3]&b[7]);
y[2]=(a[2]&b[0])^(c[15]&b[1])^(c[16]&b[2])^(c[17]&b[3])^(c[18]&b[4])^(c[19]&b[5])^(c[20]&b[6])^(c[22]&b[7]);
y[3]=(a[3]&b[0])^(c[14]&b[1])^(c[13]&b[2])^(c[12]&b[3])^(c[11]&b[4])^(c[10]&b[5])^(c[9]&b[6])^(c[8]&b[7]);
y[4]=(a[4]&b[0])^(c[0]&b[1])^(c[3]&b[2])^(c[2]&b[3])^(c[4]&b[4])^(c[5]&b[5])^(c[6]&b[6])^(c[7]&b[7]);
y[5]=(a[5]&b[0])^(a[4]&b[1])^(c[0]&b[2])^(c[3]&b[3])^(c[2]&b[4])^(c[4]&b[5])^(c[5]&b[6])^(c[6]&b[7]);
y[6]=(a[6]&b[0])^(a[5]&b[1])^(a[4]&b[2])^(c[0]&b[3])^(c[3]&b[4])^(c[2]&b[5])^(c[4]&b[6])^(c[5]&b[7]);
y[7]=(a[7]&b[0])^(a[6]&b[1])^(a[5]&b[2])^(a[4]&b[3])^(c[0]&b[4])^(c[3]&b[5])^(c[2]&b[6])^(c[4]&b[7]);


//$display("y=%b", y);

end

endtask
//endmodule















reg [7:0] erasure_polyn_U,mod_syndr_polyn_Q,magnitude_polyn_R,locator_polyn_L;
reg [7:0] leading_coef_R, leading_coef_Q;
reg [2:0] state,dpram_read_delay;
reg [width-1:0] degree_L,degree_R,degree_Q,degree_shift,shifted_coef;
reg [width-1:0] multiplier_counter,no_of_mea_iterations,clear_mem;
reg [width-1:0] errata_loc_addr_to_chien,errata_magnitude_addr_to_chien;
reg max_mea_iterations_reached;//error_free_cw,error_free_codeword,
reg syndr_and_erasure_polyn_output,magnitude_and_locator_polyn_output;
reg [7:0] in_R,in_Q,in_L,in_U;
reg swap_signal;
reg [7:0] U_least_coef;//,zero_coef;
reg [width-1:0] U_least_coef_addr;//;
reg[31:0] i,j,k,l;

Q_buffer_2		buffer0(
							.wraddress		(wraddress_shifted),
							.wren			(wren),
							.data			(in_Q),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(Q_out)
							);

R_buffer_2		buffer1(
							.wraddress		(wraddress),
							.wren			(wren),
							.data			(in_R),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(R_out)
							);

L_buffer_2		buffer2(
							.wraddress		(wraddress),
							.wren			(wren),
							.data			(in_L),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(L_out)
							);
U_buffer_2		buffer3(
							.wraddress		(wraddress_shifted),
							.wren			(wren),
							.data			(in_U),
							.rden			(rden),
							.rdaddress		(rdaddress),
							.clock			(clock),
							.q				(U_out)
							);
Q_Polynomial_2		Dpram0(
							.wraddress		(Q_dpram_addr),
							.wren			(wren_polyn),
							.data			(mod_syndr_polyn_Q),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_Q),
							.clock			(clock),
							.q				(Q_polyn_out)
							);

R_Polynomial_2		Dpram1(
							.wraddress		(R_dpram_addr),
							.wren			(wren_polyn),
							.data			(magnitude_polyn_R),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_R),
							.clock			(clock),
							.q				(R_polyn_out)
							);

L_Polynomial_2		Dpram2(
							.wraddress		(L_dpram_addr),
							.wren			(wren_polyn),
							.data			(locator_polyn_L),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_L),
							.clock			(clock),
							.q				(L_polyn_out)
							);
U_Polynomial_2		Dpram3(
							.wraddress		(U_dpram_addr),
							.wren			(wren_polyn),
							.data			(erasure_polyn_U),
							.rden			(rden_polyn),
							.rdaddress		(rdaddress_U),
							.clock			(clock),
							.q				(U_polyn_out)
							);
/*****Handshaking for the transfer the coefficints of erasure polynomial****/
always @(posedge clock)
begin
if(reset==1'b1)load_erasure_coef_done=1'b0;
else begin
	if((erasure_polyn_compute_done==1'b1)&&(erase_coef_addr < no_of_erasure_coefs))
		begin
		send_erasure_polyn=1'b1;
		end
	else if(erase_coef_addr >= no_of_erasure_coefs)
		begin
		send_erasure_polyn=1'b0;
		end
	if(erase_coef_addr > no_of_erasure_coefs)load_erasure_coef_done=1'b1;
	end
end

/*****Handshaking for the transfer coefficients of either:***********************/
/*1. Modified syndrome polynomial if there are erasures
  2. Unmodified (Default)syndrome polynomial if there are no erasures
*/

always @(posedge clock)
begin
if(reset==1'b1)
	begin
	load_modified_syndr_coef_done = 1'b0;
	load_unmodified_syndr_coef_done=1'b0;
	end
else
begin
if((modified_syndr_polyn_compute_done==1'b1)&&( modified_syndr_coef_addr< no_of_parity))
	begin
	send_syndr_polyn=1'b1;
	end
else if((modified_syndr_polyn_compute_done==1'b1)&&(modified_syndr_coef_addr >= no_of_parity))
	begin
	send_syndr_polyn=1'b0;
	load_modified_syndr_coef_done = 1'b1;
	end
if((erasures_absent==1'b1)&&(unmodified_syndr_coef_addr < no_of_parity))
	begin
	send_unmodified_syndr_polyn=1'b1;
	end
else if((erasures_absent==1'b1)&&(unmodified_syndr_coef_addr >= no_of_parity))
	begin
	send_unmodified_syndr_polyn=1'b0;
	load_unmodified_syndr_coef_done = 1'b1;
	end

end
end


always @(posedge clock)
begin
if(reset==1'b1)
	begin
	reg_init =1'b0;
	//deactivate_chien_serach =1'b0;
	MEA_iteration = 1'b0;
	end
else
begin
	if(reg_initialization_complete == 1'b1)
		begin
		MEA_iteration = 1'b1;
		reg_init =1'b1;
		polynomial_compute = 1'b1;
		end
	else if(MEA_compute_done==1'b1)
		begin
		reg_init =1'b1;
		MEA_iteration = 1'b0;
		polynomial_compute = 1'b0;
		end
	//else if(error_free_cw==1'b1)deactivate_chien_serach=1'b1;
end
end

/*Generation of the key polynomials using Modified Euclidean Algorithm (MEA):
			1. Errors-&-erasures location polynomial --> errata_loc_coefs
			2. Errors-&-erasures magnitude polynomial --> errata_magnitude_coefs
 Computation registers U, Q, R and L are initialized as follows:
	U(x) = erasure polynomial(if erasures present) OR 1 (if erasures absent);
	Q(x) = modified syndrome polynoial (if erasures present) OR unmodified syndrome polynomial (if erasures absent);
	R(x) = x^(number of parity)
	L(x) = 0;
*/
always @( posedge clock)
begin
if(reset==1'b1)
	begin
	coef_ready_flag <= 1'b0;
	multiplier_counter<=0;
	//error_free_codeword=1'b0;
	//error_free_cw=1'b0;
	max_mea_iterations_reached=1'b0;
	syndr_and_erasure_polyn_output <= 1'b0;
	magnitude_and_locator_polyn_output <= 1'b0;
	wren = 1'b0;
	rden = 1'b0;
	wraddress_shifted = 0;
	wraddress = 0;
	rdaddress =0;
	swap_signal = 0;
	U_least_coef <= 1;
	U_least_coef_addr <= 0;
	magnitude_polyn_R = 8'd0;
	wren_polyn = 1'b1;
	rden_polyn = 1'b0;
	MEA_compute_done=1'b0;
	errata_magnitude_coef_ready =1'b0;
	errata_loc_coef_ready =1'b0;
	end
else begin
if(erasure_coef_ready==1'b1)//loading the coefficients of erasures polynomial
begin
	U_dpram_addr = erase_coef_addr;
	erasure_polyn_U = erasure_polyn;
end

if(syndr_coef_ready==1'b1 && modified_syndr_coef_addr < no_of_parity)//loading the coefficients of modified syndrome polynomial
begin
	if(modified_syndr_coef_addr == no_of_parity-1 || modified_syndr_coef_addr == no_of_parity)
		begin R_dpram_addr = no_of_parity; magnitude_polyn_R = 8'd1;end
	else magnitude_polyn_R = 8'd0;
	Q_dpram_addr = modified_syndr_coef_addr;
	mod_syndr_polyn_Q = modified_syndr_polyn;
end
else if(unmodified_syndrome_ready==1'b1)//loading syndromes if the codeword has no erasures
begin
	if(unmodified_syndr_coef_addr == no_of_parity-1 || unmodified_syndr_coef_addr == no_of_parity)
		begin R_dpram_addr = no_of_parity; magnitude_polyn_R = 8'd1;end
	else magnitude_polyn_R = 8'd0;
	U_dpram_addr = U_least_coef_addr;
	erasure_polyn_U = U_least_coef;
	Q_dpram_addr = unmodified_syndr_coef_addr;
	mod_syndr_polyn_Q = unmodified_syndr_polyn;
end

if(((load_modified_syndr_coef_done==1'b1 && load_erasure_coef_done==1'b1)||(load_unmodified_syndr_coef_done==1'b1))&&(reg_init ==1'b0))
begin
		degree_R<=no_of_parity;
		degree_Q<=no_of_parity-8'd1;
		degree_L<= 0;
		no_of_mea_iterations<=no_of_erasure_coefs;
		reg_initialization_complete <= 1'b1;
		rden_polyn <= 1'b1;
		wren_polyn = 1'b0;

end
else begin  reg_initialization_complete <= 1'b0; end

if(chien_regs_initialized==1'b1)
	begin
	magnitude_and_locator_polyn_output <= 1'b0;
	syndr_and_erasure_polyn_output <= 1'b0;
	end

/*Modified Euclidean Algorithm (MEA) is an iterative algorithm. States 0-6 are performed
until the stop condition (degree_R<degree_L ) is met, then the algorithm extis at State 3 outputting:
			1. errata_loc_coefs = L(x)
			2. errata_magnitude_coefs = R(x)
			3. Locator deree = degree of L(x) -->expected number of erroneous bytes in the codeword
The maximum number of iterations  = number of parity bytes. If max iterations is reached and
stop condition isn't met, exit at State 3 anyway.
*/

if (MEA_iteration == 1'b1)
	begin
		case(state)
		0:	begin
				rdaddress_Q <= degree_Q;
				rdaddress_R <= degree_R;
				rdaddress_L <= degree_L;
				rdaddress_U <= degree_R;//ADDED
				L_dpram_addr <= {width{1'b1}};
				U_dpram_addr <= {width{1'b1}};
				Q_dpram_addr <= {width{1'b1}};
				R_dpram_addr <= {width{1'b1}};
				state <=1;
			end

		1:	begin
					if(L_polyn_out==8'd0 && degree_L!=0)
						begin
							rdaddress_L <= rdaddress_L - 1; //8'd Update degree of L(x)
							degree_L <= rdaddress_L;
							wraddress_shifted = clear_mem ;
							in_U = 8'd0;
							in_Q = 8'd0;
							clear_mem = clear_mem + 1;
							state <=1;
			 			end
					else begin
						state<=2;
						wren = 0;
						wraddress_shifted = 0;
					end
			end

		2:	begin
					if(Q_polyn_out==8'd0 && degree_Q!=1)//8'd
			 			begin
							rdaddress_Q <= rdaddress_Q - 1;
							degree_Q <= rdaddress_Q;
				 			state<=2;
			 			end
					else begin
						state <= 3;
						leading_coef_Q <= Q_polyn_out;
					end
			end
		3:	begin
					if(R_polyn_out==8'd0 && degree_R!=0)//8'd
			 			begin
							rdaddress_R <= rdaddress_R - 1;
							degree_R <= rdaddress_R;
			   				state <=3;
			 			end
					else begin
						state<=4;
						leading_coef_R <= R_polyn_out;
					end
			end
		4:
			if(degree_R<degree_L || max_mea_iterations_reached ==1'b1)//stop_signal==1'b1 therefore output the magnitude and locator polynomial
				begin
					rdaddress_R <= 0;
					rdaddress_L <= 0;
					magnitude_and_locator_polyn_output <= 1'b1;
					MEA_compute_done<=1'b1;
					locator_degree <= degree_L;
				end
			else if(no_of_erasure_coefs > degree_Q)//erasure generator has captured all errors
				begin
					rdaddress_U <= 0;
					rdaddress_Q <= 0;
					syndr_and_erasure_polyn_output <= 1'b1;
					MEA_compute_done<=1'b1;
					locator_degree <= no_of_erasure_coefs;
				end
			//else if(error_free_codeword==1'b1) error_free_cw =1'b1;//codeword contains no errors
			else state<=5;

		5:
			if(degree_R>=degree_L)//stop_signal==1'b0
				begin
					MEA_compute_done= 1'b0;
					if(degree_R < degree_Q)//swap before computation
						begin
							swap_signal = 1;
							degree_shift = degree_Q - degree_R;
						end
					else if(degree_R >= degree_Q)//no swap just go ahead with computation of L(X) and R(X);  Q(x) and U(X) remain same
 						begin
							swap_signal = 0;
							degree_shift = degree_R - degree_Q;
					end
				//if (degree_shift == number_of_coefs)//syndrome ==0 therefore codeword is error-free
				//	begin
				//		state<=4;
				//		error_free_codeword=1'b1;
				//	end
				state<=6;
 			end//end of degree_R>=degree_L loop

		6:
			if (polynomial_compute == 1'b1)
				begin
					rdaddress_Q <= multiplier_counter;
					rdaddress_U <= multiplier_counter;
					rdaddress_R <= multiplier_counter;
					rdaddress_L <= multiplier_counter;
					if (multiplier_counter >= 1)
						begin
							wren <= 1'b1; //write enable multiply buffers
							wren_polyn = 1'b1;//write enable coef mems
						end
					if (multiplier_counter >=2)
						begin
							if(swap_signal == 1'b1)
								begin
									gf_multiplier_euclid_alg_2(leading_coef_R,Q_polyn_out,in_R);
									gf_multiplier_euclid_alg_2(leading_coef_R,U_polyn_out,in_L);
									gf_multiplier_euclid_alg_2(leading_coef_Q,R_polyn_out,in_Q);
									gf_multiplier_euclid_alg_2(leading_coef_Q,L_polyn_out,in_U);

									Q_dpram_addr <= multiplier_counter - 2;
									U_dpram_addr <= multiplier_counter - 2;
									mod_syndr_polyn_Q <= R_polyn_out;
									erasure_polyn_U <= L_polyn_out;
								end
								else begin
									gf_multiplier_euclid_alg_2(leading_coef_Q,R_polyn_out,in_R);
									gf_multiplier_euclid_alg_2(leading_coef_Q,L_polyn_out,in_L);
									gf_multiplier_euclid_alg_2(leading_coef_R,Q_polyn_out,in_Q);
									gf_multiplier_euclid_alg_2(leading_coef_R,U_polyn_out,in_U);
								end
							wraddress_shifted <= degree_shift + (multiplier_counter-2);
							wraddress <= multiplier_counter-2;
							rden <= 1'b1;//rd enable mult buffers
						end
					multiplier_counter = multiplier_counter + 1;
					if (multiplier_counter >=4)//gf_mult o/p available
						begin
							rdaddress <= multiplier_counter - 4;	//rd multipl buffers
						end
					if (multiplier_counter >= 6)
						begin
							R_dpram_addr <= multiplier_counter - 6;
							L_dpram_addr <= multiplier_counter - 6;
							magnitude_polyn_R <= Q_out^R_out;
							locator_polyn_L <= L_out^U_out;
						end
					if (multiplier_counter == number_of_coefs + 7) state<=7;//6'd39

					end//end of polynomial_compute = 1'b1
		7:
						begin
							no_of_mea_iterations <= no_of_mea_iterations + 1;
							if(no_of_mea_iterations>no_of_parity)
								begin
									state<=4;
									max_mea_iterations_reached =1'b1;
								end
							degree_Q <= no_of_parity;
							degree_R <= no_of_parity;
							degree_L <= no_of_parity;
							rden = 1'b0;
							wren_polyn = 1'b0;
							wraddress_shifted = 0;
							wraddress = 0;
							multiplier_counter =6'd0;
							swap_signal <= 0;
							state<=0;
						end

		endcase

	end//MEA_iteration = 1'b1

/****Sending out the coefficients of errata (errors-&-erasure) magnitude polynomial -->omega(x)*****/

if(send_magnitude_errata_coefs==1'b1)
	begin
		if(magnitude_and_locator_polyn_output == 1'b1)
			begin
				rdaddress_R <= errata_magnitude_addr_to_chien +1;
				errata_magnitude_coefs <= R_polyn_out;

				if(rdaddress_R>=1)errata_magnitude_addr = errata_magnitude_addr_to_chien-1;
				errata_magnitude_addr_to_chien = errata_magnitude_addr_to_chien + 1;
				errata_magnitude_coef_ready=1'b1;
			end
		else if (syndr_and_erasure_polyn_output == 1'b1)
			begin
				rdaddress_Q <= errata_magnitude_addr_to_chien +1;
				errata_magnitude_coefs <= Q_polyn_out;

				if(rdaddress_Q>=1)errata_magnitude_addr = errata_magnitude_addr_to_chien-1;
				errata_magnitude_addr_to_chien = errata_magnitude_addr_to_chien + 1;
				errata_magnitude_coef_ready=1'b1;
			end
	end
	else if(send_magnitude_errata_coefs==1'b0)errata_magnitude_coef_ready=1'b0;

/****Sending out the coefficients of errata (errors-&-erasure) locator polynomial--> psi(x)*****/

if(send_loc_errata_coefs==1'b1)
	begin
		if(magnitude_and_locator_polyn_output == 1'b1)
			begin
			rdaddress_L <= errata_loc_addr_to_chien+1;
			errata_loc_coefs <= L_polyn_out;

			if(rdaddress_L>=1)errata_loc_addr = errata_loc_addr_to_chien-1;
			errata_loc_addr_to_chien = errata_loc_addr_to_chien + 1;
			errata_loc_coef_ready=1'b1;
			end
		else if(syndr_and_erasure_polyn_output == 1'b1)
			begin
			rdaddress_U <= errata_loc_addr_to_chien+1;
			errata_loc_coefs <= U_polyn_out;

			if(rdaddress_U >= 1)errata_loc_addr = errata_loc_addr_to_chien-1;
			errata_loc_addr_to_chien = errata_loc_addr_to_chien + 1;
			errata_loc_coef_ready=1'b1;
			end
	end
	else if(send_loc_errata_coefs==1'b0)errata_loc_coef_ready=1'b0;
end
end

//assign locator_degree = locator_degree;
assign magnitue_polyn = magnitude_polyn_R;
assign locator_polyn = locator_polyn_L;
assign state_case = state;
assign R_degree = degree_R;
assign Q_degree = degree_Q;
assign L_degree = degree_L;

endmodule

// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: mult_by_32_2.v
// Megafunction Name(s):
// 			lpm_mult
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module mult_by_32_2 (
	dataa,
	result);

	input	[9:0]  dataa;
	output	[15:0]  result;
    assign result = dataa * 6'h20;

/*
	lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (sub_wire1),
				.result (sub_wire0));
	defparam
		lpm_mult_component.lpm_widtha = 10,
		lpm_mult_component.lpm_widthb = 6,
		lpm_mult_component.lpm_widthp = 16,
		lpm_mult_component.lpm_widths = 16,
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_representation = "UNSIGNED",
		lpm_mult_component.lpm_hint = "INPUT_B_IS_CONSTANT=YES,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6";
*/

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthA NUMERIC "10"
// Retrieval info: PRIVATE: WidthB NUMERIC "6"
// Retrieval info: PRIVATE: WidthS NUMERIC "16"
// Retrieval info: PRIVATE: WidthP NUMERIC "16"
// Retrieval info: PRIVATE: OptionalSum NUMERIC "0"
// Retrieval info: PRIVATE: AutoSizeResult NUMERIC "1"
// Retrieval info: PRIVATE: B_isConstant NUMERIC "1"
// Retrieval info: PRIVATE: SignedMult NUMERIC "0"
// Retrieval info: PRIVATE: ConstantB NUMERIC "32"
// Retrieval info: PRIVATE: ValidConstant NUMERIC "1"
// Retrieval info: PRIVATE: Latency NUMERIC "0"
// Retrieval info: PRIVATE: aclr NUMERIC "0"
// Retrieval info: PRIVATE: clken NUMERIC "0"
// Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "0"
// Retrieval info: PRIVATE: optimize NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTHA NUMERIC "10"
// Retrieval info: CONSTANT: LPM_WIDTHB NUMERIC "6"
// Retrieval info: CONSTANT: LPM_WIDTHP NUMERIC "16"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "16"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MULT"
// Retrieval info: CONSTANT: LPM_REPRESENTATION STRING "UNSIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "INPUT_B_IS_CONSTANT=YES,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6"
// Retrieval info: USED_PORT: dataa 0 0 10 0 INPUT NODEFVAL dataa[9..0]
// Retrieval info: USED_PORT: result 0 0 16 0 OUTPUT NODEFVAL result[15..0]
// Retrieval info: CONNECT: @dataa 0 0 10 0 dataa 0 0 10 0
// Retrieval info: CONNECT: result 0 0 16 0 @result 0 0 16 0
// Retrieval info: CONNECT: @datab 0 0 6 0 32 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: mult_by_32.v
// Megafunction Name(s):
// 			lpm_mult
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module mult_by_32 (
	dataa,
	result);

	input	[9:0]  dataa;
	output	[15:0]  result;

    assign result = dataa * 6'h20;
/*
	lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (sub_wire1),
				.result (sub_wire0));
	defparam
		lpm_mult_component.lpm_widtha = 10,
		lpm_mult_component.lpm_widthb = 6,
		lpm_mult_component.lpm_widthp = 16,
		lpm_mult_component.lpm_widths = 16,
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_representation = "UNSIGNED",
		lpm_mult_component.lpm_hint = "INPUT_B_IS_CONSTANT=YES,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6";
*/

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthA NUMERIC "10"
// Retrieval info: PRIVATE: WidthB NUMERIC "6"
// Retrieval info: PRIVATE: WidthS NUMERIC "16"
// Retrieval info: PRIVATE: WidthP NUMERIC "16"
// Retrieval info: PRIVATE: OptionalSum NUMERIC "0"
// Retrieval info: PRIVATE: AutoSizeResult NUMERIC "1"
// Retrieval info: PRIVATE: B_isConstant NUMERIC "1"
// Retrieval info: PRIVATE: SignedMult NUMERIC "0"
// Retrieval info: PRIVATE: ConstantB NUMERIC "32"
// Retrieval info: PRIVATE: ValidConstant NUMERIC "1"
// Retrieval info: PRIVATE: Latency NUMERIC "0"
// Retrieval info: PRIVATE: aclr NUMERIC "0"
// Retrieval info: PRIVATE: clken NUMERIC "0"
// Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "0"
// Retrieval info: PRIVATE: optimize NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTHA NUMERIC "10"
// Retrieval info: CONSTANT: LPM_WIDTHB NUMERIC "6"
// Retrieval info: CONSTANT: LPM_WIDTHP NUMERIC "16"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "16"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MULT"
// Retrieval info: CONSTANT: LPM_REPRESENTATION STRING "UNSIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "INPUT_B_IS_CONSTANT=YES,DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6"
// Retrieval info: USED_PORT: dataa 0 0 10 0 INPUT NODEFVAL dataa[9..0]
// Retrieval info: USED_PORT: result 0 0 16 0 OUTPUT NODEFVAL result[15..0]
// Retrieval info: CONNECT: @dataa 0 0 10 0 dataa 0 0 10 0
// Retrieval info: CONNECT: result 0 0 16 0 @result 0 0 16 0
// Retrieval info: CONNECT: @datab 0 0 6 0 32 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: omega_buffer.v
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


module omega_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);

	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: Q_buffer_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Q_buffer_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: Q_buffer_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Q_buffer_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: Q_buffer.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Q_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_buffer_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: Q_Polynomial_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Q_Polynomial_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];
	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: Q_Polynomial_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Q_Polynomial_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: Q_Polynomial.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module Q_Polynomial (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL Q_Polynomial_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: R_buffer_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module R_buffer_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: R_buffer_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module R_buffer_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: R_buffer.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module R_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_buffer_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: R_Polynomial_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module R_Polynomial_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: R_Polynomial_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module R_Polynomial_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: R_Polynomial.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module R_Polynomial (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL R_Polynomial_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: sigma_buffer_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module sigma_buffer_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: sigma_buffer_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module sigma_buffer_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: sigma_buffer.v
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


module sigma_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[7:0]  wraddress;
	input	[7:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);

    /*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0));
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 8,
		altsyncram_component.numwords_a = 256,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 8,
		altsyncram_component.numwords_b = 256,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.ram_block_type = "AUTO";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "2048"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "DUAL_PORT"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: WIDTH_B NUMERIC "8"
// Retrieval info: CONSTANT: WIDTHAD_B NUMERIC "8"
// Retrieval info: CONSTANT: NUMWORDS_B NUMERIC "256"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: CONSTANT: OUTDATA_REG_B STRING "UNREGISTERED"
// Retrieval info: CONSTANT: INDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: WRCONTROL_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: RAM_BLOCK_TYPE STRING "AUTO"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 8 0 INPUT NODEFVAL wraddress[7..0]
// Retrieval info: USED_PORT: rdaddress 0 0 8 0 INPUT NODEFVAL rdaddress[7..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 8 0 wraddress 0 0 8 0
// Retrieval info: CONNECT: @address_b 0 0 8 0 rdaddress 0 0 8 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all

// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: signed_multiplier2.v
// Megafunction Name(s):
// 			lpm_mult
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module signed_multiplier2 (
	dataa,
	datab,
	clock,
	result);

	input	[14:0]  dataa;
	input	[8:0]  datab;
	input	  clock;
	output	[23:0]  result;
	reg	[23:0]  pipeline= 24'b0;

    always @(posedge clock)
    begin
        result = pipeline;
        pipeline = $signed(dataa) * $signed(datab);
    end


	/*lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (datab),
				.clock (clock),
				.result (sub_wire0));
	defparam
		lpm_mult_component.lpm_widtha = 15,
		lpm_mult_component.lpm_widthb = 9,
		lpm_mult_component.lpm_widthp = 24,
		lpm_mult_component.lpm_widths = 24,
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_representation = "SIGNED",
		lpm_mult_component.lpm_hint = "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
		lpm_mult_component.lpm_pipeline = 2;*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthA NUMERIC "15"
// Retrieval info: PRIVATE: WidthB NUMERIC "9"
// Retrieval info: PRIVATE: WidthS NUMERIC "24"
// Retrieval info: PRIVATE: WidthP NUMERIC "24"
// Retrieval info: PRIVATE: OptionalSum NUMERIC "0"
// Retrieval info: PRIVATE: AutoSizeResult NUMERIC "1"
// Retrieval info: PRIVATE: B_isConstant NUMERIC "0"
// Retrieval info: PRIVATE: SignedMult NUMERIC "1"
// Retrieval info: PRIVATE: ConstantB NUMERIC "0"
// Retrieval info: PRIVATE: ValidConstant NUMERIC "0"
// Retrieval info: PRIVATE: Latency NUMERIC "1"
// Retrieval info: PRIVATE: aclr NUMERIC "0"
// Retrieval info: PRIVATE: clken NUMERIC "0"
// Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "2"
// Retrieval info: PRIVATE: optimize NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTHA NUMERIC "15"
// Retrieval info: CONSTANT: LPM_WIDTHB NUMERIC "9"
// Retrieval info: CONSTANT: LPM_WIDTHP NUMERIC "24"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "24"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MULT"
// Retrieval info: CONSTANT: LPM_REPRESENTATION STRING "SIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6"
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "2"
// Retrieval info: USED_PORT: dataa 0 0 15 0 INPUT NODEFVAL dataa[14..0]
// Retrieval info: USED_PORT: result 0 0 24 0 OUTPUT NODEFVAL result[23..0]
// Retrieval info: USED_PORT: datab 0 0 9 0 INPUT NODEFVAL datab[8..0]
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @dataa 0 0 15 0 dataa 0 0 15 0
// Retrieval info: CONNECT: result 0 0 24 0 @result 0 0 24 0
// Retrieval info: CONNECT: @datab 0 0 9 0 datab 0 0 9 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: signed_multiplier3.v
// Megafunction Name(s):
// 			lpm_mult
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module signed_multiplier3 (
	dataa,
	datab,
	clock,
	result);

	input	[14:0]  dataa;
	input	[8:0]  datab;
	input	  clock;
	output	[23:0]  result;
	reg[23:0] pipeline = 24'b0;

    always @(posedge clock)
    begin
        result = pipeline;
        pipeline = $signed(dataa) * $signed(datab);
    end

    /*
	lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (datab),
				.clock (clock),
				.result (sub_wire0));
	defparam
		lpm_mult_component.lpm_widtha = 15,
		lpm_mult_component.lpm_widthb = 9,
		lpm_mult_component.lpm_widthp = 24,
		lpm_mult_component.lpm_widths = 24,
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_representation = "SIGNED",
		lpm_mult_component.lpm_hint = "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
		lpm_mult_component.lpm_pipeline = 2;*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthA NUMERIC "15"
// Retrieval info: PRIVATE: WidthB NUMERIC "9"
// Retrieval info: PRIVATE: WidthS NUMERIC "24"
// Retrieval info: PRIVATE: WidthP NUMERIC "24"
// Retrieval info: PRIVATE: OptionalSum NUMERIC "0"
// Retrieval info: PRIVATE: AutoSizeResult NUMERIC "1"
// Retrieval info: PRIVATE: B_isConstant NUMERIC "0"
// Retrieval info: PRIVATE: SignedMult NUMERIC "1"
// Retrieval info: PRIVATE: ConstantB NUMERIC "0"
// Retrieval info: PRIVATE: ValidConstant NUMERIC "0"
// Retrieval info: PRIVATE: Latency NUMERIC "1"
// Retrieval info: PRIVATE: aclr NUMERIC "0"
// Retrieval info: PRIVATE: clken NUMERIC "0"
// Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "2"
// Retrieval info: PRIVATE: optimize NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTHA NUMERIC "15"
// Retrieval info: CONSTANT: LPM_WIDTHB NUMERIC "9"
// Retrieval info: CONSTANT: LPM_WIDTHP NUMERIC "24"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "24"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MULT"
// Retrieval info: CONSTANT: LPM_REPRESENTATION STRING "SIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6"
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "2"
// Retrieval info: USED_PORT: dataa 0 0 15 0 INPUT NODEFVAL dataa[14..0]
// Retrieval info: USED_PORT: result 0 0 24 0 OUTPUT NODEFVAL result[23..0]
// Retrieval info: USED_PORT: datab 0 0 9 0 INPUT NODEFVAL datab[8..0]
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @dataa 0 0 15 0 dataa 0 0 15 0
// Retrieval info: CONNECT: result 0 0 24 0 @result 0 0 24 0
// Retrieval info: CONNECT: @datab 0 0 9 0 datab 0 0 9 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: signed_multiplier4.v
// Megafunction Name(s):
// 			lpm_mult
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module signed_multiplier4 (
	dataa,
	datab,
	clock,
	result);

	input	[14:0]  dataa;
	input	[8:0]  datab;
	input	  clock;
	output	[23:0]  result;

	wire [23:0] sub_wire0;
	wire [23:0] result = sub_wire0[23:0];
	reg[23:0] pipeline = 24'b0;

    always @(posedge clock)
    begin
        result = pipeline;
        pipeline = $signed(dataa) * $signed(datab);
    end

	/*lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (datab),
				.clock (clock),
				.result (sub_wire0));
	defparam
		lpm_mult_component.lpm_widtha = 15,
		lpm_mult_component.lpm_widthb = 9,
		lpm_mult_component.lpm_widthp = 24,
		lpm_mult_component.lpm_widths = 24,
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_representation = "SIGNED",
		lpm_mult_component.lpm_hint = "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
		lpm_mult_component.lpm_pipeline = 2*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthA NUMERIC "15"
// Retrieval info: PRIVATE: WidthB NUMERIC "9"
// Retrieval info: PRIVATE: WidthS NUMERIC "24"
// Retrieval info: PRIVATE: WidthP NUMERIC "24"
// Retrieval info: PRIVATE: OptionalSum NUMERIC "0"
// Retrieval info: PRIVATE: AutoSizeResult NUMERIC "1"
// Retrieval info: PRIVATE: B_isConstant NUMERIC "0"
// Retrieval info: PRIVATE: SignedMult NUMERIC "1"
// Retrieval info: PRIVATE: ConstantB NUMERIC "0"
// Retrieval info: PRIVATE: ValidConstant NUMERIC "0"
// Retrieval info: PRIVATE: Latency NUMERIC "1"
// Retrieval info: PRIVATE: aclr NUMERIC "0"
// Retrieval info: PRIVATE: clken NUMERIC "0"
// Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "2"
// Retrieval info: PRIVATE: optimize NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTHA NUMERIC "15"
// Retrieval info: CONSTANT: LPM_WIDTHB NUMERIC "9"
// Retrieval info: CONSTANT: LPM_WIDTHP NUMERIC "24"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "24"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MULT"
// Retrieval info: CONSTANT: LPM_REPRESENTATION STRING "SIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6"
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "2"
// Retrieval info: USED_PORT: dataa 0 0 15 0 INPUT NODEFVAL dataa[14..0]
// Retrieval info: USED_PORT: result 0 0 24 0 OUTPUT NODEFVAL result[23..0]
// Retrieval info: USED_PORT: datab 0 0 9 0 INPUT NODEFVAL datab[8..0]
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @dataa 0 0 15 0 dataa 0 0 15 0
// Retrieval info: CONNECT: result 0 0 24 0 @result 0 0 24 0
// Retrieval info: CONNECT: @datab 0 0 9 0 datab 0 0 9 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: signed_multiplier.v
// Megafunction Name(s):
// 			lpm_mult
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module signed_multiplier (
	dataa,
	datab,
	clock,
	result);

	input	[14:0]  dataa;
	input	[8:0]  datab;
	input	  clock;
	output	[23:0]  result;
	reg[23:0] pipeline = 24'b0;

    always @(posedge clock)
    begin
        result = pipeline;
        pipeline = $signed(dataa) * $signed(datab);
    end

/*
	lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (datab),
				.clock (clock),
				.result (sub_wire0));
	defparam
		lpm_mult_component.lpm_widtha = 15,
		lpm_mult_component.lpm_widthb = 9,
		lpm_mult_component.lpm_widthp = 24,
		lpm_mult_component.lpm_widths = 24,
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_representation = "SIGNED",
		lpm_mult_component.lpm_hint = "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6",
		lpm_mult_component.lpm_pipeline = 2;*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthA NUMERIC "15"
// Retrieval info: PRIVATE: WidthB NUMERIC "9"
// Retrieval info: PRIVATE: WidthS NUMERIC "24"
// Retrieval info: PRIVATE: WidthP NUMERIC "24"
// Retrieval info: PRIVATE: OptionalSum NUMERIC "0"
// Retrieval info: PRIVATE: AutoSizeResult NUMERIC "1"
// Retrieval info: PRIVATE: B_isConstant NUMERIC "0"
// Retrieval info: PRIVATE: SignedMult NUMERIC "1"
// Retrieval info: PRIVATE: ConstantB NUMERIC "0"
// Retrieval info: PRIVATE: ValidConstant NUMERIC "0"
// Retrieval info: PRIVATE: Latency NUMERIC "1"
// Retrieval info: PRIVATE: aclr NUMERIC "0"
// Retrieval info: PRIVATE: clken NUMERIC "0"
// Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "2"
// Retrieval info: PRIVATE: optimize NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTHA NUMERIC "15"
// Retrieval info: CONSTANT: LPM_WIDTHB NUMERIC "9"
// Retrieval info: CONSTANT: LPM_WIDTHP NUMERIC "24"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "24"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MULT"
// Retrieval info: CONSTANT: LPM_REPRESENTATION STRING "SIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=6"
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "2"
// Retrieval info: USED_PORT: dataa 0 0 15 0 INPUT NODEFVAL dataa[14..0]
// Retrieval info: USED_PORT: result 0 0 24 0 OUTPUT NODEFVAL result[23..0]
// Retrieval info: USED_PORT: datab 0 0 9 0 INPUT NODEFVAL datab[8..0]
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @dataa 0 0 15 0 dataa 0 0 15 0
// Retrieval info: CONNECT: result 0 0 24 0 @result 0 0 24 0
// Retrieval info: CONNECT: @datab 0 0 9 0 datab 0 0 9 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

module top_rs_decode(
									reset,
									ext_clk,
									k_value,						//number of message bytes
									no_of_parity,					//number of parity bytes
									new_data,
									send_data,


//signals for the Dpram storing the 10-bit quantized channel data and the fading gain
//read by erasure generator
									rdaddress_in,
									q_in, 							//10-bit sampled signal
									rdaddress_fade,
									q_fade, 						//10-bit fading gain

//erasure generator signals
									sigma_value,					//standard deviation of gaussian noise
									sigma_square,					//variance of gaussian noise
									norm_sigma_square, 				//scaled variance
									fade_value,						//channel fading gain
									channel_char,					//scaled variance divide-by-fading gain
									threshold_0,
									threshold_1,
									threshold_2,					//pre-determined erasure threshold value
									cutoff_threshold_0,
									cutoff_threshold_1,
									cutoff_threshold_2,
									cutoff_threshold_ready,
									new_channel_char,				// triggers sampled data to be sorted according to magnitude
									exact_smallest,					//most-unreliable-sampled signal
									normalized_signal,				//most-unreliable-sampled signal scaled
									modified_actual_distance,
									recieved_codeword,				//estimation of recieved codeword
									erasure_flag_0,
									erasure_flag_1,
									erasure_flag_2,
//signals for the Dpram storing the estimated recieved codeword & erasure flags
//written by erassure generator, read by decoder
									wren_decoder_in_buffer,
									write_addr,
									cw_data,
									decoder_rd_addr,
									recvd_codeword,
									rd_enable,

									erasure,
									recvd_erasure_flag_0,
									recvd_erasure_flag_1,
									recvd_erasure_flag_2,
//signals for the GF(256) lookup table
									decode_strobe,
//FIFO signals
									rdaddress,
									q,
									wren,

//Signals for erasure position calculation
									erase_position_0,
									erase_position_1,
									erase_position_2,
									number_of_erasures_0,
									number_of_erasures_1,
									number_of_erasures_2,
									erasures_absent_0,
									erasures_absent_1,
									erasures_absent_2,

//Signals for syndrome computation
									syndrome,
									unmodified_syndr_polyn_0,		//syndrome sent sent to MEA if there are no erasures
									unmodified_syndr_polyn_1,
									unmodified_syndr_polyn_2,
//Signals for erasure polynomial generation
									start_erasure_polyn_compute,
									erasure_polyn_0,
									no_of_erasure_coefs_0,
									erasure_coef_ready_0,
									erasure_polyn_1,
									no_of_erasure_coefs_1,
									erasure_coef_ready_1,
									erasure_polyn_2,
									no_of_erasure_coefs_2,
									erasure_coef_ready_2,

//Signals for modified syndrome polynomial generation
									load_non_zero_syndrome_done,
									start_modified_syndrome_polyn_compute,
									modified_syndr_polyn_0,
									syndr_coef_ready_0,
									modified_syndr_polyn_1,
									syndr_coef_ready_1,
									modified_syndr_polyn_2,
									syndr_coef_ready_2,
//Signals for modified Euclidean Algorithm	(MEA)

									send_erasure_polyn_0,
									send_syndr_polyn_0,
									send_unmodified_syndr_polyn_0,
									R_degree_0,
									Q_degree_0,
									L_degree_0,
									state_case_0,
									MEA_compute_done_0,
									locator_polyn_0,
									magnitue_polyn_0,
									errata_loc_coefs_0, 				//errors-&-erasures locator polynomial
									errata_magnitude_coefs_0,			//errors-&-erasures magnitude polynomial
									locator_degree_0,					//number of errors identified
									send_erasure_polyn_1,
									send_syndr_polyn_1,
									send_unmodified_syndr_polyn_1,
									R_degree_1,
									Q_degree_1,
									L_degree_1,
									state_case_1,
									MEA_compute_done_1,
									locator_polyn_1,
									magnitue_polyn_1,
									errata_loc_coefs_1, 				//errors-&-erasures locator polynomial
									errata_magnitude_coefs_1,			//errors-&-erasures magnitude polynomial
									locator_degree_1,					//number of errors identified
									send_erasure_polyn_2,
									send_syndr_polyn_2,
									send_unmodified_syndr_polyn_2,
									R_degree_2,
									Q_degree_2,
									L_degree_2,
									state_case_2,
									MEA_compute_done_2,
									locator_polyn_2,
									magnitue_polyn_2,
									errata_loc_coefs_2, 				//errors-&-erasures locator polynomial
									errata_magnitude_coefs_2,			//errors-&-erasures magnitude polynomial
									locator_degree_2,
//Signals for Chien Serach algorithm, Forney algorithm and Error correction block
									cycle,
									error_location_0,
									derivative_error_location,
									error_magnitude,
									corrected_cword_ready,
									corrected_cw,					//corrected codeword
									error_location_1,
									corrected_error_count,			//number of errors corrected
									signal_count,quotient,
									error_location_2

									//Q_x,R,L,U,m_counter,test_Q,test_R,test_L,test_U,
									//rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U //test

					);

/////////////////////////////////////////////
//PARAMETERIZED Triple DECODER RS
//Implements (255,k) RS Decoder
//Define k as desired, valid values are:
//217, 221, 225, 233, 237, 239
//Insure only ONE K is defined for correct operation
/////////////////////////////////////////////

//`define K217
//`define K221
//`define K225
//`define K233
//`define K237
`define K239

`ifdef K217
	parameter width = 6;
	parameter dif = 38;
	parameter erasure_threshold_value_0 = -9'd220;// T = 0.1
	parameter erasure_threshold_value_1 = -9'd115;// T = 0.24
	parameter erasure_threshold_value_2 = -9'd66;// T = 0.34
`endif

`ifdef K221
	parameter width = 6;
	parameter dif = 34;
	parameter erasure_threshold_value_0 = -9'd244;//T = 0.08
	parameter erasure_threshold_value_1 = -9'd132;//T = 0.21
	parameter erasure_threshold_value_2 = -9'd85;// T = 0.3
`endif

`ifdef K225
	parameter width = 6;
	parameter dif = 30;
	parameter erasure_threshold_value_0 = -9'd244;//T = 0.08
	parameter erasure_threshold_value_1 = -9'd127;//T = 0.22
	parameter erasure_threshold_value_2 = -9'd85;// T = 0.3
`endif

`ifdef K233
	parameter width = 5;
	parameter dif = 22;
	parameter erasure_threshold_value_0 = -9'd244;//T = 0.08
	parameter erasure_threshold_value_1 = -9'd152;//T = 0.18
	parameter erasure_threshold_value_2 = -9'd105;//T = 0.36
`endif

`ifdef K237
	parameter width = 5;
	parameter dif = 18;
	parameter erasure_threshold_value_0 = -9'd244;//T = 0.08
	parameter erasure_threshold_value_1 = -9'd127;//T = 0.22
	parameter erasure_threshold_value_2 = -9'd62;//T = 0.35
`endif

`ifdef K239
	parameter width = 5;
	parameter dif = 16;
	parameter erasure_threshold_value_0 = -9'd94;//T = 0.28
	parameter erasure_threshold_value_1 = -9'd173;//T = 0.15
	parameter erasure_threshold_value_2 = -9'd75;// T = 0.32
`endif

input reset,ext_clk;
input[7:0]k_value;//number of bytes in the message
input [4:0] sigma_value;//standard deviation of the noise

//erasure generator outputs
output reg wren_decoder_in_buffer,rd_enable,wren,erasure;
output new_channel_char;//start_sort;
output [9:0] fade_value;
output [0:7]recieved_codeword;
output [9:0] exact_smallest;
output [14:0] normalized_signal;
output [23:0] modified_actual_distance;
output [8:0] threshold_0,threshold_1,threshold_2;
output [10:0] rdaddress_in;
output reg [7:0] write_addr,cw_data,decoder_rd_addr;
output [7:0] rdaddress_fade;
output [3:0] signal_count;
//decoder outputs
output reg send_data,new_data;
output decode_strobe;
output [7:0]erase_position_0,erase_position_1,erase_position_2;
output [7:0]erasure_polyn_0,modified_syndr_polyn_0;
output [7:0]erasure_polyn_1,modified_syndr_polyn_1;
output [7:0]erasure_polyn_2,modified_syndr_polyn_2;
output reg start_erasure_polyn_compute,start_modified_syndrome_polyn_compute;
output [width-1:0] no_of_erasure_coefs_0,no_of_erasure_coefs_1,no_of_erasure_coefs_2;
output reg [width-1:0] no_of_parity;
output [width-1:0]number_of_erasures_0,number_of_erasures_1,number_of_erasures_2;
output [7:0] syndrome;
output [7:0] unmodified_syndr_polyn_0,unmodified_syndr_polyn_1,unmodified_syndr_polyn_2;
output [7:0] locator_polyn_0,magnitue_polyn_0,locator_polyn_1,magnitue_polyn_1;
output [7:0] locator_polyn_2,magnitue_polyn_2;
output load_non_zero_syndrome_done;
output send_erasure_polyn_0,send_erasure_polyn_1,send_erasure_polyn_2;
output syndr_coef_ready_0,send_syndr_polyn_0,erasure_coef_ready_0;
output syndr_coef_ready_1,send_syndr_polyn_1,erasure_coef_ready_1;
output syndr_coef_ready_2,send_syndr_polyn_2,erasure_coef_ready_2;
output reg erasures_absent_0,erasures_absent_1,erasures_absent_2;
output send_unmodified_syndr_polyn_0,send_unmodified_syndr_polyn_1;
output send_unmodified_syndr_polyn_2;
output MEA_compute_done_0,MEA_compute_done_1,MEA_compute_done_2;
output [2:0]state_case_0,state_case_1,state_case_2;
output [width-1:0]R_degree_0,Q_degree_0,L_degree_0;
output [width-1:0]R_degree_1,Q_degree_1,L_degree_1;
output [width-1:0]R_degree_2,Q_degree_2,L_degree_2;
output [7:0]corrected_error_count;
output [8:0]cycle;
output [7:0] q,corrected_cw;
output corrected_cword_ready;

//output [7:0] Q_x,R,L,U,test_Q,test_R,test_L,test_U;
//output [5:0] m_counter,rdaddress_Q,rdaddress_R,rdaddress_L,rdaddress_U;

reg[7:0] temp_k_value;
reg[width-1:0]temp_no_of_parity;
reg [7:0]count,write_flag_addr;

reg[31:0] cw_addr;

//erasure generator outputs
output wire cutoff_threshold_ready;
output wire [14:0] channel_char;
output wire [14:0] quotient;
output wire[9:0]sigma_square;
output wire [14:0]norm_sigma_square;
output wire[23:0]cutoff_threshold_0;
output wire[23:0]cutoff_threshold_1;
output wire[23:0]cutoff_threshold_2;
output wire [9:0] q_in,q_fade;
output wire [7:0] recvd_codeword;
output wire erasure_flag_0,recvd_erasure_flag_0;
output wire erasure_flag_1,recvd_erasure_flag_1;
output wire erasure_flag_2,recvd_erasure_flag_2;

//GF(256) lookup table
wire read_alpha_inverse,gf_table_ready;
wire [7:0] err_loc_derivativative,alpha_inverse;//,chien_root;

//FIFO wires
output wire [7:0] rdaddress;
wire rden_delay_buffer;

//wire [7:0]erase_position;
wire [7:0]erase_position_0,erase_position_1;
wire erasure_polyn_compute_done_0,modified_syndrome_polyn_compute_done_0;
wire erasure_polyn_compute_done_1,modified_syndrome_polyn_compute_done_1;
wire erasure_polyn_compute_done_2,modified_syndrome_polyn_compute_done_2;

wire send_syndromes,codeword_end_flag,erasure_ready;
wire [width-1:0]syndr_coef_addr;
wire syndrome_ready;
wire unmodified_syndrome_ready_0,unmodified_syndrome_ready_1,unmodified_syndrome_ready_2;

output wire [7:0] error_location_0,derivative_error_location,error_magnitude;
output wire [7:0] errata_loc_coefs_0,errata_magnitude_coefs_0;
output wire [width-1:0]locator_degree_0;
wire [width-1:0] erase_coef_addr_0,errata_loc_addr_0,errata_magnitude_addr_0;
wire [width-1:0] modified_syndr_coef_addr_0,unmodified_syndr_coef_addr_0;
wire deactivate_chien_serach_0;//codeword is error-free

output wire [7:0] error_location_1;
output wire [7:0] errata_loc_coefs_1,errata_magnitude_coefs_1;
output wire [width-1:0]locator_degree_1;
wire [width-1:0] erase_coef_addr_1,errata_loc_addr_1,errata_magnitude_addr_1;
wire [width-1:0] modified_syndr_coef_addr_1,unmodified_syndr_coef_addr_1;
wire deactivate_chien_serach_1;//codeword is error-free

output wire [7:0] error_location_2;
output wire [7:0] errata_loc_coefs_2,errata_magnitude_coefs_2;
output wire [width-1:0]locator_degree_2;
wire [width-1:0] erase_coef_addr_2,errata_loc_addr_2,errata_magnitude_addr_2;
wire [width-1:0] modified_syndr_coef_addr_2,unmodified_syndr_coef_addr_2;
wire deactivate_chien_serach_2;//codeword is error-free


defparam inst0.erasure_threshold_value_0=erasure_threshold_value_0;
defparam inst0.erasure_threshold_value_1=erasure_threshold_value_1;
defparam inst0.erasure_threshold_value_2=erasure_threshold_value_2;
erasure_generator	inst0(
						.clk						(ext_clk),
						.reset						(reset),
						.rden						(rden),
						.rdaddress					(rdaddress_in),
						.q							(q_in),
						.rdaddress_fade				(rdaddress_fade),
						.q_fade						(q_fade),
						.new_channel_char			(new_channel_char),
						.sigma_value				(sigma_value),
						.sigma_square				(sigma_square),
						.norm_sigma_square			(norm_sigma_square),
						.cutoff_threshold_0			(cutoff_threshold_0),
						.cutoff_threshold_1			(cutoff_threshold_1),
						.cutoff_threshold_2			(cutoff_threshold_2),
						.exact_smallest				(exact_smallest),
						.normalized_signal			(normalized_signal),
						.modified_actual_distance	(modified_actual_distance),
						.channel_char				(channel_char),
						.threshold_0				(threshold_0),
						.threshold_1				(threshold_1),
						.threshold_2				(threshold_2),
						.recieved_codeword			(recieved_codeword),
						.erasure_flag_0				(erasure_flag_0),
						.erasure_flag_1				(erasure_flag_1),
						.erasure_flag_2				(erasure_flag_2),
						.signal_count				(signal_count),
						.send_data					(send_data)
					//	.quotient					(quotient)
						);
//buffer used by the erasure generator to store the estimated recieved codeword.
//buffer is read by syndrome computation block in the reed-solomon decoder
decoder_input_buffer 	decoder_input(
									.data				(cw_data),//gets data from erasure generator
									.wren				(wren_decoder_in_buffer),
									.wraddress			(write_addr),
									.rden				(rd_enable),
									.rdaddress			(decoder_rd_addr),
									.clock				(ext_clk),
									.q					(recvd_codeword)
									);
//buffer used by the erasure generator to store the erasures flag.
//buffer is read by erasure_position calculation block in the reed-solomon decoder
decoder_erasure_flags 	decoder_erasures_0(
									.data				(erasure_flag_0),
									.wren				(wren_decoder_in_buffer),
									.wraddress			(write_flag_addr),
									.rden				(rd_enable),
									.rdaddress			(decoder_rd_addr),
									.clock				(ext_clk),
									.q					(recvd_erasure_flag_0)
									);

decoder_erasure_flags_1 	decoder_erasures_1(
									.data				(erasure_flag_1),//gets erasure flags from erasure generator
									.wren				(wren_decoder_in_buffer),
									.wraddress			(write_flag_addr),
									.rden				(rd_enable),
									.rdaddress			(decoder_rd_addr),
									.clock				(ext_clk),
									.q					(recvd_erasure_flag_1)
									);

decoder_erasure_flags_2 	decoder_erasures_2(
									.data				(erasure_flag_2),//gets erasure flags from erasure generator
									.wren				(wren_decoder_in_buffer),
									.wraddress			(write_flag_addr),
									.rden				(rd_enable),
									.rdaddress			(decoder_rd_addr),
									.clock				(ext_clk),
									.q					(recvd_erasure_flag_2)
									);

//signals for the GF(256) lookup table
GF_256_elements 			inst1(
								.clock					(ext_clk),
								.reset					(reset),
								.read_alpha_inverse		(read_alpha_inverse),
								.gf_table_ready			(gf_table_ready),
								.err_loc_derivativative	(err_loc_derivativative),
								.alpha_inverse			(alpha_inverse),
								.decode_strobe			(decode_strobe)
						 		 );

//signals for reed solomon delay buffer (FIFO)
delay_buffer			inst2(
								.wraddress				(decoder_rd_addr),//rd
								.wren					(wren),
								.data					(recvd_codeword),//transfer data from in_decoder buffer
								.clock					(ext_clk),
								.rdaddress				(rdaddress),
								.rden					(rden_delay_buffer),
								.q						(q)
							);

defparam inst3.width=width;
defparam inst3.max_number_of_erasures=dif;
erasure_position_calc	inst3(
							.clock								(ext_clk),
							.reset								(reset),
							.number_of_erasures_0				(number_of_erasures_0),
							.number_of_erasures_1				(number_of_erasures_1),
							.number_of_erasures_2				(number_of_erasures_2),
							.erase_position_0					(erase_position_0[7:0]),
							.erase_position_1					(erase_position_1[7:0]),
							.erase_position_2					(erase_position_2[7:0]),
							.erasure_flag_0						(recvd_erasure_flag_0),
							.erasure_flag_1						(recvd_erasure_flag_1),
							.erasure_flag_2						(recvd_erasure_flag_2),
							.new_data							(new_data),
							.erase_pos_done_0					(erase_pos_done_0),
							.erase_pos_done_1					(erase_pos_done_1),
							.erase_pos_done_2					(erase_pos_done_2),
							.erasure_ready_0					(erasure_ready_0),
							.erasure_ready_1					(erasure_ready_1),
							.erasure_ready_2					(erasure_ready_2),
							.send_erasure_positions_for_loc_0	(send_erasure_positions_for_loc_0),
							.send_erasure_positions_for_loc_1	(send_erasure_positions_for_loc_1),
							.send_erasure_positions_for_loc_2	(send_erasure_positions_for_loc_2),
							.send_erasure_positions_for_synd_0	(send_erasure_positions_for_synd_0),
							.send_erasure_positions_for_synd_1	(send_erasure_positions_for_synd_1),
							.send_erasure_positions_for_synd_2	(send_erasure_positions_for_synd_2),
							.decoder_rd_addr					(decoder_rd_addr)
							);

///////////
////////////
`ifdef K239
defparam inst4.width=width;
defparam inst4.number_of_coefs=dif;
syndromes				inst4 (
								.recd							(recvd_codeword),
								.reset							(reset),
								.clock							(ext_clk),
								.syndrome						(syndrome),
								.unmodified_syndr_polyn_0		(unmodified_syndr_polyn_0),
								.unmodified_syndr_polyn_1		(unmodified_syndr_polyn_1),
								.unmodified_syndr_polyn_2		(unmodified_syndr_polyn_2),
								.new_data						(new_data),
								.codeword_end_flag				(codeword_end_flag),
								.send_syndromes					(send_syndromes),
								.send_unmodified_syndr_polyn_0	(send_unmodified_syndr_polyn_0),
								.send_unmodified_syndr_polyn_1	(send_unmodified_syndr_polyn_1),
								.send_unmodified_syndr_polyn_2	(send_unmodified_syndr_polyn_2),
								.syndr_coef_addr				(syndr_coef_addr),
								.unmodified_syndr_coef_addr_0	(unmodified_syndr_coef_addr_0),
								.unmodified_syndr_coef_addr_1	(unmodified_syndr_coef_addr_1),
								.unmodified_syndr_coef_addr_2	(unmodified_syndr_coef_addr_2),
								.unmodified_syndrome_ready_0	(unmodified_syndrome_ready_0),
								.unmodified_syndrome_ready_1	(unmodified_syndrome_ready_1),
								.unmodified_syndrome_ready_2	(unmodified_syndrome_ready_2),
								.syndrome_ready					(syndrome_ready),
								.decoder_rd_addr				(decoder_rd_addr)
								);
`endif
`ifdef K237
defparam inst4.width=width;
defparam inst4.number_of_coefs=dif;
syndromes237			inst4 (
								.recd							(recvd_codeword),
								.reset							(reset),
								.clock							(ext_clk),
								.syndrome						(syndrome),
								.unmodified_syndr_polyn_0		(unmodified_syndr_polyn_0),
								.unmodified_syndr_polyn_1		(unmodified_syndr_polyn_1),
								.unmodified_syndr_polyn_2		(unmodified_syndr_polyn_2),
								.new_data						(new_data),
								.codeword_end_flag				(codeword_end_flag),
								.send_syndromes					(send_syndromes),
								.send_unmodified_syndr_polyn_0	(send_unmodified_syndr_polyn_0),
								.send_unmodified_syndr_polyn_1	(send_unmodified_syndr_polyn_1),
								.send_unmodified_syndr_polyn_2	(send_unmodified_syndr_polyn_2),
								.syndr_coef_addr				(syndr_coef_addr),
								.unmodified_syndr_coef_addr_0	(unmodified_syndr_coef_addr_0),
								.unmodified_syndr_coef_addr_1	(unmodified_syndr_coef_addr_1),
								.unmodified_syndr_coef_addr_2	(unmodified_syndr_coef_addr_2),
								.unmodified_syndrome_ready_0	(unmodified_syndrome_ready_0),
								.unmodified_syndrome_ready_1	(unmodified_syndrome_ready_1),
								.unmodified_syndrome_ready_2	(unmodified_syndrome_ready_2),
								.syndrome_ready					(syndrome_ready),
								.decoder_rd_addr				(decoder_rd_addr)
								);
`endif

`ifdef K233
defparam inst4.width=width;
defparam inst4.number_of_coefs=dif;
syndromes233			inst4 (
								.recd							(recvd_codeword),
								.reset							(reset),
								.clock							(ext_clk),
								.syndrome						(syndrome),
								.unmodified_syndr_polyn_0		(unmodified_syndr_polyn_0),
								.unmodified_syndr_polyn_1		(unmodified_syndr_polyn_1),
								.unmodified_syndr_polyn_2		(unmodified_syndr_polyn_2),
								.new_data						(new_data),
								.codeword_end_flag				(codeword_end_flag),
								.send_syndromes					(send_syndromes),
								.send_unmodified_syndr_polyn_0	(send_unmodified_syndr_polyn_0),
								.send_unmodified_syndr_polyn_1	(send_unmodified_syndr_polyn_1),
								.send_unmodified_syndr_polyn_2	(send_unmodified_syndr_polyn_2),
								.syndr_coef_addr				(syndr_coef_addr),
								.unmodified_syndr_coef_addr_0	(unmodified_syndr_coef_addr_0),
								.unmodified_syndr_coef_addr_1	(unmodified_syndr_coef_addr_1),
								.unmodified_syndr_coef_addr_2	(unmodified_syndr_coef_addr_2),
								.unmodified_syndrome_ready_0	(unmodified_syndrome_ready_0),
								.unmodified_syndrome_ready_1	(unmodified_syndrome_ready_1),
								.unmodified_syndrome_ready_2	(unmodified_syndrome_ready_2),
								.syndrome_ready					(syndrome_ready),
								.decoder_rd_addr				(decoder_rd_addr)
								);
`endif
`ifdef K225
defparam inst4.width=width;
defparam inst4.number_of_coefs=dif;
syndromes225			inst4 (
								.recd							(recvd_codeword),
								.reset							(reset),
								.clock							(ext_clk),
								.syndrome						(syndrome),
								.unmodified_syndr_polyn_0		(unmodified_syndr_polyn_0),
								.unmodified_syndr_polyn_1		(unmodified_syndr_polyn_1),
								.unmodified_syndr_polyn_2		(unmodified_syndr_polyn_2),
								.new_data						(new_data),
								.codeword_end_flag				(codeword_end_flag),
								.send_syndromes					(send_syndromes),
								.send_unmodified_syndr_polyn_0	(send_unmodified_syndr_polyn_0),
								.send_unmodified_syndr_polyn_1	(send_unmodified_syndr_polyn_1),
								.send_unmodified_syndr_polyn_2	(send_unmodified_syndr_polyn_2),
								.syndr_coef_addr				(syndr_coef_addr),
								.unmodified_syndr_coef_addr_0	(unmodified_syndr_coef_addr_0),
								.unmodified_syndr_coef_addr_1	(unmodified_syndr_coef_addr_1),
								.unmodified_syndr_coef_addr_2	(unmodified_syndr_coef_addr_2),
								.unmodified_syndrome_ready_0	(unmodified_syndrome_ready_0),
								.unmodified_syndrome_ready_1	(unmodified_syndrome_ready_1),
								.unmodified_syndrome_ready_2	(unmodified_syndrome_ready_2),
								.syndrome_ready					(syndrome_ready),
								.decoder_rd_addr				(decoder_rd_addr)
								);
`endif

`ifdef K221
defparam inst4.width=width;
defparam inst4.number_of_coefs=dif;
syndromes221			inst4 (
								.recd							(recvd_codeword),
								.reset							(reset),
								.clock							(ext_clk),
								.syndrome						(syndrome),
								.unmodified_syndr_polyn_0		(unmodified_syndr_polyn_0),
								.unmodified_syndr_polyn_1		(unmodified_syndr_polyn_1),
								.unmodified_syndr_polyn_2		(unmodified_syndr_polyn_2),
								.new_data						(new_data),
								.codeword_end_flag				(codeword_end_flag),
								.send_syndromes					(send_syndromes),
								.send_unmodified_syndr_polyn_0	(send_unmodified_syndr_polyn_0),
								.send_unmodified_syndr_polyn_1	(send_unmodified_syndr_polyn_1),
								.send_unmodified_syndr_polyn_2	(send_unmodified_syndr_polyn_2),
								.syndr_coef_addr				(syndr_coef_addr),
								.unmodified_syndr_coef_addr_0	(unmodified_syndr_coef_addr_0),
								.unmodified_syndr_coef_addr_1	(unmodified_syndr_coef_addr_1),
								.unmodified_syndr_coef_addr_2	(unmodified_syndr_coef_addr_2),
								.unmodified_syndrome_ready_0	(unmodified_syndrome_ready_0),
								.unmodified_syndrome_ready_1	(unmodified_syndrome_ready_1),
								.unmodified_syndrome_ready_2	(unmodified_syndrome_ready_2),
								.syndrome_ready					(syndrome_ready),
								.decoder_rd_addr				(decoder_rd_addr)
								);
`endif

`ifdef K217
defparam inst4.width=width;
defparam inst4.number_of_coefs=dif;
syndromes217			inst4 (
								.recd							(recvd_codeword),
								.reset							(reset),
								.clock							(ext_clk),
								.syndrome						(syndrome),
								.unmodified_syndr_polyn_0		(unmodified_syndr_polyn_0),
								.unmodified_syndr_polyn_1		(unmodified_syndr_polyn_1),
								.unmodified_syndr_polyn_2		(unmodified_syndr_polyn_2),
								.new_data						(new_data),
								.codeword_end_flag				(codeword_end_flag),
								.send_syndromes					(send_syndromes),
								.send_unmodified_syndr_polyn_0	(send_unmodified_syndr_polyn_0),
								.send_unmodified_syndr_polyn_1	(send_unmodified_syndr_polyn_1),
								.send_unmodified_syndr_polyn_2	(send_unmodified_syndr_polyn_2),
								.syndr_coef_addr				(syndr_coef_addr),
								.unmodified_syndr_coef_addr_0	(unmodified_syndr_coef_addr_0),
								.unmodified_syndr_coef_addr_1	(unmodified_syndr_coef_addr_1),
								.unmodified_syndr_coef_addr_2	(unmodified_syndr_coef_addr_2),
								.unmodified_syndrome_ready_0	(unmodified_syndrome_ready_0),
								.unmodified_syndrome_ready_1	(unmodified_syndrome_ready_1),
								.unmodified_syndrome_ready_2	(unmodified_syndrome_ready_2),
								.syndrome_ready					(syndrome_ready),
								.decoder_rd_addr				(decoder_rd_addr)
								);
`endif

defparam inst5.width=width;
defparam inst5.number_of_coefs=dif;
modified_syndrome_polyn		inst5(
								.clock									(ext_clk),
								.reset									(reset),
								.start_modified_syndrome_polyn_compute	(start_modified_syndrome_polyn_compute),
								.send_syndromes							(send_syndromes),
								.erase_position_0						(erase_position_0),
								.erase_position_1						(erase_position_1),
								.erase_position_2						(erase_position_2),
								.send_erasure_positions_for_synd_0		(send_erasure_positions_for_synd_0),
								.send_erasure_positions_for_synd_1		(send_erasure_positions_for_synd_1),
								.send_erasure_positions_for_synd_2		(send_erasure_positions_for_synd_2),
								.syndrome								(syndrome),
								.no_of_parity							(no_of_parity),
								.modified_syndrome_polyn_compute_done_0	(modified_syndr_polyn_compute_done_0),
								.modified_syndrome_polyn_compute_done_1	(modified_syndr_polyn_compute_done_1),
								.modified_syndrome_polyn_compute_done_2	(modified_syndr_polyn_compute_done_2),
								.erasure_ready_0						(erasure_ready_0),
								.erasure_ready_1						(erasure_ready_1),
								.erasure_ready_2						(erasure_ready_2),
								.modified_syndr_polyn_0					(modified_syndr_polyn_0),
								.modified_syndr_polyn_1					(modified_syndr_polyn_1),
								.modified_syndr_polyn_2					(modified_syndr_polyn_2),
								.load_non_zero_syndrome_done			(load_non_zero_syndrome_done),
								.codeword_end_flag						(codeword_end_flag),
								.send_syndr_polyn_0						(send_syndr_polyn_0),
								.send_syndr_polyn_1						(send_syndr_polyn_1),
								.send_syndr_polyn_2						(send_syndr_polyn_2),
								.syndr_coef_ready_0						(syndr_coef_ready_0),
								.syndr_coef_ready_1						(syndr_coef_ready_1),
								.syndr_coef_ready_2						(syndr_coef_ready_2),
								.syndr_coef_addr						(syndr_coef_addr),
								.erase_pos_done_0						(erase_pos_done_0),
								.erase_pos_done_1						(erase_pos_done_1),
								.erase_pos_done_2						(erase_pos_done_2),
								.syndrome_ready							(syndrome_ready),
								.number_of_erasures_0					(number_of_erasures_0),
								.number_of_erasures_1					(number_of_erasures_1),
								.number_of_erasures_2					(number_of_erasures_2),
								.modified_syndr_coef_addr_0				(modified_syndr_coef_addr_0),
								.modified_syndr_coef_addr_1				(modified_syndr_coef_addr_1),
								.modified_syndr_coef_addr_2				(modified_syndr_coef_addr_2),
								.error_free_codeword					(deactivate_chien_serach)
								);

defparam inst6a.width=width;
defparam inst6a.number_of_coefs=dif;
erasure_locator_polyn_0	inst6a	(
								.clock							(ext_clk),
								.reset							(reset),
								.start_erasure_polyn_compute	(start_erasure_polyn_compute),
								.erase_position					(erase_position_0),
								.send_erasure_positions_for_loc	(send_erasure_positions_for_loc_0),
								.erasure_loc_polyn				(erasure_polyn_0),
								.no_of_parity					(no_of_parity),
								.erasure_polyn_compute_done		(erasure_polyn_compute_done_0),
								.erase_pos_done					(erase_pos_done_0),
								.erasure_ready					(erasure_ready_0),
								.erase_coef_addr				(erase_coef_addr_0),
								.no_of_erasure_coefs			(no_of_erasure_coefs_0),
								.number_of_erasures				(number_of_erasures_0),
								.send_erasure_polyn				(send_erasure_polyn_0),
								.erasure_coef_ready				(erasure_coef_ready_0)
								);

defparam inst6b.width=width;
defparam inst6b.number_of_coefs=dif;
erasure_locator_polyn	inst6b	(
								.clock							(ext_clk),
								.reset							(reset),
								.start_erasure_polyn_compute	(start_erasure_polyn_compute),
								.erase_position					(erase_position_1),
								.send_erasure_positions_for_loc	(send_erasure_positions_for_loc_1),
								.erasure_loc_polyn				(erasure_polyn_1),
								.no_of_parity					(no_of_parity),
								.erasure_polyn_compute_done		(erasure_polyn_compute_done_1),
								.erase_pos_done					(erase_pos_done_1),
								.erasure_ready					(erasure_ready_1),
								.erase_coef_addr				(erase_coef_addr_1),
								.no_of_erasure_coefs			(no_of_erasure_coefs_1),
								.number_of_erasures				(number_of_erasures_1),
								.send_erasure_polyn				(send_erasure_polyn_1),
								.erasure_coef_ready				(erasure_coef_ready_1)
								);

defparam inst6c.width=width;
defparam inst6c.number_of_coefs=dif;
erasure_locator_polyn	inst6c	(
								.clock							(ext_clk),
								.reset							(reset),
								.start_erasure_polyn_compute	(start_erasure_polyn_compute),
								.erase_position					(erase_position_2),
								.send_erasure_positions_for_loc	(send_erasure_positions_for_loc_2),
								.erasure_loc_polyn				(erasure_polyn_2),
								.no_of_parity					(no_of_parity),
								.erasure_polyn_compute_done		(erasure_polyn_compute_done_2),
								.erase_pos_done					(erase_pos_done_2),
								.erasure_ready					(erasure_ready_2),
								.erase_coef_addr				(erase_coef_addr_2),
								.no_of_erasure_coefs			(no_of_erasure_coefs_2),
								.number_of_erasures				(number_of_erasures_2),
								.send_erasure_polyn				(send_erasure_polyn_2),
								.erasure_coef_ready				(erasure_coef_ready_2)
								);
defparam inst7a.width=width;
defparam inst7a.number_of_coefs=dif;
modified_euclid_alg_0		inst7a(
							.clock									(ext_clk),
							.reset									(reset),
							.no_of_parity							(no_of_parity),
							.no_of_erasure_coefs					(no_of_erasure_coefs_0),
							.erasure_polyn_compute_done				(erasure_polyn_compute_done_0),
							.modified_syndr_polyn_compute_done		(modified_syndr_polyn_compute_done_0),
							.locator_polyn							(locator_polyn_0),
							.magnitue_polyn							(magnitue_polyn_0),
							.erasure_polyn							(erasure_polyn_0),
							.modified_syndr_polyn					(modified_syndr_polyn_0),
							.unmodified_syndr_polyn					(unmodified_syndr_polyn_0),
							.erase_coef_addr						(erase_coef_addr_0),
							.modified_syndr_coef_addr				(modified_syndr_coef_addr_0),
							.unmodified_syndr_coef_addr				(unmodified_syndr_coef_addr_0),
							.erasure_coef_ready						(erasure_coef_ready_0),
							.send_erasure_polyn						(send_erasure_polyn_0),
							.send_syndr_polyn						(send_syndr_polyn_0),
							.send_unmodified_syndr_polyn			(send_unmodified_syndr_polyn_0),
							.syndr_coef_ready						(syndr_coef_ready_0),
							.unmodified_syndrome_ready				(unmodified_syndrome_ready_0),
							.MEA_compute_done						(MEA_compute_done_0),
							.reg_initialization_complete			(reg_initialization_complete_0),
							.MEA_iteration							(MEA_iteration_0),
							.reg_init								(reg_init_0),
							.state_case								(state_case_0),
							.R_degree								(R_degree_0),
							.Q_degree								(Q_degree_0),
							.locator_degree							(locator_degree_0),
							.send_loc_errata_coefs					(send_loc_errata_coefs_0),
							.send_magnitude_errata_coefs			(send_magnitude_errata_coefs_0),
							.errata_loc_coefs						(errata_loc_coefs_0),
							.errata_magnitude_coefs					(errata_magnitude_coefs_0),
							.errata_loc_coef_ready					(errata_loc_coef_ready_0),
							.errata_magnitude_coef_ready			(errata_magnitude_coef_ready_0),
							.errata_loc_addr						(errata_loc_addr_0),
							.errata_magnitude_addr					(errata_magnitude_addr_0),
							.erasures_absent						(erasures_absent_0),
							.L_degree								(L_degree_0),
							.chien_regs_initialized					(chien_regs_initialized_0)
							);

defparam inst7b.width=width;
defparam inst7b.number_of_coefs=dif;
modified_euclid_alg_1		inst7b(
							.clock									(ext_clk),
							.reset									(reset),
							.no_of_parity							(no_of_parity),
							.no_of_erasure_coefs					(no_of_erasure_coefs_1),
							.erasure_polyn_compute_done				(erasure_polyn_compute_done_1),
							.modified_syndr_polyn_compute_done		(modified_syndr_polyn_compute_done_1),
							.locator_polyn							(locator_polyn_1),
							.magnitue_polyn							(magnitue_polyn_1),
							.erasure_polyn							(erasure_polyn_1),
							.modified_syndr_polyn					(modified_syndr_polyn_1),
							.unmodified_syndr_polyn					(unmodified_syndr_polyn_1),
							.erase_coef_addr						(erase_coef_addr_1),
							.modified_syndr_coef_addr				(modified_syndr_coef_addr_1),
							.unmodified_syndr_coef_addr				(unmodified_syndr_coef_addr_1),
							.erasure_coef_ready						(erasure_coef_ready_1),
							.send_erasure_polyn						(send_erasure_polyn_1),
							.send_syndr_polyn						(send_syndr_polyn_1),
							.send_unmodified_syndr_polyn			(send_unmodified_syndr_polyn_1),
							.syndr_coef_ready						(syndr_coef_ready_1),
							.unmodified_syndrome_ready				(unmodified_syndrome_ready_1),
							.MEA_compute_done						(MEA_compute_done_1),
							.reg_initialization_complete			(reg_initialization_complete_1),
							.MEA_iteration							(MEA_iteration_1),
							.reg_init								(reg_init_1),
							.state_case								(state_case_1),
							.R_degree								(R_degree_1),
							.Q_degree								(Q_degree_1),
							.locator_degree							(locator_degree_1),
							.send_loc_errata_coefs					(send_loc_errata_coefs_1),
							.send_magnitude_errata_coefs			(send_magnitude_errata_coefs_1),
							.errata_loc_coefs						(errata_loc_coefs_1),
							.errata_magnitude_coefs					(errata_magnitude_coefs_1),
							.errata_loc_coef_ready					(errata_loc_coef_ready_1),
							.errata_magnitude_coef_ready			(errata_magnitude_coef_ready_1),
							.errata_loc_addr						(errata_loc_addr_1),
							.errata_magnitude_addr					(errata_magnitude_addr_1),
							.erasures_absent						(erasures_absent_1_1),
							.L_degree								(L_degree_1),
							.chien_regs_initialized					(chien_regs_initialized_1)
							);

defparam inst7c.width=width;
defparam inst7c.number_of_coefs=dif;
modified_euclid_alg_2		inst7c(
							.clock									(ext_clk),
							.reset									(reset),
							.no_of_parity							(no_of_parity),
							.no_of_erasure_coefs					(no_of_erasure_coefs_2),
							.erasure_polyn_compute_done				(erasure_polyn_compute_done_2),
							.modified_syndr_polyn_compute_done		(modified_syndr_polyn_compute_done_2),
							.locator_polyn							(locator_polyn_2),
							.magnitue_polyn							(magnitue_polyn_2),
							.erasure_polyn							(erasure_polyn_2),
							.modified_syndr_polyn					(modified_syndr_polyn_2),
							.unmodified_syndr_polyn					(unmodified_syndr_polyn_2),
							.erase_coef_addr						(erase_coef_addr_2),
							.modified_syndr_coef_addr				(modified_syndr_coef_addr_2),
							.unmodified_syndr_coef_addr				(unmodified_syndr_coef_addr_2),
							.erasure_coef_ready						(erasure_coef_ready_2),
							.send_erasure_polyn						(send_erasure_polyn_2),
							.send_syndr_polyn						(send_syndr_polyn_2),
							.send_unmodified_syndr_polyn			(send_unmodified_syndr_polyn_2),
							.syndr_coef_ready						(syndr_coef_ready_2),
							.unmodified_syndrome_ready				(unmodified_syndrome_ready_2),
							.MEA_compute_done						(MEA_compute_done_2),
							.reg_initialization_complete			(reg_initialization_complete_2),
							.MEA_iteration							(MEA_iteration_2),
							.reg_init								(reg_init_2),
							.state_case								(state_case_2),
							.R_degree								(R_degree_2),
							.Q_degree								(Q_degree_2),
							.locator_degree							(locator_degree_2),
							.send_loc_errata_coefs					(send_loc_errata_coefs_2),
							.send_magnitude_errata_coefs			(send_magnitude_errata_coefs_2),
							.errata_loc_coefs						(errata_loc_coefs_2),
							.errata_magnitude_coefs					(errata_magnitude_coefs_2),
							.errata_loc_coef_ready					(errata_loc_coef_ready_2),
							.errata_magnitude_coef_ready			(errata_magnitude_coef_ready_2),
							.errata_loc_addr						(errata_loc_addr_2),
							.errata_magnitude_addr					(errata_magnitude_addr_2),
							.erasures_absent						(erasures_absent_1_2),
							.L_degree								(L_degree_2),
							.chien_regs_initialized					(chien_regs_initialized_2)
							);

//////////////
//////////////
`ifdef K239
defparam inst8.width=width;
defparam inst8.number_of_coefs=dif;
defparam inst8.number_of_even_roots=dif/2;
chien_search_alg	 inst8(
							.clock							(ext_clk),
							.reset							(reset),
							.no_of_parity					(no_of_parity),
							.MEA_compute_done_0				(MEA_compute_done_0),
							.MEA_compute_done_1				(MEA_compute_done_1),
							.MEA_compute_done_2				(MEA_compute_done_2),
							.locator_degree_0				(locator_degree_0),
							.locator_degree_1				(locator_degree_1),
							.locator_degree_2				(locator_degree_2),
							.send_loc_errata_coefs_0		(send_loc_errata_coefs_0),
							.send_loc_errata_coefs_1		(send_loc_errata_coefs_1),
							.send_loc_errata_coefs_2		(send_loc_errata_coefs_2),
							.send_magnitude_errata_coefs_0	(send_magnitude_errata_coefs_0),
							.send_magnitude_errata_coefs_1	(send_magnitude_errata_coefs_1),
							.send_magnitude_errata_coefs_2	(send_magnitude_errata_coefs_2),
							.errata_loc_coefs_0				(errata_loc_coefs_0),
							.errata_loc_coefs_1				(errata_loc_coefs_1),
							.errata_loc_coefs_2				(errata_loc_coefs_2),
							.errata_magnitude_coefs_0		(errata_magnitude_coefs_0),
							.errata_magnitude_coefs_1		(errata_magnitude_coefs_1),
							.errata_magnitude_coefs_2		(errata_magnitude_coefs_2),
							.errata_loc_coef_ready_0		(errata_loc_coef_ready_0),
							.errata_loc_coef_ready_1		(errata_loc_coef_ready_1),
							.errata_loc_coef_ready_2		(errata_loc_coef_ready_2),
							.errata_magnitude_coef_ready_0	(errata_magnitude_coef_ready_0),
							.errata_magnitude_coef_ready_1	(errata_magnitude_coef_ready_1),
							.errata_magnitude_coef_ready_2	(errata_magnitude_coef_ready_2),
							.error_location_0 				(error_location_0),
							.error_location_1 				(error_location_1),
							.error_location_2 				(error_location_2),
							.derivative_error_location 		(derivative_error_location),
							.error_magnitude				(error_magnitude),
							.errata_loc_addr_0				(errata_loc_addr_0),
							.errata_loc_addr_1				(errata_loc_addr_1),
							.errata_loc_addr_2				(errata_loc_addr_2),
							.errata_magnitude_addr_0		(errata_magnitude_addr_0),
							.errata_magnitude_addr_1		(errata_magnitude_addr_1),
							.errata_magnitude_addr_2		(errata_magnitude_addr_2),
							.corrected_error_count			(corrected_error_count),
							.corrected_cword_ready			(corrected_cword_ready),
							.cycle							(cycle),
							.read_alpha_inverse				(read_alpha_inverse),
							.err_loc_derivativative			(err_loc_derivativative),
							.alpha_inverse					(alpha_inverse),
							.gf_table_ready					(gf_table_ready),
							.rdaddress						(rdaddress),
							.rden_delay_buffer				(rden_delay_buffer),
							.q								(q),
							.corrected_cw					(corrected_cw),
							.deactivate_chien_serach		(deactivate_chien_serach),
							.chien_regs_initialized_0		(chien_regs_initialized_0),
							.chien_regs_initialized_1		(chien_regs_initialized_1),
							.chien_regs_initialized_2		(chien_regs_initialized_2)
							);
`endif

`ifdef K237
defparam inst8.width=width;
defparam inst8.number_of_coefs=dif;
defparam inst8.number_of_even_roots=dif/2;
chien_search_alg237	 inst8(
							.clock							(ext_clk),
							.reset							(reset),
							.no_of_parity					(no_of_parity),
							.MEA_compute_done_0				(MEA_compute_done_0),
							.MEA_compute_done_1				(MEA_compute_done_1),
							.MEA_compute_done_2				(MEA_compute_done_2),
							.locator_degree_0				(locator_degree_0),
							.locator_degree_1				(locator_degree_1),
							.locator_degree_2				(locator_degree_2),
							.send_loc_errata_coefs_0		(send_loc_errata_coefs_0),
							.send_loc_errata_coefs_1		(send_loc_errata_coefs_1),
							.send_loc_errata_coefs_2		(send_loc_errata_coefs_2),
							.send_magnitude_errata_coefs_0	(send_magnitude_errata_coefs_0),
							.send_magnitude_errata_coefs_1	(send_magnitude_errata_coefs_1),
							.send_magnitude_errata_coefs_2	(send_magnitude_errata_coefs_2),
							.errata_loc_coefs_0				(errata_loc_coefs_0),
							.errata_loc_coefs_1				(errata_loc_coefs_1),
							.errata_loc_coefs_2				(errata_loc_coefs_2),
							.errata_magnitude_coefs_0		(errata_magnitude_coefs_0),
							.errata_magnitude_coefs_1		(errata_magnitude_coefs_1),
							.errata_magnitude_coefs_2		(errata_magnitude_coefs_2),
							.errata_loc_coef_ready_0		(errata_loc_coef_ready_0),
							.errata_loc_coef_ready_1		(errata_loc_coef_ready_1),
							.errata_loc_coef_ready_2		(errata_loc_coef_ready_2),
							.errata_magnitude_coef_ready_0	(errata_magnitude_coef_ready_0),
							.errata_magnitude_coef_ready_1	(errata_magnitude_coef_ready_1),
							.errata_magnitude_coef_ready_2	(errata_magnitude_coef_ready_2),
							.error_location_0 				(error_location_0),
							.error_location_1 				(error_location_1),
							.error_location_2 				(error_location_2),
							.derivative_error_location 		(derivative_error_location),
							.error_magnitude				(error_magnitude),
							.errata_loc_addr_0				(errata_loc_addr_0),
							.errata_loc_addr_1				(errata_loc_addr_1),
							.errata_loc_addr_2				(errata_loc_addr_2),
							.errata_magnitude_addr_0		(errata_magnitude_addr_0),
							.errata_magnitude_addr_1		(errata_magnitude_addr_1),
							.errata_magnitude_addr_2		(errata_magnitude_addr_2),
							.corrected_error_count			(corrected_error_count),
							.corrected_cword_ready			(corrected_cword_ready),
							.cycle							(cycle),
							.read_alpha_inverse				(read_alpha_inverse),
							.err_loc_derivativative			(err_loc_derivativative),
							.alpha_inverse					(alpha_inverse),
							.gf_table_ready					(gf_table_ready),
							.rdaddress						(rdaddress),
							.rden_delay_buffer				(rden_delay_buffer),
							.q								(q),
							.corrected_cw					(corrected_cw),
							.deactivate_chien_serach		(deactivate_chien_serach),
							.chien_regs_initialized_0		(chien_regs_initialized_0),
							.chien_regs_initialized_1		(chien_regs_initialized_1),
							.chien_regs_initialized_2		(chien_regs_initialized_2)
							);
`endif
`ifdef K233
defparam inst8.width=width;
defparam inst8.number_of_coefs=dif;
defparam inst8.number_of_even_roots=dif/2;
chien_search_alg233	 inst8(
							.clock							(ext_clk),
							.reset							(reset),
							.no_of_parity					(no_of_parity),
							.MEA_compute_done_0				(MEA_compute_done_0),
							.MEA_compute_done_1				(MEA_compute_done_1),
							.MEA_compute_done_2				(MEA_compute_done_2),
							.locator_degree_0				(locator_degree_0),
							.locator_degree_1				(locator_degree_1),
							.locator_degree_2				(locator_degree_2),
							.send_loc_errata_coefs_0		(send_loc_errata_coefs_0),
							.send_loc_errata_coefs_1		(send_loc_errata_coefs_1),
							.send_loc_errata_coefs_2		(send_loc_errata_coefs_2),
							.send_magnitude_errata_coefs_0	(send_magnitude_errata_coefs_0),
							.send_magnitude_errata_coefs_1	(send_magnitude_errata_coefs_1),
							.send_magnitude_errata_coefs_2	(send_magnitude_errata_coefs_2),
							.errata_loc_coefs_0				(errata_loc_coefs_0),
							.errata_loc_coefs_1				(errata_loc_coefs_1),
							.errata_loc_coefs_2				(errata_loc_coefs_2),
							.errata_magnitude_coefs_0		(errata_magnitude_coefs_0),
							.errata_magnitude_coefs_1		(errata_magnitude_coefs_1),
							.errata_magnitude_coefs_2		(errata_magnitude_coefs_2),
							.errata_loc_coef_ready_0		(errata_loc_coef_ready_0),
							.errata_loc_coef_ready_1		(errata_loc_coef_ready_1),
							.errata_loc_coef_ready_2		(errata_loc_coef_ready_2),
							.errata_magnitude_coef_ready_0	(errata_magnitude_coef_ready_0),
							.errata_magnitude_coef_ready_1	(errata_magnitude_coef_ready_1),
							.errata_magnitude_coef_ready_2	(errata_magnitude_coef_ready_2),
							.error_location_0 				(error_location_0),
							.error_location_1 				(error_location_1),
							.error_location_2 				(error_location_2),
							.derivative_error_location 		(derivative_error_location),
							.error_magnitude				(error_magnitude),
							.errata_loc_addr_0				(errata_loc_addr_0),
							.errata_loc_addr_1				(errata_loc_addr_1),
							.errata_loc_addr_2				(errata_loc_addr_2),
							.errata_magnitude_addr_0		(errata_magnitude_addr_0),
							.errata_magnitude_addr_1		(errata_magnitude_addr_1),
							.errata_magnitude_addr_2		(errata_magnitude_addr_2),
							.corrected_error_count			(corrected_error_count),
							.corrected_cword_ready			(corrected_cword_ready),
							.cycle							(cycle),
							.read_alpha_inverse				(read_alpha_inverse),
							.err_loc_derivativative			(err_loc_derivativative),
							.alpha_inverse					(alpha_inverse),
							.gf_table_ready					(gf_table_ready),
							.rdaddress						(rdaddress),
							.rden_delay_buffer				(rden_delay_buffer),
							.q								(q),
							.corrected_cw					(corrected_cw),
							.deactivate_chien_serach		(deactivate_chien_serach),
							.chien_regs_initialized_0		(chien_regs_initialized_0),
							.chien_regs_initialized_1		(chien_regs_initialized_1),
							.chien_regs_initialized_2		(chien_regs_initialized_2)
							);
`endif
`ifdef K225
defparam inst8.width=width;
defparam inst8.number_of_coefs=dif;
defparam inst8.number_of_even_roots=dif/2;
chien_search_alg225	 inst8(
							.clock							(ext_clk),
							.reset							(reset),
							.no_of_parity					(no_of_parity),
							.MEA_compute_done_0				(MEA_compute_done_0),
							.MEA_compute_done_1				(MEA_compute_done_1),
							.MEA_compute_done_2				(MEA_compute_done_2),
							.locator_degree_0				(locator_degree_0),
							.locator_degree_1				(locator_degree_1),
							.locator_degree_2				(locator_degree_2),
							.send_loc_errata_coefs_0		(send_loc_errata_coefs_0),
							.send_loc_errata_coefs_1		(send_loc_errata_coefs_1),
							.send_loc_errata_coefs_2		(send_loc_errata_coefs_2),
							.send_magnitude_errata_coefs_0	(send_magnitude_errata_coefs_0),
							.send_magnitude_errata_coefs_1	(send_magnitude_errata_coefs_1),
							.send_magnitude_errata_coefs_2	(send_magnitude_errata_coefs_2),
							.errata_loc_coefs_0				(errata_loc_coefs_0),
							.errata_loc_coefs_1				(errata_loc_coefs_1),
							.errata_loc_coefs_2				(errata_loc_coefs_2),
							.errata_magnitude_coefs_0		(errata_magnitude_coefs_0),
							.errata_magnitude_coefs_1		(errata_magnitude_coefs_1),
							.errata_magnitude_coefs_2		(errata_magnitude_coefs_2),
							.errata_loc_coef_ready_0		(errata_loc_coef_ready_0),
							.errata_loc_coef_ready_1		(errata_loc_coef_ready_1),
							.errata_loc_coef_ready_2		(errata_loc_coef_ready_2),
							.errata_magnitude_coef_ready_0	(errata_magnitude_coef_ready_0),
							.errata_magnitude_coef_ready_1	(errata_magnitude_coef_ready_1),
							.errata_magnitude_coef_ready_2	(errata_magnitude_coef_ready_2),
							.error_location_0 				(error_location_0),
							.error_location_1 				(error_location_1),
							.error_location_2 				(error_location_2),
							.derivative_error_location 		(derivative_error_location),
							.error_magnitude				(error_magnitude),
							.errata_loc_addr_0				(errata_loc_addr_0),
							.errata_loc_addr_1				(errata_loc_addr_1),
							.errata_loc_addr_2				(errata_loc_addr_2),
							.errata_magnitude_addr_0		(errata_magnitude_addr_0),
							.errata_magnitude_addr_1		(errata_magnitude_addr_1),
							.errata_magnitude_addr_2		(errata_magnitude_addr_2),
							.corrected_error_count			(corrected_error_count),
							.corrected_cword_ready			(corrected_cword_ready),
							.cycle							(cycle),
							.read_alpha_inverse				(read_alpha_inverse),
							.err_loc_derivativative			(err_loc_derivativative),
							.alpha_inverse					(alpha_inverse),
							.gf_table_ready					(gf_table_ready),
							.rdaddress						(rdaddress),
							.rden_delay_buffer				(rden_delay_buffer),
							.q								(q),
							.corrected_cw					(corrected_cw),
							.deactivate_chien_serach		(deactivate_chien_serach),
							.chien_regs_initialized_0		(chien_regs_initialized_0),
							.chien_regs_initialized_1		(chien_regs_initialized_1),
							.chien_regs_initialized_2		(chien_regs_initialized_2)
							);
`endif
`ifdef K221
defparam inst8.width=width;
defparam inst8.number_of_coefs=dif;
defparam inst8.number_of_even_roots=dif/2;
chien_search_alg221	 inst8(
							.clock							(ext_clk),
							.reset							(reset),
							.no_of_parity					(no_of_parity),
							.MEA_compute_done_0				(MEA_compute_done_0),
							.MEA_compute_done_1				(MEA_compute_done_1),
							.MEA_compute_done_2				(MEA_compute_done_2),
							.locator_degree_0				(locator_degree_0),
							.locator_degree_1				(locator_degree_1),
							.locator_degree_2				(locator_degree_2),
							.send_loc_errata_coefs_0		(send_loc_errata_coefs_0),
							.send_loc_errata_coefs_1		(send_loc_errata_coefs_1),
							.send_loc_errata_coefs_2		(send_loc_errata_coefs_2),
							.send_magnitude_errata_coefs_0	(send_magnitude_errata_coefs_0),
							.send_magnitude_errata_coefs_1	(send_magnitude_errata_coefs_1),
							.send_magnitude_errata_coefs_2	(send_magnitude_errata_coefs_2),
							.errata_loc_coefs_0				(errata_loc_coefs_0),
							.errata_loc_coefs_1				(errata_loc_coefs_1),
							.errata_loc_coefs_2				(errata_loc_coefs_2),
							.errata_magnitude_coefs_0		(errata_magnitude_coefs_0),
							.errata_magnitude_coefs_1		(errata_magnitude_coefs_1),
							.errata_magnitude_coefs_2		(errata_magnitude_coefs_2),
							.errata_loc_coef_ready_0		(errata_loc_coef_ready_0),
							.errata_loc_coef_ready_1		(errata_loc_coef_ready_1),
							.errata_loc_coef_ready_2		(errata_loc_coef_ready_2),
							.errata_magnitude_coef_ready_0	(errata_magnitude_coef_ready_0),
							.errata_magnitude_coef_ready_1	(errata_magnitude_coef_ready_1),
							.errata_magnitude_coef_ready_2	(errata_magnitude_coef_ready_2),
							.error_location_0 				(error_location_0),
							.error_location_1 				(error_location_1),
							.error_location_2 				(error_location_2),
							.derivative_error_location 		(derivative_error_location),
							.error_magnitude				(error_magnitude),
							.errata_loc_addr_0				(errata_loc_addr_0),
							.errata_loc_addr_1				(errata_loc_addr_1),
							.errata_loc_addr_2				(errata_loc_addr_2),
							.errata_magnitude_addr_0		(errata_magnitude_addr_0),
							.errata_magnitude_addr_1		(errata_magnitude_addr_1),
							.errata_magnitude_addr_2		(errata_magnitude_addr_2),
							.corrected_error_count			(corrected_error_count),
							.corrected_cword_ready			(corrected_cword_ready),
							.cycle							(cycle),
							.read_alpha_inverse				(read_alpha_inverse),
							.err_loc_derivativative			(err_loc_derivativative),
							.alpha_inverse					(alpha_inverse),
							.gf_table_ready					(gf_table_ready),
							.rdaddress						(rdaddress),
							.rden_delay_buffer				(rden_delay_buffer),
							.q								(q),
							.corrected_cw					(corrected_cw),
							.deactivate_chien_serach		(deactivate_chien_serach),
							.chien_regs_initialized_0		(chien_regs_initialized_0),
							.chien_regs_initialized_1		(chien_regs_initialized_1),
							.chien_regs_initialized_2		(chien_regs_initialized_2)
							);
`endif
`ifdef K217
defparam inst8.width=width;
defparam inst8.number_of_coefs=dif;
defparam inst8.number_of_even_roots=dif/2;
chien_search_alg217	 inst8(
							.clock							(ext_clk),
							.reset							(reset),
							.no_of_parity					(no_of_parity),
							.MEA_compute_done_0				(MEA_compute_done_0),
							.MEA_compute_done_1				(MEA_compute_done_1),
							.MEA_compute_done_2				(MEA_compute_done_2),
							.locator_degree_0				(locator_degree_0),
							.locator_degree_1				(locator_degree_1),
							.locator_degree_2				(locator_degree_2),
							.send_loc_errata_coefs_0		(send_loc_errata_coefs_0),
							.send_loc_errata_coefs_1		(send_loc_errata_coefs_1),
							.send_loc_errata_coefs_2		(send_loc_errata_coefs_2),
							.send_magnitude_errata_coefs_0	(send_magnitude_errata_coefs_0),
							.send_magnitude_errata_coefs_1	(send_magnitude_errata_coefs_1),
							.send_magnitude_errata_coefs_2	(send_magnitude_errata_coefs_2),
							.errata_loc_coefs_0				(errata_loc_coefs_0),
							.errata_loc_coefs_1				(errata_loc_coefs_1),
							.errata_loc_coefs_2				(errata_loc_coefs_2),
							.errata_magnitude_coefs_0		(errata_magnitude_coefs_0),
							.errata_magnitude_coefs_1		(errata_magnitude_coefs_1),
							.errata_magnitude_coefs_2		(errata_magnitude_coefs_2),
							.errata_loc_coef_ready_0		(errata_loc_coef_ready_0),
							.errata_loc_coef_ready_1		(errata_loc_coef_ready_1),
							.errata_loc_coef_ready_2		(errata_loc_coef_ready_2),
							.errata_magnitude_coef_ready_0	(errata_magnitude_coef_ready_0),
							.errata_magnitude_coef_ready_1	(errata_magnitude_coef_ready_1),
							.errata_magnitude_coef_ready_2	(errata_magnitude_coef_ready_2),
							.error_location_0 				(error_location_0),
							.error_location_1 				(error_location_1),
							.error_location_2 				(error_location_2),
							.derivative_error_location 		(derivative_error_location),
							.error_magnitude				(error_magnitude),
							.errata_loc_addr_0				(errata_loc_addr_0),
							.errata_loc_addr_1				(errata_loc_addr_1),
							.errata_loc_addr_2				(errata_loc_addr_2),
							.errata_magnitude_addr_0		(errata_magnitude_addr_0),
							.errata_magnitude_addr_1		(errata_magnitude_addr_1),
							.errata_magnitude_addr_2		(errata_magnitude_addr_2),
							.corrected_error_count			(corrected_error_count),
							.corrected_cword_ready			(corrected_cword_ready),
							.cycle							(cycle),
							.read_alpha_inverse				(read_alpha_inverse),
							.err_loc_derivativative			(err_loc_derivativative),
							.alpha_inverse					(alpha_inverse),
							.gf_table_ready					(gf_table_ready),
							.rdaddress						(rdaddress),
							.rden_delay_buffer				(rden_delay_buffer),
							.q								(q),
							.corrected_cw					(corrected_cw),
							.deactivate_chien_serach		(deactivate_chien_serach),
							.chien_regs_initialized_0		(chien_regs_initialized_0),
							.chien_regs_initialized_1		(chien_regs_initialized_1),
							.chien_regs_initialized_2		(chien_regs_initialized_2)
							);
`endif
always @(posedge ext_clk)
begin
	if((reset==1'b0)&&(decode_strobe==1'b1))
	begin
	temp_k_value=k_value;//k is the number of data bytes
	no_of_parity=8'd255 - temp_k_value;
	end

end

always @(posedge ext_clk)
begin
if(reset==1'b1)
	begin
 	wren_decoder_in_buffer = 1'b0;
 	new_data=1'b0;
	rd_enable = 1'b0;
	send_data = 1'b0;
	wren = 1'b0;
	cw_addr = 0;
	end
else if(reset==1'b0)
begin
	if(new_channel_char==1'b1 && send_data == 1'b0)//erasure writes recived cw into the the  decoder input DPRAM
		begin
			wren_decoder_in_buffer <= 1'b1;
			write_addr <= rdaddress_fade;
			cw_data <= recieved_codeword;
			if(rdaddress_fade >= 1)
				write_flag_addr <= rdaddress_fade -1;
		end

	if(write_addr==8'd255 && cw_addr <= 256)//erasure-generator completed writting data
	begin
		rd_enable = 1'b1;	//decoder rd data from its input DPRAM
		wren = 1'b1;		//decoder write data in the delay buffer
		send_data = 1'b1;	//activates syndrome generation and erasure location extraction to begin; and halts erasure generator from sending data to decoder buffer
		if (cw_addr <= 255)
			decoder_rd_addr = cw_addr;
		cw_addr = cw_addr + 1;
	end
	if(cw_addr>9'd256)//decoder stops reading it's input DPRAM
		begin
		rd_enable = 1'b0;
		wren = 1'b0;
		end
	if((send_data==1'b1)&&(codeword_end_flag==1'b0))
		begin
		new_data=1'b1;
		end
end
end

always @(posedge ext_clk)
begin
if(reset==1'b1)
begin
	start_erasure_polyn_compute<=1'b0;
	start_modified_syndrome_polyn_compute<=1'b0;
	erasures_absent_0<=1'b0;
	erasures_absent_1<=1'b0;
	erasures_absent_2<=1'b0;
 end
else
	begin
		if(load_non_zero_syndrome_done==1'b1)
			begin
				if(number_of_erasures_0!=6'd0 ||number_of_erasures_1!=6'd0 ||number_of_erasures_2!=6'd0)
					begin
						start_erasure_polyn_compute<=1'b1;
						start_modified_syndrome_polyn_compute<=1'b1;
						if(number_of_erasures_0==6'd0)erasures_absent_0<=1'b1;
						if(number_of_erasures_1==6'd0)erasures_absent_1<=1'b1;
						if(number_of_erasures_2==6'd0)erasures_absent_2<=1'b1;
					end
				else if(number_of_erasures_0==6'd0 && number_of_erasures_1==6'd0 && number_of_erasures_2==6'd0)
					begin
						start_erasure_polyn_compute<=1'b0;
						start_modified_syndrome_polyn_compute<=1'b0;
						erasures_absent_0<=1'b1;
						erasures_absent_1<=1'b1;
						erasures_absent_2<=1'b1;
					end
			end

	end
end
endmodule


// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: U_buffer_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module U_buffer_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: U_buffer_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module U_buffer_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: U_buffer.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module U_buffer (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_buffer_bb.v TRUE

// megafunction wizard: %LPM_DIVIDE%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_divide

// ============================================================
// File Name: unsigned_divider.v
// Megafunction Name(s):
// 			lpm_divide
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//Copyright (C) 1991-2002 Altera Corporation
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


module unsigned_divider (
	numer,
	denom,
	clock,
	quotient
	);

	input	[14:0]  numer;
	input	[9:0]  denom;
	input	  clock;
	output	[14:0]  quotient;

	wire [14:0] pipeline1 = 15'b0;
	wire [14:0] pipeline2 = 15'b0;

	always @(posedge clock)
	begin
	    pipeline1 = numer / denom;
	    pipeline2 = pipeline1;
	    quotient = pipeline2;
	end

	/*lpm_divide	lpm_divide_component (
				.denom (denom),
				.clock (clock),
				.numer (numer),
				.quotient (sub_wire0));
	defparam
		lpm_divide_component.lpm_widthn = 15,
		lpm_divide_component.lpm_widthd = 10,
		lpm_divide_component.lpm_pipeline = 3,
		lpm_divide_component.lpm_type = "LPM_DIVIDE",
		lpm_divide_component.lpm_nrepresentation = "UNSIGNED",
		lpm_divide_component.lpm_hint = "MAXIMIZE_SPEED=6,LPM_REMAINDERPOSITIVE=TRUE",
		lpm_divide_component.lpm_drepresentation = "UNSIGNED";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: VERSION_NUMBER NUMERIC "2"
// Retrieval info: PRIVATE: PRIVATE_MAXIMIZE_SPEED NUMERIC "6"
// Retrieval info: PRIVATE: PRIVATE_LPM_REMAINDERPOSITIVE STRING "TRUE"
// Retrieval info: PRIVATE: USING_PIPELINE NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTHN NUMERIC "15"
// Retrieval info: CONSTANT: LPM_WIDTHD NUMERIC "10"
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "3"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_DIVIDE"
// Retrieval info: CONSTANT: LPM_NREPRESENTATION STRING "UNSIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "MAXIMIZE_SPEED=6,LPM_REMAINDERPOSITIVE=TRUE"
// Retrieval info: CONSTANT: LPM_DREPRESENTATION STRING "UNSIGNED"
// Retrieval info: USED_PORT: numer 0 0 15 0 INPUT NODEFVAL numer[14..0]
// Retrieval info: USED_PORT: denom 0 0 10 0 INPUT NODEFVAL denom[9..0]
// Retrieval info: USED_PORT: quotient 0 0 15 0 OUTPUT NODEFVAL quotient[14..0]
// Retrieval info: USED_PORT: remain 0 0 10 0 OUTPUT NODEFVAL remain[9..0]
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @numer 0 0 15 0 numer 0 0 15 0
// Retrieval info: CONNECT: @denom 0 0 10 0 denom 0 0 10 0
// Retrieval info: CONNECT: quotient 0 0 15 0 @quotient 0 0 15 0
// Retrieval info: CONNECT: remain 0 0 10 0 @remain 0 0 10 0
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_MULT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_mult

// ============================================================
// File Name: unsigned_multiplier.v
// Megafunction Name(s):
// 			lpm_mult
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


module unsigned_multiplier (
	dataa,
	datab,
	result);

	input	[4:0]  dataa;
	input	[4:0]  datab;
	output	[9:0]  result;

	assign result = dataa * datab;
	/*lpm_mult	lpm_mult_component (
				.dataa (dataa),
				.datab (datab),
				.result (sub_wire0));
	defparam
		lpm_mult_component.lpm_widtha = 5,
		lpm_mult_component.lpm_widthb = 5,
		lpm_mult_component.lpm_widthp = 10,
		lpm_mult_component.lpm_widths = 10,
		lpm_mult_component.lpm_type = "LPM_MULT",
		lpm_mult_component.lpm_representation = "UNSIGNED",
		lpm_mult_component.lpm_hint = "MAXIMIZE_SPEED=6";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthA NUMERIC "5"
// Retrieval info: PRIVATE: WidthB NUMERIC "5"
// Retrieval info: PRIVATE: WidthS NUMERIC "10"
// Retrieval info: PRIVATE: WidthP NUMERIC "10"
// Retrieval info: PRIVATE: OptionalSum NUMERIC "0"
// Retrieval info: PRIVATE: AutoSizeResult NUMERIC "1"
// Retrieval info: PRIVATE: B_isConstant NUMERIC "0"
// Retrieval info: PRIVATE: SignedMult NUMERIC "0"
// Retrieval info: PRIVATE: ConstantB NUMERIC "0"
// Retrieval info: PRIVATE: ValidConstant NUMERIC "0"
// Retrieval info: PRIVATE: Latency NUMERIC "0"
// Retrieval info: PRIVATE: aclr NUMERIC "0"
// Retrieval info: PRIVATE: clken NUMERIC "0"
// Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "0"
// Retrieval info: PRIVATE: optimize NUMERIC "0"
// Retrieval info: CONSTANT: LPM_WIDTHA NUMERIC "5"
// Retrieval info: CONSTANT: LPM_WIDTHB NUMERIC "5"
// Retrieval info: CONSTANT: LPM_WIDTHP NUMERIC "10"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "10"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MULT"
// Retrieval info: CONSTANT: LPM_REPRESENTATION STRING "UNSIGNED"
// Retrieval info: CONSTANT: LPM_HINT STRING "MAXIMIZE_SPEED=6"
// Retrieval info: USED_PORT: dataa 0 0 5 0 INPUT NODEFVAL dataa[4..0]
// Retrieval info: USED_PORT: result 0 0 10 0 OUTPUT NODEFVAL result[9..0]
// Retrieval info: USED_PORT: datab 0 0 5 0 INPUT NODEFVAL datab[4..0]
// Retrieval info: CONNECT: @dataa 0 0 5 0 dataa 0 0 5 0
// Retrieval info: CONNECT: result 0 0 10 0 @result 0 0 10 0
// Retrieval info: CONNECT: @datab 0 0 5 0 datab 0 0 5 0
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: U_Polynomial_1.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module U_Polynomial_1 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_1.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_1.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_1.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_1.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_1_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_1_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: U_Polynomial_2.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module U_Polynomial_2 (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_2.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_2_bb.v TRUE

// megafunction wizard: %LPM_RAM_DP%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: U_Polynomial.v
// Megafunction Name(s):
// 			altsyncram
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 5.0 Build 148 04/26/2005 SJ Full Version
// ************************************************************


//Copyright (C) 1991-2005 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module U_Polynomial (
	data,
	wren,
	wraddress,
	rdaddress,
	rden,
	clock,
	q);

	input	[7:0]  data;
	input	  wren;
	input	[4:0]  wraddress;
	input	[4:0]  rdaddress;
	input	  rden;
	input	  clock;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	RAMB18E1 altsyncram_component(
		.DOBDO(sub_wire0),
		.DOADO(),
		.DOPBDOP(),
		.DOPADOP(),
		.DIBDI(),
		.DIADI(data),
		.DIPBDIP(),
		.DIPADIP(),

		.ADDRARDADDR(rdaddress),
		.CLKARDCLK(clock),
		.ENARDEN(rden),
		.REGCEAREGCE(),
		.RSTRAMARSTRAM(),
		.RSTREGARSTREG(),
		.WEA(),

		.ADDRBWRADDR(wraddress),
		.CLKBWRCLK(clock),
		.ENBWREN(wren),
		.REGCEB(),
		.RSTRAMB(),
		.RSTREGB(),
		.WEBWE()
	);
	/*
	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (clock),
				.address_a (wraddress),
				.address_b (rdaddress),
				.rden_b (rden),
				.data_a (data),
				.q_b (sub_wire0)
				// synopsys translate_off
				,
				.aclr0 (),
				.aclr1 (),
				.addressstall_a (),
				.addressstall_b (),
				.byteena_a (),
				.byteena_b (),
				.clock1 (),
				.clocken0 (),
				.clocken1 (),
				.data_b (),
				.q_a (),
				.wren_b ()
				// synopsys translate_on
				);
	defparam
		altsyncram_component.intended_device_family = "Stratix",
		altsyncram_component.operation_mode = "DUAL_PORT",
		altsyncram_component.width_a = 8,
		altsyncram_component.widthad_a = 5,
		altsyncram_component.numwords_a = 32,
		altsyncram_component.width_b = 8,
		altsyncram_component.widthad_b = 5,
		altsyncram_component.numwords_b = 32,
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.width_byteena_a = 1,
		altsyncram_component.outdata_reg_b = "UNREGISTERED",
		altsyncram_component.indata_aclr_a = "NONE",
		altsyncram_component.wrcontrol_aclr_a = "NONE",
		altsyncram_component.address_aclr_a = "NONE",
		altsyncram_component.address_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_reg_b = "CLOCK0",
		altsyncram_component.rdcontrol_aclr_b = "NONE",
		altsyncram_component.address_aclr_b = "NONE",
		altsyncram_component.outdata_aclr_b = "NONE",
		altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.init_file = "mea_buffers.mif";*/


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: MEM_IN_BITS NUMERIC "1"
// Retrieval info: PRIVATE: OPERATION_MODE NUMERIC "2"
// Retrieval info: PRIVATE: UseDPRAM NUMERIC "1"
// Retrieval info: PRIVATE: VarWidth NUMERIC "0"
// Retrieval info: PRIVATE: WIDTH_WRITE_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_WRITE_B NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_A NUMERIC "8"
// Retrieval info: PRIVATE: WIDTH_READ_B NUMERIC "8"
// Retrieval info: PRIVATE: MEMSIZE NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: Clock NUMERIC "0"
// Retrieval info: PRIVATE: rden NUMERIC "1"
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
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_B NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: ADDRESSSTALL_B NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_MIXED_PORTS NUMERIC "2"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "mea_buffers.mif"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_B"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
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
// Retrieval info: CONSTANT: RDCONTROL_REG_B STRING "CLOCK0"
// Retrieval info: CONSTANT: RDCONTROL_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: ADDRESS_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_ACLR_B STRING "NONE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_MIXED_PORTS STRING "DONT_CARE"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: INIT_FILE STRING "mea_buffers.mif"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT VCC wren
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: wraddress 0 0 5 0 INPUT NODEFVAL wraddress[4..0]
// Retrieval info: USED_PORT: rdaddress 0 0 5 0 INPUT NODEFVAL rdaddress[4..0]
// Retrieval info: USED_PORT: rden 0 0 0 0 INPUT VCC rden
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_b 0 0 8 0
// Retrieval info: CONNECT: @address_a 0 0 5 0 wraddress 0 0 5 0
// Retrieval info: CONNECT: @address_b 0 0 5 0 rdaddress 0 0 5 0
// Retrieval info: CONNECT: @rden_b 0 0 0 0 rden 0 0 0 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial.bsf TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL U_Polynomial_bb.v TRUE

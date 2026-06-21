`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:52:20 05/08/2026 
// Design Name: 
// Module Name:    dram 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dram(
    	input rst_n,
		input clk,
		input clkcpu,
		input rw,
		input as_n,
		input uds_n,
		input lds_n,
		input [22:1] adr,
		output reg [11:0] madr,
		output we_n,
		output ras_n,
		output cash_n,
		output casl_n,
		output oe_n,
		input access
		);

	reg refresh_cas;
	reg refresh_ras;
	reg access_casu;
	reg access_casl;
	reg access_ras;


	localparam tCLK_ns = 'd10;

	localparam tRFR_ns = 'd64000000;
	localparam nRFR = 'd4096;
	localparam RFR_max = (tRFR_ns/(nRFR*tCLK_ns));
	localparam tCSR_ns = 'd5;
	localparam tCSR_min = tCSR_ns/tCLK_ns ? tCSR_ns/tCLK_ns : 'd1;
	localparam tCHR_ns = 'd8;
	localparam tCHR_min = tCHR_ns/tCLK_ns ? tCHR_ns/tCLK_ns : 'd1;

	/*
	 * 4096 CBR refreshes in 64ms ^= 1 CBR refresh every 15625ns
	 * one CLK cycle @ 100 MHz ^= 10ns
	 * every ~ 1562 cycles a CBR refresh is necessary
	 */
	/*
	reg [10:0] RFR_ctr = 11'd0;
	reg cbr_cycle;

	always @(posedge clk) begin
		if (RFR_ctr == RFR_max & cbr_cyle == 1'b0) begin
			RFR_ctr <= 'd0;
		end
		else if (RFR_ctr < RFR_max) begin
			RFR_ctr <= RFR_ctr + 'd1;
		end
	end

	always @(posedge clk or posedge refresh_cas) begin
		if (refresh_cas) begin
			cbr_cycle <= 1'b0;
		end
		else if (RFR_ctr == RFR_max) begin
			cbr_cycle <= 1'b1;
		end
	end
	 */

	/*
	 * 4096 CBR refreshes in 64ms ^= 1 CBR refresh every 15625ns
	 * one CLK cycle @ 7.09 MHz ^= 140,9691ns
	 * every ~ 110 cycles a CBR refresh is necessary
	 */

	reg [6:0] counter = 7'd0;
	reg cbr_cycle;

	always @(posedge clkcpu) begin
		if (counter == 'd110) begin
			counter <= 'd0;
		end
		else begin
			counter <= counter + 'd1;
		end
	end

	always @(posedge clkcpu or posedge refresh_cas) begin
		if (refresh_cas) begin
			cbr_cycle <= 1'b0;
		end else
		if (counter == 'd110) begin
			cbr_cycle <= 1'b1;
		end
	end

	/*
	 * CBR (CAS Before RAS) refresh
	 * If this is a refresh cycle:
	 * 1. assert CAS on the rising edge of S0
	 * 2. assert RAS tCSR after asserting CAS
	 * 3. deassert CAS tCHR after asserting RAS
	 * 4. deassert RAS tRAS after asserting RAS
	 */
/*
	reg tCSR;
	reg [1:0]tCSR_ctr;
	reg tCHR;
	reg [1:0]tCHR_ctr;

	always @(posedge clkcpu or negedge rst_n) begin
		if (!rst_n) begin
			refresh_cas <= 1'b0;
		end
		else if (clkcpu) begin
			refresh_cas <= (!refresh_cas & as_n & !access_ras & cbr_cycle);
		end
	end

	always @(posedge clk or posedge refresh_cas) begin
		if (refresh_cas) begin
			tCSR <= 1'b0;
		end
		if (tCSR_ctr >= tCSR_min) begin
			tCSR <= 1'b1;
		end
	end

	always @(posedge clk) begin
		if (!tCSR) begin
			tCSR_ctr <= 'd0;
		end
		else if (!tCHR) begin
			tCHR_ctr <= 'd0;
		else if (tCSR_ctr < tCSR_min) begin
			tCSR_ctr <= tCSR_ctr + 'd1;
		end
		else if (tCHR_ctr < tCHR_min) begin
			tCHR_ctr <= tCHR_ctr + 'd1;
		end
	end

	always @(posedge tCSR) begin
		refresh_ras <= 1'b1;
	end

	always @(posedge clk or posedge refresh_ras) begin
		if (refresh_ras) begin
			tCHR <= 1'b0;
		end
		else if (tCHR_ctr >= tCHR_min) begin
			tCHR <= 1'b1;
		end
	end

	always @(posedge tCSR) begin
		refresh_ras <= 1'b1;
	end

*/

	/*
	 * CBR (CAS Before RAS) refresh
	 * assert CAS on the falling edge of S0
	 * deassert CAS on the falling egde of S2
	 */
	always @(negedge clkcpu or negedge rst_n) begin
		if (!rst_n) begin
			refresh_cas <= 1'b0;
		end
		else begin
			refresh_cas <= (!refresh_cas & as_n & !access_ras & cbr_cycle);
		end
	end

	/*
	 * CBR (CAS Before RAS) refresh
	 * assert RAS on the rising edge of S2
	 * deassert RAS on the rising edge of S4
	 */
	always @(posedge clkcpu or negedge rst_n) begin
		if (!rst_n) begin
			refresh_ras <= 1'b0;
		end
		else begin
			refresh_ras <= refresh_cas;
		end
	end

	/*
	 * memory access
	 * assert RAS on the rising edge of S4
	 * deassert RAS on the rising edge of S7
	 *
	 * assert CAS on the rising edge of S6
	 * deassert CAS on the rising edge of S7
	 */
	always @(posedge clkcpu or negedge rst_n) begin
		if (!rst_n) begin
			access_ras <= 1'b0;
			access_casu <= 1'b0;
			access_casl <= 1'b0;
		end
		else begin
			access_ras <= (access & !access_casu & !access_casl);
			access_casu <= (access_ras & !access_casu & !uds_n);
			access_casl <= (access_ras & !access_casl & !lds_n);
		end
	end

	always @(negedge clkcpu) begin
		if (!access_ras) begin
			madr[11:0] <= adr[22:11];
		end
		else begin
			madr[11:0] <= {2'b0, adr[10:1]};
		end
	end

	assign we_n = rw | (uds_n & lds_n);
	assign ras_n = !(access_ras | (refresh_ras & refresh_cas));
	assign cash_n = !(access_casu | refresh_cas);
	assign casl_n = !(access_casl | refresh_cas);
	assign oe_n = !access | as_n | !rst_n | (uds_n & lds_n);

endmodule

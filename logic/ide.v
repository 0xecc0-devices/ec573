`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:41:53 05/01/2026 
// Design Name: 
// Module Name:    ide 
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
module ide_ctrl(
	input rst_n,
	input clk,
	input rw,
	input as_n,
	input uds_n,
	input [16:12] adr,
	input [1:0] data_in,
	input configured,
	output iow_n,
	output ior_n,
	output [1:0] ide1_cs_n,
	output [1:0] ide2_cs_n,
	input access,
	output oe_n,
	output [1:0] rom_bank,
	output rom_oe_n
	);

/*
	IDE controller is mapped to one of the AutoConfig destination
	addresses for Zorro II I/O devices: $00E90000 - $00EFFFFF

	A23 A22 A21 A20 A19 A18 A17 A16
	  1   1   1   0   1   0   0   1		$00E9xxxx -- 64kB chunk
	  1   1   1   0   1   0   1   0		$00EAxxxx -- 64kB chunk
	  1   1   1   0   1   0   1   1		$00EBxxxx -- 64kB chunk
	  1   1   1   0   1   1   0   0		$00ECxxxx -- 64kB chunk
	  1   1   1   0   1   1   0   1		$00EDxxxx -- 64kB chunk
	  1   1   1   0   1   1   1   0		$00EExxxx -- 64kB chunk
	  1   1   1   0   1   1   1   1		$00EFxxxx -- 64kB chunk

	The IDE controller channels can be acccessed in the lower 64kB
	chunk. The IDE controller Autoboot ROM is mapped to the upper
	64kB chunk. Since the Autoboot ROM is larger than 64kB, a write
	to one of the bank select address takes data bus d15 and d14
	as bank select addresses for the Autoboot ROM.

	A16 A15 A14 A13 A12
	  0   0   0   0   0
	  0   0   0   0   1 - IDE channel 1 - CS0 aka CS1Fx
	  0   0   0   1   0 - IDE channel 1 - CS1 aka CS3Fx
	  0   0   0   1   1
	  0   0   1   0   0
	  0   0   1   0   1 - IDE channel 2 - CS1 aka CS1Fx
	  0   0   1   1   0 - IDE channel 2 - CS1 aka CS3Fx
	  0   0   1   1   1
	  0   1   0   0   0 - bank select
	  0   1   0   0   1 - bank select
	  0   1   0   1   0 - bank select
	  0   1   0   1   1 - bank select
	  0   1   1   0   0 - bank select
	  0   1   1   0   1 - bank select
	  0   1   1   1   0 - bank select
	  0   1   1   1   1 - bank select

*/

	reg ide_enabled = 0;

	reg [1:0] as_delay; // AS_n shifted by CLK
	reg [1:0] rom_bankSel;

	/*
	 * ide rom 64k + 64k bank selection
	 */
	assign rom_bank = (ide_enabled) ? rom_bankSel : {1'b0,adr[16]};
	// IDE ROM is mapped to whole range until ide is enabled by the first write
	// After then, it is mapped to (base address) + 64K
	assign rom_oe_n = !(!as_n && access && (!ide_enabled || !(adr[12] ^ adr[13]) || adr[16]));

	reg S3_n;           // S3 has started

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			ide_enabled <= 0;
			rom_bankSel <= 0;
		end
		else begin
		 // IDE enabled on first write seen
			if (configured && access && !rw && !uds_n && !S3_n) begin
				ide_enabled <= 1;
			end
			if (configured && access && adr[16:15] == 2'b01 && !rw && !uds_n && !S3_n) begin
				rom_bankSel <= data_in;
			end
		end
	end

	wire cs0 = ide_enabled &&
				  access &&
				  adr[16:15] == 2'b00 &&
				  adr[13:12] == 2'b01;

	wire cs1 = ide_enabled &&
				  access &&
				  adr[16:15] == 2'b00 &&
				  adr[13:12] == 2'b10;

	assign ide1_cs_n[0] = !(!adr[14] && cs0);
	assign ide1_cs_n[1] = !(!adr[14] && cs1);
	assign ide2_cs_n[0] = !( adr[14] && cs0);
	assign ide2_cs_n[1] = !( adr[14] && cs1);

	always @(negedge clk or negedge rst_n) begin
	  if (!rst_n) begin
		 S3_n <= 1;
	  end else begin
		 S3_n <= as_n;
	  end
	end

	always @(posedge clk or negedge rst_n) begin
	  if (!rst_n) begin
		 as_delay <= 2'b11;
	  end else begin
		 if (as_n) begin
			as_delay[1:0] <= 2'b11;
		 end else begin
			as_delay <= {as_delay[0], S3_n};
		 end
	  end
	end

	// IOR Active during states S3-S6
	// IOW Active during states S3-S5
	assign ior_n = !(!as_n &&  rw && !S3_n);
	assign iow_n = !(!as_n && !rw && !S3_n && as_delay[1]);

	assign oe_n = !(access | !as_n | rst_n | !uds_n);

endmodule

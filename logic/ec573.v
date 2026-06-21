`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:33:16 05/01/2026 
// Design Name: 
// Module Name:    ec573 
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
module ec573(
/*
 * system port
 */
	/*
	 * clk is a 100Mhz clock input with 10ns cycle time
	 */
	input clk,
	/*
	 * clk7m is the standard 7Mhz clock coming from the Amiga mainboard
	 */
	input clk7m,
	input rst_n,
	input as_n,
	input uds_n,
	input lds_n,
	input rw,
	output dtack_n,
	input berr_n,
	inout [15:12] d,
	input [23:1] a,
/*
 * bus buffers and level shifters
 */
	output boe_n,
/*
 * dram port
 */
	output [11:0] ma,
	output mwe_n,
	output mras_n,
	output mcash_n,
	output mcasl_n,
	output moe_n,
/*
 * ide port
 */
	output ior_n,
	output iow_n,
	output [1:0] ide1_cs_n,
	output [1:0] ide2_cs_n,
	output rom_cs_n,
	output rom_oe_n,
	output rom_we_n,
	output [1:0] rom_bank
	);
/*
	wire [3:0] debug = 4'bz;
*/
	`include "../Z2_Autoconfig_Registers/Z2_Autoconfig_Constants.v"
	wire autoconfig_cycle;
	wire dram_cycle;
	wire ide_cycle;

	wire mboe_n;
	wire iboe_n;

	wire ds_n = uds_n & lds_n;
	wire clkcpu = clk7m;

	wire cfgout_n;
	wire cfgin_n;
	wire [1:0] device_configured;
	wire [3:0] ac_data_out;
	wire [2:0] base_address_ide;

	/*
	 * autoconfig cycle
	 */
	assign autoconfig_cycle = ((a[23:16] == 8'hE8) &
								      !as_n &
								      !cfgin_n &
								      cfgout_n);

	/*
	 * dram cycle
	 */
	assign dram_cycle = ((a[23:21] >= 3'b001) &
							   (a[23:21] <= 3'b100) &
							   !as_n &
							   device_configured[ram]);

	/*
	 * ide cycle
	 */
	assign ide_cycle = ((a[23:16] >= 8'hE8 + {5'b0,base_address_ide[2:0]}) &
							  (a[23:16] < 8'hE8 + {5'b0,base_address_ide[2:0]} + {5'b0,io_128k_size[2:0]}) &
						     !as_n &
							  device_configured[ide]);

	autoconfig autoconfig (
		.rst_n(rst_n),
		.rw(rw),
		.ds_n(ds_n),
		.adr_h(a[23:16]),
		.adr_l(a[6:1]),
		.data_in(d[15:12]),
		.data_out(ac_data_out[3:0]),
		.cfgin(cfgin_n),
		.cfgout(cfgout_n),
		.access(autoconfig_cycle),
		.configured(device_configured[1:0]),
		.base_address_ide(base_address_ide[2:0])
	);

	dram dram (
		.rst_n(rst_n),
		.clk(clk),
		.clkcpu(clkcpu),
		.rw(rw),
		.as_n(as_n),
		.uds_n(uds_n),
		.lds_n(lds_n),
		.adr(a[22:1]),
		.madr(ma[11:0]),
		.we_n(mwe_n),
		.ras_n(mras_n),
		.cash_n(mcash_n),
		.casl_n(mcasl_n),
		.oe_n(mboe_n),
		.access(dram_cycle)
	);

	ide_ctrl ide_ctrl (
		.rst_n(rst_n),
		.clk(clk7m),
		.rw(rw),
		.as_n(as_n),
		.uds_n(uds_n),
		.adr(a[16:12]),
		.data_in(d[15:14]),
		.configured(device_configured[ide]),
		.iow_n(iow_n),
		.ior_n(ior_n),
		.ide1_cs_n(ide1_cs_n),
		.ide2_cs_n(ide2_cs_n),
		.access(ide_cycle),
		.oe_n(iboe_n),
		.rom_bank(rom_bank[1:0]),
		.rom_oe_n(rom_oe_n)
	);

	wire[3:0] d_out = autoconfig_cycle ? ac_data_out : 4'bz;
	assign d[15:12] = (autoconfig_cycle && rw && !uds_n && rst_n) ? d_out : 4'bz;

/*
	assign rom_oe_n = 1'bz;
	assign rom_bank[1:0] = 2'bz;
*/

	assign boe_n = iboe_n | mboe_n;

	assign rom_cs_n = 1'bz;
	assign rom_we_n = 1'bz;

	assign moe_n = 1'b0;
	assign dtack_n = 1'bz;

endmodule

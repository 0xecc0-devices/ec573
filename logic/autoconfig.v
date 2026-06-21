`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:01:06 05/01/2026 
// Design Name: 
// Module Name:    autoconfig 
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
module autoconfig(
	input rst_n,
	input rw,
	input ds_n,
	input [7:0] adr_h,
	input [5:0] adr_l,
	input [3:0] data_in,
	output reg [3:0] data_out,
	output cfgin,
	output cfgout,
	input access,
	output reg [1:0] configured,
	output reg [2:0] base_address_ide
	);

	`include "../Z2_Autoconfig_Registers/Z2_Autoconfig_Registers.v"
	`include "../Z2_Autoconfig_Registers/Z2_Autoconfig_Constants.v"
	/*
	 * virtual cfgin and cfgout
	 */
	reg cfgin_n = 1'b1;
	reg cfgout_n = 1'b1;

	reg [1:0] device = ram;

	reg ec_Reserved03_idle = 1'b0;

	assign cfgin = cfgin_n;
	assign cfgout = cfgout_n;

	/*
	 * cfgin_n simulation for Kickstart 2.0 and later
	 *
	 * From AmigaOS 2.0 (v37.150) onwards Autoconfig is scanning the device chain
	 * multiple times. If there is no other Autoconfig device answering anymore
	 * which leaves the bus levels high, we can jump in on the next Autoconfig
	 * cycle and get our boards configured.
	 * This leaves us the very last board in the chain, so we get the resources
	 * that are left by the other cards, but we save manual wires for _CFGIN and
	 * _CFGOUT signals not present on the Amiga CPU socket.
	 */
	always @(posedge ds_n or negedge rst_n) begin	
		if (!rst_n) begin
			ec_Reserved03_idle <= 1'b0;
			cfgin_n <= 1'b1;
		end else
		if (!cfgout_n) begin
			cfgin_n <= 1'b1;
		end else
		if ((adr_h == 8'he8) & rw) begin
			case (adr_l[5:0])
			/* check if er_Reserved03 is answered by another card
			 */
			er_Reserved03_u:	  
				if (!(data_in[3:0] == 4'hf)) begin
					ec_Reserved03_idle <= 1'b1;
				end
			/* if er_Reserved03 has been left unanswered at the end of the current
			 * Autoconfig cycle we can be sure there is no other card to be configured
			 */
			er_Reserved0f_l:	  
				if (ec_Reserved03_idle) begin
					cfgin_n <= 0;
				end
		  endcase
		end
	end

	/*
	 * autoconfig data
	 */
	always @(negedge ds_n or negedge rst_n) begin
		if (!rst_n) begin
			device <= ram;
			cfgout_n <= 1'b1;
			configured[1:0] <= 2'b0;
		end
		else if (access) begin
			/*
			 * output autoconfig data to operating system
			 */
			if (rw) begin
				case (adr_l)
					er_Type_u: begin
						case (device)
							ram: begin
								data_out[3:0] <= (er_Type_ZORRO_II | er_Type_SYS_MEMORY);
							end
							ide: begin
								data_out[3:0] <= (er_Type_ZORRO_II | er_Type_AUTOBOOT_ROM);
							end
						endcase
					end
					er_Type_l: begin
						case (device)
							ram: begin
								data_out[3:0] <= er_Type_Size_8MB;
							end
							ide: begin
								data_out[3:0] <= er_Type_Size_128KB;
							end
						endcase
					end
					er_Product_u: begin
						case (device)
							ram: begin
								data_out[3:0] <= ~(GGFR_PROD_ID[7:4]);
							end
							ide: begin
								data_out[3:0] <= ~(RIPPLE_PROD_ID[7:4]);
							end
						endcase
					end
					er_Product_l: begin
						case (device)
							ram: begin
								data_out[3:0] <= ~(GGFR_PROD_ID[3:0]);
							end
							ide: begin
								data_out[3:0] <= ~(RIPPLE_PROD_ID[3:0]);
							end
						endcase
					end
					er_Flags_u: begin
						case (device)
							ram: begin
								data_out[3:0] <= ~(er_Flags_8MB_PREF);
							end
							ide: begin
								data_out[3:0] <= ~(4'b0);
							end
						endcase
					end
					er_Manufacturer_byte0_u: begin
						data_out[3:0] <= ~(MFG_ID_OHR[15:12]);
					end
					er_Manufacturer_byte0_l: begin
						data_out[3:0] <= ~(MFG_ID_OHR[11:8]);
					end
					er_Manufacturer_byte1_u: begin
						data_out[3:0] <= ~(MFG_ID_OHR[7:4]);
					end
					er_Manufacturer_byte1_l: begin
						data_out[3:0] <= ~(MFG_ID_OHR[3:0]);
					end
					er_InitDiagVec_byte1_l: begin
						case (device)
							ide: begin
								data_out[3:0] <= ~(4'h8);
							end
							default:
								data_out[3:0] <= ~(4'b0);
						endcase
					end
					ec_Interrupt_u: begin
						data_out[3:0] <= 4'b0;
					end
					ec_Interrupt_l: begin
						data_out[3:0] <= 4'b0;
					end
					default:
						data_out[3:0] <= ~(4'b0);
				endcase
			end
			/*
			 * get autoconfig data from operating system
			 */
			else begin
				case (adr_l)
					ec_BaseAddress_u: begin
						case (device)
							ram: begin
								/*
								 * if configured successfully base address is 4'h2
								 */
								configured[ram] <= 1'b1;
							end
							ide: begin
								/*
								 * set if configured successfully
								 */
								configured[ide] <= 1'b1;
							end
						endcase
						if (device == ide) begin
							/*
							 * assert cfgout once we're done with getting configured
							 */
							cfgout_n <= 1'b0;
						end
						else begin
							device <= device + 1;
						end
					end
					ec_BaseAddress_l: begin
						case (device)
							ram: begin
							end
							ide: begin
								base_address_ide[2:0] <= data_in[2:0];
							end
						endcase
					end
					ec_Shutup_u: begin
						case (device)
							ram: begin
								configured[ram] <= 1'b0;
							end
							ide: begin
								configured[ide] <= 1'b0;
							end
						endcase
					end
				endcase
			end
		end
	end
endmodule

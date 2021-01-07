`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module mycpu_top(
	input wire[5:0] int,
	input wire aclk,aresetn,
	
	// axi port
    //ar
    output wire[3:0] arid,      //read request id, fixed 4'b0
    output wire[31:0] araddr,   //read request address
    output wire[7:0] arlen,     //read request transfer length(beats), fixed 4'b0
    output wire[2:0] arsize,    //read request transfer size(bytes per beats)
    output wire[1:0] arburst,   //transfer type, fixed 2'b01
    output wire[1:0] arlock,    //atomic lock, fixed 2'b0
    output wire[3:0] arcache,   //cache property, fixed 4'b0
    output wire[2:0] arprot,    //protect property, fixed 3'b0
    output wire arvalid,        //read request address valid
    input wire arready,         //slave end ready to receive address transfer
    //r              
    input wire[3:0] rid,        //equal to arid, can be ignored
    input wire[31:0] rdata,     //read data
    input wire[1:0] rresp,      //this read request finished successfully, can be ignored
    input wire rlast,           //the last beat data for this request, can be ignored
    input wire rvalid,          //read data valid
    output wire rready,         //master end ready to receive data transfer
    //aw           
    output wire[3:0] awid,      //write request id, fixed 4'b0
    output wire[31:0] awaddr,   //write request address
    output wire[3:0] awlen,     //write request transfer length(beats), fixed 4'b0
    output wire[2:0] awsize,    //write request transfer size(bytes per beats)
    output wire[1:0] awburst,   //transfer type, fixed 2'b01
    output wire[1:0] awlock,    //atomic lock, fixed 2'b01
    output wire[3:0] awcache,   //cache property, fixed 4'b01
    output wire[2:0] awprot,    //protect property, fixed 3'b01
    output wire awvalid,        //write request address valid
    input wire awready,         //slave end ready to receive address transfer
    //w          
    output wire[3:0] wid,       //equal to awid, fixed 4'b0
    output wire[31:0] wdata,    //write data
    output wire[3:0] wstrb,     //write data strobe select bit
    output wire wlast,          //the last beat data signal, fixed 1'b1
    output wire wvalid,         //write data valid
    input wire wready,          //slave end ready to receive data transfer
    //b              
    input  wire[3:0] bid,       //equal to wid,awid, can be ignored
    input  wire[1:0] bresp,     //this write request finished successfully, can be ignored
    input wire bvalid,          //write data valid
    output wire bready,          //master end ready to receive write response

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata

    );

	//sram signal
	//cpu inst sram
	wire        inst_sram_en	;
	wire [3 :0] inst_sram_wen	;
	wire [31:0] inst_sram_addr	;
	wire [31:0] inst_sram_wdata	;
	wire [31:0] inst_sram_rdata	;
	wire 		fetch_stall		;
	wire 		longest_stall_f	;
	//cpu data sram
	wire        data_sram_en	;
	wire [3 :0] data_sram_wen	;
	wire [31:0] data_sram_addr	;
	wire [31:0] data_sram_wdata	;
	wire [31:0] data_sram_rdata	;
	wire 		memory_stall	;
	wire 		longest_stall_m	;
	//axi signal
	//cpu inst axi
	wire		inst_req	;
	wire		inst_wr		;
	wire [1 :0]	inst_size	;
	wire [31:0]	inst_addr	;
	wire [31:0]	inst_wdata	;
	wire [31:0]	inst_rdata	;
	wire		inst_addr_ok;
	wire		inst_data_ok;

	//cpu data axi
	wire		data_req	;
	wire		data_wr		;
	wire [1 :0]	data_size	;
	wire [31:0]	data_addr	;
	wire [31:0]	data_wdata	;
	wire [31:0]	data_rdata	;
	wire		data_addr_ok;
	wire		data_data_ok;

	wire clk;
	wire rst;
	assign clk = ~aclk;
	assign rst = ~aresetn;

	sram_mips mips(
    	.clk              (aclk   	),
    	.resetn           (rst	),  //low active
    	.int              (6'd0		),  //interrupt,high active

    	.inst_sram_en     (inst_sram_en		),
    	.inst_sram_wen    (inst_sram_wen	),
    	.inst_sram_addr   (inst_sram_addr	),
    	.inst_sram_wdata  (inst_sram_wdata	),
    	.inst_sram_rdata  (inst_sram_rdata	),
		.fetch_stall	  (fetch_stall		),
		.longest_stall_f  (longest_stall_f	),
	
    	.data_sram_en     (data_sram_en		),
    	.data_sram_wen    (data_sram_wen	),
    	.data_sram_addr   (data_sram_addr	),
    	.data_sram_wdata  (data_sram_wdata	),
    	.data_sram_rdata  (data_sram_rdata	),
		.memory_stall	  (memory_stall		),
		.longest_stall_m  (longest_stall_m	),

    	//debug
    	.debug_wb_pc      (debug_wb_pc      ),
    	.debug_wb_rf_wen  (debug_wb_rf_wen  ),
    	.debug_wb_rf_wnum (debug_wb_rf_wnum ),
    	.debug_wb_rf_wdata(debug_wb_rf_wdata)
	);

	d_sram2sraml inst_bridge(
    	.clk(aclk),
		.rst(rst),
    	//sram
    	.data_sram_en   (inst_sram_en		),
    	.data_sram_wen  (inst_sram_wen		),
    	.data_sram_addr (inst_sram_addr		),
    	.data_sram_rdata(inst_sram_rdata	),
    	.data_sram_wdata(inst_sram_wdata	),
    	.d_stall		(fetch_stall		),
    	.longest_stall	(longest_stall_f	),
    	//sram_like
    	.data_req		(inst_req		),
    	.data_wr		(inst_wr		),
    	.data_size		(inst_size		),
    	.data_addr		(inst_addr		),
    	.data_wdata		(inst_wdata		),
    	.data_rdata		(inst_rdata		),
    	.data_addr_ok	(inst_addr_ok	),
    	.data_data_ok	(inst_data_ok	)
	);
	d_sram2sraml data_bridge(
    	.clk(aclk),
		.rst(rst),
    	//sram
    	.data_sram_en   (data_sram_en		),
    	.data_sram_wen  (data_sram_wen		),
    	.data_sram_addr (data_sram_addr		),
    	.data_sram_rdata(data_sram_rdata	),
    	.data_sram_wdata(data_sram_wdata	),
    	.d_stall		(memory_stall		),
    	.longest_stall	(longest_stall_m	),
    	//sram_like
    	.data_req		(data_req		),
    	.data_wr		(data_wr		),
    	.data_size		(data_size		),
    	.data_addr		(data_addr		),
    	.data_wdata		(data_wdata		),
    	.data_rdata		(data_rdata		),
    	.data_addr_ok	(data_addr_ok	),
    	.data_data_ok	(data_data_ok	)
	);

	cpu_axi_interface interface(
		.clk		(aclk		),
		.resetn		(aresetn		),

		.inst_req		(inst_req	 ),
		.inst_wr		(inst_wr	 ),
		.inst_size		(inst_size	 ),
		.inst_addr		(inst_addr	 ),
		.inst_wdata		(inst_wdata	 ),
		.inst_rdata		(inst_rdata	 ),
		.inst_addr_ok	(inst_addr_ok),
		.inst_data_ok	(inst_data_ok),

		.data_req		(data_req	 ),
		.data_wr		(data_wr	 ),
		.data_size		(data_size	 ),
		.data_addr		(data_addr	 ),
		.data_wdata		(data_wdata	 ),
		.data_rdata		(data_rdata	 ),
		.data_addr_ok	(data_addr_ok),
		.data_data_ok	(data_data_ok),

		.arid      (arid      ),
		.araddr    (araddr    ),
		.arlen     (arlen     ),
		.arsize    (arsize    ),
		.arburst   (arburst   ),
		.arlock    (arlock    ),
		.arcache   (arcache   ),
		.arprot    (arprot    ),
		.arvalid   (arvalid   ),
		.arready   (arready   ),
					
		.rid       (rid       ),
		.rdata     (rdata     ),
		.rresp     (rresp     ),
		.rlast     (rlast     ),
		.rvalid    (rvalid    ),
		.rready    (rready    ),
				
		.awid      (awid      ),
		.awaddr    (awaddr    ),
		.awlen     (awlen     ),
		.awsize    (awsize    ),
		.awburst   (awburst   ),
		.awlock    (awlock    ),
		.awcache   (awcache   ),
		.awprot    (awprot    ),
		.awvalid   (awvalid   ),
		.awready   (awready   ),
		
		.wid       (wid       ),
		.wdata     (wdata     ),
		.wstrb     (wstrb     ),
		.wlast     (wlast     ),
		.wvalid    (wvalid    ),
		.wready    (wready    ),
		
		.bid       (bid       ),
		.bresp     (bresp     ),
		.bvalid    (bvalid    ),
		.bready    (bready    )
	);
endmodule

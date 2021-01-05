`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/11 07:49:12
// Design Name: 
// Module Name: cp0_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// s
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//`define RegBus 			31:0

//中断异常处理流程
//首先是在会出现异常的地方进行异常判断 instRam ALU Memery Controller
//然后将信号一步一步往下面传，一直传到访存阶段，在这里就会是一个八位的信号串
//然后根据信号串在exception得到异常类型
//将异常类型传给harzard hazard 会去判断异常类型，发现异常则会输出一个pc值，这就是异常的处理地址
//将异常类型传给cp0，会记录当前的pc地址，以及一些状态记录 TODO:这里需要理清楚这些状态在跳转回来的时候需要怎么取出来，这里因为是在访存阶段处理的，所以后面已经执行的指令应该怎么处理(这里是应该去清空流水线)？

//例外入口地址统一为0xBFC0.0380

//接下来需要修改的文件
//controller 需要去判断是否会存在保留指令异常  添加vaild信号   还需要在解码的时候判断是否是 Sys 和 Break 异常信号
//alu        需要去判断是否会存在溢出异常      添加overflow信号
//ByteSel    在这里需要去判断半字和字节地址是否存在异常  添加 ADEL ADES（addr exception from stor） 信号 save 的话应该也要去判断
//instruction 在这里需要去判断取出来的pc地址是否存在异常 添加 ADEL信号


module cp0_reg(
	input wire clk,
	input wire rst,

	input wire we_i,
	input[4:0] waddr_i,
	input[4:0] raddr_i,
	input[`RegBus] data_i,

	input wire[5:0] int_i,

	input wire[`RegBus] excepttype_i, //这里是中断的类型，这个直接连接exception就可以得到
	input wire[`RegBus] current_inst_addr_i, //现在的指令地址
	input wire is_in_delayslot_i, //发生例外的指令是否是在延迟槽中 这里应该是使用上一阶段的branch判断值做为决定条件
	input wire[`RegBus] bad_addr_i, //记录最新地址相关例外的出错地址 这里是将地址传进来 TODO:这里可能是用来存放数据地址的？？ 

	output reg[`RegBus] data_o, 
	output reg[`RegBus] count_o, //TODO:？？？？？？？
	output reg[`RegBus] compare_o, //TODO:？？？？？？？
	output reg[`RegBus] status_o, //处理器状态与控制寄存器
	//[31:16] 恒为0
	//[15:8]  中断屏蔽位，每一位控制一个中断使能 1 使能 0 屏蔽
	//[7:2]   恒为0
	//[1:1]   例外级 当发生例外时被置为1 0：正常级 1：例外级 当处于1状态的时候 处理器处于核心态，屏蔽所有中断，且有新的中断不更新EPC和CAUSE
	//[0:0]   全局中断使能位 0 屏蔽所有 1 使能所有

	output reg[`RegBus] cause_o, //存放上一次例外原因
	//[31:31] 用于标识最近发生例外的指令是否发生在延迟槽中 1：在 0：不在
	//[30:16] 恒为0
	//[15:10] 待处理硬件中断标识，每一位对应一个中断线，依次对应硬件中断5-0 1：该中断线上右待处理的中断 0：该中断线上无中断
	//[9:8]   待处理软件中断标识，每一位对应一个软件中断，依次对应软件中断1-0 可由软件设置和清除
	//[7:7]   恒为0
	//[6:2]   例外编码
	//[1:0]   恒为0
	//例外编码表如下
	//0x00 Int 中断
	//0x04 ADEL 地址错例外（读数据和取指令）
	//0x05 ADES 地址错例外（写数据）
	//0x08 Sys  系统调用例外
	//0x09 Bp   断点例外
	//0x0a RI   保留指令例外？？？
	//0x0c Ov   算数溢出例外

	output reg[`RegBus] epc_o, //存放上一次发生例外指令的PC
	output reg[`RegBus] config_o, //TODO:？？？？？？？
	output reg[`RegBus] prid_o, //TODO:？？？？？？？
	output reg[`RegBus] badvaddr, //出错的虚地址
	output reg timer_int_o //TODO:？？？？？？？
    );

	always @(posedge clk) begin
		if(rst == 1'b1) begin
			count_o <= `ZeroWord;
			compare_o <= `ZeroWord;
			status_o <= 32'b00010000000000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			config_o <= 32'b00000000000000001000000000000000;
			prid_o <= 32'b00000000010011000000000100000010;
			timer_int_o <= `InterruptNotAssert;
		end else begin
			count_o <= count_o + 1;
			cause_o[15:10] <= int_i;//对应的硬件中断
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				/* code */
				timer_int_o <= `InterruptAssert;
			end
			if(we_i == `WriteEnable) begin
				/* code */
				case (waddr_i)
					`CP0_REG_COUNT:begin 
						count_o <= data_i;
					end
					`CP0_REG_COMPARE:begin 
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS:begin 
						status_o <= data_i;
					end
					`CP0_REG_CAUSE:begin 
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end
					`CP0_REG_EPC:begin 
						epc_o <= data_i;
					end
					default : /* default */;
				endcase
			end
			case (excepttype_i) 
				32'h00000001:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1; 
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
				end
				32'h00000004:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00100;
					badvaddr <= bad_addr_i;
				end
				32'h00000005:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00101;
					badvaddr <= bad_addr_i;
				end
				32'h00000008:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;
				end
				32'h00000009:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01001;
				end
				32'h0000000a:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;
				end
				32'h0000000c:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01100;
				end
				32'h0000000d:begin 
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;
				end
				32'h0000000e:begin 
					status_o[1] <= 1'b0;
				end
				default : /* default */;
			endcase
		end
	end

	always @(*) begin
		if(rst == 1'b1) begin
			/* code */
			data_o <= `ZeroWord;
		end else begin 
			case (raddr_i)
				`CP0_REG_COUNT:begin 
					data_o <= count_o;
				end
				`CP0_REG_COMPARE:begin 
					data_o <= compare_o;
				end
				`CP0_REG_STATUS:begin 
					data_o <= status_o;
				end
				`CP0_REG_CAUSE:begin 
					data_o <= cause_o;
				end
				`CP0_REG_EPC:begin 
					data_o <= epc_o;
				end
				`CP0_REG_PRID:begin 
					data_o <= prid_o;
				end
				`CP0_REG_CONFIG:begin 
					data_o <= config_o;
				end
				`CP0_REG_BADVADDR:begin 
					data_o <= badvaddr;
				end
				default : begin 
					data_o <= `ZeroWord;
				end
			endcase
		end
	
	end
endmodule

`timescale 1ns / 1ps
//判断异常类型
module exception(
    input wire rst,
    input wire [7:0] except, //这个是判断是什么中断，应该是每个时期的中断拼接在一起的

    input wire adel, //取指和取数据都可能会有这个错  
    
    input wire ades, //只针对于数据存储器，写数据的时候
//如果lw和sw指令的访问地址不对齐于字边界，或者如果lh、 lhu和sh指令的访问地址不对齐于半字边界，
//又或者如果取指PC不对齐于字边界，触发地址错例外


    input wire [31:0] cp0_states, 
    //[31:16] 恒为0
	//[15:8]  中断屏蔽位，每一位控制一个中断使能 1 使能 0 屏蔽
	//[7:2]   恒为0
	//[1:1]   例外级 当发生例外时被置为1 0：正常级 1：例外级 当处于1状态的时候 处理器处于核心态，屏蔽所有中断，且有新的中断不更新EPC和CAUSE
	//[0:0]   全局中断使能位 0 屏蔽所有 1 使能所有
    input wire [31:0] cp0_cause,
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

    output reg [31:0] excepttype //这个需要传给harzard和cp0
);

always @(*) begin
    if(rst) begin
        /*code*/
        excepttype <= 32'b0; //中断例外
    end else begin
        excepttype <= 32'b0;  
        if(((cp0_cause[15:8] & cp0_states[15:8]) != 8'h00) &&
            (cp0_states[1] == 1'b0) && (cp0_states[0] == 1'b1)) begin

            excepttype <= 32'h00000001;

        end else if(except[7] == 1'b1 || adel) begin //地址错例外 - 取指或读数据
            excepttype <= 32'h00000004;  
        end else if(ades) begin //地址错例外 - 写数据
            excepttype <= 32'h00000005;
        end else if(except[6] == 1'b1) begin //系统调用例外 - syscall
            excepttype <= 32'h00000008;
        end else if(except[5] == 1'b1) begin //断点例外 - break
            excepttype <= 32'h00000009;
        end else if(except[4] == 1'b1) begin //eret
            excepttype <= 32'h0000000e;
        end else if(except[3] == 1'b1) begin //保留指令例外
            excepttype <= 32'h0000000a;
        end else if(except[2] == 1'b1) begin //算数溢出例外
            excepttype <= 32'h0000000c;
        end
    end
end

endmodule

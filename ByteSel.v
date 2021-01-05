`timescale 1ns / 1ps
`include "defines.vh"

module ByteSel(
    input wire [31:0] addra,
    input wire [31:0] data,
    input wire [7:0] ALUControl,
    output wire [3:0] sel,
    output wire [31:0] dataOut,
    output reg ADEL,
    output reg ADES
);

reg [3:0] select;
reg [31:0] dataout;
assign sel = select;
assign dataOut = dataout;

always @(*)
begin
    ADEL <= 1'b0;
    ADES <= 1'b0;
    case(ALUControl)
        `EXE_LB_OP:  begin
            select <= 4'b0000;
            dataout <= data;
        end
        `EXE_LBU_OP:begin
            select <= 4'b0000;
            dataout <= data;
        end
        `EXE_LH_OP: begin
            select <= 4'b0000;
            dataout <= data;
            if(addra[0] != 0) ADEL <= 1'b1;
        end
        `EXE_LHU_OP: begin
            select <= 4'b0000;
            dataout <= data;
            if(addra[0] != 0) ADEL <= 1'b1;
        end
        `EXE_LW_OP: begin
            select <= 4'b0000;
            dataout <= data;
            if(addra[1:0] != 2'b00) ADEL <= 1'b1;
        end
        `EXE_SB_OP: begin
            case(addra[1:0])
                2'b11: begin 
                    select <= 4'b1000;
                    dataout <= data << 24;
                end
                2'b10: begin 
                    select <= 4'b0100;
                    dataout <= data << 16;
                end
                2'b01: begin 
                    select <= 4'b0010;
                    dataout <= data << 8;
                end
                2'b00: begin 
                    select <= 4'b0001;
                    dataout <= data;
                end
            endcase
        end

        `EXE_SH_OP: begin
            if(addra[0] != 0) ADES <= 1'b1;
            case(addra[1:0])
                2'b10: begin 
                    select <= 4'b1100;
                    dataout <= data << 16;
                end
                2'b00: begin
                    select <= 4'b0011;
                    dataout <= data;
                end
            endcase
        end
        `EXE_SW_OP: begin
            select <= 4'b1111;
            dataout <= data;
            if(addra[1:0] != 2'b00) ADES <= 1'b1;
        end
        default: begin
            select <= 4'b0000;
            dataout <= data;
        end
    endcase
end

endmodule
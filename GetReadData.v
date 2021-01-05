`timescale 1ns / 1ps
`include "defines.vh"

module GetReadData(
    input wire [31:0] addra,
    input wire [31:0] readData,
    input wire [7:0] ALUControl,
    output wire [31:0] finalData
);

reg [31:0] finalDataGet;
assign finalData = finalDataGet;


always @(*)
begin
    case(ALUControl)
        `EXE_LW_OP: finalDataGet <= readData;
        `EXE_LB_OP:  begin
            case (addra[1:0])
                2'b11: finalDataGet <= {{24{readData[31]}},readData[31:24]};
                2'b10: finalDataGet <= {{24{readData[23]}},readData[23:16]};
                2'b01: finalDataGet <= {{24{readData[15]}},readData[15:8]};
                2'b00: finalDataGet <= {{24{readData[7]}},readData[7:0]};
            endcase
        end

        `EXE_LBU_OP: begin
            case (addra[1:0])
                2'b11: finalDataGet <= {{24{1'b0}},readData[31:24]};
                2'b10: finalDataGet <= {{24{1'b0}},readData[23:16]};
                2'b01: finalDataGet <= {{24{1'b0}},readData[15:8]};
                2'b00: finalDataGet <= {{24{1'b0}},readData[7:0]};
                 
            endcase
        end

        `EXE_LH_OP:begin
            case (addra[1:0])
                2'b10: finalDataGet <= {{16{readData[31]}},readData[31:16]};
                2'b00: finalDataGet <= {{16{readData[15]}},readData[15:0]};
            endcase
        end
        `EXE_LHU_OP: begin
            case (addra[1:0])
                2'b10: finalDataGet <= {{16{1'b0}},readData[31:16]};
                2'b00: finalDataGet <= {{16{1'b0}},readData[15:0]};
                 
            endcase
        end

        default: finalDataGet <= 32'b0;
    endcase
end

endmodule
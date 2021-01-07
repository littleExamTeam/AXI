`timescale 1ns / 1ps
module hazard(
    input  wire FetchStall, MemoryStall,
    output wire LongestStall,
    //fetch stage
    output wire StallF, FlushF,

    //decode stage
    input wire [4:0] RsD, RtD,
    input wire BranchD,
    input wire [1:0] DatatoRegD,

    input wire JrD,

    output wire StallD, FlushD,
    output reg [1:0] ForwardRsED, ForwardRsMD,
    output reg [1:0] ForwardRtED, ForwardRtMD,
    //output reg [1:0] ForwardALD,

    //excute stage
    input wire [4:0] RsE, RtE,
    input wire [4:0] WriteRegE,
    input wire [1:0] DatatoRegE,
    input wire RegWriteE,

    input wire JalE, BalE,

    input wire StartDivE,
    input wire DivReadyE,

    input wire Cp0ReadE,

    output wire FlushE, StallE,
    output reg [1:0] ForwardRsME, ForwardRsWE,
    output reg [1:0] ForwardRtME, ForwardRtWE,
    output reg [1:0] ForwardHIE , ForwardLOE,
    //------------------------

    //mem stage
    input wire [4:0] RtM,
    input wire [4:0] WriteRegM,
    input wire [1:0] DatatoRegM,
    input wire RegWriteM,
    input wire HIWriteM, LOWriteM,
    input wire [1:0] DatatoHIM, DatatoLOM,
    input wire JalM, BalM,
    input wire Cp0ReadM,
    output wire StallM,
    output wire FlushM,
    //exc
    input wire ExceptSignal,
    input wire [31:0] ExceptType,
    input wire [31:0] EPCM,
    output reg [31:0] NewPCM,
    //------------------------

    //writeback stage
    input wire [4:0] RtW,
    input wire [4:0] WriteRegW,
    input wire [1:0] DatatoRegW,
    input wire RegWriteW,
    //add movedata inst oprand
    input wire HIWriteW, LOWriteW,
    input wire [1:0] DatatoHIW, DatatoLOW,
    input wire Cp0ReadW,
    output wire StallW, FlushW
    //------------------------
);


wire LwStallD, BranchStallD, JumpStallD, DivStall, Cp0StallD;
wire MemtoRegD, MemtoRegE, MemtoRegM, MemtoRegW;

//decode stage forwarding
always @(*) begin
    ForwardRsED = 2'b00;
    ForwardRsMD = 2'b00;

    ForwardRtED = 2'b00;
    ForwardRtMD = 2'b00;

    if(RsD != 0) begin
        if(RsD == WriteRegE & RegWriteE) begin
            case(DatatoRegE)
                2'b00: ForwardRsED = 2'b01;     //Rs from alu
                2'b10: ForwardRsED = 2'b10;     //Rs from hi
                2'b01: ForwardRsED = 2'b11;     //Rs from lo
                default: ForwardRsED = 2'b00;
            endcase
        end
        if(RsD == WriteRegM & RegWriteM) begin
            case(DatatoRegM)
                2'b00: ForwardRsMD = 2'b01;     //Rs from alu
                2'b10: ForwardRsMD = 2'b10;     //Rs from hi
                2'b01: ForwardRsMD = 2'b11;     //Rs from lo
                default: ForwardRsMD = 2'b00;
            endcase
        end
    end
    if(RtD != 0) begin
        if(RtD == WriteRegE & RegWriteE) begin
            case(DatatoRegE)
                2'b00: ForwardRtED = 2'b01;     //Rs from alu
                2'b10: ForwardRtED = 2'b10;     //Rs from hi
                2'b01: ForwardRtED = 2'b11;     //Rs from lo
                default: ForwardRtED = 2'b00;
            endcase
        end
        if(RtD == WriteRegM & RegWriteM) begin
            case(DatatoRegM)
                2'b00: ForwardRtMD = 2'b01;     //Rs from alu
                2'b10: ForwardRtMD = 2'b10;     //Rs from hi
                2'b01: ForwardRtMD = 2'b11;     //Rs from lo
                default: ForwardRtMD = 2'b00;
            endcase
        end
    end
end

//excute stage forwarding
always @(*) begin
    
    ForwardRsME = 2'b00;
    ForwardRsWE = 2'b00;

    ForwardRtME = 2'b00;
    ForwardRtWE = 2'b00;
    
    ForwardHIE  = 2'b00;
    ForwardLOE  = 2'b00; 
    //forward rs
    if(RsE != 0 & ~Cp0ReadM & ~Cp0ReadW) begin
        //M2E
        if(RsE == WriteRegM & RegWriteM) begin
            case(DatatoRegM)
                2'b00: ForwardRsME = 2'b01;     //Rs from alu
                2'b10: ForwardRsME = 2'b10;     //Rs from hi
                2'b01: ForwardRsME = 2'b11;     //Rs from lo
                default: ForwardRsME = 2'b00;
            endcase
        end
        //W2E
        if(RsE == WriteRegW & RegWriteW) begin
            case(DatatoRegW)
                2'b00: ForwardRsWE = 2'b01;     //Rs from alu
                2'b10: ForwardRsWE = 2'b10;     //Rs from hi
                2'b01: ForwardRsWE = 2'b11;     //Rs from lo
                2'b11: ForwardRsWE = 2'b01;     //Rs fron mem
                default: ForwardRsWE = 2'b00;
            endcase
        end
    end
    //forward rt
    if(RtE != 0 & ~Cp0ReadM & ~Cp0ReadW) begin
        if(RtE == WriteRegM & RegWriteM) begin
            case(DatatoRegM)
                2'b00: ForwardRtME = 2'b01;     //Rs from alu
                2'b10: ForwardRtME = 2'b10;     //Rs from hi
                2'b01: ForwardRtME = 2'b11;     //Rs from lo
                default: ForwardRtME = 2'b00;
            endcase
        end
        if(RtE == WriteRegW & RegWriteW) begin
            case(DatatoRegW)
                2'b00: ForwardRtWE = 2'b01;     //Rs from alu
                2'b10: ForwardRtWE = 2'b10;     //Rs from hi
                2'b01: ForwardRtWE = 2'b11;     //Rs from lo
                2'b11: ForwardRsWE = 2'b01;     //Rs from mem
                default: ForwardRtWE = 2'b00;
            endcase
        end
    end
    //forward hi
    if(DatatoRegE == 2'b10) begin
        if(HIWriteM) begin
            ForwardHIE = 2'b01;
        end
        else if(HIWriteW) begin
            ForwardHIE = 2'b10;
        end
    end
    //forward lo
    if(DatatoRegE == 2'b01) begin
        if(LOWriteM) begin
            ForwardLOE = 2'b01;
        end
        else if(LOWriteW) begin
            ForwardLOE = 2'b10;
        end
    end
end

assign MemtoRegD = DatatoRegD[1:1] & DatatoRegD[0:0];
assign MemtoRegE = DatatoRegE[1:1] & DatatoRegE[0:0];
assign MemtoRegM = DatatoRegM[1:1] & DatatoRegM[0:0];
assign MemtoRegW = DatatoRegW[1:1] & DatatoRegW[0:0];

//stalls
assign LwStallD  = ~ExceptSignal & ((MemtoRegE & (RtE == RsD | RtE == RtD)) |
                                   (MemtoRegM & (RtM == RsD | RtM == RtD)));

assign Cp0StallD = ((Cp0ReadE  & (RtE == RsD | RtE == RtD)) |
                    (Cp0ReadM  & (RtM == RsD | RtM == RtD)));

// assign BranchStallD = ~ExceptSignal & BranchD & 
//         (RegWriteE & (WriteRegE == RsD | WriteRegE == RtD) |
//          MemtoRegM & (WriteRegM == RsD | WriteRegM == RtD));

// assign JumpStallD = ~ExceptSignal & JrD & (RegWriteE & WriteRegE == RsD |
//                             MemtoRegM & WriteRegM == RsD);

assign DivStall = ~ExceptSignal & StartDivE & ~DivReadyE;

assign LongestStall = DivStall | FetchStall | MemoryStall;

// assign StallF = StallD;
// assign StallD = LwStallD | DivStall | Cp0StallD | FetchStall | MemoryStall;
// assign StallE = DivStall | FetchStall | MemoryStall;
// assign StallM = FetchStall | MemoryStall;
// assign StallW = FetchStall | MemoryStall;
//TODO:StallF = ~ExceptSignal & (LongestStall | LwStallD | Cp0StallD);
assign StallF = ~ExceptSignal & (LongestStall | LwStallD | Cp0StallD);
assign StallD = LongestStall | LwStallD | Cp0StallD;
assign StallE = LongestStall;
assign StallM = LongestStall;
assign StallW = LongestStall;

//assign LongestStall = StallF | StallD | StallE | StallM | StallW;
//TODO: FlushF = 1  FlushE = (ExceptSignal LwStallD | Cp0StallD) & ~LongestStall;
assign FlushF = 1'b1;
assign FlushD = ExceptSignal & ~LongestStall;
assign FlushE = (ExceptSignal | LwStallD | Cp0StallD) & ~LongestStall;
assign FlushM = ExceptSignal & ~LongestStall;
assign FlushW = ExceptSignal & ~LongestStall;

//EPC
always @(*) begin
    case(ExceptType)
        32'h00000001: NewPCM <= 32'hbfc00380;
        32'h00000004: NewPCM <= 32'hbfc00380;
        32'h00000005: NewPCM <= 32'hbfc00380;
        32'h00000008: NewPCM <= 32'hbfc00380;
        32'h00000009: NewPCM <= 32'hbfc00380;
        32'h0000000a: NewPCM <= 32'hbfc00380;
        32'h0000000c: NewPCM <= 32'hbfc00380;
        32'h0000000e: NewPCM <= EPCM;
        default:;
    endcase
end
endmodule

//bfc04b74
`timescale 1ns / 1ps
module hazard(
    //fetch stage
    output wire StallF, FlushF,

    //decode stage
    input wire [4:0] RsD, RtD,
    input wire BranchD,
    input wire [1:0] DatatoRegD,

    input wire JrD,

    output wire StallD, FlushD,
    output wire ForwardAD, ForwardBD, ForwardJrD,
    output reg  [1:0] ForwardHILOAED, ForwardHILOAMD,
    output reg  [1:0] ForwardHILOBED, ForwardHILOBMD,
    output reg  [1:0] ForwardHILOJED, ForwardHILOJMD,
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
    output reg [1:0] ForwardAE, ForwardBE,
    output reg [1:0] ForwardHIE, ForwardLOE,
    output reg [1:0] ForwardMultE, ForwardDivE,
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
assign ForwardAD  = (RsD != 0 & RsD == WriteRegM & RegWriteM);
assign ForwardBD  = (RtD != 0 & RtD == WriteRegM & RegWriteM);
assign ForwardJrD = (RsD != 0 & RsD == WriteRegM & RegWriteM);

//excute stage forwarding
always @(*) begin
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;

    ForwardHIE = 2'b00; 
    ForwardLOE = 2'b00;

    ForwardMultE = 2'b00; 
    ForwardDivE  = 2'b00;
    
    ForwardHILOAED = 2'b00;
    ForwardHILOAMD = 2'b00;

    ForwardHILOBED = 2'b00;
    ForwardHILOBMD = 2'b00;

    ForwardHILOJED = 2'b00;
    ForwardHILOJMD = 2'b00;


    if(RsE != 0 & ~Cp0ReadM & ~Cp0ReadW) begin
        if(RsE == WriteRegM & RegWriteM)begin
            ForwardAE = 2'b10;
        end
        else if(RsE == WriteRegW & RegWriteW)begin
            ForwardAE = 2'b01;
        end
    end
    if(RtE != 0 & ~Cp0ReadM & ~Cp0ReadW) begin
        if(RtE == WriteRegM & RegWriteM)begin
            ForwardBE = 2'b10;
        end
        else if(RtE == WriteRegW & RegWriteW)begin
            ForwardBE = 2'b01;
        end
    end
    //add datamove inst oprand
    //forwarding HI
    if(DatatoRegE == 2'b10 & HIWriteM == 1'b1)begin
        ForwardHIE = 2'b01;
    end
    else if(DatatoRegE == 2'b10 & HIWriteW == 1'b1)begin
        ForwardHIE = 2'b10;
    end
    //forwarding LO
    if(DatatoRegE == 2'b01 & LOWriteM == 1'b1)begin
        ForwardLOE = 2'b01;
    end
    else if(DatatoRegE == 2'b01 & LOWriteW == 1'b1)begin
        ForwardLOE = 2'b10;
    end
    //forwarding mult div result
    //mult
    if( (DatatoRegE == 2'b10 | DatatoRegE == 2'b01) & 
            RegWriteE == 1'b1 & DatatoHIM == 2'b01  &
            DatatoLOM == 2'b01)begin
        ForwardMultE = 2'b01;
    end
    else if((DatatoRegE == 2'b10 | DatatoRegE == 2'b01) & 
                RegWriteE == 1'b1 & DatatoHIW == 2'b01  & 
                DatatoLOW == 2'b01)begin
        ForwardMultE = 2'b10;
    end
    //div
    if( (DatatoRegE == 2'b10 | DatatoRegE == 2'b01) & 
            RegWriteE == 1'b1 & DatatoHIM == 2'b10  &
            DatatoLOM == 2'b10)begin
        ForwardDivE = 2'b01;
    end
    else if((DatatoRegE == 2'b10 | DatatoRegE == 2'b01) & 
                RegWriteE == 1'b1 & DatatoHIW == 2'b10  &
                DatatoLOW == 2'b10)begin
        ForwardDivE = 2'b10;
    end
    //forwarding hilo to branch or jump
    if(RsD != 0) begin
        //e stage
        if(RsD == WriteRegE & RegWriteE)begin
            //read hi
            if(DatatoRegE == 2'b10)begin
                ForwardHILOAED = 2'b01;
                ForwardHILOJED = 2'b01;
            end
            //read lo
            else if(DatatoRegE == 2'b01)begin
                ForwardHILOAED = 2'b10;
                ForwardHILOJED = 2'b10;
            end
        end 
        //m stage
        else if(RsD == WriteRegM & RegWriteM)begin
            //read hi
            if(DatatoRegM == 2'b10)begin
                ForwardHILOAMD = 2'b01;
                ForwardHILOJMD = 2'b01;
            end
            //read lo
            else if(DatatoRegM == 2'b01)begin
                ForwardHILOAMD = 2'b10;
                ForwardHILOJMD = 2'b10;
            end
        end
    end
    if(RtD != 0) begin
        //e stage
        if(RtD == WriteRegE & RegWriteE)begin
            //read hi
            if(DatatoRegE == 2'b10)begin
                ForwardHILOBED = 2'b01;
            end
            //read lo
            else if(DatatoRegE == 2'b01)begin
                ForwardHILOBED = 2'b10;
            end
        end 
        //m stage
        else if(RtD == WriteRegM & RegWriteM)begin
            //raed hi
            if(DatatoRegM == 2'b10)begin
                ForwardHILOBMD = 2'b01;
            end
            //raed lo
            else if(DatatoRegM == 2'b01)begin
                ForwardHILOBMD = 2'b10;
            end
        end
    end
    //------------------------
    //forwarding AL
    // if(JrD == 1'b1 & JalE | BalE == 1'b1) begin
    //     ForwardALD = 2'b01;
    // end
    // else if(JrD == 1'b1 & JalM | BalM == 1'b1) begin
    //     ForwardALD = 2'b10;
    // end
end

assign MemtoRegD = DatatoRegD[1:1] & DatatoRegD[0:0];
assign MemtoRegE = DatatoRegE[1:1] & DatatoRegE[0:0];
assign MemtoRegM = DatatoRegM[1:1] & DatatoRegM[0:0];
assign MemtoRegW = DatatoRegW[1:1] & DatatoRegW[0:0];

//stalls
assign LwStallD  = ~ExceptSignal & MemtoRegE & (RtE == RsD | RtE == RtD);
assign Cp0StallD = ((Cp0ReadE  & (RtE == RsD | RtE == RtD)) |
                    (Cp0ReadM  & (RtM == RsD | RtM == RtD)));

assign BranchStallD = ~ExceptSignal & BranchD & 
        (RegWriteE & (WriteRegE == RsD | WriteRegE == RtD) |
         MemtoRegM & (WriteRegM == RsD | WriteRegM == RtD));

assign JumpStallD = ~ExceptSignal & JrD & (RegWriteE & WriteRegE == RsD |
                            MemtoRegM & WriteRegM == RsD);

assign DivStall = ~ExceptSignal & StartDivE & ~DivReadyE;

assign StallD = LwStallD | BranchStallD | JumpStallD | DivStall | Cp0StallD;
assign StallF = StallD;
assign StallE = DivStall;
assign StallM = 1'b0;
assign StallW = 1'b0;

assign FlushF = ExceptSignal;
assign FlushD = ExceptSignal;
assign FlushE = LwStallD | BranchStallD | JumpStallD | Cp0StallD | ExceptSignal;
assign FlushM = ExceptSignal;
assign FlushW = ExceptSignal;

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
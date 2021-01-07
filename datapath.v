`timescale 1ns / 1ps


//TODO: 1.4 要做的事�????????????
//1.把cp0放在通路外面，读值在第二周期，存值在第五周期
//2.exception得到异常地址
//3.except八位后两位分别是ADEL，ADES
//4.有异常需要刷新流水线
//5.syscall后面接上div就会有问�???????????? �????????????要改�????????????下pc接口那里
//6.int_i 这里是硬件中�????????????

module datapath(
    input  wire clk, rst,
    input  wire FetchStall, MemoryStall,
    output wire LongestStall,
    //-----fetch stage-------------------------------
    //--to sram--
    output wire[31:0] PCF,
    input  wire[31:0] InstF,
    //-----------------------------------------------

    //-----decode stage------------------------------
    output wire [31:0] InstD,
    //--signals--
    input  wire       RegWriteD,
    input  wire [1:0] DatatoRegD,
    input  wire       MemWriteD,
    input  wire [7:0] ALUControlD,
    input  wire       ALUSrcAD,
    input  wire [1:0] ALUSrcBD,
    input  wire       RegDstD,
    input  wire       JumpD,
    input  wire       BranchD,
    input  wire       JalD,
    input  wire       JrD,
    input  wire       BalD,

    input  wire       HIWriteD,
    input  wire       LOWriteD,
    input  wire [1:0] DatatoHID,
    input  wire [1:0] DatatoLOD,
    input  wire       SignD,
    input  wire       StartDivD,
    input  wire       AnnulD,
    //--exc--
    input  wire       NoInstD,
    input  wire       Cp0WriteD, Cp0ReadD,
    //-----------------------------------------------

    //-----mem stage---------------------------------
    //--to sram--
    output wire        MemEn,
    output wire [3:0]  Sel,
    output wire [31:0] ALUOutM,
    output wire [31:0] WriteDataM,
    input  wire [31:0] ReadDataM,
    //-----------------------------------------------

    //-----write back stage--------------------------
    //--to sram--
    output wire [31:0] PCW,
    output wire        RegWriteW,
    output wire [4:0]  WriteRegW,
    output wire [31:0] FinalResultW,
    output wire        StallW,
    output wire        ExceptSignal
    //-----------------------------------------------
);
wire [31:0] PC;
//-----fetch stage-----------------------------------
wire [31:0] PCPlus4F;
wire StallF, FlushF;
//--exc--
wire [7:0] ExceptF;
wire Adel1F;
wire IsSlotF;
//---------------------------------------------------


//-----decode stage----------------------------------
wire [31:0] PCD;
wire [5:0] Op, Funct;
//--signal--
wire [1:0]  PCSrcD;
wire        JumpSignal;
wire        BranchSignal;
//--addr--
wire [31:0] PCPlus4D, PCBranchD, PCJumpD;
wire [31:0] PCPlus8D;
wire [27:0] ExJumpAddr;
//--imm--
wire [31:0] SignImmD, ExSignImmD, ZeroImmD, SaD;
//--data--
wire [31:0] HIIn,HIDataD;
wire [31:0] LOIn,LODataD;
wire [31:0] DataAD, DataBD;
//--regs info--
wire [4:0]  RsD, RtD, RdD;
//--hazard handle--
wire [31:0] CmpA, CmpB;
wire        EqualD;
wire [1:0]  ForwardRsED, ForwardRsMD;
wire [1:0]  ForwardRtED, ForwardRtMD;
//wire [1:0]  ForwardALD;
wire        StallD, FlushD;
//--exc--
wire [7:0] ExceptD;
wire Adel1D, IsSlotD;
wire Eret, Break, Syscall;
//-------------------------------------------------------


//-----excute stage--------------------------------------
wire [31:0] PCE;
wire [31:0] InstE;
//--signals--
wire       RegWriteE;
wire [1:0] DatatoRegE;
wire       MemWriteE;
wire [7:0] ALUControlE;
wire       ALUSrcAE;
wire [1:0] ALUSrcBE;
wire       RegDstE;
wire       JalE;
wire       JrE;
wire       BalE;

wire       HIWriteE;
wire       LOWriteE;
wire [1:0] DatatoHIE;
wire [1:0] DatatoLOE;
wire       SignE;
wire       StartDivE;
wire       AnnulE;
//--imm--
wire [31:0] SignImmE, ZeroImmE, SaE;
//--data--
wire [31:0] DataAE, DataBE;
wire [31:0] HIDataE, NewHIDataE;
wire [31:0] LODataE, NewLODataE;
//--regs info--
wire  [4:0] RsE, RtE, RdE;
wire  [4:0] WriteRegE;
wire  [4:0] WriteRegTemp;
//--alu src--
wire [31:0] TempSrcA1E, TempSrcA2E;
wire [31:0] TempSrcB1E;
wire [31:0] SrcAE, SrcBE, ALUOutE;
wire [31:0] WriteDataE;
wire [31:0] ALUOutTemp;
wire [31:0] PCPlus8E;
wire Zero;
//--mult div--
wire [31:0] MultHIE, MultLOE;
wire [31:0] DivHIE, DivLOE;
wire DivReadyE;
//--hazard handle--
wire [1:0] ForwardRsME, ForwardRsWE;
wire [1:0] ForwardRtME, ForwardRtWE;
wire [1:0] ForwardHIE , ForwardLOE;
wire FlushE, StallE;
//--exc--
wire [7:0] ExceptE;
wire Cp0ReadE, Cp0WriteE;
wire Adel1E, IsSlotE;
wire Overflow;
//----------------------------------------------------------


//-----mem stage--------------------------------------------
wire [31:0] PCM;
wire [31:0] InstM;
wire [31:0] EPCM;
wire [4:0] RdM;
//--signals--
wire       RegWriteM;
wire [1:0] DatatoRegM;
wire       MemWriteM;
wire [7:0] ALUControlM;
wire       JalM;
wire       BalM;
wire       HIWriteM;
wire       LOWriteM;
wire [1:0] DatatoHIM;
wire [1:0] DatatoLOM;
//--data--
wire [31:0] HIDataM, LODataM;
wire [31:0] NewHIDataM, NewLODataM;
//--mult div--
wire [31:0] MultHIM, MultLOM;
wire [31:0] DivHIM, DivLOM;
//--regs info--
wire [4:0]  RtM;
wire [4:0]  WriteRegM; 
//--mem--
//wire [3:0]  Sel;
wire [31:0] FinalDataM;
wire [31:0] RegDataM;
//--harzard--
wire StallM, FlushM;
//--exc--
wire [31:0] NewPCM;
wire [31:0] ExceptType;
wire [31:0] BadAddr;
wire [31:0] Cp0DataM;
wire [31:0] Cp0Status;
wire [31:0] Cp0Cause;
wire [7:0] ExceptM;
wire Cp0WriteM, Cp0ReadM;
//wire ExceptSignal;
wire IsSlotM;
wire Adel1M, Adel2M, AdelM, AdesM;
//----------------------------------------------------------


//-----writeback stage--------------------------------------
wire [31:0] InstW;
wire [4:0] RtW;
//--signals
wire [1:0] DatatoRegW;
wire       HIWriteW;
wire       LOWriteW;
wire [1:0] DatatoHIW;
wire [1:0] DatatoLOW;
//--data--
wire [31:0] ReadDataW;
wire [31:0] ResultW;
wire [31:0] HIDataW;
wire [31:0] LODataW;
wire [31:0] ALUOutW;
//--mult div--
wire [31:0] MultHIW, MultLOW;
wire [31:0] DivHIW, DivLOW;
//--harzard--
//wire StallW;
wire  FlushW;
//--exc--
wire [31:0] Cp0DataW;
wire Cp0ReadW;
//----------------------------------------------------------


//-----next pc----------------------------------------------
mux4 #(32) PCMux(PCPlus4F, PCBranchD, PCJumpD, NewPCM, PCSrcD, PC);
//----------------------------------------------------------


//-----fetch stage------------------------------------------
pc #(32) PCReg(clk, rst, ~StallF, PC, PCF);
adder PCAdder(PCF, 32'b100, PCPlus4F);
wire [39:0] asciiF;
instdec decinstf(InstF, asciiF);
//--exc--
assign Adel1F = (PCF[1:0] == 2'b00) ? 1'b0 : 1'b1;
assign IsSlotF = BranchSignal | JumpSignal;
assign ExceptF[7] = Adel1F;
//----------------------------------------------------------
//               1a    0e
//010000 00000 11010 01110 00000000 000
//-----decode stage-----------------------------------------
flopenrc #(32)D1(clk, rst, ~StallD, FlushD, InstF, InstD);
flopenrc #(32)D2(clk, rst, ~StallD, FlushD, PCPlus4F, PCPlus4D);
flopenrc #(32)D3(clk, rst, ~StallD, FlushD, PCF, PCD);

wire [39:0] asciiD;
instdec decinstd(InstD, asciiD);
//--exc--
flopenrc #(10)D4(clk, rst, ~StallD, FlushD, {ExceptF, Adel1F, IsSlotF}, {ExceptD, Adel1D, IsSlotD});

assign Op    = InstD[31:26];
assign RsD   = InstD[25:21];
assign RtD   = InstD[20:16];
assign RdD   = InstD[15:11];
assign Funct = InstD[5:0];

assign SaD = {27'b0, InstD[10:6]};

assign JumpSignal   = JumpD | JalD | JrD;
assign BranchSignal = BranchD | BalD;

assign PCSrcD[0:0] = (BranchSignal & EqualD) | ExceptSignal;
assign PCSrcD[1:1] = JumpSignal | ExceptSignal;

//--regs--
regfile Regs(clk, RegWriteW & ~ExceptSignal & ~StallW, RsD, RtD, WriteRegW, FinalResultW, DataAD, DataBD);
hiloreg HILO(clk, rst, HIWriteW, LOWriteW, HIIn, LOIn, HIDataD, LODataD);

mux2 #(32)Cp0Mux(ResultW, Cp0DataW, Cp0ReadW, FinalResultW);
//--barnch hazrad handle--
wire [31:0] TempCmpA1;
wire [31:0] TempCmpB1;
mux4 #(32) ForwardRsMDMux(DataAD, ALUOutM, NewHIDataM, NewLODataM, ForwardRsMD, TempCmpA1);
mux4 #(32) ForwardRsEDMux(TempCmpA1, ALUOutE, NewHIDataE, NewLODataE, ForwardRsED, CmpA);
mux4 #(32) ForwardRtMDMux(DataBD, ALUOutM, NewHIDataM, NewLODataM, ForwardRtMD, TempCmpB1);
mux4 #(32) ForwardRtEDMux(TempCmpB1, ALUOutE, NewHIDataE, NewLODataE, ForwardRtED, CmpB);
eqcmp Cmp(CmpA, CmpB, Op, RtD, EqualD);

//assign FlushD = PCSrcD[0:0] | PCSrcD[1:1];
//--ext imm--
signext Se(InstD[15:0], SignImmD);
zeroext Ze(InstD[15:0], ZeroImmD);
//--sl--
sl2 #(32) Sl2Imm(SignImmD, ExSignImmD);
//--branch addr--
adder BranchAdder(PCPlus4D, ExSignImmD, PCBranchD);
adder PCPlus8(PCPlus4D, 32'b100, PCPlus8D);
//--jump addr--
assign ExJumpAddr = {InstD[25:0], 2'b00};
mux2 #(32)JumpMux({PCPlus4D[31:28], ExJumpAddr}, CmpA, JrD, PCJumpD);
//--exc--
assign Syscall = (Op == 6'b000000) & (Funct == 6'b001100) & (~StallD);
assign Break   = (Op == 6'b000000) & (Funct == 6'b001101) & (~StallD);
assign Eret    = (InstD == `EXE_ERET) & (~StallD);

assign ExceptD[6] = Syscall;
assign ExceptD[5] = Break;
assign ExceptD[4] = Eret;
assign ExceptD[3] = NoInstD;
//-------------------------------------------------------------


//-----excute stage---------------------------------------------
//TODO:change the bits of signal
flopenrc   #(32)E0(clk, rst, ~StallE, FlushE, InstD, InstE);
flopenrc   #(30)E1(clk, rst, ~StallE, FlushE,
    {RegWriteD,DatatoRegD,MemWriteD,ALUControlD,ALUSrcAD,ALUSrcBD,RegDstD,JalD,JrD,BalD,
    HIWriteD,LOWriteD,DatatoHID,DatatoLOD,SignD,StartDivD,AnnulD,Cp0WriteD,Cp0ReadD},
    {RegWriteE,DatatoRegE,MemWriteE,ALUControlE,ALUSrcAE,ALUSrcBE,RegDstE,JalE,JrE,BalE,
    HIWriteE,LOWriteE,DatatoHIE,DatatoLOE,SignE,StartDivE,AnnulE,Cp0WriteE,Cp0ReadE});
flopenrc  #(32)E2(clk, rst, ~StallE, FlushE, DataAD, DataAE);
flopenrc  #(32)E3(clk, rst, ~StallE, FlushE, DataBD, DataBE);
flopenrc   #(5)E4(clk, rst, ~StallE, FlushE, RsD, RsE);
flopenrc   #(5)E5(clk, rst, ~StallE, FlushE, RtD, RtE);
flopenrc   #(5)E6(clk, rst, ~StallE, FlushE, RdD, RdE);
flopenrc  #(32)E7(clk, rst, ~StallE, FlushE, SignImmD, SignImmE);
flopenrc  #(32)E8(clk, rst, ~StallE, FlushE, ZeroImmD, ZeroImmE);
flopenrc  #(32)E9(clk, rst, ~StallE, FlushE, SaD, SaE);
flopenrc #(32)E10(clk, rst, ~StallE, FlushE, HIDataD, HIDataE);
flopenrc #(32)E11(clk, rst, ~StallE, FlushE, LODataD, LODataE);
flopenrc #(32)E12(clk, rst, ~StallE, FlushE, PCPlus8D, PCPlus8E);
flopenrc #(32)E13(clk, rst, ~StallE, FlushE, PCD, PCE);
//--debug--
wire [39:0] asciiE;
instdec decinste(InstE, asciiE);

//--exc--
flopenrc #(10)E14(clk, rst, ~StallE, FlushE, {ExceptD, Adel1D, IsSlotD}, {ExceptE, Adel1E, IsSlotE});
//--alu forwarding--
mux4 #(32) ForwardRsWEMux(DataAE, FinalResultW, HIDataW, LODataW, ForwardRsWE, TempSrcA1E);
mux4 #(32) ForwardRsMEMux(TempSrcA1E, ALUOutM, HIDataM, LODataM, ForwardRsME, TempSrcA2E);
mux4 #(32) ForwardRtWEMux(DataBE, FinalResultW, HIDataW, LODataW, ForwardRtWE, TempSrcB1E);
mux4 #(32) ForwardRtMEMux(TempSrcB1E, ALUOutM, HIDataM, LODataM, ForwardRtME, WriteDataE);
//--alu src--
mux2 #(32) AluSrcAMux(TempSrcA2E, SaE, ALUSrcAE, SrcAE);
mux3 #(32) AluSrcBMux(WriteDataE, SignImmE, ZeroImmE, ALUSrcBE, SrcBE);
//--hilo forwarding--
mux3 #(32) ForwardHIEMux(HIDataE, NewHIDataM, HIDataW, ForwardHIE, NewHIDataE);
mux3 #(32) ForwardLOEMux(LODataE, NewLODataM, LODataW, ForwardLOE, NewLODataE);
//--branch jump--
mux2 #(5) RegMux1(RtE, RdE, RegDstE, WriteRegTemp);
mux2 #(5) RegMux2(WriteRegTemp, 5'b11111, JalE | BalE, WriteRegE);
mux2 #(32) ALUMux(ALUOutTemp, PCPlus8E, JalE | JrE | BalE, ALUOutE);
//--ari--
alu Alu(ALUControlE, SrcAE, SrcBE, ALUOutTemp, Zero, Overflow);
my_mul Mult(SrcAE, SrcBE, SignE, {MultHIE, MultLOE});
wire DivStart = StartDivE & ~ DivReadyE;
div Div(clk, rst, SignE, SrcAE, SrcBE, DivStart, AnnulE, {DivHIE, DivLOE}, DivReadyE);
//--exc--
assign ExceptE[2] = Overflow;
//-----------------------------------------------------------

//000100 00000 00000 1111111111111111
//11111 11111 1111 111111111111111100
//10111 11111 0001 001100100111001000
//-----mem stage---------------------------------------------
//TODO:change the bits of signal
flopenrc  #(32)M0(clk, rst, ~StallM, FlushM, InstE, InstM);
flopenrc  #(22)M1(clk, rst, ~StallM, FlushM,
    {RegWriteE,DatatoRegE,MemWriteE,ALUControlE,JalE,BalE,
    HIWriteE,LOWriteE,DatatoHIE,DatatoLOE,Cp0WriteE,Cp0ReadE},
    {RegWriteM,DatatoRegM,MemWriteM,ALUControlM,JalM,BalM,
    HIWriteM,LOWriteM,DatatoHIM,DatatoLOM,Cp0WriteM,Cp0ReadM});
flopenrc #(32)M2(clk, rst, ~StallM, FlushM, ALUOutE, ALUOutM);
flopenrc #(32)M3(clk, rst, ~StallM, FlushM, WriteDataE, RegDataM);
flopenrc  #(5)M4(clk, rst, ~StallM, FlushM, WriteRegE, WriteRegM);
flopenrc #(32)M5(clk, rst, ~StallM, FlushM, NewHIDataE, HIDataM);
flopenrc #(32)M6(clk, rst, ~StallM, FlushM, NewLODataE, LODataM);
flopenrc #(32)M7(clk, rst, ~StallM, FlushM, MultHIE, MultHIM);
flopenrc #(32)M8(clk, rst, ~StallM, FlushM, MultLOE, MultLOM);
flopenrc #(32)M9(clk, rst, ~StallM, FlushM, DivHIE, DivHIM);
flopenrc#(32)M10(clk, rst, ~StallM, FlushM, DivLOE, DivLOM);
flopenrc#(32)M11(clk, rst, ~StallM, FlushM, PCE, PCM);
wire [39:0] asciiM;
instdec decinstm(InstM, asciiM);
//--exc--
flopenrc#(10)M12(clk, rst, ~StallM, FlushM, {ExceptE, Adel1E, IsSlotE}, {ExceptM, Adel1M, IsSlotM});
flopenrc #(5)M13(clk, rst, ~StallM, FlushM, RdE, RdM);
flopenrc #(5)M14(clk, rst, ~StallM, FlushM, RtE, RtM);
flopenrc#(32)M15(clk, rst, ~StallM, FlushM, Cp0DataM, Cp0DataW);

mux4 #(32) HIDataMux(HIDataM, MultHIM, DivHIM, ALUOutM, DatatoHIM, NewHIDataM); 
mux4 #(32) LODataMux(LODataM, MultLOM, DivLOM, ALUOutM, DatatoLOM, NewLODataM); 
//--exc--
assign AdelM = Adel1M | Adel2M;
assign ExceptM [1] = AdelM;
assign ExceptM [0] = AdesM;


assign ExceptSignal = (ExceptType != 32'b0) ? 1 : 0;
assign BadAddr = (Adel2M | AdesM) ? ALUOutM : PCM;

assign MemEn = (DatatoRegM[0] & DatatoRegM[1] | MemWriteM) & ~ExceptSignal;
ByteSel BS(ALUOutM, RegDataM, ALUControlM, Sel, WriteDataM, Adel2M, AdesM);
GetReadData GRD(ALUOutM, ReadDataM, ALUControlM, FinalDataM);

wire [31:0] real_write_data;
wire [31:0] real_except_pc;
wire [31:0] real_cp0cause;
//wire        real_delayslot;
//assign real_write_data = (Cp0WriteE & RdE == 5'b01101) ? WriteDataE : WriteDataM; 
assign real_except_pc  = (Cp0WriteM & RdM == 5'b01101) ? PCE: PCM;
//assign real_delayslot  = (Cp0WriteE & RdE == 5'b01101) ? IsSlotE : IsSlotM;
assign real_cp0cause   = (Cp0WriteM & RdM == 5'b01101) ? WriteDataM : Cp0Cause;
//--exc--
cp0_reg cp0(
    .clk(clk), 
    .rst(rst),
    .en(~(FetchStall | MemoryStall)),
    //TODO: signals
    .we_i(Cp0WriteM), 
    .waddr_i(RdM),
    .raddr_i(RdM),
    .data_i(WriteDataM),

    .int_i(6'b0),
    .excepttype_i(ExceptType),
    .current_inst_addr_i(real_except_pc),
    .is_in_delayslot_i(IsSlotM),
    .bad_addr_i(BadAddr),

    .data_o(Cp0DataM),
    .count_o(),
    .compare_o(),
    .status_o(Cp0Status),
    .cause_o(Cp0Cause),
    .epc_o(EPCM),
    .config_o(),
    .prid_o(),

    .badvaddr(),

    .timer_int_o()
);

exception exc(
    .rst(rst),
    .except(ExceptM), 
    .adel(AdelM),
    .ades(AdesM),
    .cp0_states(Cp0Status),
    .cp0_cause(real_cp0cause),
    .excepttype(ExceptType)
);
//------------------------------------------------------------


//-----writeback stage----------------------------------------
//TODO:change the bits of signal
flopenrc  #(32)w0(clk, rst, ~StallW, FlushW, InstM, InstW);
flopenrc  #(10)W1(clk, rst, ~StallW, FlushW,
    {RegWriteM,DatatoRegM,HIWriteM,LOWriteM,DatatoHIM,DatatoLOM,Cp0ReadM},
    {RegWriteW,DatatoRegW,HIWriteW,LOWriteW,DatatoHIW,DatatoLOW,Cp0ReadW});
flopenrc #(32)W2(clk, rst, ~StallW, FlushW, FinalDataM, ReadDataW);
flopenrc #(32)W3(clk, rst, ~StallW, FlushW, ALUOutM, ALUOutW);
flopenrc  #(5)W4(clk, rst, ~StallW, FlushW, WriteRegM, WriteRegW);
flopenrc #(32)W5(clk, rst, ~StallW, FlushW, NewHIDataM, HIDataW);
flopenrc #(32)W6(clk, rst, ~StallW, FlushW, NewLODataM, LODataW);
flopenrc #(32)W7(clk, rst, ~StallW, FlushW, MultHIM, MultHIW);
flopenrc #(32)W8(clk, rst, ~StallW, FlushW, MultLOM, MultLOW);
flopenrc #(32)W9(clk, rst, ~StallW, FlushW, DivHIM, DivHIW);
flopenrc #(32)W10(clk, rst, ~StallW, FlushW, DivLOM, DivLOW);
flopenrc #(32)W11(clk, rst, ~StallW, FlushW, PCM, PCW);
flopenrc #(32)W12(clk, rst, ~StallW, FlushW, RtM, RtW);
mux4 #(32) DatatoRegMux (ALUOutW, LODataW, HIDataW, ReadDataW, DatatoRegW, ResultW);
assign HIIn = HIDataW;
assign LOIn = LODataW;
wire [39:0] asciiW;
instdec instd(InstW, asciiW);
//------------------------------------------------------------


//hazard
hazard h(
    FetchStall, MemoryStall,
    LongestStall,
    //fetch stage
    StallF, FlushF,
    //decode stage
    RsD, RtD,
    BranchD,
    DatatoRegD,
    JrD,

    StallD, FlushD,
    ForwardRsED, ForwardRsMD,
    ForwardRtED, ForwardRtMD,
    //ForwardALD,
    //excute stage
    RsE, RtE,
    WriteRegE,
    DatatoRegE,
    RegWriteE,

    JalE, BalE,

    StartDivE,
    DivReadyE,

    Cp0ReadE,

    FlushE, StallE,
    ForwardRsME, ForwardRsWE,
    ForwardRtME, ForwardRtWE,
    ForwardHIE , ForwardLOE,
    //mem stage
    RtM,
    WriteRegM,
    DatatoRegM,
    RegWriteM,
    HIWriteM, LOWriteM,
    DatatoHIM, DatatoLOM,
    JalM, BalM,
    Cp0ReadM,
    StallM,
    FlushM,

    ExceptSignal,
    ExceptType,
    EPCM,
    NewPCM,
    //writeback stage
    RtW,
    WriteRegW,
    DatatoRegW,
    RegWriteW,
    HIWriteW, LOWriteW,
    DatatoHIW, DatatoLOW,
    Cp0ReadW,
    StallW, FlushW
);

endmodule
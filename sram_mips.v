`timescale 1ns / 1ps
module sram_mips(
    input  wire clk                    ,
    input  wire resetn                 ,
    input  wire int                    ,

    output reg        inst_sram_en           ,    //useless
    output wire [3:0]   inst_sram_wen          ,    //useless
    output wire [31:0]  inst_sram_addr         ,    //PCF
    output wire [31:0]  inst_sram_wdata        ,    //useless
    input  wire [31:0]  inst_sram_rdata        ,    //Inst
    input  wire         fetch_stall            ,
    output wire         longest_stall_f        , 

    output wire         data_sram_en           ,    //MemtoRegM | MemWriteM
    output wire [3:0]   data_sram_wen          ,    //Sel
    output wire [31:0]  data_sram_addr         ,    //ALUOutM
    output wire [31:0]  data_sram_wdata        ,    //WriteDataM
    input  wire [31:0]  data_sram_rdata        ,    //ReadDataM
    input  wire         memory_stall           ,
    output wire         longest_stall_m        ,

    output wire [31:0]  debug_wb_pc            ,    //PCW
    output wire [3:0]   debug_wb_rf_wen        ,    //RegWriteW
    output wire [4:0]   debug_wb_rf_wnum       ,    //WriteRegW
    output wire [31:0]  debug_wb_rf_wdata           //ResultW
);
wire        longest_stall;

wire        RegWriteD;
wire [1:0]  DatatoRegD;
wire        MemWriteD;
wire [7:0]  ALUControlD;
wire        ALUSrcAD;
wire [1:0]  ALUSrcBD;
wire        RegDstD;
wire        JumpD;
wire        BranchD;


wire       JalD;
wire       JrD;
wire       BalD;

wire        HIWrite;
wire        LOWrite;
wire [1:0]  DatatoHID;
wire [1:0]  DatatoLOD;
wire        SignD;
wire        StartDivD;
wire        AnnulD;

wire        NoInst;
wire        Cp0Write, Cp0Read;

wire [31:0] InstD;
wire [5:0] Op;
wire [5:0] Funct;
wire [4:0] Rt, Rs;

wire [31:0] PCF, InstF;

wire        MemEn;
wire [3:0]  Sel;
wire [31:0] ALUOutM, WriteDataM, ReadDataM;

wire        RegWriteW;
wire        StallW;
wire [4:0]  WriteRegW;
wire [31:0] PCW, FinalResultW;
wire        ExceptSignal;

wire [39:0] ascii;
instdec id(InstF, ascii);

controller c(
    .InstD(InstD),
    .Jump(JumpD), 
    .RegWrite(RegWriteD), 
    .RegDst(RegDstD), 
    .ALUSrcA(ALUSrcAD), 
    .ALUSrcB(ALUSrcBD), 
    .Branch(BranchD), 
    .MemWrite(MemWriteD), 
    .DatatoReg(DatatoRegD), 
    .HIwrite(HIWrite), 
    .LOwrite(LOWrite),
    .DataToHI(DatatoHID), 
    .DataToLO(DatatoLOD), 
    .Sign(SignD), 
    .startDiv(StartDivD), 
    .annul(AnnulD),
    .ALUContr(ALUControlD),
    .jal(JalD), 
    .jr(JrD), 
    .bal(BalD),
    .Invalid(NoInst),
    .cp0Write(Cp0Write),
    .cp0Read(Cp0Read)
);

datapath dp(
    //--to sram--
    .clk(clk), .rst(resetn),
    
    .FetchStall(fetch_stall), .MemoryStall(memory_stall),
    .LongestStall(longest_stall),

    .PCF(PCF), .InstF(InstF),
    
    .InstD(InstD),
    .RegWriteD(RegWriteD),
    .DatatoRegD(DatatoRegD),
    .MemWriteD(MemWriteD),
    .ALUControlD(ALUControlD),
    .ALUSrcAD(ALUSrcAD),
    .ALUSrcBD(ALUSrcBD),
    .RegDstD(RegDstD),
    .JumpD(JumpD),
    .BranchD(BranchD),

    .JalD(JalD),
    .JrD(JrD),
    .BalD(BalD),

    .HIWriteD(HIWrite),
    .LOWriteD(LOWrite),
    .DatatoHID(DatatoHID),
    .DatatoLOD(DatatoLOD),
    .SignD(SignD),
    .StartDivD(StartDivD),
    .AnnulD(AnnulD),

    .NoInstD(NoInst),
    .Cp0WriteD(Cp0Write),
    .Cp0ReadD(Cp0Read),
    //--to sram--
    .MemEn(MemEn),
    .Sel(Sel),
    .ALUOutM(ALUOutM),
    .WriteDataM(WriteDataM),
    .ReadDataM(ReadDataM),
    //--to sram--
    .PCW(PCW),
    .RegWriteW(RegWriteW),
    .WriteRegW(WriteRegW),
    .FinalResultW(FinalResultW),
    .StallW(StallW),
    .ExceptSignal(ExceptSignal)
);

always@(negedge clk) begin
    if(resetn)
        inst_sram_en <= 1'b0;
    else
        inst_sram_en <= 1'b1;
end

// assign inst_sram_en     = 1'b1;
assign inst_sram_wen    = 4'b0000;
assign inst_sram_addr   = PCF[31] ? {3'b0, PCF[28:0]} : PCF;

assign inst_sram_wdata  = 32'b0;
assign InstF            = inst_sram_rdata;
assign longest_stall_f  = longest_stall;

assign data_sram_en     = MemEn;
assign data_sram_wen    = Sel;
assign data_sram_addr   = ALUOutM[31] ? {3'b0, ALUOutM[28:0]} : ALUOutM;
assign data_sram_wdata  = WriteDataM;
assign ReadDataM        = data_sram_rdata;
assign longest_stall_m  = longest_stall;

assign debug_wb_pc             = PCW;
assign debug_wb_rf_wen         = {4{RegWriteW & ~StallW}}; // & ~StallW & ~ExceptSignal
assign debug_wb_rf_wnum        = WriteRegW;
assign debug_wb_rf_wdata       = FinalResultW;

endmodule
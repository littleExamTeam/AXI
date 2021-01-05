`timescale 1ns / 1ps
`include "defines.vh"

module main_dec(
    input wire [5:0] op,funct,
    input wire [4:0] rt,
    input wire [4:0] rs,
    output wire jump, regwrite, regdst,
    output wire alusrcA,//正常的话�???0
    output wire [1:0] alusrcB, //这里修改成两位是为了选择操作数，00 normal 01 Sign 10 UNsign
    output wire branch, memwrite, 
    output wire [1:0] DatatoReg,//这里是去找写到寄存器中的�??? 11 mem 10 HI 01 LO 00 ALU  there need changed to 3bits for div and mult
    output wire HIwrite,//这里是去寻找是否写HILO 直接传给HILO
    output wire LOwrite, //选择写的是HI还是LO寄存�???? 0 LO 1 HI  信号传给HILO
    output wire [1:0] DataToHI, //这里是因为乘除法器加上的信号�???00选ALU 01选乘�??? 10 选除�???
    output wire [1:0] DataToLO,  //这里是因为乘除法器加上的信号�???00选ALU 01选乘�??? 10 选除�???
    output wire Sign, //这个是乘除法的符号数
    output wire startDiv, //乘除法的�???始信�???

    output wire annul, //乘除法取消信�???
//=====新加的关于跳转的指令=====
    output wire jal,
    output wire jr,
    output wire bal,
//=====新加的关于跳转的指令===== 

//=====异常添加的指�?==========
    //output reg eret,//这个是去控制pcSrc 选择从cp0出来的pc�? TODO:这里改成通路判断
    output reg Invalid,  //1: 证明指令不在我们规划�? 0：代表指令存�?
    output reg cp0Write, //这里是去判断是否这个周期要去更改cp0的�??
    output reg cp0Read  //这里是去判断下一个周期是否要去读cp0寄存器的�? TODO:这里记得在寄存器堆前面加个二选一 
                        //这个值就是去控制�?个寄存器二�?�一 
//=====异常添加的指�?==========

);

reg [21:0] signals; //添加eret变成22???
//TODO: 记得明天通路中需要修改这个位�??? 12.30 晚上 12 > 13

//assign {jump, regwrite, regdst, alusrcB[1:0], branch, memwrite, DatatoReg} = signals;
assign {regwrite, DatatoReg[1:0], memwrite, alusrcA ,{alusrcB[1:1]}, {alusrcB[0:0]}, regdst, jump, branch,
        HIwrite,LOwrite,DataToHI[1:0],DataToLO[1:0],Sign,startDiv,annul,jal,jr,bal} = signals;

//100  00
// `define EXE_NOP			6'b000000
// `define EXE_AND 		6'b100100
// `define EXE_OR 			6'b100101
// `define EXE_XOR 		6'b100110
// `define EXE_NOR			6'b100111
// `define EXE_ANDI		6'b001100
// `define EXE_ORI			6'b001101
// `define EXE_XORI		6'b001110
// `define EXE_LUI			6'b001111



always @(*) begin
    Invalid <= 1'b0;
    //eret <= 1'b0;
    cp0Write <= 1'b0;
    cp0Read <= 1'b0;
    case(op)
    //     `EXE_NOP: begin    //R-type
    //     signals <= 8'b011 000;
    //     aluop_reg <= 2'b10;
    // end
        6'b000000: begin    //lw
        case(funct)
//=====move Position===
            `EXE_SLL:signals <= 22'b1_00_0_1_00_1_0_0_0_0_00_00_000_000;
            `EXE_SRA:signals <= 22'b1_00_0_1_00_1_0_0_0_0_00_00_000_000;
            `EXE_SRL:signals <= 22'b1_00_0_1_00_1_0_0_0_0_00_00_000_000;
            `EXE_SLLV:signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_SRAV:signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_SRLV:signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
//=====move Position===

//=====HILO============
            `EXE_MFHI:signals <= 22'b1_10_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_MFLO:signals <= 22'b1_01_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_MTHI:signals <= 22'b0_00_0_0_00_1_0_0_1_0_00_00_000_000;
            `EXE_MTLO:signals <= 22'b0_00_0_0_00_1_0_0_0_1_00_00_000_000;
//=====HILO============
//{regwrite, DatatoReg[1:0], memwrite, alusrcA ,{alusrcB[1:1]}, {alusrcB[0:0]}, regdst, jump, branch,HIwrite,LOwrite,DataToHI,DataToLO} = signals;
//=====ARI=============
            `EXE_ADD: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_ADDU: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_SUB: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_SUBU: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_SLT: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_SLTU: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;

            `EXE_DIV:signals <= 22'b0_00_0_0_00_1_0_0_1_1_10_10_110_000;
            `EXE_DIVU:signals <= 22'b0_00_0_0_00_1_0_0_1_1_10_10_010_000;
            `EXE_MULT:signals <= 22'b0_00_0_0_00_1_0_0_1_1_01_01_100_000;
            `EXE_MULTU:signals <= 22'b0_00_0_0_00_1_0_0_1_1_01_01_000_000;
//=====================

//=====Logic===========
            `EXE_NOR:signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_AND:signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_OR:signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            `EXE_XOR:signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;

//=====Logic===========
//======jump===========
            `EXE_JR: signals <= 22'b0_00_0_0_00_0_1_0_0_0_00_00_0_0_0_0_1_0;
            `EXE_JALR: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_0_0_0_0_1_0;
//======jump===========
//======SYS&&BREAK======
            `EXE_SYSCALL: signals <= 22'b0;
            `EXE_BREAK: signals <= 22'b0;
//======SYS&&BREAK======
            //default: signals <= 22'b1_00_0_0_00_1_0_0_0_0_00_00_000_000;
            default: Invalid <= 1'b1;
            
        endcase
    
    end
//======Logic===========
        `EXE_ANDI:signals <= 22'b1_00_0_0_10_0_0_0_0_0_00_00_000_000;
        `EXE_XORI:signals <= 22'b1_00_0_0_10_0_0_0_0_0_00_00_000_000;
        `EXE_ORI:signals <= 22'b1_00_0_0_10_0_0_0_0_0_00_00_000_000;
        `EXE_LUI:signals <= 22'b1_00_0_0_10_0_0_0_0_0_00_00_000_000;
//======Logic===========

//======ARI=============

        `EXE_ADDI: signals <= 22'b1_00_0_0_01_0_0_0_0_0_00_00_000_000;
        `EXE_ADDIU: signals <= 22'b1_00_0_0_01_0_0_0_0_0_00_00_000_000;
        `EXE_SLTI: signals <= 22'b1_00_0_0_01_0_0_0_0_0_00_00_000_000;
        `EXE_SLTIU: signals <= 22'b1_00_0_0_01_0_0_0_0_0_00_00_000_000;
        
// assign {regwrite, DatatoReg[1:0], memwrite, alusrcA ,{alusrcB[1:1]}, {alusrcB[0:0]}, regdst, jump, branch,
//         HIwrite,LOwrite,DataToHI[1:0],DataToLO[1:0],Sign,startDiv,annul,jal,jr,bal} = signals;
//======ARI=============

//======Branch==========
        `EXE_BEQ: signals <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;
        `EXE_BNE: signals <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;

        // `EXE_BGEZ: signals <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;
        // `EXE_BLTZ: signals <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;
        // `EXE_BGEZAL: signals <= 22'b1_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_1;
        // `EXE_BLTZAL: signals <= 22'b1_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_1;
        6'b000001:begin
            case(rt)
                `EXE_BGEZ:signals   <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;
                `EXE_BLTZ:signals   <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;
                `EXE_BGEZAL:signals <= 22'b1_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_1;
                `EXE_BLTZAL:signals <= 22'b1_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_1;
                default: Invalid <= 1'b1;
            endcase
        end


        `EXE_BGTZ: signals <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;
        `EXE_BLEZ: signals <= 22'b0_00_0_0_00_0_0_1_0_0_00_00_0_0_0_0_0_0;
        `EXE_J: signals <= 22'b0_00_0_0_00_0_1_0_0_0_00_00_0_0_0_0_0_0;
        `EXE_JAL: signals <= 22'b1_00_0_0_00_0_1_0_0_0_00_00_0_0_0_1_0_0;
        
//======Branch==========
// assign {regwrite, DatatoReg[1:0], memwrite, alusrcA ,{alusrcB[1:1]}, {alusrcB[0:0]}, regdst, jump, branch,
//         HIwrite,LOwrite,DataToHI[1:0],DataToLO[1:0],Sign,startDiv,annul,jal,jr,bal} = signals;
//======load&&save======
        `EXE_LB: signals <= 22'b1_11_0_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;
        `EXE_LBU: signals <= 22'b1_11_0_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;
        `EXE_LH:signals <= 22'b1_11_0_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;
        `EXE_LHU:signals <= 22'b1_11_0_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;
        `EXE_LW:signals <= 22'b1_11_0_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;

        `EXE_SB:signals <= 22'b0_00_1_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;
        `EXE_SH:signals <= 22'b0_00_1_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;
        `EXE_SW:signals <= 22'b0_00_1_0_01_0_0_0_0_0_00_00_0_0_0_0_0_0;
//======load&&save======


//{regwrite, DatatoReg[1:0], memwrite, alusrcA ,{alusrcB[1:1]}, {alusrcB[0:0]}, regdst, jump, branch,
        //HIwrite,LOwrite,DataToHI[1:0],DataToLO[1:0],Sign,startDiv,annul,jal,jr,bal}
//======SPECIAL=========
        6'b010000:begin
            if(funct == 6'b011000)begin
                //eret <= 1'b1;
                signals <= {1'b1,21'b0};
            end else begin
                case(rs)
                    5'b00000:begin
                        signals <= 22'b1_00_0_0_00_0_0_0_0_0_00_00_0_0_0_0_0_0;
                        cp0Read <= 1'b1;
                    end//MFC0
                    5'b00100: begin
                        signals <= 22'b0_00_0_0_00_0_0_0_0_0_00_00_0_0_0_0_0_0;
                        cp0Write <= 1'b1;
                    end//MTC0
                    default :Invalid <= 1'b1;
                endcase
            end
        end

//======SPECIAL=========
        //default:signals <= 22'b0_00_0_0_00_0_0_0_0_0_00_00_000_000;
        default: Invalid <= 1'b1;
    endcase
end

endmodule

module controller(
    input wire [5:0] Op, Funct,
    input wire [4:0] rt,rs,//TODO:记得数据通路中添加这个，还有mips，top
    output wire Jump, RegWrite, RegDst,
    output wire ALUSrcA, 
    output wire [1:0] ALUSrcB, 

    output wire Branch, MemWrite, 
    output wire [1:0]DatatoReg,
    output wire HIwrite,LOwrite,
    output wire [1:0] DataToHI, //这里是因为乘除法器加上的信号�???00选ALU 01选乘�??? 10 选除�???
    output wire [1:0] DataToLO,  //这里是因为乘除法器加上的信号�???00选ALU 01选乘�??? 10 选除�???
    output wire Sign, //这个是乘除法的符号数
    output wire startDiv, //乘除法的�???始信�???

    output wire annul, //乘除法取消信�???
    output wire [7:0] ALUContr,
//=====新加的关于跳转的指令=====
    output wire jal,
    output wire jr,
    output wire bal,
//=====新加的关于跳转的指令=====  

//=====异常添加的指�?==========
    //output reg eret,//这个是去控制pcSrc 选择从cp0出来的pc�? 
    output wire Invalid, //1: 证明指令不在我们规划�? 0：代表指令存�?
    output wire cp0Write,
    output wire cp0Read
//=====异常添加的指�?==========


);


main_dec main_dec(
    .op(Op),
    .funct(Funct),
    .rt(rt),
    
    .jump(Jump),
    .regwrite(RegWrite),
    .regdst(RegDst),
    .alusrcA(ALUSrcA),
    .alusrcB(ALUSrcB),
    .branch(Branch),
    .memwrite(MemWrite),

    .DatatoReg(DatatoReg),
    .HIwrite(HIwrite),
    .LOwrite(LOwrite),
    .DataToHI(DataToHI),
    .DataToLO(DataToLO),
    .Sign(Sign),
    .startDiv(startDiv),
    .annul(annul),

//=====新加的关于跳转的指令=====
    .jal(jal),
    .jr(jr),
    .bal(bal),
//=====新加的关于跳转的指令===== 

    .Invalid(Invalid),
    //.eret(eret),
    .cp0Write(cp0Write),
    .rs(rs),
    .cp0Read(cp0Read)
);

aludec aludec(
    .Funct(Funct),
    .Op(Op),
    .ALUControl(ALUContr)
);

endmodule

`timescale 1ns / 1ps
`include "defines.vh"
module eqcmp(
	input wire [31:0] a,b,
	input wire [5:0] op,
	input wire [4:0] rt,
	output wire y //1'b1 转移
    );

	reg isTran;
	
	assign y = isTran;

	always @(*)
	begin
		case(op)
			`EXE_BEQ: begin 
				if(($signed(a)) == ($signed(b)))begin
					isTran <= 1'b1;
				end else begin
					isTran <= 1'b0;
				end
			end

			`EXE_BNE:begin
				if(($signed(a)) == ($signed(b)))begin
					isTran <= 1'b0;
				end else begin
					isTran <= 1'b1;
				end
			end

			// `EXE_BGEZ:begin
			// 	if(a > 0 || a == 0)begin
			// 		isTran <= 1'b1;
			// 	end else begin
			// 		isTran <= 1'b0;
			// 	end
			// end

			`EXE_BGTZ:begin
				if(($signed(a)) > 0)begin
					isTran <= 1'b1;
				end else begin
					isTran <= 1'b0;
				end
			end

			`EXE_BLEZ:begin
				if(($signed(a)) < 0 || ($signed(a)) == 0)begin
					isTran <= 1'b1;
				end else begin
					isTran <= 1'b0;
				end
			end

			// `EXE_BLTZ:begin
			// 	if(a < 0)begin
			// 		isTran <= 1'b1;
			// 	end else begin
			// 		isTran <= 1'b0;
			// 	end
			// end

			6'b000001:begin
				if(rt == `EXE_BGEZAL)begin

					if(($signed(a)) > 0 || ($signed(a)) == 0)begin
						isTran <= 1'b1;
					end else begin
						isTran <= 1'b0;
					end

				end else if(rt == `EXE_BLTZAL) begin

					if(($signed(a)) < 0)begin
						isTran <= 1'b1;
					end else begin
						isTran <= 1'b0;
					end
					
				end else if(rt == `EXE_BGEZ) begin

					if(($signed(a)) > 0 || ($signed(a)) == 0)begin
						isTran <= 1'b1;
					end else begin
						isTran <= 1'b0;
					end

				end else if(rt == `EXE_BLTZ) begin

					if(($signed(a)) < 0)begin
						isTran <= 1'b1;
					end else begin
						isTran <= 1'b0;
					end

				end
			end

		endcase
	end


endmodule
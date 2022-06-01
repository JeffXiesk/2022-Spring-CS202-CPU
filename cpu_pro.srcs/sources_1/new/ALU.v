`timescale 1ns / 1ps

module ALU(input[31:0] Read_data_1,      //the source of A input
                 input[31:0] Read_data_2,      //one of the sources of Binput
                 input[31:0] Imme_extend,      //one of the sources of Binput
                 input[5:0] Function_opcode,   //instructions[5:0]
                 input[5:0] opcode,            //instruction[31:26]
                 input[4:0] Shamt,             // instruction[10:6], the amount of shift bits
                 input[31:0] PC_plus_4,        // pc+4, from ifetch's branch_base_addr
                 input[1:0] ALUOp,             //{ (R_format || I_format), (Branch || nBranch) }
                 input ALUSrc,                 // 1 means the 2nd operand is an immedite (except beq，bne)
                 input I_format,               // 1 means I-Type instruction except beq, bne, LW, SW
                 input Sftmd,                  // 1 means this is a shift instruction
                 input Jr,                     // 1 means this is a jr instruction
                 output Zero,                  // 1 means the ALU_reslut is zero, 0 otherwise, In ALU, Zero is determined by ALU_output_mux, not ALU_Result
                 output reg [31:0] ALU_Result, // the ALU calculation result
                 output[31:0] Addr_Result);    // the calculated instruction address
    wire[31:0] Ainput,Binput; // two operands for calculation
    wire[5:0] Exe_code; // use to generate ALU_ctrl. (I_format == 0) ? Function_opcode : { 3'b000 , Opcode[2:0] };
    wire[2:0] ALU_ctl; // the control signals which affact operation in ALU directely
    wire[2:0] Sftm; // identify the types of shift instruction, equals to Function_opcode[2:0]
    reg[31:0] ALU_output_mux; // the result of arithmetic or logic calculation
    reg[31:0] Shift_Result; // the result of shift operation
    wire[32:0] Branch_Addr; // the calculated address of the instruction, Addr_Result is Branch_Addr[31:0]

    assign Ainput      = Read_data_1;
    assign Binput      = (ALUSrc == 0) ? Read_data_2 : Imme_extend[31:0];
    assign Exe_code    = (I_format == 0) ? Function_opcode : { 3'b000 , opcode[2:0] };
    assign Sftm        = Function_opcode[2:0]; //the code of shift operations
    assign Addr_Result = Branch_Addr[31:0];
    assign ALU_ctl[0]  = (Exe_code[0] | Exe_code[3]) & ALUOp[1];
    assign ALU_ctl[1]  = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2]  = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
    assign Branch_Addr = PC_plus_4 / 4 + Imme_extend;
    assign Zero        = (ALU_output_mux == 0) ? 1'b1 : 1'b0;

    always @(ALU_ctl or Ainput or Binput) begin
        case (ALU_ctl)
            3'b000: ALU_output_mux = Ainput & Binput; // and, andi
            3'b001: ALU_output_mux = Ainput | Binput; // or, ori
            3'b010: ALU_output_mux = Ainput + Binput; // add, addi, lw, sw
            3'b011: ALU_output_mux = Ainput + Binput; // addu, addiu
            3'b100: ALU_output_mux = Ainput ^ Binput; // xor, xori
            3'b101: ALU_output_mux = ~(Ainput | Binput); // nor, lui
            3'b110: ALU_output_mux = $signed(Ainput)- $signed(Binput); // sub, slt, beq, bne
            3'b111: ALU_output_mux = Ainput - Binput; // subu, sltiu, slt, sltu
            default:
            ALU_output_mux = 32'h00000000;
        endcase
    end

    always @* begin // six types of shift instructions
        if (Sftmd)
            case(Sftm[2:0])
                3'b000:Shift_Result  = Binput << Shamt; //Sll rd,rt,shamt 00000
                3'b010:Shift_Result  = Binput >> Shamt; //Srl rd,rt,shamt 00010
                3'b100:Shift_Result  = Binput << Ainput; //Sllv rd,rt,rs 000100
                3'b110:Shift_Result  = Binput >> Ainput; //Srlv rd,rt,rs 000110
                3'b011:Shift_Result  = $signed(Binput) >>> Shamt; //Sra rd,rt,shamt 00011
                3'b111:Shift_Result  = $signed(Binput) >>> Ainput; //Srav rd,rt,rs 00111
                default:Shift_Result = Binput;
            endcase
        else
            Shift_Result = Binput;
    end

    always @* begin
        if (((ALU_ctl == 3'b111) && (Exe_code[3] == 1)) || ((ALU_ctl[2:1] == 2'b11) && (I_format == 1))) begin//set type operation (slt, slti, sltu, sltiu)
            ALU_Result = ($signed(Ainput)- $signed(Binput) < 0) ? 1 : 0;
            end
        else if ((ALU_ctl == 3'b101) && (I_format == 1)) begin //lui operation
            ALU_Result[31:0] = {Binput[15:0],{16{1'b0}}};
        end
        else if (Sftmd == 1) begin //shift operation
            ALU_Result = Shift_Result;
        end
        else begin //other types of operation in ALU (arithmatic or logic calculation)
            ALU_Result = ALU_output_mux[31:0];
        end
    end
endmodule

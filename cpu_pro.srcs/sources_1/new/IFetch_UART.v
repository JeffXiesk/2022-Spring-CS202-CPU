`timescale 1ns / 1ps

module IFetch_UART(Instruction_i,
               branch_base_addr,
               link_addr,
               clock,
               reset,
               Addr_result,
               Read_data_1,
               Branch,
               nBranch,
               Jmp,
               Jal,
               Jr,
               Zero,
               Instruction_o,
               rom_adr_o);
    input[31:0] Instruction_i; // the instruction fetched from this module
    input clock,reset; // Clock and reset
    // from ALU
    input[31:0] Addr_result; // the calculated address from ALU
    input Zero; // while Zero is 1, it means the ALUresult is zero
    // from Decoder
    input[31:0] Read_data_1; // the address of instruction used by jr instruction
    // from controller
    input Branch; // while Branch is 1,it means current instruction is beq
    input nBranch; // while nBranch is 1,it means current instruction is bnq
    input Jmp; // while Jmp 1,it means current instruction is jump
    input Jal; // while Jal is 1,it means current instruction is jal
    input Jr; // while Jr is 1,it means current instruction is jr

    output[31:0] Instruction_o;
    output[31:0] branch_base_addr; // (pc+4) to ALU which is used by branch type instruction
    output reg [31:0] link_addr; // (pc+4) to decoder which is used by jal instruction
    output[13:0] rom_adr_o;      // bind with the new output port 'pco' in IFetc32
    
    reg [31:0] PC;
    reg [31:0] Next_PC;

    assign branch_base_addr = PC + 4;
    assign rom_adr_o = PC[15:2];
    assign Instruction_o = Instruction_i;
    
    always @* begin
        if (((Branch == 1) && (Zero == 1)) || ((nBranch == 1) && (Zero == 0))) // beq, bne
            Next_PC = Addr_result * 4; // the calculated new value for PC
        else if (Jr == 1)
            Next_PC = Read_data_1 * 4; // the value of $31 register
        else if ((Jmp == 1) || (Jal == 1))
            Next_PC = {4'b0000, Instruction_i[25:0], 2'b00};
        else Next_PC = PC + 4; // PC+4
    end

    always @(negedge clock, posedge reset) begin
        if (reset == 1)
            PC <= 32'h0000_0000;
        else begin
            if((Jmp == 1) || (Jal == 1)) begin
                PC <= Next_PC;
                link_addr = (PC + 4) / 4;
            end
            else PC <= Next_PC;
        end
    end
endmodule

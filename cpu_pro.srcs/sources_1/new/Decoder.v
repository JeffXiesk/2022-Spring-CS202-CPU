`timescale 1ns / 1ps

module Decoder(input [31:0] Instruction,
                 input [31:0] read_data,
                 input [31:0] ALU_result,
                 input Jal,
                 input RegWrite,
                 input MemtoReg,
                 input RegDst,
                 input clock,
                 input reset,
                 input[31:0] opcplus4,      // from ifetch link_address
                 output[31:0] read_data_1,
                 output[31:0] read_data_2,
                 output[31:0] imme_extend);

reg[31:0] register[0:31];
wire[4:0] rs;
wire[4:0] rt;
wire[4:0] rd;
wire[5:0] opcode;
reg[4:0] RegWrite_address;
reg[31:0] write_data;

assign opcode = Instruction[31:26];

assign rs          = Instruction[25:21];       // register 0~31
assign rt          = Instruction[20:16];       // register 0~31
assign rd          = Instruction[15:11];       // register to be written 0~31
assign read_data_1 = register[rs];    // set the output read_data_1
assign read_data_2 = register[rt];    // set the output read_data_2

assign imme_extend = {{16{Instruction[15]}},Instruction[15:0]};     // I-format imme

// register destination
always @(*)
begin
    if (~Jal)
    begin
        if (RegDst)
            RegWrite_address = rd;
        else
            RegWrite_address = rt;
    end
    else
        RegWrite_address = 5'b11111;
end

// write_data sourse
always @(*)
begin
    if (Jal)
        write_data = opcplus4;
    else
    begin
        if (MemtoReg)
            write_data = read_data;
        else
            write_data = ALU_result;
    end
end

integer i = 0;
always @(posedge clock, posedge reset) begin       // do write operation on posedge of the clock
    if (reset) begin     // reset is 1, set all register to 0
        for(i = 0; i < 32; i = i+1)
            register[i] <= 0;
    end
    else if (RegWrite && RegWrite_address != 0) begin     // write register, notice that $0 can't be write
        register[RegWrite_address] <= write_data;
    end
end
endmodule

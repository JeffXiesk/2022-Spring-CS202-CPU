`timescale 1ns/1ps

module decode32(read_data_1,read_data_2,Instruction,mem_data,ALU_result,
                 Jal,RegWrite,MemorIOtoReg,RegDst,Sign_extend,clock,reset,opcplus4);
    output[31:0] read_data_1;               // 输出的第一操作数
    output[31:0] read_data_2;               // 输出的第二操作数
    input[31:0]  Instruction;               // 取指单元来的指令
    input[31:0]  mem_data;   				//  从DATA RAM or I/O port取出的数据
    input[31:0]  ALU_result;   				// 从执行单元来的运算的结果
    input        Jal;                       //  来自控制单元，说明是JAL指令 
    input        RegWrite;                  // 来自控制单元
    input        MemorIOtoReg;              // 来自控制单元
    input        RegDst;             
    output[31:0] Sign_extend;               // 扩展后的32位立即数
    input		 clock,reset;                // 时钟和复位
    input[31:0]  opcplus4;                 // 来自取指单元，JAL中用

reg[31:0] register [0:31];

wire [5:0] Opcode;
wire [4:0] rs;
wire [4:0] rt;
wire [4:0] rd;
wire [4:0] shamt;
wire [5:0] funct;
assign Opcode = Instruction[31:26];
assign rs = Instruction[25:21];
assign rt = Instruction[20:16];
assign rd = Instruction[15:11];
assign shamt = Instruction[10:6];
assign funct = Instruction[5:0];

wire [15:0] immediate;
wire sign;
wire [15:0] sign_extend_num;
assign immediate = Instruction[15:0];
assign sign = immediate[15];
assign sign_extend_num = sign ? 16'b1111_1111_1111_1111 : 16'b0000_0000_0000_0000;

assign Sign_extend = (4'b0011 == Opcode[5:2] || 6'b001001 == Opcode || 6'b001011 == Opcode) ?
                    {16'b0000_0000_0000_0000,immediate}:{sign_extend_num,immediate};
// assign Sign_extend = {sign_extend_num,immediate};

assign read_data_1 = register[rs];
assign read_data_2 = register[rt];

wire [25:0] addr;
assign addr = {rs,rt,immediate};

reg [4:0] write_target;

always @* begin
    if (RegWrite == 1)
        write_target = Jal ? 5'b1_1111 : (RegDst ? rd : rt);
end

reg [31:0] write_data;

integer i;
always @(posedge clock or posedge reset) begin
    if (reset)
        for (i=0;i<32;i=i+1)
            register[i] <= 0;
    else if (RegWrite== 1)
        register[write_target] <= write_data;
end

always @* begin
    if (RegWrite == 1)
        write_data = Jal ? opcplus4 : (MemorIOtoReg ? mem_data : ALU_result);
end

endmodule
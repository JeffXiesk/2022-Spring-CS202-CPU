`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/26 21:17:31
// Design Name: 
// Module Name: CPU_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CPU_top(
    input fpga_rst, //Active High
    input fpga_clk, 
    input[23:0] switch2N4, 
    output[23:0] led2N4, // UART Programmer Pinouts
    // start Uart communicate at high level
    input start_pg,
    input rx,
    output tx
);

// UART Programmer Pinouts
wire upg_clk, upg_clk_o;
wire upg_wen_o; //Uart write out enable
wire upg_done_o; //Uart rx data have done
//data to which memory unit of program_rom/dmemory32
wire [14:0] upg_adr_o;
//data to program_rom or dmemory32
wire [31:0] upg_dat_o;

wire spg_bufg;
BUFG U1(.I(start_pg), .O(spg_bufg)); // de-twitter// Generate UART Programmer reset signal
reg upg_rst;
always @ (posedge fpga_clk) begin
    if (spg_bufg) upg_rst = 0;
    if (fpga_rst) upg_rst = 1;
end
//used for other modules which don't relatetoUART
wire rst;
assign rst = fpga_rst | !upg_rst;



wire[31:0] Instruction;
wire[31:0] PC_plus_4;
wire[31:0] opcplus4;
wire clk;
wire[31:0] ALU_Result;
wire[31:0] Addr_Result;
wire[31:0] write_data;
wire[31:0] mread_data;
wire[31:0] read_data;
wire[31:0] address;
wire[31:0] ioread_data;

wire[31:0] Read_data_1;
wire[31:0] Read_data_2;
wire[31:0] Sign_extend;

wire Jr,RegDST,ALUSrc,MemorIOtoReg,RegWrite,MemWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd;
wire[1:0] ALUOp;
wire Zero,MemRead;

wire ioRead,ioWrite;
wire SwitchCtrl,LEDCtrl;

wire[21:0] ALU_resultHigh;
assign ALU_resultHigh = ALU_Result[31:10];

wire upg_f1,upg_f2;
assign upg_f1 = upg_wen_o & upg_adr_o[14];
assign upg_f2 = upg_wen_o & (!upg_adr_o[14]);

cpuclk cpuclk_1(
    .clk_in1(fpga_clk),
    .clk_out1(clk),
    .clk_out2(upg_clk)
);

uart_bmpg_0(
        .upg_clk_i      (upg_clk),
        .upg_rst_i      (upg_rst),
        .upg_rx_i       (rx),
        .upg_clk_o      (upg_clk_o),
        .upg_wen_o      (upg_wen_o),
        .upg_adr_o      (upg_adr_o),
        .upg_dat_o      (upg_dat_o),
        .upg_done_o     (upg_done_o),
        .upg_tx_o       (tx)
);

Ifetc32 Ifetc32_1(
    .Instruction        (Instruction),
    .branch_base_addr   (PC_plus_4),
    .link_addr          (opcplus4),
    .clock              (clk),
    .reset              (fpga_rst),
    .Addr_result        (Addr_Result),
    .Zero               (Zero),
    .Read_data_1        (Read_data_1),

    .Branch             (Branch),
    .nBranch            (nBranch),
    .Jmp                (Jmp),
    .Jal                (Jal),
    .Jr                 (Jr),

    .upg_rst_i          (upg_rst),
    .upg_clk_i          (upg_clk_o),
    .upg_wen_i          (upg_wen_o),
    .upg_adr_i          (upg_adr_o[13:0]),
    .upg_dat_i          (upg_dat_o),
    .upg_done_i         (upg_done_o)
);
executs32 executs32_1(
    .Read_data_1        (Read_data_1),
    .Read_data_2        (Read_data_2),
    .Sign_extend        (Sign_extend),
    .Function_opcode    (Instruction[5:0]),
    .Exe_opcode         (Instruction[31:26]),
    .ALUOp              (ALUOp),
    .Shamt              (Instruction[10:6]),
    .Sftmd              (Sftmd),
    .ALUSrc             (ALUSrc),
    .I_format           (I_format),
    .Jr                 (Jr),
    .Zero               (Zero),
    .ALU_Result         (ALU_Result),
    .Addr_Result        (Addr_Result),
    .PC_plus_4          (PC_plus_4)
); 
control32 control32_1(
    .Opcode             (Instruction[31:26]),
    .Function_opcode    (Instruction[5:0]),
    .Jr                 (Jr),
    .RegDST             (RegDST),
    .ALUSrc             (ALUSrc),
    .MemorIOtoReg       (MemorIOtoReg),
    .RegWrite           (RegWrite),
    .MemWrite           (MemWrite),
    .Branch             (Branch),
    .nBranch            (nBranch),
    .Jmp                (Jmp),
    .Jal                (Jal),
    .I_format           (I_format),
    .Sftmd              (Sftmd),
    .ALUOp              (ALUOp),
    .MemRead            (MemRead),
    .Alu_resultHigh     (ALU_resultHigh), 
    .IORead             (ioRead), 
    .IOWrite            (ioWrite) 
);
decode32 decode32_1(
    .read_data_1        (Read_data_1),
    .read_data_2        (Read_data_2),
    .Instruction        (Instruction),
    .mem_data           (read_data),
    .ALU_result         (ALU_Result),
    .Jal                (Jal),
    .RegWrite           (RegWrite),
    .MemorIOtoReg       (MemorIOtoReg),
    .RegDst             (RegDST),
    .Sign_extend        (Sign_extend),
    .clock              (clk),
    .reset              (fpga_rst),
    .opcplus4           (opcplus4)
);

dmemory32 dmemory32_1(
    .ram_clk_i          (clk),
    .ram_wen_i          (MemWrite),
    .ram_adr_i          (address),
    .ram_dat_i          (write_data),
    .ram_dat_o          (mread_data),

    .upg_rst_i          (upg_rst),
    .upg_clk_i          (upg_clk_o),
    .upg_wen_i          (upg_f1),
    .upg_adr_i          (upg_adr_o[13:0]),
    .upg_dat_i          (upg_dat_o),
    .upg_done_i         (upg_done_o)
);

MemOrIO MemOrIO_1(
    .mRead              (MemRead),
    .mWrite             (MemWrite),
    .ioRead             (ioRead),
    .ioWrite            (ioWrite),
    .addr_in            (ALU_Result),
    .addr_out           (address),
    .m_rdata            (mread_data),
    .io_rdata           (ioread_data),
    .r_wdata            (read_data),
    .r_rdata            (Read_data_2),
    .write_data         (write_data),
    .SwitchCtrl         (SwitchCtrl),
    .LEDCtrl            (LEDCtrl)
);

switch switch_1(
    .switclk            (clk),
    .switrst            (fpga_rst),
    .switchread         (ioRead),
    .switchaddr         (address[1:0]),
    .switch_i           (switch2N4),
    .switchrdata        (ioread_data),
    .switchcs           (SwitchCtrl)
);

led led_1(
.led_clk            (clk),
.ledrst             (fpga_rst),
.ledwrite           (ioWrite),
.ledcs              (LEDCtrl),
.ledaddr            (address[1:0]),
.ledwdata           (write_data[15:0]),
.ledout             (led2N4)
);

endmodule

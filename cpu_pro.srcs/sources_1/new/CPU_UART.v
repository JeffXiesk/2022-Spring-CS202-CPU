`timescale 1ns / 1ps

module CPU_UART(input fpga_clk,
           input fpga_rst, // Active High
           input [23:0] switchN24,
           output [23:0] ledN24,
           output [7:0] DIG,
           output [7:0] Y,
           // UART Programmer Pinouts
           // start Uart communicate at high level
           input start_pg, // Active High
           input upg_rx, // receive data by UART
           output upg_tx); // send data by UART

    wire digcs;

    wire cpu_clk; // output cpu_clk signal, should not be annotated
    wire rst;
    wire [31:0]Instruction;
    wire [31:0]Instruction_i;
    wire [31:0]branch_base_addr;
    wire [31:0]Addr_result;
    wire [31:0]Read_data_1;
    wire Branch,nBranch,Jmp,Jal,Jr,Zero;
    wire [31:0]link_addr;
    wire [13:0]rom_adr_o;
    
    wire [31:0] Read_data_2;
    wire [31:0] read_data;
    wire RegWrite;
    wire RegDst;
    wire [31:0]imme_extend;
    
    wire ALUSrc;
    wire MemorIOtoReg;
    wire MemRead;
    wire MemWrite;
    wire IORead;
    wire IOWrite;
    wire I_format;
    wire Sftmd;
    wire [1:0]ALUOp;
    
    wire [4:0]Shamt;
    wire [31:0]ALU_Result;
    wire[31:0] read_data_fromMemory;
    wire[31:0] address;
    wire[31:0] write_data;
    wire [15:0]ioread_data;
    wire switchcs;
    wire [1:0]switchaddr;
    wire [23:0]switch_i;
    
    wire ledcs;
    wire [1:0]ledaddr;

    // UART Programmer Pinouts
    wire upg_clk, upg_clk_o;
    wire upg_wen_o; //Uart write out enable
    wire upg_done_o; //Uart rx data have done
    //data to which memory unit of program_rom/dmemory32
    wire [14:0] upg_adr_o;
    //data to program_rom or dmemory32
    wire [31:0] upg_dat_o;

    wire spg_bufg;
    BUFG U1(.I(start_pg), .O(spg_bufg)); // de-twitter
    // Generate UART Programmer reset signal
    reg upg_rst;
    always @ (posedge fpga_clk) begin
        if (spg_bufg) upg_rst = 0;
        if (fpga_rst) upg_rst = 1;
    end
    assign rst = fpga_rst | !upg_rst;

    // IO and Display module
    Tubs tube(
        .rst(rst),
        .clk(fpga_clk),
        //.digaddr(address[1:0]),
        .write_data({8'h00,ledN24}),//灏嗕互8浣�16杩涘埗鏄剧ず杩�32浣嶇殑鏁版嵁
        .digwrite(IOWrite),
        .digcs(digcs),
        .DIG(DIG),
        .Y(Y)
    );

    Switch switch24(
    .switclk(cpu_clk),
    .switrst(rst),
    .switchcs(switchcs),
    .switchaddr(address[1:0]),
    .switchread(IORead),
    .switchrdata(ioread_data), // data from io switch, 16-bit output to other module
    .switch_i(switchN24) // 19bit switch io data in
    );

    LED led24(
    .led_clk(cpu_clk),
    .ledrst(rst),
    .ledwrite(IOWrite),
    .ledcs(ledcs),
    .ledaddr(address[1:0]),
    .ledwdata(write_data[15:0]), // io write data to be displayed on leds
    .ledout(ledN24) // led display port
    );

    // uart module
    uart_bmpg_0 uart(
        .upg_clk_i(upg_clk),
        .upg_rst_i(upg_rst),
        .upg_rx_i(upg_rx),
        .upg_clk_o(upg_clk_o),
        .upg_wen_o(upg_wen_o),
        .upg_adr_o(upg_adr_o),
        .upg_dat_o(upg_dat_o),
        .upg_done_o(upg_done_o),
        .upg_tx_o(upg_tx)
    );

    // generate cpuclk
    cpuclk cpuclk(
    .clk_in1(fpga_clk),
    .clk_out1(cpu_clk),
    .clk_out2(upg_clk)
    );
    // assign cpu_clk = fpga_clk;
    // assign upg_clk = fpga_clk;

    // instruction fetch destination
    ProgramROM_UART programrom_o(
        .rom_clk_i(cpu_clk),
        .rom_adr_i(rom_adr_o),
        .upg_rst_i(upg_rst),
        .upg_clk_i(upg_clk_o),
        .upg_wen_i((!upg_adr_o[14] & upg_wen_o)?1'b1:1'b0),
        .upg_adr_i(upg_adr_o[13:0]),
        .upg_dat_i(upg_dat_o),
        .upg_done_i(upg_done_o),
        .Instruction_o(Instruction_i)
    );
    
    IFetch_UART ifetch(
    .Instruction_i(Instruction_i),
    .clock(cpu_clk),
    .reset(rst),
    .Addr_result(Addr_result),
    .Zero(Zero),
    .Read_data_1(Read_data_1),
    .Branch(Branch),
    .nBranch(nBranch),
    .Jmp(Jmp),
    .Jal(Jal),
    .Jr(Jr),
    .Instruction_o(Instruction),
    .branch_base_addr(branch_base_addr),
    .link_addr(link_addr),
    .rom_adr_o(rom_adr_o)
    );
    
    Decoder decoder(
    .read_data_1(Read_data_1),
    .read_data_2(Read_data_2),
    .Instruction(Instruction),
    .read_data(read_data),
    .ALU_result(ALU_Result),
    .Jal(Jal),
    .RegWrite(RegWrite),
    .MemtoReg(MemorIOtoReg),
    .RegDst(RegDst),
    .imme_extend(imme_extend),
    .clock(cpu_clk),
    .reset(rst),
    .opcplus4(link_addr)
    );
    
    ControllerIO control(
    .Opcode(Instruction[31:26]),
    .Function_opcode(Instruction[5:0]),
    .Alu_resultHigh(ALU_Result[31:10]),
    .Jr(Jr),
    .Jmp(Jmp),
    .Jal(Jal),
    .Branch(Branch),
    .nBranch(nBranch),
    .RegDST(RegDst),
    .MemorIOtoReg(MemorIOtoReg),
    .RegWrite(RegWrite),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .IORead(IORead),
    .IOWrite(IOWrite),
    .ALUSrc(ALUSrc),
    .I_format(I_format),
    .Sftmd(Sftmd),
    .ALUOp(ALUOp)
    );
    
    ALU execute(
    .Read_data_1(Read_data_1),
    .Read_data_2(Read_data_2),
    .Imme_extend(imme_extend),
    .Function_opcode(Instruction[5:0]),
    .opcode(Instruction[31:26]),
    .Shamt(Instruction[10:6]),
    .PC_plus_4(branch_base_addr),
    .ALUOp(ALUOp),
    .ALUSrc(ALUSrc),
    .I_format(I_format),
    .Sftmd(Sftmd),
    .Jr(Jr),
    .Zero(Zero),
    .ALU_Result(ALU_Result),
    .Addr_Result(Addr_result)
    );
    
    Dmem_UART memory(
    .ram_clk_i(cpu_clk),
    .ram_wen_i(MemWrite),
    .ram_adr_i(address[15:2]),
    .ram_dat_i(write_data), // 32bit
    .upg_rst_i(upg_rst),
    .upg_clk_i(upg_clk_o),
    .upg_wen_i( (upg_adr_o[14] & upg_wen_o)? 1'b1:1'b0),
    .upg_adr_i(upg_adr_o[13:0]), // notice 15bit to 14bit
    .upg_dat_i(upg_dat_o),
    .upg_done_i(upg_done_o),
    .ram_dat_o(read_data_fromMemory)
    );

    MemOrIO memorio(
    .Alu_resultLow(ALU_Result[7:0]),
    .mRead(MemRead),
    .mWrite(MemWrite),
    .ioRead(IORead),
    .ioWrite(IOWrite),
    .addr_in(ALU_Result),
    .addr_out(address),
    .m_rdata(read_data_fromMemory),
    .io_rdata(ioread_data), // input io data from switch, 16 bit to 32 bit r_wdata
    .r_wdata(read_data), // io read data output to idecode32(register file)
    .r_rdata(Read_data_2), // data read from idecode32(register file) input port
    .write_data(write_data), // data to memory or I/O (m_wdata, io_wdata) output reg
    .LEDCtrl(ledcs),
    .SwitchCtrl(switchcs),
    .DigCtrl(digcs)
    );
endmodule

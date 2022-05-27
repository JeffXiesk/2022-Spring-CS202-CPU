`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/27 16:16:40
// Design Name: 
// Module Name: MemOrIO_tb
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

module MemOrIO_tb( );
reg mRead,mWrite,ioRead,ioWrite;
reg[31:0] addr_in,m_rdata,r_rdata;
reg[15:0] io_rdata;
wire LEDCtrl,SwitchCtrl;
wire [31:0] addr_out,r_wdata,write_data;
MemOrIO umio(
    .mRead(mRead),
    .mWrite(mWrite),
    .ioRead(ioRead),
    .ioWrite(ioWrite),
    .addr_in(addr_in), 
    .addr_out(addr_out),
    .m_rdata(m_rdata),
    .io_rdata(io_rdata), 
    .r_wdata(r_wdata),
    .r_rdata(r_rdata),
    .write_data(write_data),
    .SwitchCtrl(SwitchCtrl),
    .LEDCtrl(LEDCtrl)
);
initial begin // r_rdata -> m_wdata(write_data)
m_rdata = 32'hffff_0001; 
io_rdata = 32'hffff; 
r_rdata = 32'h0f0f_0f0f; 
addr_in = 32'h4; 
{mRead,mWrite,ioRead,ioWrite}=4'b01_00;
#10 begin addr_in = 32'hffff_fc60; {mRead,mWrite,ioRead,ioWrite}= 4'b00_01; end // r_rdata -> io_wdata(write_data)
#10 begin addr_in = 32'h0000_0004; {mRead,mWrite,ioRead,ioWrite}= 4'b10_00; end // m_rdata -> r_wdata
#10 begin addr_in = 32'hffff_fc70; {mRead,mWrite,ioRead,ioWrite}= 4'b00_10; end // io_rdata -> r_wdata(write_data)
#10 $finish;
end
endmodule

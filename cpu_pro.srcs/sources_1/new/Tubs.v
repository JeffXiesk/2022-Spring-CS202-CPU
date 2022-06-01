`timescale 1ns / 1ps

module Tubs(
    input rst,              //复位
    input clk,              //Y18
    //input [1:0] digaddr, // 地址低端
    input [31:0] write_data,      //要显示的数字  
    input digwrite,	        
    input digcs,		    
    output [7:0] DIG,       
    output [7:0] Y          
    );

    reg clkout;
    reg [31:0] cnt;
    reg [2:0] scan_cnt;
    //wire [31:0] num; // num to be displayed
    parameter period = 20000; //5000Hz
    reg [7:0] DIG_r;

    reg [3:0] bcd;
    reg [7:0] seg_out;
    //reg init = 1'b0; // the first time to use dig, open dig

    reg [15:0] store;//存住上一次想要输出的东西

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            store <= 16'b0;
        end
        else if (digwrite&digcs) begin
            store <= write_data[15:0];
        end
    end

    assign Y = seg_out;
    assign DIG = ~DIG_r;


    //分频
    always @ (posedge clk or posedge rst)
    begin
        if (rst) begin
            cnt <= 0;
            clkout <=0;
        end
        else begin
            if(cnt == (period>>1)-1)
            begin
                clkout <= ~clkout;
                cnt <= 0;
            end
            else
                cnt <= cnt+1;
        end
    end

    always @ (posedge clkout or posedge rst) begin
        if(rst)
        begin
            scan_cnt <=3'b00;
        end

        else begin
            scan_cnt <= scan_cnt +1;
        end
    end

    always @ (scan_cnt) begin
        case (scan_cnt)
            3'b01 : bcd = store[3:0];
            3'b10 : bcd = store[7:4];
            3'b11 : bcd = store[11:8];
            3'b100 : bcd = store[15:12];
            default: bcd = 4'bz;
        endcase
    end

    always @ (bcd) begin
            case(bcd)
                4'b0000: seg_out = 8'b1100_0000;  //0
                4'b0001: seg_out = 8'b1111_1001;  // 1
                4'b0010: seg_out = 8'b1010_0100;  // 2
                4'b0011: seg_out = 8'b1011_0000;  // 3
                4'b0100: seg_out = 8'b1001_1001;  // 4
                4'b0101: seg_out = 8'b1001_0010;  // 5
                4'b0110: seg_out = 8'b1000_0010;  // 6
                4'b0111: seg_out = 8'b1101_1000;  // 7
                4'b1000: seg_out = 8'b1000_0000;  // 8
                4'b1001: seg_out = 8'b1001_0000;  // 9
                4'b1010: seg_out = 8'b1000_1000;  // A
                4'b1011: seg_out = 8'b1000_0011;  // b
                4'b1100: seg_out = 8'b1100_0110;  // c
                4'b1101: seg_out = 8'b1010_0001;  // d
                4'b1110: seg_out = 8'b1000_0110;  // E
                4'b1111: seg_out = 8'b1000_1110;  // F
                default :seg_out = 8'b1111_1111;  //全灭
            endcase
        //end
    end

    always @ (scan_cnt) begin
        case (scan_cnt)
            3'b01 : DIG_r = 8'b0000_0001;
            3'b10 : DIG_r = 8'b0000_0010;
            3'b11 : DIG_r = 8'b0000_0100;
            3'b100: DIG_r = 8'b0000_1000;
            default : DIG_r = 8'b0000_0000;
        endcase
    end
endmodule
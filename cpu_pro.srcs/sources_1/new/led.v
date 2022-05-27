`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/28 00:43:32
// Design Name: 
// Module Name: led
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


module led(led_clk, ledrst, ledwrite, ledcs, ledaddr,ledwdata, ledout);
    input led_clk;    		    // ʱ���ź�
    input ledrst; 		        // ��λ�ź�
    input ledwrite;		       	// д�ź�
    input ledcs;		      	// ��memorio����LEDƬѡ�ź�   !!!!!!!!!!!!!!!!!
    input[1:0] ledaddr;	        //  ��LEDģ��ĵ�ַ�Ͷ�  !!!!!!!!!!!!!!!!!!!!
    input[15:0] ledwdata;	  	//  д��LEDģ������ݣ�ע��������ֻ��16��
    output reg [23:0] ledout;		//  ������������24λLED�ź�
    always@(posedge led_clk or posedge ledrst) begin
        if(ledrst) begin
            ledout <= 24'h000000;
        end
		else if(ledcs && ledwrite) begin
			if(ledaddr == 2'b00)
				ledout[23:0] <= { ledout[23:16], ledwdata[15:0] };
			else if(ledaddr == 2'b10 )
				ledout[23:0] <= { ledwdata[7:0], ledout[15:0] };
			else
				ledout <= ledout;
        end
		else begin
            ledout <= ledout;
        end
    end
endmodule

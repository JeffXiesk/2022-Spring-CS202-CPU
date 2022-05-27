`timescale 1ns / 1ps
module executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,
                 Shamt,ALUSrc,I_format,Zero,Jr,Sftmd,ALU_Result,Addr_Result,PC_plus_4);
    input[31:0]  Read_data_1;		
    input[31:0]  Read_data_2;		
    input[31:0]  Sign_extend;		
    input[5:0]   Function_opcode;  	
    input[5:0]   Exe_opcode;  		
    input[1:0]   ALUOp;             
    input[4:0]   Shamt;             
    input  		 Sftmd;            
    input        ALUSrc;            
    input        I_format;          
    input        Jr;               
    output       Zero;              
    output[31:0] ALU_Result;       
    output[31:0] Addr_Result;		    
    input[31:0]  PC_plus_4;        
    
    reg[31:0] ALU_Result;
    wire[31:0] Ainput,Binput;
    reg[31:0] Shift_Result;
    reg[31:0] ALU_output_mux;
    wire[32:0] Branch_Addr;
    wire[2:0] ALU_ctl;
    wire[5:0] Exe_code;
    wire[2:0] Sftm;
    wire Sftmd;
    
    assign Sftm = Function_opcode[2:0];   // 实际有用的只有低三位(移位指令�?
    assign Exe_code = (I_format==0) ? Function_opcode : {3'b000,Exe_opcode[2:0]};
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0]; //R/LW,SW  sft  else的时候含LW和SW
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];      //24H AND 
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
 
 
//    always @* begin
//        if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slti(sub)  处理�?有SLT类的问题
//            ALU_Result = (Ainput < Binput) ? 31'd1 : 31'd0;
//        else if((ALU_ctl==3'b101) && (I_format==1)) ALU_Result[31:0] = Sign_extend << 16;   //lui data
//        else if(Sftmd==1) ALU_Result = Shift_Result;   //  移位
//        else  ALU_Result = ALU_output_mux[31:0];   //otherwise
//    end
 
    assign Branch_Addr = PC_plus_4 + {Sign_extend[29:0],2'b00};
    assign Addr_Result = Branch_Addr[31:0];   //算出的下�?个PC值已经做了除4处理，所以不�?左移16�?
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;
    
    always @(ALU_ctl or Ainput or Binput) begin
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput & Binput;
            3'b001:ALU_output_mux = Ainput | Binput;
            3'b010:ALU_output_mux = Ainput + Binput;
            3'b011:ALU_output_mux = $signed(Ainput) + $signed(Binput);
            3'b100:ALU_output_mux = Ainput ^ Binput;
            3'b101:ALU_output_mux = ~(Ainput | Binput);
            3'b110:ALU_output_mux = Ainput - Binput;
            3'b111:ALU_output_mux = $signed(Ainput) - $signed(Binput);
            default:ALU_output_mux = 32'h00000000;
        endcase
    end
    
    always @* begin  // 6种移位指�?
           if(Sftmd)
            case(Sftm[2:0])
                3'b000:Shift_Result = Binput << Shamt;               //Sll rd,rt,shamt  00000
                3'b010:Shift_Result = Binput >> Shamt;                //Srl rd,rt,shamt  00010
                3'b100:Shift_Result = Binput << Ainput;              //Sllv rd,rt,rs 000100
                3'b110:Shift_Result = Binput >> Ainput;              //Srlv rd,rt,rs 000110
                3'b011:Shift_Result = $signed(Binput)>>>Shamt;                 //Sra rd,rt,shamt 00011
                3'b111:Shift_Result = $signed(Binput)>>>Ainput;                //Srav rd,rt,rs 00111
                default:Shift_Result = Binput;
            endcase
           else Shift_Result = Binput;
     end
    
    always @* begin 
        //set type operation (slt, slti, sltu, sltiu) 
        if( ((ALU_ctl==3'b111) && (Exe_code[3]==1)) || ((ALU_ctl[2:1]==2'b11) && (I_format==1)) )
             ALU_Result = (ALU_output_mux[31:0])?1:0; 
        //lui operation 
        else if((ALU_ctl==3'b101) && (I_format==1)) 
            ALU_Result[31:0]={Binput[15:0],{16{1'b0}}};
        //shift operation 
        else if(Sftmd==1) 
            ALU_Result = Shift_Result ; 
        //other types of operation in ALU (arithmatic or logic calculation) 
        else 
            ALU_Result = ALU_output_mux[31:0]; 
     end
endmodule
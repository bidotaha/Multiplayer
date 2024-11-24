module top_level_8x8 ( output [15:0] product8x8_out,
                       output done_flag,
                       output seg_a,seg_b,seg_c,seg_d,seg_e,seg_f,seg_g,
                       input [7:0] dataa,datab,
                       input start,reset_a,clk);
wire [3:0] aout,bout;
wire [1:0] sel;
wire [7:0] product;
wire [15:0] shift_out;
wire [1:0] shift;
wire [15:0] sum;
wire sclr_n,clk_ena;
wire [1:0] count;
wire [2:0] state_out;

mux4 w1 (aout,dataa[3:0],dataa[7:4],sel[1]);
mux4 w2 (bout,datab[3:0],datab[7:4],sel[0]);
multi4x4 w3 (product,aout,bout);
shifter w4 (shift_out,product,shift);
adder_16 w5 (sum,shift_out,product8x8_out);
reg16 w6 (product8x8_out,sum,clk,sclr_n,clk_ena);
counter w7 (count,clk,~start);
seven_segment7_cntrl w8 (seg_a,seg_b,seg_c,seg_d,seg_e,seg_f,seg_g,state_out);
mult_control w9 (sel,shift,state_out,done_flag,clk_ena,sclr_n,clk,reset_a,start,count);

endmodule

//////////////////////////////////// test_bench ///////////////////////////////

module top_level_8x8_ts ();
wire [15:0] product8x8_out;
wire done_flag;
wire seg_a,seg_b,seg_c,seg_d,seg_e,seg_f,seg_g;
reg [7:0] dataa,datab;
reg start,reset_a,clk;
top_level_8x8 u (product8x8_out,done_flag,seg_a,seg_b,seg_c,seg_d,seg_e,seg_f,seg_g,dataa,datab,start,reset_a,clk);

initial
begin
$monitor ("A=%d  B=%d out=%d done=%b",dataa,datab,product8x8_out,done_flag); 
end
initial
begin
clk = 0;
repeat (100) #5 clk = ~clk;
end
initial
begin
reset_a = 0;
#10 reset_a = 1;
end
initial
begin
dataa = 0;
datab = 0;
#30 dataa = 8'b00011101; datab = 8'b00000111;
end
initial
begin
start = 0;
repeat (20) #15 start = ~start;
end
endmodule

/////////////////////////////////// mult_control //////////////////////////////

module mult_control ( output reg [1:0] input_sel,shift_sel,
                      output reg[2:0] state_out,
                      output reg done,clk_ena,sclr_n,
                      input clk,reset_a,start,
                      input [1:0] count);
parameter IDLE=3'b000,LSB=3'b001,MID=3'b010,MSB=3'b011,CALC_DONE=3'b100,ERR=3'b101;
reg [2:0] c_s,n_s;
always @ (posedge clk)
begin
if (reset_a) c_s <= n_s;
else c_s = IDLE;
end
always@(*)
begin
casex (c_s)
IDLE      : if (start==0) begin 
                          n_s=IDLE; 
                          input_sel=2'bxx; 
                          shift_sel=2'bxx; 
                          done=0; 
                          clk_ena=0; 
                          sclr_n=1; 
                          end
            else if (start==1) begin 
                               n_s=LSB; 
                               input_sel=2'bxx; 
                               shift_sel=2'bxx; 
                               done=0; 
                               clk_ena=1; 
                               sclr_n=0; 
                               end
LSB       : if (start==0 && count==0) begin 
                                      n_s=MID; 
                                      input_sel=2'b00; 
                                      shift_sel=2'b00; 
                                      done=0; 
                                      clk_ena=1; 
                                      sclr_n=1; 
                                      end
            else begin 
                 n_s=ERR; 
                 input_sel=2'bxx; 
                 shift_sel=2'bxx; 
                 done=0; 
                 clk_ena=0; 
                 sclr_n=1;
                 end
MID       : if (start==0 && count==2'b01) begin 
                                       n_s=MID; 
                                       input_sel=2'b01; 
                                       shift_sel=2'b01;
                                       done=0; 
                                       clk_ena=1;
                                       sclr_n=1;
                                       end
            else if (start==0 && count==2'b10) begin 
                                            n_s=MSB;
                                            input_sel=2'b10;
                                            shift_sel=2'b01; 
                                            done=0; 
                                            clk_ena=1;
                                            sclr_n=1;
                                            end
            else begin 
                 n_s=ERR; 
                 input_sel=2'bxx;
                 shift_sel=2'bxx; 
                 done=0;
                 clk_ena=0;
                 sclr_n=1;
                 end
MSB       : if (start==0 && count==2'b11) begin 
                                       n_s=CALC_DONE;
                                       input_sel=2'b11;
                                       shift_sel=2'b10; 
                                       done=0;
                                       clk_ena=1;
                                       sclr_n=1;
                                       end
            else begin 
                 n_s=ERR;
                 input_sel=2'bxx; 
                 shift_sel=2'bxx; 
                 done=0;
                 clk_ena=0;
                 sclr_n=1;
                 end
CALC_DONE : if (start==0) begin 
                          n_s=IDLE; 
                          input_sel=2'bxx;
                          shift_sel=2'bxx; 
                          done=1; 
                          clk_ena=0; 
                          sclr_n=1;
                          end
            else if (start==1) begin 
                               n_s=ERR;
                               input_sel=2'bxx; 
                               shift_sel=2'bxx;
                               done=0; 
                               clk_ena=0;
                               sclr_n=1;
                               end
ERR       : if (start==0) begin 
                          n_s=ERR; 
                          input_sel=2'bxx;
                          shift_sel=2'bxx;
                          done=0; 
                          clk_ena=0;
                          sclr_n=1;
                          end
            else if (start==1) begin 
                               n_s=LSB; 
                               input_sel=2'bxx; 
                               shift_sel=2'bxx; 
                               done=0; 
                               clk_ena=1; 
                               sclr_n=0;
                               end
default   : n_s=IDLE;
endcase
end
always@(c_s)
begin
case (c_s)  
IDLE      : state_out = 3'b000; 
LSB       : state_out = 3'b001; 
MID       : state_out = 3'b010; 
MSB       : state_out = 3'b011; 
CALC_DONE : state_out = 3'b100; 
ERR       : state_out = 3'b101;
endcase
end
endmodule     

/////////////////////////////////  adder_16  ///////////////////////////////////

module adder_16 ( output [15:0]sum,
                 input [15:0]A,B );
assign sum = A + B ;
endmodule

module adder_16_ts ();
reg [15:0] A,B;
wire [15:0] sum;
adder_16 k (sum,A,B);
initial
begin
$monitor (" %d %d %d ",A,B,sum);
#5 A=16'b1000100100111; B=16'b1101001010100;
//#5 A=16'b1110110000011; B=16'b1001101110100;
#5 A=16'b0111111111111; B=16'b0111111111111;
end 
endmodule 

////////////////////////////  multi4x4   //////////////////////////////////////////

module multi4x4 ( output [7:0]product,
                  input [3:0] dataa,datab);
assign product = dataa * datab;
endmodule 

module multi4x4_ts ();
reg [3:0] dataa,datab;
wire [7:0] product;
multi4x4 l (product,dataa,datab);
initial
begin
#5 dataa=4'b1111; datab=4'b1111;
end 
endmodule 

///////////////////////////////////// mux4 /////////////////////////////////////////////

module mux4 ( output reg [3:0]muxout,
              input [3:0] mux_in_a,mux_in_b,
              input mux_sel);
always@(*)
begin
if (mux_sel == 0) muxout = mux_in_a;
else if (mux_sel == 1) muxout = mux_in_b;
end
endmodule 

module mux4_ts();
reg [3:0] A,B;
reg Sel;
wire [3:0]out;
mux4 p(out,A,B,Sel);
initial
begin
Sel = 1'b0;
A = 4'b0;
B = 4'b0;
$monitor ("A = %d B = %d S = %b out = %d",A,B,Sel,out); 
#10 Sel = 0; A = 10; B = 11;
#10 Sel = 0; A = 12; B = 8;
#10 Sel = 1; A = 1; B = 7;
#10 Sel = 1; A = 2; B = 4;
end
endmodule 

/////////////////////////// shifter //////////////////////////////////////////////

module shifter ( output reg [15:0] shift_out,
                 input [7:0] inp,
                 input [1:0] shift_cntrl);
always@(*)
begin
case (shift_cntrl)
2'b00,2'b11 : shift_out = {8'b0,inp};
2'b01 : shift_out = {inp,4'b0};
2'b10 : shift_out = {inp,8'b0};
endcase
end
endmodule

module shifter_ts ();
reg [7:0] inp;
reg [1:0] cn;
wire [15:0] out;
shifter w (out,inp,cn);
initial
begin
inp = 8'b0;
cn = 2'b0;
$monitor ("in = %b  cn = %b  out = %b",inp,cn,out);
#10 inp = 8'b11110000; cn = 0;
#10 inp = 8'b00001111; cn = 1;
#10 inp = 8'b11001100; cn = 2;
#10 inp = 8'b10000000; cn = 3;
end
endmodule 

/////////////////////////////// seven_segment7_cntrl //////////////////////////////////

module seven_segment7_cntrl (output reg seg_a,seg_b,seg_c,seg_d,seg_e,seg_f,seg_g,
                             input [2:0] inp);
always @(*)
begin
case (inp)
3'b000 : begin seg_a=1; seg_b=1; seg_c=1; seg_d=1; seg_e=1; seg_f=1; seg_g=0; end
3'b001 : begin seg_a=0; seg_b=1; seg_c=1; seg_d=0; seg_e=0; seg_f=0; seg_g=0; end
3'b010 : begin seg_a=1; seg_b=1; seg_c=0; seg_d=1; seg_e=1; seg_f=0; seg_g=1; end
3'b011 : begin seg_a=1; seg_b=1; seg_c=1; seg_d=1; seg_e=0; seg_f=0; seg_g=1; end 
default : begin seg_a=1; seg_b=0; seg_c=0; seg_d=1; seg_e=1; seg_f=1; seg_g=1; end
endcase
end
endmodule

module seven_segment7_cntrl_ts ();
reg [2:0] inp;
wire a,b,c,d,e,f,g;
seven_segment7_cntrl j (a,b,c,d,e,f,g,inp);
initial
begin
#5 inp = 1;
#5 inp = 4;
#5 inp = 5;
#5 inp = 7;
end
endmodule

/////////////////////////////// reg16 ///////////////////////////////////////

module reg16 ( output reg [15:0] reg_out,
               input [15:0] datain,
               input clk,sclr_n,clk_ena);
always@(posedge clk)
begin
        if (clk_ena==1 && sclr_n==0) 
        begin
              reg_out <= 16'b0;  
        end 
        else if (clk_ena==1 && sclr_n==1) 
        begin
              reg_out <= datain;      
        end
end
endmodule

module reg16_tb();
reg clk;
reg sclr_n;
reg clk_ena;
reg [15:0] datain;
wire [15:0] reg_out;
reg16 r(reg_out,datain,clk,sclr_n,clk_ena);
initial
begin
clk = 0;
repeat(20) #5 clk = ~clk;  
end
initial 
begin
sclr_n = 0; 
clk_ena = 0; 
datain = 16'b0000;
$monitor ("clk=%b clk_ena=%b sclr_n=%b in=%b out=%b",clk,clk_ena,sclr_n,datain,reg_out);
#10 datain = 16'b1111111111100101; clk_ena = 1; sclr_n = 0;
#10 datain = 16'b1001101001111101; clk_ena = 1; sclr_n = 1;
#10 datain = 16'b1001101000000000; clk_ena = 1; sclr_n = 0;
#10 datain = 16'b1111111001100101; clk_ena = 1; sclr_n = 1;
#10 datain = 16'b1111111111100101; clk_ena = 1; sclr_n = 0;
#10 datain = 16'b1001101001111101; clk_ena = 1; sclr_n = 1;
end
endmodule

//////////////////////////////////// counter /////////////////////////////////////////

module counter ( output reg [1:0] count_out, 
                 input clk,       
                 input aclr_n);
always @(posedge clk , negedge aclr_n) 
begin
    if (!aclr_n)          
        count_out <= 2'b00;       
    else
        count_out <= count_out + 1;      
end
endmodule

module counter_ts();
reg clk;           
reg aclr_n;          
wire [1:0] count_out;        
counter u(count_out,clk,aclr_n);
initial
begin
clk = 0;
repeat(20) #5 clk = ~clk;  
end
initial 
begin
aclr_n = 1;       
#7 aclr_n = 0;    
#5 aclr_n = 1;    
#7 aclr_n = 0;
#5 aclr_n = 1;
end
initial
begin
$monitor("clk=%b  aclr_n=%b  count_out=%b",clk,aclr_n,count_out);
end
endmodule








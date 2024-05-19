module covariance_matrix(
    input wire clk,
    input wire rst,
    input wire [31:0] data_in0,
    input wire [31:0] data_in1,
    input wire [31:0] data_in2,
    input wire [31:0] data_in3,
    //input wire [19:0]g_states,
    output reg output_av,
    output reg signed [31:0] A0, A1, A2, A3,
    output reg signed [31:0] A4, A5, A6, A7,
    output reg signed [31:0] A8, A9, A10, A11,
    output reg signed[31:0] A12, A13, A14, A15
);
    // Internal registers and logic to compute the covariance matrix from four inputs
    reg clean=0;
    reg [7:0] samples=0; // cause mac is 40 bit so 8 bit for max range
    wire signed [39:0] B [0:9];// due to symatric property
    wire [9:0]imp_bit;
    
    always@(posedge clk)
        if (rst)
            begin
            output_av<=0;
            samples<=0;
            clean<=0;
            end
        else if (samples==8'b11111111)
            begin
            output_av<=1;
            clean<=1;
            samples<=0;
            A0<=B[0][39:8];
            A1<=B[1][39:8];
            A2<=B[2][39:8];
            A3<=B[3][39:8];
            A4<=B[1][39:8];
            A5<=B[4][39:8];
            A6<=B[5][39:8];
            A7<=B[6][39:8];
            A8<=B[2][39:8];
            A9<=B[5][39:8];
            A10<=B[7][39:8];
            A11<=B[8][39:8];
            A12<=B[3][39:8];
            A13<=B[6][39:8];
            A14<=B[8][39:8];
            A15<=B[9][39:8];
            end
        else 
            begin
            samples<=samples+1;
            clean<=0;
            end
            
            
     xbip_multadd_0 mac0(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in0),
     .B(data_in0),
     .C(B[0]),
     .P({imp_bit[0],B[0]})
     );
     
     xbip_multadd_0 mac1(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in0),
     .B(data_in1),
     .C(B[1]),
     .P({imp_bit[1],B[1]})
     );
     
     xbip_multadd_0 mac2(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in0),
     .B(data_in2),
     .C(B[2]),
     .P({imp_bit[2],B[2]})
     );
     
     xbip_multadd_0 mac3(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in0),
     .B(data_in3),
     .C(B[3]),
     .P({imp_bit[3],B[3]})
     );
     
     xbip_multadd_0 mac4(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in1),
     .B(data_in1),
     .C(B[4]),
     .P({imp_bit[4],B[4]})
     );
     
     xbip_multadd_0 mac5(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in1),
     .B(data_in2),
     .C(B[5]),
     .P({imp_bit[5],B[5]})
     );
     xbip_multadd_0 mac6(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in1),
     .B(data_in3),
     .C(B[6]),
     .P({imp_bit[6],B[6]})
     );
     
     xbip_multadd_0 mac7(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in2),
     .B(data_in2),
     .C(B[7]),
     .P({imp_bit[7],B[7]})
     );
     
     xbip_multadd_0 mac8(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in2),
     .B(data_in3),
     .C(B[8]),
     .P({imp_bit[8],B[8]})
     );
     
     xbip_multadd_0 mac9(
     .CLK(clk),
     .CE(1'b1),
     .SCLR(clean),
     .A(data_in3),
     .B(data_in3),
     .C(B[9]),
     .P({imp_bit[9],B[9]})
     );
     

     
           
    
endmodule

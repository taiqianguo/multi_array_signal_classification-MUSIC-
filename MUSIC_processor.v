`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.05.2024 23:10:12
// Design Name: 
// Module Name: MUSIC_processor
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


module MUSIC_processor(
    input wire clk,
    input wire rst,
    input wire [31:0] data_in0,
    input wire [31:0] data_in1,
    input wire [31:0] data_in2,
    input wire [31:0] data_in3,
    
    output  [63:0] product_theta
);
    reg [2:0]g_state=0;// global state 0 for idle , 1 for evd, 2 for compare, 3 for product_generator
    // Intermediate signals to connect the modules
    wire signed [31:0] A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15;
    wire signed [31:0] V0, V1, V2, V3, V4, V5, V6, V7, V8, V9, V10, V11, V12, V13, V14, V15;
    wire signed [31:0] D0, D1, D2, D3;
    wire evd_av,  product_av;
    wire cov_av;

    // Instance of the covariance_matrix
    covariance_matrix cm_inst(
        .clk(clk),
        .rst(rst),
        .data_in0(data_in0),
        .data_in1(data_in1),
        .data_in2(data_in2),
        .data_in3(data_in3),
        .output_av(cov_av),
        .A0(A0), .A1(A1), .A2(A2), .A3(A3),
        .A4(A4), .A5(A5), .A6(A6), .A7(A7),
        .A8(A8), .A9(A9), .A10(A10), .A11(A11),
        .A12(A12), .A13(A13), .A14(A14), .A15(A15)
    );

    // Instance of the evd
    evd evd_inst(
        .clk(clk),
        .rst(rst),
        .data_available(cov_av),  // Connect to an output of cm_inst signaling data ready
        .output_available(evd_av),
        .A0(A0), .A1(A1), .A2(A2), .A3(A3),
        .A4(A4), .A5(A5), .A6(A6), .A7(A7),
        .A8(A8), .A9(A9), .A10(A10), .A11(A11),
        .A12(A12), .A13(A13), .A14(A14), .A15(A15),
        .V0(V0), .V1(V1), .V2(V2), .V3(V3),
        .V4(V4), .V5(V5), .V6(V6), .V7(V7),
        .V8(V8), .V9(V9), .V10(V10), .V11(V11),
        .V12(V12), .V13(V13), .V14(V14), .V15(V15),
        .D0(D0), .D1(D1), .D2(D2), .D3(D3)
    );
    
    
    reg signed [7:0] steering0;
    reg signed [7:0] steering1;
    reg signed [7:0] steering2;
    reg signed [7:0] steering3;
    reg steer_av=0;
    wire signed [7:0] steering_cos_tmp;
    reg [7:0] theta;// ranging from 0-180
    wire [9:0]steer_tmp_addr;
    reg [2:0]steer_count;
    
    // cos and sin steer LUT
    reg [1:0] min_idx1, min_idx2;  // Assuming 4 eigenvalues, used for comparsion
    reg [15:0] noise_vector_real10;
    reg [15:0] noise_vector_real11;
    reg [15:0] noise_vector_real12;
    reg [15:0] noise_vector_real13;
    reg [15:0] noise_vector_real20;
    reg [15:0] noise_vector_real21;
    reg [15:0] noise_vector_real22;
    reg [15:0] noise_vector_real23;
    
    cos_steer steer0(
    .clka(clk),
    .addra(steer_tmp_addr),
    .douta(steering_cos_tmp)
    );
    
    // process noise matrix comparsion and steer fetching with coresponse steering.
    
    always @ (posedge clk)
    if(rst)
        begin
        theta<=0;
        steering0<=0;
        steering1<=0;
        steering2<=0;
        steering3<=0;
        min_idx1 <= 2'd0;
        min_idx2 <= 2'd1;
        steer_count<=0;
        end
        
    else if(g_state==0)
    begin
    theta<=0;
    steer_count<=0;
    end
    else if(g_state==2)// get data;
        begin
            // Initial comparison to find first minimum
            if (D0 < D1 && D0 < D2 && D0 < D3) min_idx1 <= 2'd0;
            else if (D1 < D2 && D1 < D3) min_idx1 <= 2'd1;
            else if (D2 < D3) min_idx1 <= 2'd2;
            else min_idx1 <= 2'd3;

            // Second comparison excluding the first minimum
            case (min_idx1)
                2'd0: min_idx2 <= (D1 < D2) ? ((D1 < D3) ? 2'd1 : 2'd3) : ((D2 < D3) ? 2'd2 : 2'd3);
                2'd1: min_idx2 <= (D0 < D2) ? ((D0 < D3) ? 2'd0 : 2'd3) : ((D2 < D3) ? 2'd2 : 2'd3);
                2'd2: min_idx2 <= (D0 < D1) ? ((D0 < D3) ? 2'd0 : 2'd3) : ((D1 < D3) ? 2'd1 : 2'd3);
                2'd3: min_idx2 <= (D0 < D1) ? ((D0 < D2) ? 2'd0 : 2'd2) : ((D1 < D2) ? 2'd1 : 2'd2);
            endcase

            // Map selected eigenvectors to output noise vectors
           case(min_idx1)
                2'd0: {noise_vector_real10, noise_vector_real11, noise_vector_real12, noise_vector_real13} = {V0[15:0], V1[15:0], V2[15:0], V3[15:0]};
                2'd1: {noise_vector_real10, noise_vector_real11, noise_vector_real12, noise_vector_real13} = {V4[15:0], V5[15:0], V6[15:0], V7[15:0]};
                2'd2: {noise_vector_real10, noise_vector_real11, noise_vector_real12, noise_vector_real13} = {V8[15:0], V9[15:0], V10[15:0], V11[15:0]};
                2'd3: {noise_vector_real10, noise_vector_real11, noise_vector_real12, noise_vector_real13} = {V12[15:0], V13[15:0], V14[15:0], V15[15:0]};
            endcase

            case(min_idx2)
                2'd0: {noise_vector_real20, noise_vector_real21, noise_vector_real22, noise_vector_real23} = {V0[15:0], V1[15:0], V2[15:0], V3[15:0]};
                2'd1: {noise_vector_real20, noise_vector_real21, noise_vector_real22, noise_vector_real23} = {V4[15:0], V5[15:0], V6[15:0], V7[15:0]};
                2'd2: {noise_vector_real20, noise_vector_real21, noise_vector_real22, noise_vector_real23} = {V8[15:0], V9[15:0], V10[15:0], V11[15:0]};
                2'd3: {noise_vector_real20, noise_vector_real21, noise_vector_real22, noise_vector_real23} = {V12[15:0], V13[15:0], V14[15:0], V15[15:0]};
            endcase
            
            case (steer_count)
            1:steering0<=steering_cos_tmp;
            2:steering1<=steering_cos_tmp;
            3:steering2<=steering_cos_tmp;
            4:steering3<=steering_cos_tmp;
            endcase
            
            
            
            //steer_tmp_addr<={theta,steer_count};
            if(steer_count==4)
                begin
                steer_count<=0;
                theta<=theta+1;
                steer_av<=1;
                end
            else 
                begin
                steer_count<=steer_count+1;
                steer_av<=0;
                end
                
        end
    else if(g_state==3)
            steer_av<=0;
            //store the product theta for peak detetcion

        
assign steer_tmp_addr={theta,steer_count};     
        
        
   
        
    
    // Instance of the spectrum_calculator
    spectrum_calculator sc_inst(
        .clk(clk),
        .rst(rst),
        .in_av(steer_av),  // after switch the noise vector and get steerings 
        .steering0(steering0),
        .steering1(steering1),
        .steering2(steering2),
        .steering3(steering3),
        .noise_vector_real10(V0[15:0]),  // Example connection, assuming noise vectors are part of V outputs
        .noise_vector_real11(V1[15:0]),
        .noise_vector_real12(V2[15:0]),
        .noise_vector_real13(V3[15:0]),
        .noise_vector_real20(V4[15:0]),
        .noise_vector_real21(V5[15:0]),
        .noise_vector_real22(V6[15:0]),
        .noise_vector_real23(V7[15:0]),
        .out_av(product_av),
        .product_theta(product_theta)
    );


    // non-blocking controller state machine
    // only specify who can start do , no specifiy who can't do
    
    always @ (posedge clk)
    if (g_state==0)
        if(cov_av)
            g_state<=1;
        else
            g_state<=0;

    else if (g_state==1)
        if(evd_av)
            begin
            g_state<=2;  
            end
         else
            begin
            g_state<=g_state;
            end
         
    else if(g_state==2)
     if(steer_av)
        g_state<=3;
     else 
        g_state<=g_state;
    else // g_state==3
        if(product_av && theta<180)
            g_state<=2;
        else if(theta==180)g_state<=0;
        else g_state<=g_state;
            
            
            
        
        
    
    
        

endmodule

module evd (
    input wire clk,
    input wire rst,
    input wire data_available,
    output reg output_available=0,
    input wire [31:0] A0, A1, A2, A3,
    input wire [31:0] A4, A5, A6, A7,
    input wire [31:0] A8, A9, A10, A11,
    input wire [31:0] A12, A13, A14, A15,
    output wire signed [31:0] V0, V1, V2, V3,
    output wire signed [31:0] V4, V5, V6, V7,
    output wire signed [31:0] V8, V9, V10, V11,
    output wire signed [31:0] V12, V13, V14, V15,
    output wire signed [31:0] D0, D1, D2, D3
);

    reg signed [31:0] B [0:15], V [0:15], D [0:3], B_tmp [0:15], V_tmp [0:15]; 
    reg [5:0] iter=0;

    reg signed [31:0] alpha = 32'sd0;
    reg signed [31:0] beta = 32'sd0;
    reg signed [31:0] gamma = 32'sd0;
    reg signed [47:0] zeta = 32'sd0;
    reg signed [47:0] t = 0;
    reg signed [47:0] t1 = 0;
    wire signed [31:0] c ;
    wire signed [31:0] s ;

    reg [5:0] state=0;
    reg [1:0]i=0, j=1;
    reg [5:0]k=0;
    integer idx;

    localparam S_IDLE = 0,
               S_CALC = 1,
               S_UPDATE_B = 2,
               S_UPDATE_V = 3,
               S_DONE = 4;
    reg [5:0] delay=0;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output_available <= 0;
            iter <= 0;
            delay<=0;
            state <= S_IDLE;
            alpha <= 32'sd0;
            beta <= 32'sd0;
            gamma <= 32'sd0;
            for (idx = 0; idx < 16; idx = idx + 1) begin
                V_tmp[idx] <= (idx % 5 == 0) ? 32'sd10000 : 32'sd0; // Initialize V to identity matrix
                B_tmp[idx] <= (idx == 0) ? A0 : (idx == 1) ? A1 : (idx == 2) ? A2 : (idx == 3) ? A3 :
                          (idx == 4) ? A4 : (idx == 5) ? A5 : (idx == 6) ? A6 : (idx == 7) ? A7 :
                          (idx == 8) ? A8 : (idx == 9) ? A9 : (idx == 10) ? A10 : (idx == 11) ? A11 :
                          (idx == 12) ? A12 : (idx == 13) ? A13 : (idx == 14) ? A14 : A15;
            end
        end 
        
        else if(data_available==0)
            begin
                output_available <= 0;
                iter<=0;
            end
        else if(data_available==1 && iter==0)
        begin
            output_available <= 0;
            iter <= 1;
            delay<=0;
            state <= S_IDLE;
            alpha <= 32'sd0;
            beta <= 32'sd0;
            gamma <= 32'sd0;
            for (idx = 0; idx < 16; idx = idx + 1) begin
                V_tmp[idx] <= (idx % 5 == 0) ? 32'sd10000 : 32'sd0; // Initialize V to identity matrix
                B_tmp[idx] <= (idx == 0) ? A0 : (idx == 1) ? A1 : (idx == 2) ? A2 : (idx == 3) ? A3 :
                          (idx == 4) ? A4 : (idx == 5) ? A5 : (idx == 6) ? A6 : (idx == 7) ? A7 :
                          (idx == 8) ? A8 : (idx == 9) ? A9 : (idx == 10) ? A10 : (idx == 11) ? A11 :
                          (idx == 12) ? A12 : (idx == 13) ? A13 : (idx == 14) ? A14 : A15;
            end
        end 
            
        else if (iter>0 && iter < 5) begin
            case (state)
                S_IDLE: begin
                    output_available <= 0;
                    alpha <= 32'sd0;
                    beta <= 32'sd0;
                    gamma <= 32'sd0;
                    t<=0;
                    t1<=0;
                    zeta<=0;
                    k <= 0;
                    delay<=delay+1;
                    if (delay==18)
                    begin
                    state <= S_CALC;
                    delay<=0;
                    end
                end
                S_CALC: begin
                        k<=k+1;
                        alpha <= $signed(B_tmp[i*4+i]);
                        beta <= $signed(B_tmp[j*4+j]) ;
                        gamma <= $signed(B_tmp[i*4+j]) ;
                        t<=(256* gamma);
                        t1<=t /(beta - alpha);
                        zeta <= t1+512;  //arctan  range from -4-4
                        if(k==5)
                        begin
                             if (zeta<=0) zeta<=0;
                             else if( zeta>=1023)zeta<=1024;
                             state <= S_UPDATE_B;
                             k<=0;
                        end
                    end
                S_UPDATE_B: begin
                if (k < 4) begin
                    // Update temporary matrix B_tmp for rows i and j
                    if (k != i && k != j) begin
                        // For non-target rows, update normally without zeroing out any element
                        B_tmp[i*4+k] <= (c * B_tmp[i*4+k] - s * B_tmp[j*4+k]) / 32'sd512;
                        B_tmp[j*4+k] <= (s * B_tmp[i*4+k] + c * B_tmp[j*4+k]) / 32'sd512;
                    end else begin
                        // Handle special case for the rotation indices p and q
                        B_tmp[4*i + i] <= (c*c*B_tmp[4*i + i] + s*s*B_tmp[4*j + j] - 2*s*c*B_tmp[4*i + j]) / 32'sd262144;
                        B_tmp[4*j + j] <= (s*s*B_tmp[4*i + i] + c*c*B_tmp[4*j + j] + 2*s*c*B_tmp[4*i + j]) / 32'sd262144;
                        B_tmp[4*i + j] <= 0;  // Zeroing out the off-diagonal terB_tmpms after rotation
                        B_tmp[4*j + i] <= 0;
                    end
                    k <= k + 1;
                end else begin
                    // Copy from temporary to actual matrix B
                    
                    k <= 0;  // Reset k for next use
                    state <= S_UPDATE_V;  // Move to updating V
                end
            end
            
            S_UPDATE_V: begin
                if (k < 4) begin
                    // Update V_tmp matrix rows i and j
                    V_tmp[k*4+i] <= (c * V_tmp[k*4+i] - s * V_tmp[k*4+j]) / 32'sd512;
                    V_tmp[k*4+j] <= (s * V_tmp[k*4+i] + c * V_tmp[k*4+j]) / 32'sd512;
                    k <= k + 1;
                end else begin
                    // Copy from temporary to actual matrix V
                   
                    k <= 0;  // Reset k for next use
                    iter <= iter + 1; 
                    state <= S_IDLE;  // Transition to the next state
                    end
                end
            endcase
        end
        else if(iter==5)
        begin
        output_available <= 1;
        iter<=0;
        end
        
    end
    
    reg [3:0]count=0;
    reg signed [31:0]max_val=0;
    reg signed [31:0]current_val=0;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            max_val <= 32'd0;
            i <= 0;
            j <= 1;
        end
        else if(state==0)
            if (count < 16) begin
                // Calculate current matrix indices
                current_val = B_tmp[count];
                if (current_val > max_val && count!=0 && count!=5 && count!=10 && count!=15 ) begin
                    max_val <= current_val; 
                    i <= count[3:2];  // Equivalent to count / 4 (row)
                    j <= count[1:0];  // Equivalent to count % 4 (column)
                end
                count <= count + 1;
            end
            else 
                count <= 0;   // Signal that processing is complete
        else
        begin
        count<=0;
        j<=j;
        i<=i;
        max_val<=0;
        end
    end
    /*integer t_i,t_j;
    reg signed [31:0] max_val;
    always @(posedge clk or posedge rst)
     begin
            if (rst) begin
                i <= 2'd1;
                j <= 2'd0;
                max_val <= 32'sd0;
            end 
            else if (state==1) 
            case({i,j})
            4'b0100:{i,j}<=4'b1000;
            4'b1000:{i,j}<=4'b1100;
            4'b1100:{i,j}<=4'b0001;
            4'b0001:{i,j}<=4'b1001;
            4'b1001:{i,j}<=4'b1101;
            4'b1101:{i,j}<=4'b0010;
            4'b0010:{i,j}<=4'b0110;
            4'b0110:{i,j}<=4'b1110;
            4'b1110:{i,j}<=4'b0011;
            4'b0011:{i,j}<=4'b0111;
            4'b0111:{i,j}<=4'b1011;
            4'b1011:{i,j}<=4'b0100;
            default : {i,j}<=4'b0100;
            endcase
            
    end         
            
        */    
       
       sin_lut sin(
       .clka(clk),
       .addra(zeta[9:0]),
       .douta(s)
       );
            
       cos_lut cos(
       .clka(clk),
       .addra(zeta[9:0]),
       .douta(c)
       );        


      assign  V0 = V_tmp[0], V1 = V_tmp[1], V2 = V_tmp[2], V3 = V_tmp[3];
      assign  V4 = V_tmp[4], V5 = V_tmp[5], V6 = V_tmp[6], V7 = V_tmp[7];
      assign  V8 = V_tmp[8], V9 = V_tmp[9], V10 = V_tmp[10], V11 = V_tmp[11];
      assign  V12 = V_tmp[12], V13 = V_tmp[13], V14 = V_tmp[14], V15 = V_tmp[15];
      assign  D0 = B_tmp[0] ,D1 = B_tmp[5], D2 = B_tmp[10] , D3 = B_tmp[15];

endmodule
module spectrum_calculator (
    input wire clk,
    input wire rst,
    input wire in_av,  // input data available
    input wire [7:0] steering0, steering1, steering2, steering3,
    input wire [15:0] noise_vector_real10, noise_vector_real11, noise_vector_real12, noise_vector_real13,
    input wire [15:0] noise_vector_real20, noise_vector_real21, noise_vector_real22, noise_vector_real23,
    output reg out_av=0,
    output reg [63:0] product_theta=0
);

    // Internal registers for storing intermediate results
    reg [31:0] nnh [0:3][0:3];
    reg [31:0] temp_vector_real[0:3];
    reg [63:0] dot_product_real=0;
    
    // Counters
    reg [2:0] i, j;
    reg [2:0] state;
    
    // States
    localparam IDLE = 0, CALC_NNH = 1, CALC_TEMP_VECTOR = 2, CALC_DOT_PRODUCT = 3, OUTPUT_RESULT = 4;

    // Main FSM for computation
    always @(posedge clk) begin
        if (rst) begin
            i <= 0;
            j <= 0;
            state <= IDLE;
            out_av <= 0;
            product_theta <= 0;
            temp_vector_real[0]<=0;
            temp_vector_real[1]<=0;
            temp_vector_real[2]<=0;
            temp_vector_real[3]<=0;
        end else begin
            case (state)
                IDLE: begin
                    out_av<=0;
                    i <= 0;
                    j <= 0;
                    dot_product_real <= 0; // Reset accumulation
                    if (in_av)
                        state <= CALC_NNH;
                end
                CALC_NNH: begin
                    // Dynamically calculate each element of NN^H
                    nnh[i][j] <= (i == 0 ? noise_vector_real10 : i == 1 ? noise_vector_real11 : i == 2 ? noise_vector_real12 : noise_vector_real13) *
                                 (j == 0 ? noise_vector_real10 : j == 1 ? noise_vector_real11 : j == 2 ? noise_vector_real12 : noise_vector_real13) +
                                 (i == 0 ? noise_vector_real20 : i == 1 ? noise_vector_real21 : i == 2 ? noise_vector_real22 : noise_vector_real23) *
                                 (j == 0 ? noise_vector_real20 : j == 1 ? noise_vector_real21 : j == 2 ? noise_vector_real22 : noise_vector_real23);
                    j <= j + 1;
                    if (j == 3) begin
                        j <= 0;
                        i <= i + 1;
                        if (i == 3) begin
                            i <= 0;
                            state <= CALC_TEMP_VECTOR;
                        end
                    end
                end
                CALC_TEMP_VECTOR: begin
                    temp_vector_real[i] <= temp_vector_real[i] + nnh[i][j] *(j == 0 ? steering0 : j == 1 ? steering1 : j == 2 ? steering2 : steering3);
                    j <= j + 1;
                    if (j == 3) begin
                        j <= 0;
                        i <= i + 1;
                        if (i == 3) begin
                            i <= 0;
                            state <= CALC_DOT_PRODUCT;
                        end
                    end
                end
                CALC_DOT_PRODUCT: begin
                    dot_product_real <= dot_product_real + temp_vector_real[i] *
                        (i == 0 ? steering0 : i == 1 ? steering1 : i == 2 ? steering2 : steering3);
                    i <= i + 1;
                    if (i == 3) begin
                        i <= 0;
                        state <= OUTPUT_RESULT;
                    end
                end
                OUTPUT_RESULT: begin
                    out_av <= 1;
                    product_theta <= dot_product_real;  // Simplified inversion as reciprocal for demonstration
                    state <= IDLE;  // Loop back or wait for new inputs
                end
            endcase
        end
    end
endmodule

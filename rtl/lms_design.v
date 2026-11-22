`timescale 1ns/1ps

module lms_design (
    input  wire               clk,
    input  wire               reset,
    input  wire               start,

    input  wire signed [15:0] sample_in,
    input  wire signed [15:0] desired_in,

    output reg  signed [15:0] output_y,
    output reg                done
);

    // =========================================================
    // STATE MACHINE
    // =========================================================

    localparam S_IDLE   = 3'd0;
    localparam S_LOAD   = 3'd1;
    localparam S_MAC    = 3'd2;
    localparam S_ERROR  = 3'd3;
    localparam S_UPDATE = 3'd4;
    localparam S_DONE   = 3'd5;

    reg [2:0] state;

    // =========================================================
    // 8-TAP INPUT SHIFT REGISTER
    //
    // x_reg[0] = newest sample
    // x_reg[7] = oldest sample
    //
    // Q1.15
    // =========================================================

    reg signed [15:0] x_reg [0:7];

    // =========================================================
    // LMS COEFFICIENTS
    //
    // Q1.15
    // =========================================================

    reg signed [15:0] w_reg [0:7];

    // =========================================================
    // DESIRED SIGNAL
    //
    // Q1.15
    // =========================================================

    reg signed [15:0] desired_reg;

    // =========================================================
    // ACCUMULATOR
    //
    // 35 bits
    // Product = Q2.30
    // =========================================================

    reg signed [34:0] accumulator;

    // =========================================================
    // ERROR
    //
    // 17 bits
    // =========================================================

    reg signed [16:0] error_reg;

    // =========================================================
    // TAP COUNTER
    //
    // 0 to 7
    // =========================================================

    reg [2:0] tap;

    integer i;

    // =========================================================
    // MAC PRODUCT
    //
    // 16-bit × 16-bit = 32-bit
    // =========================================================

    wire signed [31:0] mac_product;

    assign mac_product = x_reg[tap] * w_reg[tap];

    // =========================================================
    // SIGN EXTEND PRODUCT TO 35 BITS
    // =========================================================

    wire signed [34:0] mac_product_ext;

    assign mac_product_ext = {
        {3{mac_product[31]}},
        mac_product
    };

    // =========================================================
    // NEXT ACCUMULATOR
    // =========================================================

    wire signed [34:0] accumulator_next;

    assign accumulator_next = accumulator + mac_product_ext;

    // =========================================================
    // FILTER OUTPUT
    //
    // Q2.30 -> Q1.15
    //
    // Right shift by 15
    // =========================================================

    wire signed [34:0] output_scaled;

    assign output_scaled = accumulator_next >>> 15;

    // =========================================================
    // 16-BIT OUTPUT
    //
    // Explicit signed conversion
    // =========================================================

    wire signed [15:0] output_q15;

    assign output_q15 = $signed(output_scaled);

    // =========================================================
    // EXTENDED OUTPUT FOR ERROR CALCULATION
    //
    // 16-bit signed -> 17-bit signed
    // =========================================================

    wire signed [16:0] output_extended;

    // Use the registered final output, matching the output consumed by the filter.
    assign output_extended = $signed({output_y[15], output_y});

    // =========================================================
    // EXTENDED DESIRED SIGNAL
    //
    // 16-bit signed -> 17-bit signed
    // =========================================================

    wire signed [16:0] desired_extended;

    assign desired_extended = desired_reg;

    // =========================================================
    // ERROR
    //
    // e(n) = d(n) - y(n)
    // =========================================================

    wire signed [16:0] error_next;

    assign error_next = desired_extended - output_extended;

    // =========================================================
    // ERROR × INPUT
    //
    // 17 × 16 = 33 bits
    // =========================================================

    wire signed [32:0] error_x_input;

    assign error_x_input = error_reg * x_reg[tap];

    // =========================================================
    // LMS CORRECTION
    //
    // mu = 1/32
    //
    // e × x has 30 fractional bits.
    //
    // >>>15 converts back to Q1.15
    // >>>5 implements division by 32
    //
    // Total shift = 20
    // =========================================================

    wire signed [32:0] correction_scaled;

    assign correction_scaled = error_x_input >>> 20;

    // =========================================================
    // 16-BIT CORRECTION
    //
    // Explicit signed conversion
    // =========================================================

    wire signed [15:0] correction;

    assign correction = $signed(correction_scaled);

    // =========================================================
    // EXTENDED WEIGHT
    //
    // 16-bit signed -> 17-bit signed
    // =========================================================

    wire signed [16:0] weight_extended;

    assign weight_extended = w_reg[tap];

    // =========================================================
    // EXTENDED CORRECTION
    //
    // 16-bit signed -> 17-bit signed
    // =========================================================

    wire signed [16:0] correction_extended;

    assign correction_extended = correction;

    // =========================================================
    // NEW WEIGHT
    // =========================================================

    wire signed [16:0] weight_sum;

    assign weight_sum = weight_extended + correction_extended;

    // =========================================================
    // SATURATION
    //
    // Q1.15 limits:
    //
    // Maximum = +32767
    // Minimum = -32768
    // =========================================================

    reg signed [15:0] saturated_weight;

    always @(*) begin

        if (weight_sum > 17'sd32767) begin
            saturated_weight = 16'sh7FFF;
        end

        else if (weight_sum < -17'sd32768) begin
            saturated_weight = 16'sh8000;
        end

        else begin
            saturated_weight = weight_sum;
        end

    end

    // =========================================================
    // MAIN FSM
    // =========================================================

    always @(posedge clk) begin

        if (reset) begin

            state       <= S_IDLE;
            accumulator <= 35'sd0;
            error_reg   <= 17'sd0;
            desired_reg <= 16'sd0;
            output_y    <= 16'sd0;
            done        <= 1'b0;
            tap         <= 3'd0;

            for (i = 0; i < 8; i = i + 1) begin
                x_reg[i] <= 16'sd0;
                w_reg[i] <= 16'sd0;
            end

        end

        else begin

            case (state)

                // =================================================
                // IDLE
                // =================================================

                S_IDLE: begin

                    done <= 1'b0;

                    if (start) begin
                        state <= S_LOAD;
                    end

                end

                // =================================================
                // LOAD
                // =================================================

                S_LOAD: begin

                    // Shift input samples

                    x_reg[7] <= x_reg[6];
                    x_reg[6] <= x_reg[5];
                    x_reg[5] <= x_reg[4];
                    x_reg[4] <= x_reg[3];
                    x_reg[3] <= x_reg[2];
                    x_reg[2] <= x_reg[1];
                    x_reg[1] <= x_reg[0];
                    x_reg[0] <= sample_in;

                    // Store desired signal

                    desired_reg <= desired_in;

                    // Clear MAC accumulator

                    accumulator <= 35'sd0;

                    // Start from tap 0

                    tap <= 3'd0;

                    state <= S_MAC;

                end

                // =================================================
                // MAC
                // =================================================

                S_MAC: begin

                    // Add current tap product

                    accumulator <= accumulator_next;

                    if (tap == 3'd7) begin

                        // Complete 8-tap output

                        output_y <= output_q15;

                        state <= S_ERROR;

                    end

                    else begin

                        tap <= tap + 3'd1;

                    end

                end

                // =================================================
                // ERROR
                // =================================================

                S_ERROR: begin

                    // Calculate:
                    //
                    // e(n) = d(n) - y(n)

                    error_reg <= error_next;

                    // Start coefficient update

                    tap <= 3'd0;

                    state <= S_UPDATE;

                end

                // =================================================
                // UPDATE
                // =================================================

                S_UPDATE: begin

                    // w(n+1) = w(n) + mu*e(n)*x(n)

                    w_reg[tap] <= saturated_weight;

                    if (tap == 3'd7) begin

                        state <= S_DONE;

                    end

                    else begin

                        tap <= tap + 3'd1;

                    end

                end

                // =================================================
                // DONE
                // =================================================

                S_DONE: begin

                    done <= 1'b1;

                    state <= S_IDLE;

                end

                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state <= S_IDLE;

                end

            endcase

        end

    end

endmodule

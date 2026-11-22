`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.09.2026 09:39:49
// Design Name: 
// Module Name: tb_lms_filter_optimized
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
////////////////////////////////////////////////////////////////////////////
module lmstb;

    reg clk;
    reg reset;
    reg start;

    reg signed [15:0] sample_in;
    reg signed [15:0] desired_in;

    wire signed [15:0] output_y;
    wire done;

    // =========================================================
    // DUT
    // =========================================================

   lmsdesign dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .sample_in(sample_in),
        .desired_in(desired_in),
        .output_y(output_y),
        .done(done)
    );

    // =========================================================
    // MEMORY
    // =========================================================

    reg signed [15:0] input_mem [0:999];
    reg signed [15:0] desired_mem [0:999];
    reg signed [15:0] output_mem [0:999];

    integer i;

    // =========================================================
    // CLOCK
    // =========================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // =========================================================
    // TEST
    // =========================================================
    // Cadence Xcelium / SimVision waveform database
    initial begin
        $shm_open("lmsdesign_cadence.shm");
        $shm_probe("ASM"); // all signals and memories in this scope and below
    end


    initial begin

        // Load input data
        $readmemh("mem/input_q15.mem", input_mem);

        // Load desired signal
        $readmemh("mem/desired_q15.mem", desired_mem);

        // Initial values
        reset      = 1'b1;
        start      = 1'b0;
        sample_in  = 16'sd0;
        desired_in = 16'sd0;

        // Reset
        #20;
        reset = 1'b0;

        // =====================================================
        // PROCESS 1000 SAMPLES
        // =====================================================

        for (i = 0; i < 1000; i = i + 1) begin

            @(negedge clk);

            sample_in  = input_mem[i];
            desired_in = desired_mem[i];

            start = 1'b1;

            @(negedge clk);

            start = 1'b0;

            // Wait until LMS processing is complete
            wait(done == 1'b1);

            output_mem[i] = output_y;

            // Print selected samples
            if ((i < 10) ||
                (i == 99) ||
                (i == 199) ||
                (i == 499) ||
                (i == 999)) begin

                $display(
                    "Sample %0d: Input=%0d Desired=%0d Output=%0d",
                    i,
                    $signed(sample_in),
                    $signed(desired_in),
                    $signed(output_y)
                );

            end

            @(negedge clk);

        end

        // =====================================================
        // WRITE OUTPUT FILE
        // =====================================================

        $writememh("rtl_output_cadence_q15.mem", output_mem);

        $display("--------------------------------------------");
        $display("CADENCE LMS SIMULATION COMPLETE");
        $display("1000 samples processed.");
        $display("Output written to rtl_output_cadence_q15.mem");
        $display("--------------------------------------------");

        #20;

        $shm_close;
        $finish;

    end

endmodule

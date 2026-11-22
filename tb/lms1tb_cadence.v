`timescale 1ns/1ps

module lms1tb;

    // =========================================================
    // PARAMETERS
    // =========================================================

    parameter N = 1000;

    // =========================================================
    // CLOCK AND CONTROL
    // =========================================================

    reg clk;
    reg reset;
    reg start;

    // =========================================================
    // INPUTS
    // =========================================================

    reg signed [15:0] sample_in;
    reg signed [15:0] desired_in;

    // =========================================================
    // OUTPUTS
    // =========================================================

    wire signed [15:0] output_y;
    wire done;

    // =========================================================
    // MEMORY ARRAYS
    //
    // input_mem   = noisy input x(n)
    // desired_mem = desired signal d(n)
    // =========================================================

    reg signed [15:0] input_mem [0:N-1];
    reg signed [15:0] desired_mem [0:N-1];

    // =========================================================
    // OUTPUT MEMORY
    //
    // Stores RTL output for every sample
    // =========================================================

    reg signed [15:0] output_mem [0:N-1];

    integer sample_count;

    // =========================================================
    // DUT
    // =========================================================

    lms_design DUT (
        .clk        (clk),
        .reset      (reset),
        .start      (start),
        .sample_in  (sample_in),
        .desired_in (desired_in),
        .output_y   (output_y),
        .done        (done)
    );

    // =========================================================
    // CADENCE XCELIUM / SIMVISION WAVEFORM DUMP
    // Simulation only; not synthesized.
    // =========================================================

    //initial begin
        //$shm_open("lms1tb_35bit.shm");
        //$shm_probe("ASM");
    //end

    // =========================================================
    // CLOCK
    //
    // 10 ns period = 100 MHz
    // =========================================================

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end

    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // Initialize
        // -----------------------------------------------------

        reset      = 1'b1;
        start      = 1'b0;
        sample_in  = 16'sd0;
        desired_in = 16'sd0;

        sample_count = 0;

        // -----------------------------------------------------
        // Read MATLAB-generated files
        // -----------------------------------------------------

        $readmemh("mem/input_q15.mem", input_mem);

        $readmemh("mem/desired_q15.mem", desired_mem);

        // -----------------------------------------------------
        // Display test information
        // -----------------------------------------------------

        $display("============================================");
        $display("       COMPLETE LMS 1000-SAMPLE TEST");
        $display("============================================");

        $display("Input file   : mem/input_q15.mem");
        $display("Desired file : mem/desired_q15.mem");
        $display("Samples      : %d", N);

        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------

        #20;

        reset = 1'b0;

        // =====================================================
        // PROCESS ALL 1000 SAMPLES
        // =====================================================

        for (sample_count = 0;
             sample_count < N;
             sample_count = sample_count + 1) begin

            // -------------------------------------------------
            // Apply current sample
            // -------------------------------------------------

            sample_in  = input_mem[sample_count];
            desired_in = desired_mem[sample_count];

            // -------------------------------------------------
            // Start processing
            // -------------------------------------------------

            @(negedge clk);

            start = 1'b1;

            @(negedge clk);

            start = 1'b0;

            // -------------------------------------------------
            // Wait for complete LMS calculation
            // -------------------------------------------------

            wait(done == 1'b1);

            #1;

            // -------------------------------------------------
            // Store output
            // -------------------------------------------------

            output_mem[sample_count] = output_y;

            // -------------------------------------------------
            // Display selected samples
            // -------------------------------------------------

            if ((sample_count < 10) ||
                (sample_count == 99) ||
                (sample_count == 199) ||
                (sample_count == 499) ||
                (sample_count == 999)) begin

                $display(
                    "Sample = %4d | Input = %6d | Desired = %6d | Output = %6d",
                    sample_count,
                    $signed(sample_in),
                    $signed(desired_in),
                    $signed(output_y)
                );

            end

            // -------------------------------------------------
            // Wait before next sample
            // -------------------------------------------------

            @(negedge clk);

        end

        // =====================================================
        // SAVE RTL OUTPUT
        // =====================================================

        $writememh(
            "mem/rtl_output_35bit_q15.mem",
            output_mem
        );

        // =====================================================
        // SIMULATION COMPLETE
        // =====================================================

        $display("============================================");
        $display("       LMS RTL TEST COMPLETE");
        $display("============================================");

        $display("Total samples processed = %d", N);

        $display("RTL output file:");
        $display("mem/rtl_output_35bit_q15.mem");

        $display("Waveform file:");
        $display("lms1tb_35bit.shm");

        $display("============================================");

        #20;

        $shm_close;
        $finish;

    end

endmodule

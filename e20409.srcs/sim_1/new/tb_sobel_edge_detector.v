`timescale 1ns/1ps

module tb_sobel_edge_detector;

    parameter IMG_WIDTH   = 225;
    parameter IMG_HEIGHT  = 225;
    parameter DATA_WIDTH  = 8;
    parameter CLK_PERIOD  = 10;

    reg clk;
    reg rst;
    reg start;
    reg [DATA_WIDTH-1:0] pixel_in;
    reg [15:0] pixel_addr;
    reg pixel_wr_en;

    wire [DATA_WIDTH-1:0] edge_out;
    wire [15:0] edge_addr;
    wire edge_valid;
    wire done;

    sobel_edge_detector #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .pixel_in(pixel_in),
        .pixel_addr(pixel_addr),
        .pixel_wr_en(pixel_wr_en),
        .edge_out(edge_out),
        .edge_addr(edge_addr),
        .edge_valid(edge_valid),
        .done(done)
    );

    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    integer in_fd;
    integer out_fd;
    integer val;
    integer idx;

    // write output when valid
    always @(posedge clk) begin
        if (edge_valid) begin
            $fwrite(out_fd, "%0d %0d\n", edge_addr, edge_out);
        end
    end

    initial begin
        // init
        rst = 1;
        start = 0;
        pixel_wr_en = 0;
        pixel_in = 0;
        pixel_addr = 0;

        // reset for 2 clocks
        repeat(2) @(posedge clk);
        rst = 0;

        // open input file
        in_fd = $fopen("test_image_data.txt", "r");
        if (in_fd == 0) begin
            $display("ERROR: Cannot open test_image_data.txt");
            $finish;
        end

        // open output file
        out_fd = $fopen("verilog_edges.txt", "w");
        if (out_fd == 0) begin
            $display("ERROR: Cannot create verilog_edges.txt");
            $finish;
        end

        // load ALL pixels (50625 lines)
        for (idx = 0; idx < IMG_WIDTH*IMG_HEIGHT; idx = idx + 1) begin
            if ($fscanf(in_fd, "%d\n", val) != 1) begin
                $display("ERROR: Not enough data at idx=%0d", idx);
                $finish;
            end

            // set inputs BEFORE next posedge (blocking '=')
            pixel_addr  = idx[15:0];
            pixel_in    = val[DATA_WIDTH-1:0];
            pixel_wr_en = 1'b1;

            @(posedge clk); // DUT writes here
        end

        pixel_wr_en = 1'b0;
        @(posedge clk);

        $fclose(in_fd);

        // start pulse
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // wait done
        wait(done == 1'b1);
        @(posedge clk);

        $fclose(out_fd);
        $display("DONE. Saved verilog_edges.txt");
        $finish;
    end

endmodule
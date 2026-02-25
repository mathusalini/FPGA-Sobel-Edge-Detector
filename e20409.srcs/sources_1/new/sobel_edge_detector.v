`timescale 1ns/1ps

module sobel_edge_detector #(
    parameter IMG_WIDTH  = 225,
    parameter IMG_HEIGHT = 225,
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   start,
    input  wire [DATA_WIDTH-1:0]  pixel_in,
    input  wire [15:0]            pixel_addr,
    input  wire                   pixel_wr_en,

    output reg  [DATA_WIDTH-1:0]  edge_out,
    output reg  [15:0]            edge_addr,
    output reg                    edge_valid,
    output reg                    done
);

    // 225*225 = 50625, fits in 16-bit address
    reg [DATA_WIDTH-1:0] image_mem  [0:IMG_WIDTH*IMG_HEIGHT-1];
    reg [DATA_WIDTH-1:0] output_mem [0:IMG_WIDTH*IMG_HEIGHT-1];

    localparam [2:0] IDLE         = 3'b000,
                     LOAD_WINDOW  = 3'b001,
                     COMPUTE_GX   = 3'b010,
                     COMPUTE_GY   = 3'b011,
                     COMPUTE_MAG  = 3'b100,
                     WRITE_OUTPUT = 3'b101,
                     DONE_STATE   = 3'b110;

    reg [2:0] state, next_state;

    reg [15:0] row, col;
    reg signed [15:0] gx, gy;
    reg [15:0] magnitude;

    reg [DATA_WIDTH-1:0] window [0:8];

    integer i;

    // Sobel kernels via functions (pure Verilog)
    function signed [3:0] kx;
        input [3:0] idx;
        begin
            case (idx)
                0: kx = -1; 1: kx =  0; 2: kx =  1;
                3: kx = -2; 4: kx =  0; 5: kx =  2;
                6: kx = -1; 7: kx =  0; 8: kx =  1;
                default: kx = 0;
            endcase
        end
    endfunction

    function signed [3:0] ky;
        input [3:0] idx;
        begin
            case (idx)
                0: ky = -1; 1: ky = -2; 2: ky = -1;
                3: ky =  0; 4: ky =  0; 5: ky =  0;
                6: ky =  1; 7: ky =  2; 8: ky =  1;
                default: ky = 0;
            endcase
        end
    endfunction

    // write pixels into memory
    always @(posedge clk) begin
        if (pixel_wr_en)
            image_mem[pixel_addr] <= pixel_in;
    end

    // next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:         if (start) next_state = LOAD_WINDOW;
            LOAD_WINDOW:  next_state = COMPUTE_GX;
            COMPUTE_GX:   next_state = COMPUTE_GY;
            COMPUTE_GY:   next_state = COMPUTE_MAG;
            COMPUTE_MAG:  next_state = WRITE_OUTPUT;
            WRITE_OUTPUT: next_state = (row == IMG_HEIGHT-2 && col == IMG_WIDTH-2) ? DONE_STATE : LOAD_WINDOW;
            DONE_STATE:   next_state = IDLE;
            default:      next_state = IDLE;
        endcase
    end

    // sequential (single driver)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            row        <= 16'd1;
            col        <= 16'd1;
            gx         <= 16'sd0;
            gy         <= 16'sd0;
            magnitude  <= 16'd0;
            edge_out   <= 8'd0;
            edge_addr  <= 16'd0;
            edge_valid <= 1'b0;
            done       <= 1'b0;
            for (i = 0; i < 9; i = i + 1) window[i] <= 0;
        end else begin
            state <= next_state;

            // pulses default
            edge_valid <= 1'b0;
            done       <= 1'b0;

            case (state)
                IDLE: begin
                    row <= 16'd1;
                    col <= 16'd1;
                end

                LOAD_WINDOW: begin
                    window[0] <= image_mem[(row-1)*IMG_WIDTH + (col-1)];
                    window[1] <= image_mem[(row-1)*IMG_WIDTH + (col)];
                    window[2] <= image_mem[(row-1)*IMG_WIDTH + (col+1)];
                    window[3] <= image_mem[(row)*IMG_WIDTH   + (col-1)];
                    window[4] <= image_mem[(row)*IMG_WIDTH   + (col)];
                    window[5] <= image_mem[(row)*IMG_WIDTH   + (col+1)];
                    window[6] <= image_mem[(row+1)*IMG_WIDTH + (col-1)];
                    window[7] <= image_mem[(row+1)*IMG_WIDTH + (col)];
                    window[8] <= image_mem[(row+1)*IMG_WIDTH + (col+1)];
                end

                COMPUTE_GX: begin
                    gx <= ($signed({1'b0, window[0]}) * kx(0)) +
                          ($signed({1'b0, window[1]}) * kx(1)) +
                          ($signed({1'b0, window[2]}) * kx(2)) +
                          ($signed({1'b0, window[3]}) * kx(3)) +
                          ($signed({1'b0, window[4]}) * kx(4)) +
                          ($signed({1'b0, window[5]}) * kx(5)) +
                          ($signed({1'b0, window[6]}) * kx(6)) +
                          ($signed({1'b0, window[7]}) * kx(7)) +
                          ($signed({1'b0, window[8]}) * kx(8));
                end

                COMPUTE_GY: begin
                    gy <= ($signed({1'b0, window[0]}) * ky(0)) +
                          ($signed({1'b0, window[1]}) * ky(1)) +
                          ($signed({1'b0, window[2]}) * ky(2)) +
                          ($signed({1'b0, window[3]}) * ky(3)) +
                          ($signed({1'b0, window[4]}) * ky(4)) +
                          ($signed({1'b0, window[5]}) * ky(5)) +
                          ($signed({1'b0, window[6]}) * ky(6)) +
                          ($signed({1'b0, window[7]}) * ky(7)) +
                          ($signed({1'b0, window[8]}) * ky(8));
                end

                COMPUTE_MAG: begin
                    // magnitude = |gx| + |gy|
                    magnitude <= (gx >= 0 ? gx : -gx) + (gy >= 0 ? gy : -gy);
                end

                WRITE_OUTPUT: begin
                    output_mem[row*IMG_WIDTH + col] <= (magnitude > 16'd255) ? 8'd255 : magnitude[7:0];

                    edge_addr  <= row*IMG_WIDTH + col;
                    edge_out   <= (magnitude > 16'd255) ? 8'd255 : magnitude[7:0];
                    edge_valid <= 1'b1;

                    // next pixel (skip border)
                    if (col == IMG_WIDTH-2) begin
                        col <= 16'd1;
                        if (row == IMG_HEIGHT-2) row <= 16'd1;
                        else row <= row + 16'd1;
                    end else begin
                        col <= col + 16'd1;
                    end
                end

                DONE_STATE: begin
                    done <= 1'b1; // 1-cycle pulse
                end
            endcase
        end
    end

endmodule
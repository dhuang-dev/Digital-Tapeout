//1.3a Synchronous FIFO, read if FIFO !empty
module sync_fifo #(
    parameter FIFO_DEPTH = 32,
    parameter DATA_W = 16
) (
    input logic clk,
    input logic rst_n,

    input logic in_valid,
    output logic in_ready,
    input logic [DATA_W-1:0] w_data,

    input logic out_valid,
    output logic out_ready,
    output logic [DATA_W-1:0] r_data,
)

localparam ADDR_W = $clog2(FIFO_DEPTH);
logic [DATA_W-1:0] mem [FIFO_DEPTH-1:0];
logic [ADDR_W:0] w_ptr, r_ptr;
//ptrs wider for wraparound detection

logic full, empty;
assign full = (w_ptr[ADDR_W] != r_ptr[ADDR_W]) && (w_ptr[ADDR_W-1:0] == r_ptr[ADDR_W-1:0]);
assign empty = (w_ptr == r_ptr);
assign in_ready = !full;
assign out_ready = !empty;
assign r_data = mem[r_ptr[ADDR_W-1:0]];

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        w_ptr <= '0;
        r_ptr <= '0;
    end else begin
        if(in_valid && in_ready) begin
            mem[w_ptr[ADDR_W-1:0]] <= w_data;
            w_ptr <= w_ptr + 1'b1;
        end
        if(out_valid && out_ready) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end
end
endmodule

//1.3b Remove cycle of latency, allow consumer to consume from empty
//FIFO if producer adds data in same cycle: zero latency FIFO

module sync_fifo #(
    parameter FIFO_DEPTH = 32,
    parameter DATA_W = 16
) (
    input logic clk,
    input logic rst_n,

    input logic in_valid,
    output logic in_ready,
    input logic [DATA_W-1:0] w_data,

    input logic out_valid,
    output logic out_ready,
    output logic [DATA_W-1:0] r_data,
)
// 
localparam ADDR_W = $clog2(FIFO_DEPTH);
logic [DATA_W-1:0] mem [FIFO_DEPTH-1:0]; //16 bit wide, 32 deep memory
logic [ADDR_W:0] w_ptr, r_ptr;

logic full, empty;
logic bypass;
assign full = (w_ptr[ADDR_W] != r_ptr[ADDR_W]) && (w_ptr[ADDR_W-1:0] == r_ptr[ADDR_W-1:0]);
assign empty = (w_ptr == r_ptr);
assign in_ready = !full;
assign bypass = is_empty && in_valid && out_valid;
assign out_valid = !is_empty || in_valid;

assign r_data = bypass ? w_data : mem[r_ptr[ADDR_W-1:0]];

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        w_ptr <= '0;
        r_ptr <= '0;
    end else begin
        if(in_valid && in_ready && !bypass) begin
            mem[w_ptr[ADDR_W-1:0]] <= w_data;
            w_ptr <= w_ptr + 1'b1;
        end
        if(out_valid && out_ready && !bypass) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end
end
endmodule

//1.3c Same cycle tradeoff
//Adding same-cycle consuming introduces more combinational paths (kinda like Mealy vs Moore)
//This can limit freq max and also complicate timing closure.

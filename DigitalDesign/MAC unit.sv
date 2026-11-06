//1.2a MAC Unit
module mac_unit(
    input logic clk,
    input logic rst_n,
    input logic [7:0] a, b,
    output logic [11:0] acc
);
logic [15:0] product;
logic [12:0] next_acc;

assign product = a * b;
assign next_acc = acc + product [11:0];
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        acc <= 12'd0;
    end else begin
        acc <= next_acc;
    end
end
endmodule

//1.2b Pipeling MAC so multiple is one cycle, accumulate is another
module mac_unit(
    input logic clk,
    input logic rst_n,
    input logic [7:0] a, b,
    output logic [11:0] acc
);
logic [15:0] product;
logic [12:0] mult_reg;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        product <= 16'd0;
        acc <= 12'd0;
    end else begin
        product <= a * b;
        acc <= acc + mult_reg [11:0];
    end
end
endmodule

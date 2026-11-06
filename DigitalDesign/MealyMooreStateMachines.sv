//SECTION 1: RTL DESIGN
//1.1a: detect 10010 as Mealy Machine, current state and input
module overlapping_seq_detector (
    input logic clk,
    input logic rst_n,
    input logic din, //input bit
    output logic detect //when 10010 is seen
)

typedef enum logic [2:0] {
    S_IDLE = 3'b000, //nothing
    S_1 = 3'b001, //1
    S_10 = 3'b010, //10
    S_100 = 3'b011, //100
    S_1001 = 3'b100 //1001
} state_t; //type name

state_t current_state, next_state; //2 instances

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current state <= S_IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    case(current_state) 
        S_IDLE: begin
            if (din) next_state = S_1;
            else next_state = S_IDLE;
        end
        S_1: begin
            if (!din) next_state = S_10;
            else next_state = S_1; //stays in S1 if another 1 seen
        end
        S_10: begin
            if (!din) next_state = S_100;
            else next_state = S_1;
        end
        S_100: begin
            if (din) next_state = S_1001;
            else next_state = S_IDLE;
        end
        S_1001: begin
            if (!din) begin
                detect = 1'b1;
                next_state = S_10;
            end else begin
                next_state = S_10;
            end
        default: next_state = S_IDLE, detect = 1'b0;
    endcase
end
endmodule

//1.1b Moore Machine
//Tradeoff: Mealy Machines react 1 cycle earlier (final input transition with fewer states)
//However, Mealy require combinational paths added from inputs to ouputs for possible glitch/fault
//Moore Machines outputs are all registered but need an extra clock cycle of latency and an extra/more states
module overlapping_seq_detector (
    input logic clk,
    input logic rst_n,
    input logic din, //input bit
    output logic detect //when 10010 is seen
)

typedef enum logic [2:0] {
    S_IDLE = 3'b000, //nothing
    S_1 = 3'b001, //1
    S_10 = 3'b010, //10
    S_100 = 3'b011, //100
    S_1001 = 3'b100 //1001
    S_10010 = 3'b101 //10010 extra state
} state_t; //type name

state_t current_state, next_state; //2 instances

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current state <= S_IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    case(current_state)
        S_IDLE: begin
            if (din) next_state = S_1;
            else next_state = S_IDLE;
        end
        S_1: begin
            if (!din) next_state = S_10;
            else next_state = S_1; //stays in S1 if another 1 seen
        end
        S_10: begin
            if (!din) next_state = S_100;
            else next_state = S_1;
        end
        S_100: begin
            if (din) next_state = S_1001;
            else next_state = S_IDLE;
        end
        S_1001: begin
            if (!din) next_state = S_10010;
            else next_state = S_1;
        end
        S_10010: begin
            detect = 1'b1;
            next_state = S_10;
        end
        default: next_state = S_IDLE, detect = 1'b0;
    endcase
endmodule

//1.1c Parameterizable Sequence
//As a parameterizable sequence of length n, use a shift register to shift in din
//every cycle and all contents, compare it to a parameter mask to find output or detect

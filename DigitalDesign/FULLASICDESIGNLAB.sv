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
    next_state = current_state;
    detect = 1'b0;
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
        end
        default: next_state = S_IDLE;
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
    next_state = current_state;
    detect = 1'b0;
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
        default: next_state = S_IDLE;
    endcase
end
endmodule

//1.1c Parameterizable Sequence
//As a parameterizable sequence of length n, use a shift register to shift in din
//every cycle and all contents, compare it to a parameter mask to find output or detect

//1.2a MAC Unit
module mac_unit(
    input logic clk,
    input logic rst_n,
    input logic [7:0] a, b,
    output logic [11:0] acc
);
logic [15:0] product;
logic [11:0] next_acc;

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

//1.4a Implement RTL for a fixed priority arbiter, module interface provided
//accepts an N-bit request vector, outputs N-bit grant vector, prioritizes Req 0 to Req N-1


module fixed_priority_arbiter #(
    parameter REQUESTERS = 8
) (
    input logic [REQUESTERS-1:0] reqs,
    output logic [REQUESTERS-1:0] grants,
    output logic grants_valid
);
//Arbiter priority: lowest bit has highest; isolate lowest bit to take info from
//Idea: use a mask to isolate the lowest bit of reqs, then use that to generate grants
//Ex: we need 8'b011010100 -> 8'b00000100, so we need to && with 100101111
//This number is 2's complement of reqs, then & with reqs to isolate lowest bit
assign grants = reqs & (~reqs + 1'b1);
assign grants_valid = |grants; //if any bit is 1, then valid
endmodule

//1.4b Round-robin arbiter, module interface provided, 2 fixed priority arbiters
//Accepts N-bit vector, has a priority_mask and reqs (one arbiter), other general arbiter
module round_robin_arbiter #(
    parameter REQUESTERS = 8
) (
    input logic clk,
    input logic rst_n,
    input logic [REQUESTERS-1:0] reqs,
    output logic [REQUESTERS-1:0] grants,
    output logic grants_valid
);
//In this case, we need to keep track of the last granted request, so we can rotate the priority mask
//The mask can be created to be all bits above the last granted request, then warp to beginning
//We need to keep track of the last granted request
logic [REQUESTERS-1:0] last_grant; //encoding of last granted request
logic [REQUESTERS-1:0] mask, masked_reqs;
logic [REQUESTERS-1:0] unmasked_grants, masked_grants;
logic masked_valid, unmasked_valid;

//isolate last bit (done in fixed prio arbiter) and create mask of bits all bits above it
// ex: 00100000 - 1 -> 00011111 -> ~ -> 11100000, bit 5 is prio
assign mask = ~((last_grant << 1) - 1'b1);

fixed_prio_arbiter #(.REQUESTERS(REQUESTERS)) unmasked_arbiter (
    .reqs(reqs),
    .grants(unmasked_grants),
    .grants_valid(unmasked_valid)
);
assign masked_reqs = reqs & mask; //mask request to only allow those above last grant

fixed_prio_arbiter #(.REQUESTERS(REQUESTERS)) masked_arbiter (
    .reqs(masked_reqs),
    .grants(masked_grants),
    .grants_valid(masked_valid)
);
//anyone in first granted, use result, else use general arbiters
assign grants = masked_valid ? masked_grants : unmasked_grants;
assign grants_valid = masked_valid || unmasked_valid;
//if any grant occurs, update last grant to be current grant
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin   
        last_grant <= 1'b0;
    end else if (grants_valid) begin
        //update last grant to be current grant for loop
        last_grant <= grants;
    end
end

endmodule

//1.4c: concept of starvation: in a fixed_priority arbiter, the lowest priority requester
//may never get granted if higher priority requesters are always requesting a certain resource and getting granted.
//That's the concept of starvation. A round-robin arbiter fixed this because it rotates a priority mask
//so that the lowest priority requester will eventually get granted if it is requesting

//1.4d: round robin arbiter method 2
//rotating request vectors before and after fixed priority arbiter requires more shifters
//increases combinational logic path, delay (frequency slower), and also more area on the chip

//SECTION 2: CDCs
//2.1 Not all modules are run on the same clock domain because across the entire chip, there would be a lot
//of clock skew if we try to connect everything to the same domain (wire lengths differ), and also the wiring 
//would probably be terrible. It also isn't the best for power consumption since the clock signal has to 
//travel across so much internal wire, and also not all parts of chips have to be run at the same frequency.
//Some may be slower, some may be faster. Therefore, different modules of the chip are run on different clock
//domains. However, this introduces CDCs, where signals sent from one clock domain may violate setup or hold of
//another module since they are asynchronous. This causes metastability, where the receiving module may not know if the signal is a 1 or 0
//and may oscillate between the two. This can cause errors in the receiving module. 
//We then use synchronizers to fix this. A 2FF synchronizer solves a lot of problems given that it provides a 
//full clock cycle for the metastable signal to resolve itself before being used in the receiving module. 
//However, it does not guarantee that the signal will resolve itself in time, and therefore there is still a small probability of failure.

//2.2: 10x Faster Producer
//A 2FF synchronizer will sample only on the destination clock edges which means it'll miss many rapid intermediate
//pulses that happen, leading to data los.

//2.3: Buses of values
//For buses of values, individual wire skews can cause bus to be sampled at different times leading to data loss and errors.
//To solve this, we can use FIFO buffers to store data, then use handshake protocols to ensure data is sent and received properly.
//We could also use Gray codes to change data 1 bit at a time, so tha the recieving module can sample the bus at any time.

//2.4 Asynchronous FIFO
//implement ASYNC FIFO like sync FIFO, but with wclk and rclk
//must pass gray-coded pointers across clock domain thru 2FF syncrhonizers
//then compare local pointer to stabilized gray-coded pointer
//Why is comparing your new pointer to an old pointer legal?
//Assume pow-2 FIFO depth and add an elaboration-time to check to your code

module async_fifo #(
    parameter FIFO_DEPTH = 32,
    parameter DATA_W = 16
) (
    input logic rclk, wclk,
    input logic rst_n,

    input logic in_valid,
    output logic in_ready,
    input logic [DATA_W-1:0] w_data,

    input logic out_valid,
    output logic out_ready,
    output logic [DATA_W-1:0] r_data,
);

localparam ADDR_W = $clog2(FIFO_DEPTH);
logic [DATA_W-1:0] mem [FIFO_DEPTH-1:0];

//Now we need to implement graycoded pointers for read and write
//Gray code changes 1 bit at a time
//We have to convert to gray code across clock
//we set gray_next to check if we write this data in, will it be full? if not we are ready
logic [ADDR_W:0] w_ptr_bin, w_ptr_bin_next, w_ptr_gray, w_ptr_gray_next;
logic [ADDR_W:0] r_ptr_bin, r_ptr_bin_next, r_ptr_gray, r_ptr_gray_next;
logic [ADDR_W:0] r2w_ptr_gray, r2w_ptr_gray_sync1;
logic [ADDR_W:0] w2r_ptr_gray, w2r_ptr_gray_sync1;
logic full, empty;

//actually converting
assign w_ptr_bin_next = wptr_bin + (in_valid && in_ready ? 1'b1 : 1'b0);
assign w_ptr_gray_next = w_ptr_bin_next ^ (w_ptr_bin_next >> 1);

//3 things: check if full, ~full inready = 1; check lap bit, check mirror gray code bit, check rest
assign in_ready = {~r2w_ptr_gray[ADDR_W:ADDR_W-1], r2w_ptr_gray[ADDR_W-2:0]};

//writing data and assigning next pointer 
always_ff @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        w_ptr_bin <= 1'0;
        w_ptr_gray <= 1'b0;
    end else if (in_valid && in_ready) begin
        mem[w_ptr_bin[ADDR_W-1:0]] <= w_data;
        w_ptr_bin <= w_ptr_bin_next;
        w_ptr_gray <= w_ptr_gray_next;
    end
end

//READ TO WRITE 2FF Synchronizer for gray coded data; write value is compared to gray coded read value
always_ff @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        r2w_ptr_gray_sync1 <= 1'b0;
        r2w_ptr_gray <= 1'b0;
    end else begin
        r2w_ptr_gray_sync1 <= r_ptr_gray;
        r2w_ptr_gray <= r2w_ptr_gray_sync1;
    end
end

//reading data
assign r_data = mem[r_ptr_bin[ADDR_W-1:0]];
//empty if read = write, because at same lap and position, meaning no unread items remaining
//no need to check lap and mirror bit; just if all bits are equal, then empty
assign out_valid = (r_ptr_gray != w2r_ptr_gray);

assign r_ptr_bin_next = r_ptr_bin + (out_valid && out_ready ? 1'b1 : 1'b0);
assign r_ptr_gray_next = r_ptr_bin_next ^ (r_ptr_bin_next >> 1);

//calculate next read pointers if data is read after handshake
always_ff @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        r_ptr_bin <= 1'b0;
        r_ptr_gray <= 1'b0;
    end else if (out_valid && out_ready) begin
        r_ptr_bin <= r_ptr_bin_next;
        r_ptr_gray <= r_ptr_gray_next;
    end
end

//WRITE TO READ 2FF Synchronizer for gray coded data; read value is compared to gray coded write value
always_ff @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        w2r_ptr_gray_sync1 <= 1'b0;
        w2r_ptr_gray <= 1'b0;
    end else begin
        w2r_ptr_gray_sync1 <= w_ptr_gray;
        w2r_ptr_gray <= w2r_ptr_gray_sync1;
    end
end
endmodule

//2.5 Consumer operates 100MHz, writes syn FIFO for 100 cycles, then stops 200 cycles, then repeats
//Producer operates at 50 MHz, depth of FIFO needed to prevent overflow? Assume no phase shift
//(meaning they come from same clock, 100MHz lines up with 50MHz)
//Consumer freq = 2x producer frequency
//Consumer Period: 1/100MHz = 10ns/cycle, Producer Period = 20ns/cycle
//Time in: 1000 ns, 100 items
//Items Read: 1000ns / 20ns/cycle = 50 items read
//We need to store 50 more items for FIFO storage
//FIFOs need powers of 2 in order for wrap around logic, 64 total entries

//2.6 Assume the synchronous FIFO becomes an asynchronous FIFO; what depth would you choose?
//Justify Reasoning, now we have 2 clock cycles
//64 entries already has room, but we have to account for the latency of converting
//everything to gray codes, so 64 entries would probably still work, to be safe you could
//do 128 entries, but that would introduce area increase; probably test 64 entries first, if 
//overflow, use 128

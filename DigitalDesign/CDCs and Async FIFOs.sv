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

//conversion of binary to gray code function
function automatic [ADDR_W:0] bin2gray(input [ADDR_W:0] bin);
    return bin ^ (bin >> 1);
endfunction

//actually converting
assign w_ptr_bin_next = wptr_bin + (in_valid && in_ready ? 1'b1 : 1'b0);
assign w_ptr_gray_next = bin2gray(w_ptr_bin_next);

//3 things: check if full, ~full inready = 1; check lap bit, check mirror gray code bit, check rest
assign in_ready = ~((w_ptr_gray_next[ADDR_W] != r2w_ptr_gray[ADDR_W])
                  && (w_ptr_gray_next[ADDR_W-1] != r2w_ptr_gray[ADDR_W-1])
                  && (w_ptr_gray_next[ADDR_W-2:0] == r2w_ptr_gray[ADDR_W-2:0]));

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
assign r_ptr_gray_next = bin2gray(r_ptr_bin_next);

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

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

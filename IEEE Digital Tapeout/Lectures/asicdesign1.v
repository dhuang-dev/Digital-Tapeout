// literally a bucnh of bs
//Chip Designer --> Chip Foundry (Fab) --> Chip Verification (Firmware)

//Frontend design includes digital design, architectural design, RTL description (HDL), Functional Verification
//This is ASIC design, lots of design; specification --> design --> RTL
//Lots of writing HDL code

//Background Design; Synthesis, Logic Equivalence Check, Physical Design w/ Gate Level Netlist and GDSII, Floorplanning, Placing and Routing wires
//Wires have their own capacitance, resistance, and inductance. This is physical design
//Logic checks, floor placing (where do things go), routing (how do we connect things), timing analysis, power analysis, etc
//EDA tools are used (Cadence, Synopsys), hard to get hands on though, so digital tapeout lets us get hands on
//W/ semiconductors, photolithography is used to make chips w/ wafers, silicon crystals cut into wafers, then u get a bunch of chips

//FPGA vs ASIC design
//FPGA very quick to prototype, higher to cost, but able to reprogram
//ASIC design when low unit cost and needs high performance; ASIC is fully custom
//higher performance
//For transistors, we have MOSFETs, which are voltage controlled switches; they have a gate, source, and drain. 
//When voltage is applied to the gate, it allows current to flow from source to drain. The channel is the path between source and drain. The gate is insulated from the channel by a thin layer of oxide. The gate voltage controls the conductivity of the channel.
//But transistors have limits, physical boundaries, how do we get them smaller and easier to program




//Synthesizers just basically unlock based off a select line
//example:

always_ff @(posedge clk) begin
    b<=a;
    c<=b;
end
//This case, b takes value a, c takes old value of b
//An 8 to 1 mux case statements, we promise it will always be one of some certain values
//With an if else statement, there can be two things that are true and mux priority takes the first one
//WIth case, we promise only one is true

//An inferred module: you write some RTL, synthesis tool sees, its gonna make a guess on what to do
//Ex: you would infer block memory, flip flops (sensitivity list), look up tables, etc for custom gate logic
//Also latches are inferred; memory elemeents on FPGAs (ROM, BRAM, etc)
//Adders, CLok Gating ELements
//When you don't have a default cause or an end else, you will infer a latch

//Hold and Setup Violation Examples
//A setup violation occurs when the data input to a flip-flop changes too close to the clock edge, causing the flip-flop to potentially capture incorrect data. 
//A hold violation occurs when the data input changes too soon after the clock edge, preventing the flip-flop from properly latching the data. 
//Both violations can lead to unpredictable behavior in digital circuits and must be carefully managed during design and timing analysis.




//For what you design for, these things below matter more than another:

//For Power Analysis: how much power does our design expend/need?
//Important concern in ASICs, low-power designs, etc; for Apple, Samsung, they want low power design
//Two types of Power: Static and Dynamic
//Static Power: power leakage when circuit is idle, transistors leak
//Dynamic Power: power consumed when circuit is active with switching power

//For Performance, how well does our design perform?
//You are things to run fast as possible, take in all data, etc
//Determined by Critical Path (longest time between two flip flops within a circuit) for clock frequency
//Don't clock your designs too fast (setup violation), with a faster frequency, our period improves
//Many ways we can improve:
//Pipelining: ex way with laundry, we need washing, drying,  folding, closet
//If we have 4 roommates, one washes, dries, folds, and puts away clothes in parallel, with one person going to a different machine after the other leaves
//We can basically add a buffer to the critical path where we add another flip flop to reduce the time
//By adding a buffer, we can also add flip flops to combinational logic

//Clock Skewing (ASIC)
//Time borrowing(latches)
//Parallelism (reducing combinational logic depth)
//bunch of other stuff


//For Area, how much hardware does our design take to build?
//Varies based on process, also correlates w/ cost; you can't achieve everything you want, but small amount
//Area is defined as total physical silicon area, consumed by cells, macros, resources
//Combinational logic with gates, muxes, adders, Sequential Elements, MEMORY Macros (SRAMS)

//FSMs (different states transferred between)
//FSMs with counters are difficult - do the design example on the slide
//Moore machines generate outputs based on current state (one cycle), Mealy on current state and inputs

//Design and Verification: designer's responsibility to verify their design and module
//U can do something called concurrent assertions (these are the properties that must be true), write some elements of a testbench

//PRACTICE

//1.2: Latches
// (1)
always_comb begin
  if (sel) y = x;
  else if (enable) y = a;
end
// Latch, Sel = 0, Enable = 0 not defined
// (2)
always_comb begin
  x = in;
  for (integer a = 1; a < 32; a *= 2)
    x ^= x >> a;
end
//No Latch = in at top
// (3)
always_comb begin
  if (en) a[7:4] = b;
  a[3:0] = c;
end
//Latch, en = 0 undef
// (4)
always_comb begin
  for (int i = 0; i < 4; i++)
    if (en[i]) y[i] = a[i];
end
//latch en[i] = 0 undef

//1.3 Pipelining
//Practice 1.3:
//(a) A path has t_clk→Q = 0.25 ns, logic = 2.0 ns, and t_setup = 0.15 ns. What’s fmax? 
//Pipeline the logic into two equal halves and find the new fmax, the speedup, and the added latency.
//ANSWER: T = 0.25 + 2.0 + 0.15 = 2.4 ns, fmax = 1/T = 416.7 MHz; 2 stages, T = 0.25 + 1.0 + 0.15 = 1.4ns;


//(b) You accumulate 100 products of an unsigned 8-bit by an unsigned 6-bit multiplier. 
//What’s the smallest safe accumulator width?
//ANSWER: 8 + 6 = 14, accumulator summing 14 products, 14 + log2(100) + 1 bits = 21 bits

//1.4 FSMs
// Practice 1.4:
//(a) Design the lecture’s slot machine: it takes ten_in and twenty_in, starts the game 
//(start_slots pulses once) when 40 dollars total is reached, and returns any excess 
//in ten-dollar pulses on return_ten. A cancel input returns all bills taken so far, one return_ten pulse at a time, 
//ignoring everything but reset until it finishes. Hints: let the state represent dollars held in tens (0, 10, 20, 30), 
//add a returning state with a down-counter for cancel, and decide how to handle a 20 added at 30 (total 50).
module slot_machine (
    input  logic clk,
    input  logic rst_n,
    input  logic ten_in,
    input  logic twenty_in,
    input  logic cancel,
    output logic start_slots,
    output logic return_ten
);

    // State definitions: Representing money held in tens + refund states
    typedef enum logic [2:0] {
        S_0,          // $0 held
        S_10,         // $10 held
        S_20,         // $20 held
        S_30,         // $30 held
        S_RETURN_10   // Dedicated state to return $10 change (e.g. total hit $50)
    } state_t;

    state_t state, next_state;

    // -------------------------------------------------------------------------
    // 1. Sequential State Register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_0;
        end else begin
            state <= next_state;
        end
    end

    // -------------------------------------------------------------------------
    // 2. Combinational Next-State and Output Logic
    // -------------------------------------------------------------------------
    always_comb begin
        // Default outputs
        next_state  = state;
        start_slots = 1'b0;
        return_ten  = 1'b0;

        case (state)
            // --- $0 HELD ---
            S_0: begin
                if (ten_in)         next_state = S_10;
                else if (twenty_in) next_state = S_20;
            end

            // --- $10 HELD ---
            S_10: begin
                if (cancel) begin
                    return_ten = 1'b1;      // Return $10
                    next_state = S_0;       // All money returned
                end else if (ten_in) begin
                    next_state = S_20;
                end else if (twenty_in) begin
                    next_state = S_30;
                end
            end

            // --- $20 HELD ---
            S_20: begin
                if (cancel) begin
                    return_ten = 1'b1;      // Return $10 step 1
                    next_state = S_10;      // $10 remaining to refund
                end else if (ten_in) begin
                    next_state = S_30;
                end else if (twenty_in) begin
                    start_slots = 1'b1;     // Reached $40 exactly!
                    next_state  = S_0;
                end
            end

            // --- $30 HELD ---
            S_30: begin
                if (cancel) begin
                    return_ten = 1'b1;      // Return $10 step 1
                    next_state = S_20;      // $20 remaining to refund
                end else if (ten_in) begin
                    start_slots = 1'b1;     // Reached $40 exactly!
                    next_state  = S_0;
                end else if (twenty_in) begin
                    start_slots = 1'b1;     // Reached $50 total ($40 spent + $10 excess)
                    next_state  = S_RETURN_10; // Must issue $10 return pulse next!
                end
            end

            // --- RETURN EXPOSED CHANGE STATE ---
            S_RETURN_10: begin
                return_ten = 1'b1;          // Pulse return_ten for $10 change
                next_state = S_0;           // Fully refunded/balanced
            end

            default: next_state = S_0;
        endcase
    end

endmodule



//(b) For an overlapping detector of 110 (Mealy), list the states and every transition with its output.
//we want 110: S0: no output, S1: we have 1, S2: we have 11
//When din = 0, at S0 outputs 0, S1 outputs 0, S2 outputs 1 (ending in 0, current input included)
//When din = 1, at S0 outputs 0, moves to S1, S1 outputs 0, moves to S2, S2 outputs 0, back to S0







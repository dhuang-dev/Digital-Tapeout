//telling us how to get a job: SVA, UVM, debugging, function code coverage, formal verification, logic equivalence checking
//Verification: gives your system inputs, watch your signals change cycle-by cycle, etc
//Dynamic Verification: specify stiumulus, see what outputs are over time
//Static Verification: not time, but checking through mathematical proofs

//SVAs Immediate Assertions vs Concurrent
//Immediate Assertion: checking a value of something
//Most to least severe: $fatal, etc
always_comb begin
    BUSERROR: assert ($onehot(bus_grant)) else $fatal("Bus grant is not one-hot");
end
//checks if busgrant has 1, if not, fatal

//Concurrent Assertion: checking over clocks and times
SUCCESS: assert property (@(posedge clk) disable iff (!rst_n) (in_valid |-> ##[1:3] out_ready));
//this code checks if in_valid is true, then within 1 to 3 cycles, out_ready should be true

//SVA Operators:
//Sequences: Delays ##2, ##[m:n], repetition: [*n] (did something happen n times), [->n] (did something happen n times in a row), [=n] (did something happen n times in a row with no gaps)
//Implication: Overlapping (check on same cycle as trigger): |->, Non-overlapping (check on next cycle after trigger): |=>

//SVA assertions: there are directives
//Assert: validates that design is behaving correctly
//Assume: constraints input, syas you can assume the statement is always true
//Cover: keeps score of whether specfic scenarios or complex sequences actually occured during the test
//Expect: pauses execution of program until specific sequence completes successfully
//ex: if you have a handshake, you wanna check a certain wire, you don't have to run entier thing

//Test Benching: every one needs test cases
//We have a Driver, a reference model that is supposed to have the right case, a monitor that observes output pins, and a score board to check and compare reference results
//UVM: Universal Verification Methodology, a certain package of code used to build test benches, very common in industry
//A Sequencer, Driver, and Monitor make up an Agent, which is a reusable component that can be used in multiple test benches
//The DUT is the Device Under Test, the design you are trying to verify

//UVM example for 2 bit adder, use vivado as simualtors
//ex: standard 2 bit adder ALU
//testbench there are 2 clocking blocks with a posedge and a negedge
//there are class statements that defines a transaction, a driver, a motor, etc
class alu_item extends uvm_sequence_item;
    rand bit [1:0] a, b, op;
    logic [1:0] result;

    `uvm_object_utils(alu_item)

endclass
//example of a transaction, a bunch of stuff talks with each other;
//The phases to building
//Build_phase: configuring comps, connect_phase: wires, end_of_elab: final check of setup, start_of_sim: print initial sim message, run_phase: run the actual thing
//UVM Config DB: lets UVM components connect to other DUTs or non UVM modules
//UVM Factory: entire testbench itself, need to register it within the factory
//How does a simulator work? SV = parallel language, your testbench is sequential: one line at a time;
//splits each time step into infinitesimally small steps of frozen time;
//with the simulator and your SV, there could be nothing wrong with the code, but the simulator runs at a different time than your code, so you have to be careful with the timing of your code and the simulator
//X propogation: x is an unknown state, with metastability, uninitialized values, setup/hold violations, bus contention (if ur trying to write a 0 and 1 to a wire), when u access smthn out of bounds
//X optimisim: simulator treats X like a logical 0 or 1
//X pessimism: when simulator ecnounters X, forces everything else to be an X

//X optimisim is worse bug to have because you possibly don't know if theres an X there or not
//What is State Space: set of all possible states a design can be in
//you states can have memory: register q, q can either be 0 or 1
//for N flip flops: 2^n states
//if you have combinational stuff, theres only 1 state - combinational memory only has 1 state
//when running test, hit as many states as possible; how much of the code did we actually test?
//With coverpoints, all cases we wanna cover for a specific reg; maximal value or minimal value

//Formal Verification (Static Side)
//Math and Boolean Algebra to evaluate state space... and induction
//With Formal, we evaluate all paths at the same time
//Input constraints into the DUT, a partial model of the DUT (for all the right inputs)
//Cone of Influence: all inputs/internal variables influence a checker: very big, so we check the formal core

//Functional Verification:
//Veri/VCS (Synopsys)
//Incisive/Xcelium (Cadence)
//ModelSim/Questa

//Comparing with nonSV models:
//Python: cocotb
//C/C++: DPI-C
//Formal verification tools: JasperGold (Candence), VC Formal (Synopsys), Yosys
//LEC:Formality (Synopsys)

//There is a Github SVA syntax cheatsheet made by Cadence

//SPI Protocol
//SPI slave has blocks for rise/falling edge
//The master should happen across clock domains
//CDCs - u need a synchronizer, need to push an s clock thru the mater itself
//We need to implement SPI Slave: detects when transaction starts, include syncronizer or CDC will happen
//slave runs the same frequency as master

//A PDK: we use a tsmc PDK


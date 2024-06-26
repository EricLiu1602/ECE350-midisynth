# MIDI Synth
## Authors: Annabel Lee & Eric Liu

For ISA specifications and other technical information, see [REFERENCE.md](REFERENCE.md). The rest of this document is scheduled for rennovation.

## Description of Design
This is a 5-stage pipelined processor that implements a reduced version of the MIPS ISA, with custom instructions for audio processing.

I/O wise, it's designed to work on the Nexys A7.

## Pipelining:
This processor follows the Patterson and Hennessey convention of splitting the datapath into Fetch, Decode, Execute, Memory, and Writeback. The IR latches in between each stage latch in the stage's results on the falling edge of the clock.

#### Fetch:
The instruction is fetched from data memory on the rising edge. Data hazard stall is also checked in this location.

#### Decode:
The instruction's control signals are mostly calculated here. The register file is read here, which means that the results of any instruction in the Execute or Memory stage will not be present (the register file is clocked on the rising edge before the falling edge IR latches are clocked on). In the case of a data hazard stall, a bubble in inserted here.

#### Execute:
The majority of calculation takes place here. ALU calculations are made, branches are resolved, etc. This and all previous stages stall in the case of a divide. Results are also bypassed into this stage for both read registers A and B. 

#### Memory:
The RAM is accessed here. Since we aren't dealing with a real computer, there is no need to stall in order to wait on memory results. Results from Writeback may be bypassed into this stage as write data.

#### Writeback:
The results of calculation are written back to the register file on the rising edge of the clock. This means there is a 4 cycle latency for instructions that don't stall.

## Stalling:
This processor implements a Dadda multiplier, which means it does multiplication in 1 cycle. This means this processor stalls in the case of division and for data hazards. For division, the first three stages are essentially frozen until the divider asserts its ready state. This means that nops are inserted into the X/M latch for 32 cycles. In order to avoid bypassing difficulties, data hazards stall only the Fetch and Decode stages, inserting a single nop into Execute, in order to give enough time for an instruction to go throgh.

## Bypassing
Bypass logic is implemented in a separate circuit, but a majority of its effects are felt in the Execute stage. 
It checks to see if any calculation-critical registers are required in earlier stages but haven't been able to write to the register file yet. If it is determined that a bypass is necessary, the value in the latter instruction is swapped out for the result of the earlier instruction. This is possible to do from any stage after Execute to a stage before it. Due to the fact that Writeback writes to the register file before it is read by Decode, the only bypasses necessary for a maximally bypassed processor are from Memory to Execute, Writeback to Execute, and Writeback to Memory. However, this does not cover the case of loading a value from memory and immediately using it, as the loaded value would only be available after the calculation in the Execute stage were complete.

## Optimizations:
This processor implements Dadda multiplication, which executes in a single cycle.

## Inefficiencies:
Division is by far the slowest instruction on this machine--it takes 33 cycles to execute.
There is no branch prediction in this processor--all branches are assumed to be not taken by default. This means that if you are writing a loop in assembly, you should unconditionally jump at the end of every loop instead of branching to the top in order to avoid pipeline flushes.
Using a value immediately after loading it from memory will require the pipeline to stall for a cycle. If desired, you can insert an instruction in between the load and usage for more efficiency.

## Bugs:
I haven't fully tested interactions between subsequent divides, so there may be improper behavior in the case of division by zero and other exception-causing behavior.

## Testing:
Compile the desired assembly file using `asm.exe`, found in the `'Test Files/'` folder. Move the resulting `.mem` file to `Memory Files/`. Change the default `instr_file` and `FILE` fields in `Wrapper.v` and `Wrapper_tb.v`, respectively, to be the name of the assembly file (without the .s). Compile using `filelist.txt` as the control file, setting `Wrapper_tb` to be the top-level module. More info can be found in [in the Test Files folder](/Test%20Files/instructions.txt).
If you will be modifying the assembly a lot, you you can modify `update_and_run.ps1` to automatically assemble and run your code.

**UPDATE** I updated update_and_run to automatically replace the arguments in Wrapper.v and Wrapper_tb.v as well. I asked copilot to write the bash version of that, idk if it actually works.

## TODO:
rennovate document

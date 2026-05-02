# Project Report — Design of an 8-bit Processor

2025-2026

**Authors:** BE • DO

---

## Introduction

This report presents the complete work carried out to design an 8-bit processor in Logisim Evolution. The project was built step by step, starting from logic gates and culminating in a full CPU.

The `cpu8.circ` file contains 17 nested circuits. Rather than following the chronological order of development, this report describes each sub-circuit from the lowest level to the highest. Each section specifies the operation and a test scenario with observed results.

The instruction set we defined is encoded on 14 bits and supports: assigning an immediate value to a register, register-to-register operations (ADD, AND, OR, XOR), loading from RAM, storing to RAM, and unconditional jump (JUMP). Registers R0 to R3 handle 8-bit unsigned data.

---

## 1. Bitwise Logic Units

### 1.1 AND_8_bits
This sub-circuit performs a bitwise AND between two 8-bit buses. It is the first module we designed, using only 2-input, 1-bit AND gates — no high-level components.

**Architecture:** Two splitters decompose each input bus into 8 individual wires. Eight 2-input AND gates compute each output bit in parallel. A reconstruction splitter reassembles the 8 results into an 8-bit output bus.

- **Interface:** Input 1 (8 bits) and Input 2 (8 bits) | Output (8 bits)
- **Components:** 3 splitters (8-bit) + 8 AND gates (1-bit)

**Test & Verification**
- Input 1 = 0b10111001 | Input 2 = 0b11001010
- Observed result = 0b10000000

### 1.2 OR_8_bits
Same architecture as AND, replacing the AND gates with OR gates: 2 input splitters, 8 one-bit OR gates, 1 output splitter.

- **Interface:** Input 1 (8 bits) and Input 2 (8 bits) | Output (8 bits)

**Test & Verification**
- Input 1 = 0b10111001 | Input 2 = 0b11001010
- Result: 0b11111011

### 1.3 XOR_8_bits
Same logic with XOR gates. This module is used both in the 1-bit adder (sum calculation) and in the ALU for register-to-register XOR operations.

- **Interface:** Input 1 (8 bits) and Input 2 (8 bits) | Output (8 bits)

**Test & Verification**
- Input 1 = 0b10111001 | Input 2 = 0b11001010
- Observed result: 0b01110011

### 1.4 UL_setp_2 — Logic Unit
This circuit groups the three previous modules under a single interface. It has two 8-bit inputs (A and B) and simultaneously and continuously produces three outputs: A AND B, A OR B, and A XOR B. This is not yet the final ALU: this module computes all three operations in parallel and leaves the selection of the useful result to a higher-level multiplexer.

- **Interface:** A (8-bit input), B (8-bit input) | AND, OR, XOR (all 8-bit outputs)

**Test & Verification**
- Input: A = 0x0F, B = 0xF0
- Outputs: AND = 0x00 | OR = 0xFF | XOR = 0xFF

---

## 2. 8-bit Adder

### 2.1 Additionneur_1_bit — 1-bit Adder
Before building the 8-bit adder, we designed the foundation: a 1-bit adder with carry-in. This module has three 1-bit inputs (a, b, Rin) and two 1-bit outputs (sum, Rout).

We derived the Boolean equations from the truth table:
- **Sum** = (a XOR b) XOR Rin
- **Rout** = (a AND b) OR (Rin AND (a XOR b))

The Logisim implementation uses only 2-input, 1-bit gates: 4 XOR gates, 4 AND gates, 1 OR gate.

- **Interface:** a (1 bit), b (1 bit), Rin (1 bit) | sum (1 bit), Rout (1 bit)

### 2.2 ADDITIONNEUR_8_bits — 8-bit Adder
Eight instances of Additionneur_1_bit are chained together in a ripple-carry configuration: the carry-out (Rout) of each stage feeds the carry-in (Rin) of the next. The carry-in of the first stage is tied to 0. Two splitters handle bus decomposition and reconstruction.

- **Interface:** A (8 bits), B (8 bits), Rin (1 bit) | Sum (8 bits), Rout (1 bit)

**Test & Verification**
- 0x05 + 0x03 = 0x08 
- 0xFF + 0x01 = 0x00 with Rout=1 (overflow) 

---

## 3. Arithmetic and Logic Unit (ALU)

The ALU integrates the logic unit and the 8-bit adder. A 2-bit OP signal selects the operation:

| OP (bits 12-11) | Operation | Result |
|----------------|-----------|--------|
| 00 | ADD | A + B (8 bits) |
| 01 | AND | A AND B |
| 10 | OR | A OR B |
| 11 | XOR | A XOR B |

Architecturally, the ALU instantiates all sub-modules simultaneously: ADDITIONNEUR_8_bits, AND_8_bits, OR_8_bits, XOR_8_bits. The four results are computed in parallel and fed into a 4-to-1, 2-bit multiplexer. The OP signal selects which of the four 8-bit buses is routed to the output.

- **Interface:** A (8 bits), B (8 bits), OP (2 bits) | Result (8 bits)

> **Note:** Computing all results in parallel and selecting via a multiplexer (rather than sequential paths) simplifies wiring and eliminates any issue between operations: the output is always stable after combinational propagation (no clock needed).

**Test & Verification**
- OP=00: A=0x05, B=0x00 —> Result=0x05 (ADD) 
- OP=01: A=0x05, B=0x00 —> Result=0x00 (AND) 
- OP=10: A=0x00, B=0x05 —> Result=0x05 (OR) 
- OP=11: A=0x05, B=0x05 —> Result=0x00 (XOR) 

---

## 4. Register File

### 4.1 Registre_8_bits — Individual Register
An 8-bit register is built from 8 D flip-flops wired to the same clock bus. Each D flip-flop stores 1 bit: on the rising clock edge, it captures the value present on its D input and holds it on its Q output until the next edge.

A Write Enable (WE) signal controls each flip-flop individually (via the enable input). When WE=0, the flip-flops ignore the clock and the stored value is frozen. When WE=1, the rising clock edge loads the new value. Two splitters frame the flip-flops for bus decomposition and reconstruction.

- **Interface:** Input (8 bits), Clock (1 bit), WE (1 bit) | Output Q (8 bits)

**Test & Verification**
- WE=1, Clock, Input=0x2A —> Q = 0x2A on next cycle 
- WE=0, Clock, Input=0xFF —> Q retains 0x2A 

### 4.2 Banc_4_Registres — 4-Register File
The register file groups four instances of Registre_8_bits (R0, R1, R2, R3). It manages in parallel: writing to the destination register and simultaneously reading two source registers, which is necessary to feed both ALU operands in the same cycle.

Three 2-bit selection signals address the registers: ADDR_RES (destination register for write), ADDR_OP1 (first operand, output A), ADDR_OP2 (second operand, output B).

Writing is orchestrated by 6 four-to-one multiplexers: four muxes generate individual WE signals (only one active at a time based on ADDR_RES + global WE); two muxes select the output values on buses A and B according to OP1 and OP2 addresses.

- **Interface:** E (8 bits, data), ADDR_RES (2 bits), ADDR_OP1 (2 bits), ADDR_OP2 (2 bits), WE (1 bit), Clock | A (8 bits), B (8 bits)

**Test & Verification**
- ADDR_OP1=01 (R1), ADDR_OP2=00 (R0) —> A=0x05, B=0x00 

---

## 5. Processing Unit — UAL_ET_BANC

This circuit assembles the register file and the ALU in a closed loop: the A and B outputs of the register file feed the ALU operands, and the ALU result is fed back to the register file's E input. This is the functional validation step before introducing the ROM.

An input multiplexer allows choosing between the loop (ALU result) and an externally injected constant (useful to initialize a register to a non-zero value, since all registers start at 0x00 at power-up).

The externally exposed control signals are: OP (2 bits), addresses of the two operands, destination address, global WE, and clock. These signals will later be generated automatically by the instruction decoder.

**Test & Verification**
- Cycle 1: Load R1=5 via external multiplexer
- Cycle 2: ADD R2 <— R1+R0, OP=00 —> result 5 stored in R2
- XOR: OP=11, ADDR_OP1=01, ADDR_OP2=10 —> 5 XOR 5 = 0 —> R3=0 

---

## 6. Program Memory and Instruction Decoding

### 6.1 Instruction Format — 14 bits
The 14-bit instruction format we designed is as follows. The encoding was designed so that the decoder is purely combinational, with no internal state.

| Bit 13 | Bits 12-11 | Bits 10-9 | Bits 8-1 | Bit 0 |
|--------|-----------|-----------|---------|-------|
| MODE (1=immediate) | OP (ADD/AND/OR/XOR) | ADDR_RES | VARIABLE FIELD (DATA 8b or ADDR_OP1+OP2) | WE |

- **MODE=1:** Immediate assignment. Bits 8-1 = 8-bit value to load into ADDR_RES. OP is ignored.
- **MODE=0:** Register-to-register operation. Bits 6-5 = source 1 address (LSB), bits 2-1 = source 2 address (LSB). Bits 8-7 and 4-3 are don't-cares (set to 00).

The five test instructions encoded in the ROM are:

| Address | Instruction | 14 bits | Hex |
|---------|------------|---------|-----|
| 0x00 | R1 = 5 | 10001000001011 | 220B |
| 0x01 | R2 = R1 + R0 | 00010000100001 | 0421 |
| 0x02 | R3 = R1 XOR R2 | 01111000100101 | 1E25 |
| 0x03 | R0 = R2 AND R3 | 00100001000111 | 0847 |
| 0x04 | R1 = R0 OR R2 | 01001000000101 | 1205 |

### 6.2 Pointeur_Programme — Program Counter
The Program Counter is an 8-bit register that acts as a counter: on each rising clock edge, it increments by 1 to point to the next instruction. It is wired via an additive constant of 1 fed back to its load input. The initial value on reset is 0x00, corresponding to the first ROM instruction.

- **Interface:** Clock (1 bit), Reset (1 bit) | PC (8 bits, current ROM address)

**Test & Verification**
- Reset=1 —> PC = 0x00 immediately 
- Clock ×5 —> PC: 0x00 —> 0x01 —> 0x02 —> 0x03 —> 0x04 —> 0x05 

### 6.3 Decodage_Instruction — Combinational Decoder
The decoder receives the 14 bits of an instruction read from ROM and directly generates all the control signals needed by the processing unit — no micro-program, no control ROM. It is a combinational circuit made of splitters, NOT gates, AND gates, and a constant.

Field extraction is done by splitters applied to the 14-bit bus:
- Bit 13 —> MODE (immediate or register-to-register)
- Bits 12-11 —> OP (ALU operation, 2 bits)
- Bits 10-9 —> ADDR_RES (destination register, 2 bits)
- Bits 8-1 —> DATA or ADDR_OP1+OP2 (depending on MODE)
- Bit 0 —> WE (write enable)

In immediate mode (MODE=1), the 8-bit DATA directly goes to the register file's E input. In register mode (MODE=0), bits 6-5 and 2-1 provide ADDR_OP1 and ADDR_OP2 respectively.

- **Interface (inputs):** Instruction (14 bits from ROM)
- **Interface (outputs):** OP (2 bits), ADDR_RES (2 bits), ADDR_OP1 (2 bits), ADDR_OP2 (2 bits), WE (1 bit), DATA (8 bits), MODE (1 bit)

**Test & Verification**
- Instruction=0x220B —> MODE=1, ADDR_RES=01(R1), DATA=0x05, WE=1 —> R1 will receive 5 ✓
- Instruction=0x0421 —> MODE=0, OP=00(ADD), ADDR_RES=10(R2), ADDR_OP1=01(R1), ADDR_OP2=00(R0), WE=1 ✓

### 6.4 Etape7_ROM — Complete Processor with ROM
This circuit is the first fully functional complete processor: it integrates the processing unit (UAL_ET_BANC), the instruction decoder (DECODAGE_INSTRUCTION), the ROM, the program counter (Pointeur_Programme), and the data bus multiplexing logic.

The execution flow of an instruction is:
1. The PC provides an address to the ROM.
2. The ROM outputs the 14 bits of the corresponding instruction.
3. The decoder analyzes the instruction and generates all control signals.
4. The processing unit executes the operation (ALU or immediate load).
5. On the rising clock edge, the result is written to the target register and the PC increments.

**Test & Verification**  
ROM program: 220B 0421 1E25 0847 1205
- Cycle 0 (PC=0x00): R1 <— 5
- Cycle 1 (PC=0x01): R2 <— R1+R0 = 5+0 = 5
- Cycle 2 (PC=0x02): R3 <— R1 XOR R2 = 5 XOR 5 = 0
- Cycle 3 (PC=0x03): R0 <— R2 AND R3 = 5 AND 0 = 0
- Cycle 4 (PC=0x04): R1 <— R0 OR R2 = 0 OR 5 = 5
- **Final results: R0=0, R1=5, R2=5, R3=0** 

---

## 7. RAM Extension — ETAPE8_RAM

To go beyond the limitation of four registers, we added a RAM memory accessible for reading (LOAD) and writing (STORE). This extension requires two new instruction types and a LOAD/STORE unit inserted between the decoder and the processing unit.

The three new supported instructions are:
- `LOAD Ri, imm` — immediate load into a register
- `LOAD Ri, @addr` — load from RAM address into register
- `STORE @addr, Ri` — store register value to RAM address

The ETAPE8_RAM circuit integrates: the program ROM (unchanged), the data RAM, the PC, the (extended) decoder with memory access type bits, and two multiplexers. The first multiplexer selects the data source for writing into the register file (ALU result or RAM read). The second multiplexer selects the RAM address.

**Test & Verification**
- STORE @0x02, R1: R1's value written to mem[0x02] —> RAM[0x02] = 0x05 if R1=5 
- LOAD R3, @0x02: R3 <— mem[0x02] = 0x05 
- LOAD R0, 0x12: R0 <— 0x12 (decimal 18) directly 

---

## 8. Branching Instructions — ETAPE9_JUMP

### 8.1 Pointeur_Programme_JMP
The original Program Counter is a simple +1 counter. To support jumps, we extended it with an 8-bit multiplexer that chooses, at each cycle, between two next-PC values: PC+1 or a jump address provided by the decoder.

A JUMP control signal (1 bit) selects the multiplexer input. When JUMP=0, the PC increments normally. When JUMP=1, the PC loads the target address encoded in the instruction.

- **Interface:** Clock, Reset, JUMP_ADDR (8 bits), JUMP (1 bit) | PC (8 bits)

**Test & Verification**
- JUMP=0: normal counter behavior, PC++ 
- JUMP=1, JUMP_ADDR=0x00: PC <— 0x00 (return to program start) 
- JUMP=1, JUMP_ADDR=0x03: PC <— 0x03 (direct jump to address 3) 

### 8.2 Decodage_Instruction_JUMP
This decoder incorporates all of DECODAGE_INSTRUCTION and adds JUMP type handling. An additional splitter extracts the instruction type bits. Additional combinational AND/NOT logic detects JUMP and generates the JUMP signal sent to POINTEUR_PROGRAMME_JMP, as well as the target address extracted from the variable field bits. The JUMP bit replaces the padding bit.

When a JUMP instruction is present, the WE signal is forced to 0 (no register write) and JUMP=1 is emitted. The target address is read directly from bits 2-9 of the instruction (8 bits), allowing jumps to any ROM address (0x00 to 0xFF).

Outputs: **JUMP** (1 bit) and **JUMP_ADDR** (8 bits)

### 8.3 ETAPE9_JUMP — Final Complete Processor
This circuit is the final processor: it integrates all previous modules (processing unit, ROM, RAM, JUMP decoder, PC). It is capable of executing a program with loops and unconditional jumps.

The RAM is still present (same LOAD/STORE as in step 8). The register file data input multiplexer now supports three sources: ALU result, RAM read, and direct data — the decoder drives this multiplexer via its instruction type bits.

The behavior during a cycle with JUMP:
1. The PC provides the JUMP instruction address to the ROM.
2. The decoder detects the JUMP opcode, extracts the target address, emits JUMP=1 and WE=0.
3. The PC multiplexer selects the target address instead of PC+1.
4. On the clock edge, the PC loads the new address. No register is modified.
5. On the next cycle, execution resumes at the new address.

**Test & Verification**  
Program: 220B (R1<—5), 0421 (R2<—R1+R0), JUMP 0x00
- Cycle 0: R1=5
- Cycle 1: R2=5
- Cycle 2: JUMP —> PC <— 0x00 (infinite loop)
- Cycle 3: R1 reloaded to 5 (loop verified over multiple cycles) 

---

## Conclusion

We started from a 1-bit AND gate and arrived at a complete 8-bit processor with a program memory (ROM), data memory (RAM), and support for unconditional branching. Each abstraction layer — from the logic gate to the ALU module, then from the decoder to the PC — was built and tested independently before being integrated into higher levels.

**Possible improvements:**
- Add conditional branch instructions (JUMP IF ZERO, JUMP IF CARRY) by exploiting ALU flags
- Extend the register file to 8 registers
- Implement a simple pipeline

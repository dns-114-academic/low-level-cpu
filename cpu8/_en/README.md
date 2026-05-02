# 8-bit CPU Project — Logisim Evolution


**Year:** 2025-2026  
**Authors:** EB • DO

---

## Description

Design of a fully functional **8-bit processor** built in **Logisim Evolution**, constructed step by step from elementary logic gates up to a complete CPU supporting ROM, RAM, and unconditional branching.

The `cpu8.circ` file contains **17 nested circuits**. The instruction set is encoded on **14 bits** and supports:
- Immediate value assignment into a register
- Register-to-register operations: **ADD, AND, OR, XOR**
- Loading from RAM (**LOAD**)
- Storing to RAM (**STORE**)
- Unconditional jump (**JUMP**)

Registers R0 to R3 operate on **8-bit unsigned** data.

---

## Project Structure

```
cpu8/
├── cpu8.circ               # Main Logisim file (17 sub-circuits)
├── rapport_cpu8.pdf        # Project report (PDF, French)
├── tests/
│   ├── _README.md                    # Test guide
│   ├── rom_etape7.hex                # ROM program – Step 7 (basic CPU)
│   ├── rom_etape8_sans_jump.hex      # ROM program – Step 8 (with RAM)
│   ├── rom_etape9_avec_jump.hex      # ROM program – Step 9 (with JUMP)
│   ├── ram_etape8_init.hex           # Initial RAM state – Step 8
│   └── ram_etape9_init.hex           # Initial RAM state – Step 9
└── _en/
    ├── README.md                     # This file
    └── rapport_cpu8_en.md            # Project report (English translation)
```

---

## Sub-circuit Architecture

| Step | Sub-circuit | Role |
|------|------------|------|
| 1 | AND_8_bits, OR_8_bits, XOR_8_bits | Bitwise logical operations |
| 1 | UL_setp_2 | Combined logic unit |
| 2 | Additionneur_1_bit | 1-bit adder with carry |
| 2 | ADDITIONNEUR_8_bits | 8-bit ripple-carry adder |
| 3 | UAL | Full Arithmetic and Logic Unit (ALU) |
| 4 | Registre_8_bits | Individual 8-bit register (8× D flip-flop) |
| 4 | Banc_4_Registres | 4-register bank (R0–R3) |
| 5 | UAL_ET_BANC | ALU + register bank in closed loop |
| 6 | Pointeur_Programme | Program Counter (PC) |
| 6 | Decodage_Instruction | Combinational instruction decoder |
| 6 | Etape7_ROM | Complete processor with ROM |
| 7 | ETAPE8_RAM | RAM extension (LOAD/STORE) |
| 8 | Pointeur_Programme_JMP | PC with JUMP support |
| 8 | Decodage_Instruction_JUMP | Extended decoder (JUMP) |
| 8 | ETAPE9_JUMP | Final complete processor |

---

## Instruction Format (14 bits)

| Bit 13 | Bits 12-11 | Bits 10-9 | Bits 8-1 | Bit 0 |
|--------|-----------|-----------|---------|-------|
| MODE (1=immediate) | OP (ADD/AND/OR/XOR) | ADDR_RES | DATA or ADDR_OP1+OP2 | WE |

---

## Prerequisites & Usage

1. Download [Logisim Evolution](https://github.com/logisim-evolution/logisim-evolution/releases)
2. Open `cpu8.circ`
3. Load the appropriate `.hex` file into the ROM (and RAM for steps 8/9)
4. Run the simulation using the clock

---

## Report

The full report (in English) details each sub-circuit, its interface, behavior, and verification tests.  
→ `rapport_cpu8_en.md` (English) | `../rapport_cpu8.pdf` (French PDF)

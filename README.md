# Low-level Programming & CPU Architecture

**Course project** | ENSIBS — Jan.–Apr. 2026 | MASM x86, Logisim

## Overview

Two-part project exploring computing at the lowest level: 32-bit x86 assembly programming and full CPU design in Logisim.

## Part 1 — x86 Assembly (MASM)

Recursive `DIR /S` clone for Windows:
- **CLI mode** — directory tree traversal with file listing and statistics
- **GUI mode** — Win32 API window with list view
- Direct Win32 API calls (`FindFirstFile`, `FindNextFile`, `CreateWindowEx`, ...)
- No macros — pure 32-bit MASM
- Recursive implementation using the call stack

## Part 2 — CPU Design (Logisim)

Full microprocessor implementation:
- **ALU** — arithmetic and logic operations with flags (Zero, Carry, Overflow, Sign)
- **Register file** — general-purpose registers
- **ROM/RAM** — instruction memory and data memory
- **Control unit** — instruction decoding and signal generation
- **Fetch-Decode-Execute** cycle

## Stack

`MASM x86` · `Win32 API` · `Logisim` · `Assembly`

---

*Academic project — école d'ingénieurs*

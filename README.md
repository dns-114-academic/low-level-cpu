# x86 Assembly & Digital Logic Projects — MASM32 / Logisim

This repository contains two independent projects built in x86 32-bit assembly (MASM32) and digital logic simulation (Logisim):

1. **Recursive Directory Explorer** — a CLI and GUI application that traverses a Windows directory tree
2. **Mini Microprocessor** *(coming soon)* — a simple microprocessor designed and simulated in Logisim

---

## Directory tree

```
.
├── recursive-directory-explorer/
│   ├── src/
│   │   ├── main.asm        # CLI version — console subsystem
│   │   ├── gui.asm         # GUI version — Windows subsystem
│   │   ├── build_cli.bat   # Build script for main.asm
│   │   └── build_gui.bat   # Build script for gui.asm
│   └── reports/
│       ├── rapport_fr.pdf  # Project report (French)
│       ├── report_en.pdf   # Project report (English)
│       ├── rapport_fr.tex  # LaTeX source (French)
│       └── report_en.tex   # LaTeX source (English)
├── mini-microprocessor/    # Logisim project (coming soon)
│   └── ...
└── README.md
```

---

## Project 1 — Recursive Directory Explorer

### Components

| File | Version | Description |
|---|---|---|
| `main.asm` | CLI | Reads a path from stdin, recursively lists all entries to stdout |
| `gui.asm` | GUI | Win32 window with a TextBox, a Browse button, and a read-only results area |
| `build_cli.bat` | — | Assembles and links `main.asm` with `/SUBSYSTEM:CONSOLE` |
| `build_gui.bat` | — | Assembles and links `gui.asm` with `/SUBSYSTEM:WINDOWS` |

### Requirements

- **Windows** (32-bit or 64-bit with WOW64)
- **MASM32 SDK** installed at `C:\masm32\` — download from [masm32.com](http://www.masm32.com/)

No Python, no third-party libraries, no runtime other than the standard Win32 API (`kernel32.dll`, `user32.dll`, `gdi32.dll`).

### How to build

**CLI version**
```bat
cd recursive-directory-explorer/src
build_cli.bat
```
Produces `main.exe` via:
```bat
c:\masm32\bin\ml /c /Zd /coff main.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE main.obj
```

**GUI version**
```bat
cd recursive-directory-explorer/src
build_gui.bat
```
Produces `gui.exe` via:
```bat
c:\masm32\bin\ml /c /Zd /coff gui.asm
c:\masm32\bin\Link /SUBSYSTEM:WINDOWS gui.obj
```

### How to run

**CLI**
```
main.exe
Path: C:\Windows\System32
```
Prints a header for each directory visited, followed by all entries within it.

**GUI** — Launch `gui.exe`. A 900 × 600 window appears with a path input, a Browse button, and a scrollable results area showing the directory tree indented by depth level (one TAB per level).

### Design notes

Both versions share the same core algorithm: an **iterative depth-first traversal** using a statically allocated path stack (`stackPaths`, 60 × 260 bytes). Key decisions:

- **Static stack** capped at 60 levels — covers the vast majority of real Windows trees.
- **`dword ptr findData`** for `dwFileAttributes` — a direct compile-time address corrupted the `.obj` file during early testing.
- **Explicit `.`/`..` filtering** — always present in every Windows directory, would cause an infinite loop if not skipped.
- **Batch display (GUI)** — results accumulate in a 32 000-byte `resultBuffer`, flushed in one `SetWindowTextA` call.
- **Depth stack (GUI only)** — `stackDepths` tracks the depth of each pushed path to drive hierarchical TAB indentation.

---

## Project 2 — Mini Microprocessor *(Logisim)*

> Work in progress — files will be added to `mini-microprocessor/`.

A minimal microprocessor designed from scratch in [Logisim](http://www.cburch.com/logisim/). Details on architecture, instruction set, and usage will be documented here once the project is complete.

### Requirements *(anticipated)*

- **Logisim** or **Logisim Evolution** — download from [github.com/logisim-evolution](https://github.com/logisim-evolution/logisim-evolution)

---

## References

- [MASM32 SDK](http://www.masm32.com/)
- Microsoft Win32 API: `FindFirstFileA`, `FindNextFileA`, `FindClose`, `CreateWindowExA`, `RegisterClassExA`
- [WIN32_FIND_DATAA structure (MSDN)](https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-win32_find_dataa)
- [Logisim Evolution](https://github.com/logisim-evolution/logisim-evolution)

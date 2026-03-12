# Recursive Directory Explorer — x86 32-bit Assembly (MASM32)

Two programs that recursively traverse a Windows directory tree and display every file and folder found: one CLI application and one GUI application, both written in x86 32-bit assembly using MASM32.

---

## Directory tree

```
recursive-directory-explorer/
├── src/
│   ├── main.asm        # CLI version — console subsystem
│   ├── gui.asm         # GUI version — Windows subsystem
│   ├── build_cli.bat   # Build script for main.asm
│   └── build_gui.bat   # Build script for gui.asm
├── reports/
│   ├── rapport_fr.pdf  # Project report (French)
│   ├── report_en.pdf   # Project report (English)
│   ├── rapport_fr.tex  # LaTeX source (French)
│   └── report_en.tex   # LaTeX source (English)
└── README.md
```

---

## Components

| File | Version | Description |
|---|---|---|
| `main.asm` | CLI | Reads a path from stdin, recursively lists all entries to stdout |
| `gui.asm` | GUI | Win32 window with a TextBox, a Browse button, and a read-only results area |
| `build_cli.bat` | — | Assembles and links `main.asm` with `/SUBSYSTEM:CONSOLE` |
| `build_gui.bat` | — | Assembles and links `gui.asm` with `/SUBSYSTEM:WINDOWS` |

---

## Requirements

- **Windows** (32-bit or 64-bit with WOW64)
- **MASM32 SDK** installed at `C:\masm32\` — download from [masm32.com](http://www.masm32.com/)

No Python, no third-party libraries, no runtime other than the standard Win32 API (`kernel32.dll`, `user32.dll`, `gdi32.dll`).

---

## How to build

### CLI version

```bat
cd src
build_cli.bat
```

This runs:
```bat
c:\masm32\bin\ml /c /Zd /coff main.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE main.obj
```

Expected output: `main.exe` in `src\`.

### GUI version

```bat
cd src
build_gui.bat
```

This runs:
```bat
c:\masm32\bin\ml /c /Zd /coff gui.asm
c:\masm32\bin\Link /SUBSYSTEM:WINDOWS gui.obj
```

Expected output: `gui.exe` in `src\`.

---

## How to run

### CLI

```
main.exe
Path: C:\Windows\System32
```

The program prints a header for each directory visited, followed by the names of all entries within it:

```
Directory: C:\Windows\System32
ntdll.dll
kernel32.dll
...

Directory: C:\Windows\System32\drivers
...
```

### GUI

Launch `gui.exe`. A 900 × 600 window appears with:

- A **path input** TextBox pre-filled with a default path
- A **Browse** button — click it to start the scan
- A **scrollable results area** showing the full directory tree, indented by depth level (one TAB per level)

---

## Design notes

Both versions share the same core algorithm: an **iterative depth-first traversal** implemented with a statically allocated stack (`stackPaths`, 60 × 260 bytes). Recursion through function calls is deliberately avoided to prevent call-stack overflows on deep trees.

Key design decisions:
- **Static stack** sized for 60 levels — sufficient for the vast majority of real Windows trees.
- **`dword ptr findData`** (symbolic address) for `dwFileAttributes` — using a direct compile-time address corrupted the `.obj` file during early testing.
- **Explicit `.`/`..` filtering** — these entries are always present in every Windows directory and would cause an infinite loop if not skipped.
- **Batch display (GUI)** — all results are accumulated in a 32 000-byte `resultBuffer` and sent to the results area in a single `SetWindowTextA` call, rather than line-by-line as in the CLI.
- **Depth stack (GUI only)** — a second stack (`stackDepths`) tracks the depth of each pushed path so that `AddFileNameToResult` can insert the correct number of TABs for hierarchical indentation.

---

## References

- [MASM32 SDK](http://www.masm32.com/)
- Microsoft Win32 API: `FindFirstFileA`, `FindNextFileA`, `FindClose`, `CreateWindowExA`, `RegisterClassExA`
- [WIN32_FIND_DATAA structure (MSDN)](https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-win32_find_dataa)

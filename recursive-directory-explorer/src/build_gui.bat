@echo off
REM Build script for GUI version (gui.asm)
c:\masm32\bin\ml /c /Zd /coff gui.asm
c:\masm32\bin\Link /SUBSYSTEM:WINDOWS gui.obj
pause

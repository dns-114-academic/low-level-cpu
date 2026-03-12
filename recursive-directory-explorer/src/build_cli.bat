@echo off
REM Build script for CLI version (main.asm)
c:\masm32\bin\ml /c /Zd /coff main.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE main.obj
pause

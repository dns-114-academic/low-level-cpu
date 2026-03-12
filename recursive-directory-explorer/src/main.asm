.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\gdiplus.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\msvcrt.lib


.data
adr1B               db 'Path: ',0              ; prompt displayed to the user
msgSearchError      db 'Error: no file found',13,10,0
msgNewLine          db 13,10,0
msgDirectory        db 13,10,'Directory: ',0   ; header for each visited directory
searchPattern       db '\*.*',0                ; wildcard pattern for FindFirstFileA


.data?
stdOut              dd ?    ; handle for stdout (4 bytes)
stdIn               dd ?    ; handle for stdin
bytesRead           dd ?    ; number of bytes read by ReadFile
path                db 260 dup(?)   ; user-entered path (260 bytes: 256 + drive + colon + slash + null)
searchPath          db 520 dup(?)   ; path + "\*.*" passed to FindFirstFileA
findData            db 320 dup(?)   ; WIN32_FIND_DATAA structure
hFind               dd ?            ; search handle returned by FindFirstFileA
pathLength          dd ?            ; length of the current path string
fileCounter         dd ?            ; number of entries found

; Iterative recursion stack
stackPaths          db 15600 dup(?) ; path stack (60 paths x 260 bytes) — depth capped at 60
stackPtr            dd ?            ; stack top pointer (index of next free slot)
currentPath         db 260 dup(?)   ; path currently being processed
tempBuffer          db 260 dup(?)   ; temporary buffer used for path concatenation


.code
start:

    ; --- Acquire console handles ---

    push -11                        ; STD_OUTPUT_HANDLE constant
    call GetStdHandle               ; kernel32.dll — returns handle in eax
    mov stdOut, eax                 ; save stdout handle

    push -10                        ; STD_INPUT_HANDLE constant
    call GetStdHandle               ; kernel32.dll
    mov stdIn, eax                  ; save stdin handle (keyboard)


    ; --- Display "Path: " prompt ---
    push 0                          ; lpOverlapped = NULL
    push offset bytesRead           ; lpNumberOfBytesWritten
    push 6                          ; nNumberOfBytesToWrite (length of "Path: ")
    push offset adr1B               ; lpBuffer = address of prompt string
    push stdOut                     ; hFile = stdout handle
    call WriteFile                  ; kernel32.dll


    ; --- Read user input ---
    push 0
    push offset bytesRead
    push 260                        ; nNumberOfBytesToRead (max buffer size)
    push offset path                ; lpBuffer = destination buffer
    push stdIn                      ; hFile = stdin handle
    call ReadFile                   ; kernel32.dll — reads characters from keyboard


    ; Strip trailing CR LF (ReadFile appends 2 bytes: 0x0D 0x0A)
    mov ecx, bytesRead              ; copy byte count into ecx
    sub ecx, 2                      ; subtract 2 to remove CR LF
    mov byte ptr [path + ecx], 0    ; null-terminate the string
    mov pathLength, ecx             ; save effective path length


    ; --- Initialise recursion stack ---
    mov stackPtr, 0                 ; stack is empty (index = 0)

    ; Push the initial path onto the stack
    mov esi, offset path            ; source = user-entered path
    mov edi, offset stackPaths      ; destination = base of stack
    mov ecx, pathLength             ; number of bytes to copy

push_initial:
    mov al, byte ptr [esi]          ; copy one byte at a time
    mov byte ptr [edi], al
    inc esi
    inc edi
    dec ecx
    jnz push_initial                ; loop while ecx != 0

    mov byte ptr [edi], 0           ; append null terminator
    mov stackPtr, 260               ; advance stack pointer (1 path = 260 bytes)


    ; --- Main loop: process every stacked path ---

boucle_stack:
    ; Check whether the stack is empty
    mov eax, stackPtr
    cmp eax, 0                      ; stackPtr == 0 ?
    jz fin_recursion                ; if so, all directories have been processed


    ; Pop: retrieve one path from the stack
    sub stackPtr, 260               ; decrement pointer (move back one slot)

    mov eax, stackPtr               ; eax = byte offset of last pushed path
    lea esi, [stackPaths + eax]     ; esi = address of that path in the stack
    mov edi, offset currentPath     ; edi = destination buffer
    mov ecx, 260                    ; copy at most 260 bytes

pop_chemin:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0                       ; end of string?
    jz pop_termine                  ; yes — copy complete
    inc esi
    inc edi
    dec ecx
    jnz pop_chemin

pop_termine:
    ; currentPath now holds the directory to explore

    ; Print "\r\nDirectory: "
    push 0
    push offset bytesRead
    push 13                         ; length of "\r\nDirectory: " (2 + 11)
    push offset msgDirectory
    push stdOut
    call WriteFile

    ; Compute the length of currentPath
    mov esi, offset currentPath
    mov ecx, 0                      ; character counter

calc_longueur_courant:
    mov al, byte ptr [esi + ecx]
    cmp al, 0                       ; null terminator?
    jz longueur_courant_trouvee
    inc ecx
    jmp calc_longueur_courant

longueur_courant_trouvee:
    ; ecx = length of currentPath — print it
    push 0
    push offset bytesRead
    push ecx
    push offset currentPath
    push stdOut
    call WriteFile

    ; Print newline
    push 0
    push offset bytesRead
    push 2
    push offset msgNewLine
    push stdOut
    call WriteFile


    ; --- Build the search pattern: currentPath + "\*.*" ---
    mov esi, offset currentPath
    mov edi, offset searchPath

copier_courant:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0                       ; null?
    jz fin_copie_courant
    inc esi
    inc edi
    jmp copier_courant

fin_copie_courant:
    ; edi now points at the null of searchPath
    ; Ensure the path ends with '\'
    dec edi                         ; step back onto the last character
    mov al, byte ptr [edi]
    cmp al, '\'
    je ajouter_motif_recursif       ; already has '\', skip adding one

    ; Append '\'
    inc edi                         ; move back to null position
    mov byte ptr [edi], '\'
    inc edi

ajouter_motif_recursif:
    ; Append "*.*" (4 bytes including null)
    mov esi, offset searchPattern
    mov ecx, 4

copier_motif_recursif:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    inc esi
    inc edi
    dec ecx
    jnz copier_motif_recursif


    ; --- Find first file matching the pattern ---
    push offset findData            ; lpFindFileData
    push offset searchPath          ; lpFileName (pattern)
    call FindFirstFileA             ; kernel32.dll
    mov hFind, eax                  ; save search handle


    ; --- Inner loop: iterate over every entry in the current directory ---

boucle_fichiers:
    ; Filter "." and ".." (always present in every directory — skipping them
    ; prevents an infinite recursion loop)
    lea esi, [findData+44]          ; esi = cFileName (offset 44 in WIN32_FIND_DATAA)
    mov al, byte ptr [esi]          ; al = first character
    cmp al, '.'
    jne pas_point                   ; not a dot — process normally

    mov al, byte ptr [esi+1]
    cmp al, 0                       ; just "." ?
    je fichier_suivant              ; skip

    cmp al, '.'
    jne pas_point

    mov al, byte ptr [esi+2]
    cmp al, 0                       ; just ".." ?
    je fichier_suivant              ; skip

pas_point:
    ; Check FILE_ATTRIBUTE_DIRECTORY flag (bit 4 = 0x10)
    ; Note: reading dwFileAttributes via dword ptr avoids the direct-address
    ; issue that caused the .obj file to disappear during early testing.
    mov eax, dword ptr findData     ; eax = dwFileAttributes (offset 0)
    and eax, 10h                    ; mask directory bit
    jz pas_dossier                  ; flag absent => regular file

    ; --- It is a subdirectory: build its full path ---
    mov esi, offset currentPath
    mov edi, offset tempBuffer

concat_base:
    ; Copy currentPath into tempBuffer
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0                       ; null?
    jz base_copiee
    inc esi
    inc edi
    jmp concat_base

base_copiee:
    ; edi is on the null — ensure a trailing '\'
    dec edi                         ; step back to last character
    mov al, byte ptr [edi]
    cmp al, '\'
    je concat_nom_dossier

    inc edi                         ; back to null position
    mov byte ptr [edi], '\'
    inc edi

concat_nom_dossier:
    ; Append the subdirectory name
    lea esi, [findData+44]          ; source = cFileName

concat_nom_loop:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0                       ; null?
    jz concat_termine
    inc esi
    inc edi
    jmp concat_nom_loop

concat_termine:
    ; Push tempBuffer (full subdirectory path) onto the stack
    mov eax, stackPtr
    cmp eax, 15600                  ; overflow check (60 * 260 bytes)
    jge pas_dossier                 ; stack full — skip this directory

    lea edi, [stackPaths + eax]     ; destination slot in stack
    mov esi, offset tempBuffer      ; source = full path

push_dossier:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0
    jz push_termine
    inc esi
    inc edi
    jmp push_dossier

push_termine:
    add stackPtr, 260               ; advance stack pointer by one slot


pas_dossier:
    ; --- Print the entry name (file or directory) ---
    lea esi, [findData+44]          ; start of filename
    mov edi, esi
    mov ecx, 260

chercher_null:
    cmp byte ptr [edi], 0
    je trouve_null
    inc edi
    dec ecx
    jnz chercher_null

trouve_null:
    sub edi, esi                    ; edi = length of filename string
    mov ecx, edi                    ; ecx = length

    ; Print filename
    push 0
    push offset bytesRead
    push ecx                        ; nNumberOfBytesToWrite
    lea eax, [findData+44]
    push eax                        ; lpBuffer = cFileName
    push stdOut
    call WriteFile                  ; kernel32.dll

    ; Print newline
    push 0
    push offset bytesRead
    push 2
    push offset msgNewLine
    push stdOut
    call WriteFile

    inc fileCounter                 ; increment entry counter


fichier_suivant:
    ; Advance to the next entry in the current directory
    push offset findData
    push hFind
    call FindNextFileA              ; kernel32.dll
    cmp eax, 0
    jnz boucle_fichiers             ; non-zero = more entries exist


    ; Close the search handle for the current directory
    push hFind
    call FindClose                  ; kernel32.dll


    ; Return to the main stack loop — process the next stacked path
    jmp boucle_stack


    ; --- End of traversal ---

fin_recursion:
    push 0                          ; exit code 0 = success
    call ExitProcess                ; kernel32.dll


end start

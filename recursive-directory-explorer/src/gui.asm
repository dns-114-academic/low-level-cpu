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
    ; Window class and application identity
    szClassName     db "FileExplorerApp",0              ; window class name
    szAppName       db "Recursive File Explorer",0      ; application title bar
    szEditClass     db "EDIT",0                         ; TextBox control class
    szButtonClass   db "BUTTON",0                       ; Button control class
    szStaticClass   db "STATIC",0                       ; Label control class
    szOKButton      db "Browse",0                       ; button label
    szDefaultInput  db "C:\Users\user",0                ; default path shown in the TextBox

    ; Search patterns and messages
    searchPattern   db '\*.*',0         ; wildcard pattern for FindFirstFileA
    msgNewLine      db 13,10,0          ; CR LF newline
    adr1B           db 'Path: ',0       ; "Path: " label string
    msgSearchError  db 'Error: no file found',13,10,0  ; error message when search fails


.data?
    ; Window and control handles
    hInstance       dd ?    ; application instance handle
    hWnd            dd ?    ; main window handle
    hEdit           dd ?    ; TextBox control handle (path input)
    hButton         dd ?    ; Button control handle ("Browse")
    hResult         dd ?    ; Results area control handle (read-only multiline edit)

    ; File-search variables
    path            db 260 dup(?)   ; user-entered path (260 bytes)
    searchPath      db 520 dup(?)   ; path + "\*.*" passed to FindFirstFileA
    findData        db 320 dup(?)   ; WIN32_FIND_DATAA structure (320 bytes)
    hFind           dd ?            ; search handle returned by FindFirstFileA
    pathLength      dd ?            ; length of the current path string
    fileCounter     dd ?            ; total number of entries found
    currentDepth    dd ?            ; depth of the current directory (0 = root)

    ; Iterative recursion stacks
    stackPaths      db 15600 dup(?) ; path stack (60 paths x 260 bytes, max depth = 60)
    stackPtr        dd ?            ; path stack top pointer (index of next free slot)
    stackDepths     db 240 dup(?)   ; depth stack (60 depths x 4 bytes)
    depthPtr        dd ?            ; depth stack top pointer

    currentPath     db 260 dup(?)   ; path currently being processed (popped from stack)
    tempBuffer      db 260 dup(?)   ; temporary buffer for path concatenation

    ; Result buffer for the GUI display area
    resultBuffer    db 32000 dup(?) ; accumulates all text to display (32 000 bytes)
    resultPtr       dd ?            ; current write position within resultBuffer

.code

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; start: Application entry point — initialise GUI and run message loop
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
start:
    ; Retrieve the current application instance handle
    push 0
    call GetModuleHandleA           ; kernel32.dll
    mov hInstance, eax              ; save instance handle

    ; Register the window class (style, procedure, icon, cursor, background)
    call RegisterWindowClass
    test eax, eax                   ; eax == 0 means failure
    je exit_app                     ; exit on error

    ; Create the main window
    call CreateMainWindow
    test eax, eax                   ; eax == 0 means failure
    je exit_app                     ; exit on error
    mov hWnd, eax                   ; save main window handle

    ; Make the window visible (SW_SHOW = 5)
    push SW_SHOW
    push hWnd
    call ShowWindow                 ; user32.dll

    ; Force an immediate repaint
    push hWnd
    call UpdateWindow               ; user32.dll


    ; --- Main message loop ---
message_loop:
    sub esp, 28                     ; allocate space for MSG structure on the stack
    mov ebx, esp                    ; ebx = pointer to MSG

    ; Retrieve the next message from the thread message queue
    push 0                          ; wMsgFilterMax = 0 (no filter)
    push 0                          ; wMsgFilterMin = 0
    push 0                          ; hWnd = NULL (all windows of this thread)
    push ebx                        ; lpMsg = pointer to MSG
    call GetMessageA                ; user32.dll — returns 0 on WM_QUIT

    test eax, eax                   ; eax == 0 => WM_QUIT received
    je end_message_loop             ; exit loop

    ; Translate virtual-key messages into character messages
    push ebx
    call TranslateMessage           ; user32.dll

    ; Dispatch message to the appropriate window procedure
    push ebx
    call DispatchMessageA           ; user32.dll

    add esp, 28                     ; release MSG structure from stack
    jmp message_loop                ; continue loop


end_message_loop:
    add esp, 28                     ; restore stack pointer

exit_app:
    ; Terminate the process (exit code 0 = success)
    push 0
    call ExitProcess                ; kernel32.dll


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; RegisterWindowClass: register the window class with the OS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
RegisterWindowClass:
    push edi
    sub esp, 48                     ; allocate 48 bytes for WNDCLASSEX (12 DWORDs)
    mov edi, esp                    ; edi = pointer to WNDCLASSEX

    ; Populate WNDCLASSEX fields
    mov dword ptr [edi],    48                      ; cbSize = sizeof(WNDCLASSEX)
    mov dword ptr [edi+4],  CS_HREDRAW or CS_VREDRAW ; style = redraw on resize
    lea eax, WndProc
    mov dword ptr [edi+8],  eax                     ; lpfnWndProc = WndProc address
    mov dword ptr [edi+12], 0                       ; cbClsExtra = 0
    mov dword ptr [edi+16], 0                       ; cbWndExtra = 0
    mov eax, hInstance
    mov dword ptr [edi+20], eax                     ; hInstance

    ; Load standard application icon
    push 0
    call GetModuleHandleA           ; kernel32.dll
    push IDI_APPLICATION            ; standard app icon ID
    push eax
    call LoadIconA                  ; user32.dll
    mov dword ptr [edi+24], eax     ; hIcon

    ; Load standard arrow cursor
    push IDC_ARROW
    push 0
    call LoadCursorA                ; user32.dll
    mov dword ptr [edi+28], eax     ; hCursor

    ; Background colour / brush
    mov dword ptr [edi+32], COLOR_BTNFACE+1 ; hbrBackground = light grey button face
    mov dword ptr [edi+36], 0               ; lpszMenuName = NULL (no menu)

    ; Class name and small icon
    lea eax, szClassName
    mov dword ptr [edi+40], eax     ; lpszClassName = "FileExplorerApp"
    mov dword ptr [edi+44], 0       ; hIconSm = NULL

    ; Register the class
    push edi
    call RegisterClassExA           ; user32.dll — returns atom or 0 on failure

    add esp, 48                     ; release WNDCLASSEX from stack
    pop edi
    ret


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CreateMainWindow: create the 900x600 main window
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
CreateMainWindow:
    ; CreateWindowExA parameters (right-to-left on stack):
    ; dwExStyle, lpClassName, lpWindowName, dwStyle, x, y, nWidth, nHeight,
    ; hWndParent, hMenu, hInstance, lpParam
    push 0                          ; lpParam = NULL
    push hInstance                  ; hInstance
    push 0                          ; hMenu = NULL
    push 0                          ; hWndParent = NULL (top-level window)
    push 600                        ; nHeight = 600 px
    push 900                        ; nWidth  = 900 px
    push CW_USEDEFAULT              ; y = auto-position
    push CW_USEDEFAULT              ; x = auto-position
    push WS_OVERLAPPEDWINDOW        ; dwStyle = standard overlapped window
    lea eax, szAppName              ; window title "Recursive File Explorer"
    push eax
    lea eax, szClassName            ; window class "FileExplorerApp"
    push eax
    push 0                          ; dwExStyle = 0 (no extended styles)
    call CreateWindowExA            ; user32.dll — returns handle or NULL on failure
    ret


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; WndProc: main window procedure (message callback)
; Stack frame: [ebp+8]=hWnd  [ebp+12]=uMsg  [ebp+16]=wParam  [ebp+20]=lParam
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
WndProc:
    ; Save registers (stdcall convention)
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; Dispatch on message type
    mov eax, [ebp+12]               ; uMsg

    cmp eax, WM_CREATE              ; window just created
    je wm_create_handler

    cmp eax, WM_COMMAND             ; button click or accelerator
    je wm_command_handler

    cmp eax, WM_DESTROY             ; window being destroyed
    je wm_destroy_handler

    ; Unhandled message — pass to default handler
    push dword ptr [ebp+20]         ; lParam
    push dword ptr [ebp+16]         ; wParam
    push dword ptr [ebp+12]         ; uMsg
    push dword ptr [ebp+8]          ; hWnd
    call DefWindowProcA             ; user32.dll
    jmp wndproc_exit

wm_create_handler:
    ; Create child controls (TextBox, Button, results area)
    mov eax, [ebp+8]                ; eax = hWnd
    push eax
    call CreateControls
    xor eax, eax                    ; return 0 (success)
    jmp wndproc_exit

wm_command_handler:
    ; Extract low 16 bits of wParam = control ID
    mov eax, [ebp+16]
    and eax, 0FFFFh
    cmp eax, 1001                   ; ID of "Browse" button
    je button_clicked
    xor eax, eax                    ; not handled — return 0
    jmp wndproc_exit

button_clicked:
    ; User clicked "Browse" — start recursive scan
    call ScanAndDisplay
    xor eax, eax                    ; return 0 (success)
    jmp wndproc_exit

wm_destroy_handler:
    ; Post WM_QUIT to break the message loop
    push 0
    call PostQuitMessage            ; user32.dll
    xor eax, eax                    ; return 0

wndproc_exit:
    ; Restore registers and return (stdcall: clean 4 parameters = 16 bytes)
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 16


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CreateControls: create TextBox (input), Button, and results area
;   Parameter: [ebp+8] = parent hWnd
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
CreateControls:
    push ebp
    mov ebp, esp
    mov esi, [ebp+8]                ; esi = parent window handle

    ; --- Path input TextBox (ID 1000) ---
    push 0                          ; lpParam = NULL
    push hInstance                  ; hInstance
    push 1000                       ; hMenu = control ID 1000
    push esi                        ; hWndParent
    push 25                         ; nHeight = 25 px
    push 750                        ; nWidth  = 750 px
    push 10                         ; y = 10 px
    push 10                         ; x = 10 px
    push WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL
    push 0                          ; lpWindowName = NULL
    lea eax, szEditClass            ; lpClassName = "EDIT"
    push eax
    push 0                          ; dwExStyle = 0
    call CreateWindowExA            ; user32.dll
    mov hEdit, eax                  ; save TextBox handle

    ; Pre-fill the TextBox with the default path
    push offset szDefaultInput      ; "C:\Users\user"
    push hEdit
    call SetWindowTextA             ; user32.dll

    ; --- "Browse" button (ID 1001) ---
    push 0                          ; lpParam = NULL
    push hInstance
    push 1001                       ; hMenu = control ID 1001
    push esi                        ; hWndParent
    push 30                         ; nHeight = 30 px
    push 120                        ; nWidth  = 120 px
    push 10                         ; y = 10 px
    push 770                        ; x = 770 px
    push WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON
    lea eax, szOKButton             ; lpWindowName = "Browse"
    push eax
    lea eax, szButtonClass          ; lpClassName = "BUTTON"
    push eax
    push 0                          ; dwExStyle = 0
    call CreateWindowExA            ; user32.dll
    mov hButton, eax                ; save Button handle

    ; --- Results area — read-only multiline TextBox (ID 1002) ---
    push 0                          ; lpParam = NULL
    push hInstance
    push 1002                       ; hMenu = control ID 1002
    push esi                        ; hWndParent
    push 520                        ; nHeight = 520 px
    push 860                        ; nWidth  = 860 px
    push 50                         ; y = 50 px (below input row)
    push 10                         ; x = 10 px
    push WS_CHILD or WS_VISIBLE or WS_BORDER or WS_VSCROLL or \
         ES_MULTILINE or ES_READONLY or ES_AUTOVSCROLL or \
         WS_HSCROLL or ES_AUTOHSCROLL
    push 0                          ; lpWindowName = NULL
    lea eax, szEditClass            ; lpClassName = "EDIT"
    push eax
    push 0                          ; dwExStyle = 0
    call CreateWindowExA            ; user32.dll
    mov hResult, eax                ; save results area handle

    pop ebp
    ret 4


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ScanAndDisplay: read path from TextBox, run recursive scan,
;                 populate results area with the full directory tree
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
ScanAndDisplay:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; --- Read path from the TextBox ---
    push 260                        ; nMaxCount = 260 chars
    lea eax, path
    push eax                        ; lpString = destination buffer
    push hEdit                      ; hWnd = TextBox handle
    call GetWindowTextA             ; user32.dll — returns char count in eax

    test eax, eax                   ; eax == 0 means empty or error
    je scan_exit
    mov pathLength, eax             ; save path length

    ; --- Reset all scan state ---
    mov resultPtr, 0                ; result buffer write position = start
    mov fileCounter, 0              ; entry counter = 0
    mov currentDepth, 0            ; current depth = 0

    ; Empty both stacks
    mov stackPtr, 0
    mov depthPtr, 0

    ; Write the root path header into the result buffer
    call AddRootHeader

    ; --- Push the initial path onto the stack ---
    mov esi, offset path            ; source = user path
    mov edi, offset stackPaths      ; destination = base of path stack
    mov ecx, pathLength             ; bytes to copy

push_initial:
    mov al, byte ptr [esi]          ; copy one byte at a time
    mov byte ptr [edi], al
    inc esi
    inc edi
    dec ecx
    jnz push_initial                ; loop while ecx != 0

    mov byte ptr [edi], 0           ; null-terminate
    mov stackPtr, 260               ; advance stack pointer (1 path = 260 bytes)

    ; Push depth 0 (root level) onto the depth stack
    mov eax, depthPtr
    mov dword ptr [stackDepths + eax], 0    ; depth = 0
    add depthPtr, 4                         ; advance by 1 DWORD


    ; --- Main recursion loop ---
boucle_stack:
    ; Is the stack empty?
    mov eax, stackPtr
    cmp eax, 0
    jz fin_recursion                ; yes — all directories processed

    ; Pop one path
    sub stackPtr, 260               ; move stack pointer back one slot

    mov eax, stackPtr
    lea esi, [stackPaths + eax]     ; esi = address of popped path
    mov edi, offset currentPath     ; edi = destination
    mov ecx, 260

pop_chemin:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0                       ; null terminator?
    jz pop_chemin_termine
    inc esi
    inc edi
    dec ecx
    jnz pop_chemin

pop_chemin_termine:
    ; Pop the corresponding depth
    sub depthPtr, 4                 ; move depth pointer back one DWORD
    mov eax, depthPtr
    mov ebx, dword ptr [stackDepths + eax]  ; ebx = depth value
    mov currentDepth, ebx           ; save as current depth


    ; --- Build search pattern: currentPath + "\*.*" ---
    mov esi, offset currentPath
    mov edi, offset searchPath

copier_chemin_pattern:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0
    jz fin_copie_chemin_pattern
    inc esi
    inc edi
    jmp copier_chemin_pattern

fin_copie_chemin_pattern:
    ; Ensure trailing '\'
    dec edi                         ; step back to last character
    mov al, byte ptr [edi]
    cmp al, '\'
    je ajouter_motif_pattern        ; already has '\'

    inc edi                         ; back to null position
    mov byte ptr [edi], '\'
    inc edi

ajouter_motif_pattern:
    ; Append "*.*\0" (4 bytes)
    mov esi, offset searchPattern
    mov ecx, 4

copier_motif_pattern:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    inc esi
    inc edi
    dec ecx
    jnz copier_motif_pattern


    ; --- FindFirstFileA with the pattern ---
    push offset findData            ; lpFindFileData
    push offset searchPath          ; lpFileName
    call FindFirstFileA             ; kernel32.dll
    mov hFind, eax                  ; save search handle

    cmp eax, INVALID_HANDLE_VALUE   ; -1 = error (path not found, access denied, etc.)
    je boucle_stack                 ; skip — go to next stacked path


    ; --- Iterate over entries in the current directory ---
boucle_fichiers:
    ; Filter "." and ".." to avoid infinite loops
    lea esi, [findData+44]          ; cFileName is at offset 44 in WIN32_FIND_DATAA
    mov al, byte ptr [esi]
    cmp al, '.'
    jne pas_point

    mov al, byte ptr [esi+1]
    cmp al, 0                       ; single "." ?
    je fichier_suivant

    cmp al, '.'
    jne pas_point

    mov al, byte ptr [esi+2]
    cmp al, 0                       ; double ".." ?
    je fichier_suivant

pas_point:
    ; Check FILE_ATTRIBUTE_DIRECTORY (0x10)
    mov eax, dword ptr findData     ; dwFileAttributes at offset 0
    and eax, 10h
    jz pas_dossier                  ; bit clear => regular file

    ; --- Entry is a directory: display it and push its full path ---
    call AddFileNameToResult        ; write indented name to result buffer

    ; Build full path of the subdirectory
    mov esi, offset currentPath
    mov edi, offset tempBuffer

concat_chemin_base:
    ; Copy currentPath to tempBuffer
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0
    jz base_concate
    inc esi
    inc edi
    jmp concat_chemin_base

base_concate:
    ; Ensure trailing '\'
    dec edi
    mov al, byte ptr [edi]
    cmp al, '\'
    je concat_nom_dossier_base

    inc edi
    mov byte ptr [edi], '\'
    inc edi

concat_nom_dossier_base:
    ; Append subdirectory name
    lea esi, [findData+44]

concat_nom_dossier_loop:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0
    jz concat_dossier_termine
    inc esi
    inc edi
    jmp concat_nom_dossier_loop

concat_dossier_termine:
    ; Push full path onto the path stack (overflow check)
    mov eax, stackPtr
    cmp eax, 15600                  ; 60 * 260 = 15600 bytes max
    jge pas_dossier                 ; stack full — skip

    lea edi, [stackPaths + eax]     ; slot in path stack
    mov esi, offset tempBuffer

push_chemin_dossier:
    mov al, byte ptr [esi]
    mov byte ptr [edi], al
    cmp al, 0
    jz push_profondeur_dossier
    inc esi
    inc edi
    jmp push_chemin_dossier

push_profondeur_dossier:
    add stackPtr, 260               ; advance path stack pointer

    ; Push depth (currentDepth + 1) onto the depth stack
    mov eax, currentDepth
    inc eax                         ; child depth = parent depth + 1
    mov ebx, depthPtr
    mov dword ptr [stackDepths + ebx], eax  ; push new depth
    add depthPtr, 4                         ; advance depth stack pointer

    jmp fichier_suivant             ; continue to next entry


pas_dossier:
    ; --- Entry is a regular file: display it ---
    call AddFileNameToResult        ; write indented name to result buffer
    inc fileCounter                 ; increment file counter


fichier_suivant:
    ; Advance to the next directory entry
    push offset findData
    push hFind
    call FindNextFileA              ; kernel32.dll
    cmp eax, 0
    jnz boucle_fichiers             ; non-zero = more entries


    ; Close the search handle for the current directory
    push hFind
    call FindClose                  ; kernel32.dll

    ; Continue with the next stacked path
    jmp boucle_stack


    ; --- Scan complete ---
fin_recursion:
    ; Flush the full result buffer into the results TextBox in one operation
    ; (unlike CLI which writes line-by-line, GUI batches all output here)
    lea eax, resultBuffer
    push eax                        ; lpString
    push hResult                    ; hWnd = results area
    call SetWindowTextA             ; user32.dll

scan_exit:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AddRootHeader: write the root path + newline into resultBuffer
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
AddRootHeader:
    push esi
    push edi

    mov edi, resultPtr              ; load current write position
    lea edi, [resultBuffer + edi]   ; edi = absolute write address

    cmp resultPtr, 31000            ; buffer nearly full? (32000 - 1000 safety margin)
    jge add_root_exit               ; yes — skip

    ; Copy the root path string
    mov esi, offset path

add_root_loop:
    mov al, byte ptr [esi]
    cmp al, 0                       ; null terminator?
    je add_root_done
    mov byte ptr [edi], al
    inc esi
    inc edi
    jmp add_root_loop

add_root_done:
    ; Append CR LF
    mov byte ptr [edi], 13          ; CR (carriage return)
    inc edi
    mov byte ptr [edi], 10          ; LF (line feed)
    inc edi

    ; Update write pointer
    lea eax, [resultBuffer]         ; base address of buffer
    sub edi, eax                    ; edi = new offset
    mov resultPtr, edi

add_root_exit:
    pop edi
    pop esi
    ret


; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AddFileNameToResult: write current entry name to resultBuffer
;   Indentation: one TAB character per depth level
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
AddFileNameToResult:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    mov edi, resultPtr
    lea edi, [resultBuffer + edi]   ; edi = absolute write address

    cmp resultPtr, 31800            ; safety margin (32000 - 200)
    jge add_file_exit_clean         ; buffer full — skip

    ; Insert TAB characters for hierarchical indentation
    mov ecx, currentDepth
    cmp ecx, 0
    je no_tabs_add_name             ; depth 0 = root, no indentation

add_tabs_loop:
    mov byte ptr [edi], 9           ; ASCII 9 = TAB
    inc edi
    dec ecx
    jnz add_tabs_loop

no_tabs_add_name:
    ; Copy filename from WIN32_FIND_DATAA.cFileName (offset 44)
    lea esi, [findData+44]

add_name_loop:
    mov al, byte ptr [esi]
    cmp al, 0                       ; null terminator?
    je add_name_done
    mov byte ptr [edi], al
    inc esi
    inc edi
    jmp add_name_loop

add_name_done:
    ; Append CR LF
    mov byte ptr [edi], 13          ; CR
    inc edi
    mov byte ptr [edi], 10          ; LF
    inc edi

    ; Update write pointer
    lea eax, [resultBuffer]
    sub edi, eax                    ; edi = new offset
    mov resultPtr, edi

add_file_exit_clean:
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

end start

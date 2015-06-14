    extern fread
    extern fopen
    extern fclose
    extern fprintf
    extern malloc
    extern free
    extern exit
    extern stderr

    SECTION .text
GLOBAL _start
_start:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 4]

    push eax
    call writei
    pop eax
    
    cmp eax, 2
    ja TooManyArgs
    jb NoArgs
    
    mov eax, [ebp + 12]
    sub esp, 12
    call Read
    push RSuccess
    push dword[stderr]
    call fprintf
    add esp, 8
    call free
    add esp, 12

    push dword 0
    call exit


Read:
    push ebp
    mov ebp, esp
    
    push eax
    call FileCk
    pop eax

    push Mode
    push eax
    call fopen
    add esp, 8
    cmp eax, 0
    jne OpenSuccess
    push OpenFail
    call ErrOut
    add esp, 4
    push dword 1
    call exit

;
;read file and format checking
;
OpenSuccess:
    sub esp, 18
    push eax
    push dword 1
    push dword 18
    mov eax, ebp
    sub eax, 18
    push eax
    call fread
    cmp eax, 1
    jne ErrFormat

    mov eax, [esp]
    movzx ebx, word [eax]
    cmp ebx, 0x4D42
    jne ErrFormat
    
    mov ebx, [eax + 14]
    sub ebx, 4

    add esp, 12
    pop eax

    sub esp, ebx
    push ebx
    push eax
    push dword 1
    push ebx
    mov eax, esp
    add eax, 16
    push eax
    call fread
    cmp eax, 1
    jne ErrFormat

    mov eax, [esp]
    mov edx, [eax + 12]
    cmp edx, 0
    jne ErrFormat
    
    mov ebx, [eax]
    mov [ebp + 12], ebx
    mov ebx, [eax + 4]
    mov [ebp + 16], ebx 
    push ebx
    add eax, [eax - 4]
    mov ebx, [eax + 2]
    sub ebx, [eax + 10]

    mov eax, ebx
    pop ebx
    mov edx, 0 
    div ebx
    cmp edx, 0
    jne ErrFormat
    push eax
    call xmalloc
    push eax

    mov eax, [ebp + 12]
    cmp eax, 0
    je ErrFormat
    mul ebx
    jo ErrFormat
    mov ebx, 4
    mul ebx 
    jo ErrFormat
    push eax
    call xmalloc
    mov [ebp + 8], eax
    add esp, 4

    mov edi, eax
    mov esi, [esp]
    mov edx, [esp + 4]
    mov eax, [esp + 20]
    mov ecx, [ebp + 16]
.L1:
    push ecx
    push edi
    push eax
    push dword 1
    push edx
    push esi
    call fread
    cmp eax, 1
    jne ErrFormat

    mov ecx, [ebp + 12]
    .L2:
        mov eax, [esi]
        and eax, 0xffffff
        mov [edi], eax
        add esi, 3
        add edi, 4
        loop .L2
    pop esi
    pop edx
    add esp, 4
    pop eax
    pop edi
    pop ecx
    loop .L1


    push eax
    call fclose
    mov [esp], esi
    call free
    mov esp, ebp
    pop ebp
    ret

    
ErrFormat:
    push ErrForm
    call ErrOut
    add esp, 4
    push dword 1
    call exit


;
;Filename check (use DFA)
;must be .bmp extension
;
FileCk:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]


.S0: movzx ebx, byte[eax]
    cmp ebx,  0
    je .Serr
    cmp ebx, 0x2e
    je .S2

.S1: inc eax 
    movzx ebx, byte[eax]
    cmp ebx, 0
    je .Serr
    cmp ebx, 0x2e
    jne .S1

.S2: inc eax 
    movzx ebx, byte[eax]
    cmp ebx, 0
    je .Serr
    cmp ebx, 0x2e
    je .S2
    cmp ebx, 0x62
    jne .S1

.S3: inc eax 
    movzx ebx, byte[eax]
    cmp ebx, 0
    je .Serr
    cmp ebx, 0x2e
    je .S2
    cmp ebx, 0x6D
    jne .S1

.S4: inc eax 
    movzx ebx, byte[eax]
    cmp ebx, 0
    je .Serr
    cmp ebx, 0x2e
    je .S2
    cmp ebx, 0x70
    jne .S1

.S5: inc eax 
    movzx ebx, byte[eax]
    cmp ebx, 0
    je .Sac
    cmp ebx, 0x2e
    je .S2
    jmp .S1

.Serr:
    push ErrName
    call ErrOut
    mov [esp], dword 1
    call exit
    
.Sac:
    mov esp, ebp
    pop ebp
    ret

ErrOut:
    push ebp
    mov ebp, esp
    push dword[ebp + 8]
    push dword[stderr]
    call fprintf
    mov esp, ebp
    pop ebp
    ret

TooManyArgs:
    push TMArgs
    call ErrOut
    push dword 1
    call exit
NoArgs:
    push NArgs
    call ErrOut
    push dword 1
    call exit

writei:
    push ebp
    mov ebp, esp
    push eax
    push dword [ebp + 8]
    push INT_OUT
    push dword [stderr]
    call fprintf
    pop eax
    pop eax
    pop eax
    mov esp, ebp
    pop ebp
    ret

xmalloc:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    push eax
    call malloc
    mov esp, ebp
    pop ebp
    cmp eax, 0
    je .NFreeMem
    ret 
.NFreeMem:
    push NoFrMem
    call ErrOut
    mov [esp], dword 1
    call exit
    
    

    SECTION .data
NoFrMem : db "There is no free memory", 0x21, 0x0a, 0x00
TMArgs  : db "Too many argument", 0x21, 0x0a, 0x00
NArgs   : db "It need one argument", 0x21, 0x0a, 0x00
ErrName : db "File name is incorrect", 0x21, 0x0a, 0x00
OpenFail: db "Open file faild", 0x21, 0x0a, 0x00
ErrForm : db "The format is incorrect", 0x21, 0x0a, 0x00
TooLarge: db "The size of file is too large", 0x21, 0x0a, 0x00
Mode    : db "r", 0x00
INT_OUT : db "%x", 0x0a, 0x00
RSuccess: db "Read Sucess", 0x21, 0x0a, 0x00

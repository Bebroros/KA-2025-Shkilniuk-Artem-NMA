.model tiny
.code
org 100h
start:
    jmp main
rule_count   dw 0
rule_before  dw 0
rule_after   dw 0
len_of_string dw 0
len_before   dw 0
len_after    dw 0
start_of_rules dw 0
ending_flag  db 0
applying_flag db 0
difference   dw 0
buffer dw ?
string dw ?
filename dw ?

main:
    mov bx, offset end_of_code
    mov filename, bx
    add bx, 64
    mov buffer, bx  ; place to buffer the address of the end of code segment
    add bx, 32000
    mov string, bx  ; place to string the address of the end of the buffer

    mov si, 82h
    mov di, [filename]
    cld
    rep movsb

    mov [di], byte ptr '$'
open_file:
    mov ah, 3dh
    mov dx, [filename]
    int 21h
    mov bx, ax
read_file:
    mov ax, 3f00h
    mov dx, [buffer]
    mov cx, 32000
    int 21h
close_file:
    mov ax, 3e00h
    inc ah
    int 21h
writing_string:
    mov si, [buffer]
    mov cx, word ptr [si]
    add si, 4
    add si, cx

    mov ch, byte ptr [si + 1]       ;!!!!!!!!!!!!!! MOVE
    mov cl, byte ptr [si]
    add si, 4
    dec cx
    dec cx
    mov len_of_string, cx
    mov di, [string]
    cld
    rep movsb
    inc si
    inc si
    mov start_of_rules, si 
changing_string:
    cmp applying_flag, 1
    jne change
    mov rule_count, 0
change:
    inc rule_count
    mov ending_flag, 0
    mov applying_flag, 0
    call reading_rules
    cmp ending_flag, 2
    je printing
    call applying_rules
    cmp ending_flag, 1
    jne changing_string
    cmp applying_flag, 1
    jne changing_string
printing:
    mov dx, [string]
    mov ax, 0900h
    int 21h

    mov ah, 02h
    mov dl, 0Dh
    int 21h
    mov dl, 0Ah
    int 21h
exit:
    mov ax, 4C00h
    int 21h

applying_rules proc
    mov bx, len_before
    mov dx, len_after

    mov si, [string]
    mov di, si
next_char:
    cld
    lodsb
    inc di
    cmp al, '$'
    je done
    push di
    push si
    mov cx, bx
    mov di, rule_before

    dec si
    cld
    rep cmpsb
    pop si
    pop di
    jne next_char

    dec si
    dec di
    cmp dx, bx
    je insert
    jg shift_right
    jmp shift_left

done:
    mov di, [string]
    add di, len_of_string
    mov byte ptr [di], '$'
    ret

shift_right:
    push dx
    sub dx, bx
    mov difference, dx
    pop dx

    push si
    push di
    push bx
    push dx

    mov dx, si
    mov bx, len_of_string
    add bx, [string]
    dec dx
    add dx, len_before
    sub bx, dx
    xchg bx, dx

    mov bx, len_of_string

    mov si, [string]
    add si, bx  ; !!!!!!!!!!!
    dec si


    mov bx, difference

    lea di, [si+bx]     ; !!!!!!!!!!!!!!
;    mov di, si
;    add di, bx


    add len_of_string, bx
    cmp len_of_string, 32768d    ; Reduced size check
    ja over_limit
    mov cx, dx
    pop dx
    pop bx

    std
    rep movsb
    cld
    pop di
    pop si
    jmp insert
over_limit:
    sub len_of_string, bx
    mov applying_flag, 1
    mov ending_flag, 1
    pop dx
    pop bx
    pop di
    pop si
    jmp done

insert:
    mov cx, dx
    mov di, si
    mov si, rule_after
    rep movsb
    mov si, [string]
    mov applying_flag, 1
    jmp done

shift_left:
    push bx
    sub bx, dx
    mov difference, bx
    pop bx
    
    push si
    push di
    push bx
    push dx

    mov dx, si
    push dx
    mov dx, bx
    lea si, [di+bx]
    add di, len_after

    mov bx, len_of_string
    add bx, [string]
    sub bx, dx
    pop dx
    sub bx, dx

    mov cx, difference
    sub len_of_string, cx

    mov cx, bx
    pop dx
    pop bx
    
    cld
    rep movsb

    mov si, [string]
    add si, len_of_string
    mov [si], byte ptr '$'

    pop di
    pop si
    jmp insert
applying_rules endp

reading_rules proc
    mov bx, rule_count
    mov si, start_of_rules
    mov dh, byte ptr [si + 1]
    mov dl, byte ptr [si]
    add si, 4
reading_loop:
    test dx, dx
    jz end_of_rules
    dec bx
    mov rule_before, si
    xor cx, cx
rule_b:
    cld
    lodsb
    inc cx
    dec dx
    cmp al, 09h  
    jne rule_b
    dec cx
    mov len_before, cx
    mov rule_after, si
    xor cx, cx
rule_a:
    cld
    lodsb
    inc cx
    dec dx    
    cmp al, 09h
    jne rule_a
    dec cx
    mov len_after, cx
skip_comment:
    cld
    lodsb
    dec dx
    cmp al, 0Dh
    jne skip_comment
    cld
    lodsb
    dec dx
    cmp al, 0Ah
    jne skip_comment
    test bx, bx
    jnz reading_loop
final_state:
    cmp len_after, 0
    je return

    mov si, rule_after
    add si, len_after
    dec si

    cmp [si], byte ptr '.'
    jne return
    dec len_after
    inc ending_flag
return:
    ret
end_of_rules:
    mov ending_flag, 2
    ret
    
reading_rules endp

end_of_code:
end start

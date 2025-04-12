.model tiny
.code
org 100h
start:
    mov bx, 4000h
    mov es, bx

    xor bh, bh
    mov bl, [80h]
    mov byte ptr[bx+81h], '$'

open_file:
    mov ax, 3d00h
    mov dx, 0082h
    int 21h
    xchg bx, ax
    
    push ds
    push es
    pop ds
read_file:
    mov ah, 3fh
    xor dx, dx
    mov cx, 32000
    int 21h
writing_string:
    cld
    xor si, si  ; buffer
    lodsw
    inc si
    inc si
    add si, ax

    mov cx, word ptr [si]
    add si, 4
    dec cx
    dec cx
    mov cs:[len_of_string], cx
    mov di, 32000 ; string
    rep movsb
    mov [di], byte ptr 0
    add si, 6

    pop ds
    mov [start_of_rules], si 
    
changing_string:
    cmp byte ptr applying_flag, 1
    jne change
    mov rule_count, 0
change:
    inc rule_count
    mov ending_flag, 0
    mov applying_flag, 0
    push ds
    call reading_rules
    cmp cs:[ending_flag], 2
    je printing
    call applying_rules
    pop ds
    mov al, [applying_flag]
    and al, [ending_flag]
    cmp al, 1
    jne changing_string
printing:
    push es
    pop ds
    mov si, 32000
print_loop:
    mov ah, 02h
    mov dl, [si]
    test dl, dl
    jz end_print
    int 21h
    inc si
    jmp print_loop
end_print:
    mov dl, 0Dh
    int 21h
    mov dl, 0Ah
    int 21h
exit:
    int 20h

applying_rules proc
    mov bx, cs:[len_before]         ; LEN BEFORE
    mov dx, cs:[len_after]          ; LEN AFTER
    mov si, 32000 ; string
    test bx, bx
    jz shift_right
next_char:
    lodsb
    test al, al
    jz done
    push si
    mov cx, bx
    mov di, cs:[rule_before]

    dec si
    rep cmpsb
    pop si
    jne next_char

    dec si
    mov di, si
    cmp dx, bx
    je insert
    jg shift_right
shift_left:
    push si
    push di
    push bx
    push dx

    mov ax, bx
    sub ax, dx


    mov dx, si
    push dx
    mov dx, bx
    lea si, [di+bx]
    add di, cs:[len_after]          

    mov cx, cs:[len_of_string]
    add ch, 7dh
    sub cx, dx
    pop dx
    sub cx, dx

    sub cs:[len_of_string], ax

    pop dx
    pop bx
    
    rep movsb

    pop di
    pop si
insert:
    mov cx, dx
    mov di, si
    mov si, cs:[rule_after]
    rep movsb
    inc cs:[applying_flag]
done:
    mov di, 32000 ; string
    add di, cs:[len_of_string]
    mov byte ptr [di], 0
    ret

shift_right:
    push si
    push bx
    push dx
    sub dx, bx
    push dx

    add bx, si
    dec bx
    mov cx, cs:[len_of_string]
    push cx
    add ch, 7dh ; string
    sub cx, bx

    pop bx

    mov si, 31999
    add si, bx      ; to the end of the string

    pop bx

    lea di, [si+bx]

    add cs:[len_of_string], bx
    cmp cs:[len_of_string], 32768d
    ja over_limit
    pop dx
    pop bx

    std
    rep movsb
    cld
    pop si
    jmp insert
over_limit:  
    sub cs:[len_of_string], bx
    inc cs:[applying_flag]
    inc cs:[ending_flag]
    add sp, 6
    jmp done
applying_rules endp

reading_rules proc
    mov bx, [rule_count]
    mov si, [start_of_rules]

    push es
    pop ds

    mov dh, byte ptr [si-3]
    mov dl, byte ptr [si-4]
reading_loop:
    test dx, dx
    jz end_of_rules
    dec bx
    mov cs:[rule_before], si
    xor cx, cx
rule_b:
    lodsb
    inc cx
    dec dx
    cmp al, 09h  
    jne rule_b
    dec cx
    mov cs:[len_before], cx         ; LEN BEFORE
    mov cs:[rule_after], si
    xor cx, cx
rule_a:
    lodsb
    inc cx
    dec dx    
    cmp al, 09h
    jne rule_a
    dec cx
    mov cs:[len_after], cx              ; LEN AFTER
skip_comment:
    dec si
    lodsw
    dec dx
    cmp ax, 0A0Dh
    jne skip_comment
    test bx, bx
    jnz reading_loop
final_state:
    mov ax, cs:[len_after]          ; LEN AFTER

    mov si, cs:[rule_after]        
    cmp [si], byte ptr '.'
    jne second
    inc cs:[rule_after]
b:
    dec cs:[len_after]          ; LEN AFTER
    inc cs:[ending_flag]
    ret
second:
    add si, ax
    dec si
    cmp [si], byte ptr '.'
    je b
return:
    ret ; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
end_of_rules:
    mov cs:[ending_flag], 2
    ret ; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
reading_rules endp

rule_count   dw 0
rule_before  dw 0
rule_after   dw 0
len_of_string dw 0      ; 64
len_before   dw 0
len_after    dw 0
start_of_rules dw 0
ending_flag  db 0
applying_flag db 0

end start

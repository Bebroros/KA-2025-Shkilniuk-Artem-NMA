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
; buffer dw 65
; string dw 32064
; filename dw 0

main:
    mov bx, 4000h
    mov es, bx

    xor bx, bx
    mov bl, byte ptr ds:[80h]
    mov byte ptr[bx+81h], '$'

    push ds
open_file:
    mov ax, 3d00h
    xor dx, dx
    mov dl, 82h
    int 21h
    mov bx, ax
    
    push ds
    mov ax, es
    mov ds, ax
read_file:
    mov ax, 3f00h
    xor dx, dx
    mov cx, 32000
    int 21h
close_file:
    mov ax, 3e00h
    inc ah
    int 21h
writing_string:
    xor si, si  ; buffer
    mov cx, word ptr [si]
    add si, 4
    add si, cx

    mov cx, word ptr [si]
    add si, 4
    dec cx
    dec cx
    mov cs:[len_of_string], cx
    mov di, 32000 ; string
    cld
    rep movsb
    mov [di], byte ptr '$'
    inc si
    inc si

    mov cs:[start_of_rules], si 
    
changing_string:
    pop ds
    cmp applying_flag, 1
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
    cmp ending_flag, 1
    jne changing_string
    cmp applying_flag, 1
    jne changing_string
printing:
    mov dx, 32000 ; string
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
    mov bx, cs:[len_before]
    mov dx, cs:[len_after]

    mov si, 32000 ; string
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
    mov di, cs:[rule_before]

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
    mov di, 32000 ; string
    add di, cs:[len_of_string]
    mov byte ptr [di], '$'
    ret

shift_right:
    push dx
    sub dx, bx
    mov cs:[difference], dx
    pop dx

    push si
    push di
    push bx
    push dx

    mov dx, si
    mov bx, cs:[len_of_string]
    add bx, 32000 ; string
    dec dx
    add dx, cs:[len_before]
    sub bx, dx
    xchg bx, dx

    mov bx, cs:[len_of_string]

    mov si, 32000 ; string
    add si, bx  ; !!!!!!!!!!!
    dec si


    mov bx, cs:[difference]

    lea di, [si+bx]     ; !!!!!!!!!!!!!!
;    mov di, si
;    add di, bx


    add cs:[len_of_string], bx
    cmp cs:[len_of_string], 32768d
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
    sub cs:[len_of_string], bx
    mov cs:[applying_flag], 1
    mov cs:[ending_flag], 1
    pop dx
    pop bx
    pop di
    pop si
    jmp done

insert:
    mov cx, dx
    mov di, si
    mov si, cs:[rule_after]
    rep movsb
    mov si, 32000 ; string
    mov cs:[applying_flag], 1
    jmp done

shift_left:
    push bx
    sub bx, dx
    mov cs:[difference], bx
    pop bx
    
    push si
    push di
    push bx
    push dx

    mov dx, si
    push dx
    mov dx, bx
    lea si, [di+bx]
    add di, cs:[len_after]

    mov bx, cs:[len_of_string]
    add bx, 32000
    sub bx, dx
    pop dx
    sub bx, dx

    mov cx, cs:[difference]
    sub cs:[len_of_string], cx

    mov cx, bx
    pop dx
    pop bx
    
    cld
    rep movsb

    mov si, 32000
    add si, cs:[len_of_string]
    mov [si], byte ptr '$'

    pop di
    pop si
    jmp insert
applying_rules endp

reading_rules proc
    mov bx, [rule_count]
    mov si, [start_of_rules]
    mov dh, byte ptr es:[si + 1]
    mov dl, byte ptr es:[si]
    add si, 4

    mov ax, es
    mov ds, ax
reading_loop:
    test dx, dx
    jz end_of_rules
    dec bx
    mov cs:[rule_before], si
    xor cx, cx
rule_b:
    cld
    lodsb
    inc cx
    dec dx
    cmp al, 09h  
    jne rule_b
    dec cx
    mov cs:[len_before], cx
    mov cs:[rule_after], si
    xor cx, cx
rule_a:
    cld
    lodsb
    inc cx
    dec dx    
    cmp al, 09h
    jne rule_a
    dec cx
    mov cs:[len_after], cx
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
    cmp cs:[len_after], 0
    je return

    mov si, cs:[rule_after]
    add si, cs:[len_after]
    dec si

    cmp [si], byte ptr '.'
    jne return
    dec cs:[len_after]
    inc cs:[ending_flag]
return:
    ret
end_of_rules:
    mov cs:[ending_flag], 2
    ret
    
reading_rules endp

end start

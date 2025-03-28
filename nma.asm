.model small
stack 100h
.data
string db 32768 dup(?), '$'
rule_count dw 0d
rule_before dw ?
rule_after dw ?
len_of_string dw ?
len_before dw ?
len_after dw ?
filename db 255 dup(?), '$'
buffer db 32000 dup(?)
buffer_size dw 32000
start_of_rules dw ?
file_handle dw ?
ending_flag db 0d
applying_flag db 0d
difference dw ?
.code
start:
    call get_filename
    call open_file
    call read_file
    call close_file
    call writing_string
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
    je null_term
    call applying_rules
    cmp ending_flag, 1
    jne changing_string
    cmp applying_flag, 1
    jne changing_string
null_term:
    lea si, string
    mov [si+len_of_string], '$'
printing:
    call print_message
exit:
    mov ax, 4C00h
    int 21h

applying_rules proc
    mov bx, len_before
    mov dx, len_after

    lea si, string
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
    je insert1
    jg shift_right
    jmp shift_left

done:
    lea di, string
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
    add bx, offset string
    dec dx
    add dx, len_before
    sub bx, dx
    xchg bx, dx

    mov bx, len_of_string
    lea si, [string+bx-1]
    mov bx, difference
    lea di, [si+bx]
    add len_of_string, bx
    cmp len_of_string, 32768d
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
    pop si
    pop si
    pop si
    pop si
    jmp done

insert1:
    cmp dx, 0
    jne insert
insert:
    mov cx, dx
    mov di, si
    mov si, rule_after
    rep movsb
    lea si, string
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
    lea si, [di+bx] ; 1 2 111
    add di, len_after

    mov bx, len_of_string
    add bx, offset string
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

    lea si, string
    add si, len_of_string
    mov [si], byte ptr '$'

    pop di
    pop si
    jmp insert
applying_rules endp

reading_rules proc
    mov bx, rule_count          ; counter of the rule to use
    mov si, start_of_rules
    mov dh, byte ptr [si + 1]   ; rule section counter
    mov dl, byte ptr [si]
    add si, 4
reading_loop:
    cmp dx, 0
    je end_of_rules
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
    cmp bx, 0
    jne reading_loop
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

print_message proc
    mov ax, @data
    mov ds, ax
    mov es, ax
    mov dx, offset string
    mov ax, 0900h
    int 21h
    ret
print_message endp

get_filename proc
    mov ax, @data    ; delete in .com
    mov es, ax       ; delete in .com

    xor ch, ch
    mov cl, ds:[80h]
    dec cl
    jle read_end
    
    mov si, 82h
    lea di, filename
    cld
    rep movsb

    mov ds, ax       ; delete in .com

    mov [di], byte ptr '$'
read_end:
    ret
get_filename endp

open_file proc
    mov ax, 3d00h
    lea dx, filename
    int 21h
    mov file_handle, ax

open_file endp

read_file proc
    mov ax, 3F00h
    mov bx, file_handle
    lea dx, buffer
    mov cx, buffer_size
    int 21h
    ret
read_file endp

close_file proc
    mov ax, 3E00h
    mov bx, file_handle
    int 21h
    ret
close_file endp

writing_string proc
    lea si, buffer
    mov cx, word ptr [si]
    add si, 4
    add si, cx

    mov ch, byte ptr [si + 1]
    mov cl, byte ptr [si]
    add si, 4
    sub cx, 2
    mov len_of_string, cx
    lea di, string
    cld
    rep movsb
    add si, 2
    mov start_of_rules, si 
    ret
writing_string endp

end start

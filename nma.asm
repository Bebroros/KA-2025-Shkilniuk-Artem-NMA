.model tiny
.code
org 100h
.data
filename db 255 dup(?), '$'

start:
    call get_filename
    call print_message 

    mov ax, 4C00h
    int 21h

print_message proc
    mov dx, offset filename
    mov ah, 09h
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

end start

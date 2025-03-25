.model tiny
.code
org 100h
.data
filename db 255 dup(?), '$'
file_handle dw ?
file db 5 dup(?)
buffer db 32000 dup(?)
buffer_size dw 32000

start:
    call get_filename
    call open_file
    call read_file
    call close_file
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

open_file proc
    mov ah, 3dh
    mov al, 00h
    lea dx, filename
    int 21h
    mov file_handle, ax

open_file endp

read_file proc
    mov ah, 3Fh
    xor al, al
    mov bx, file_handle
    lea dx, buffer
    mov cx, buffer_size
    int 21h
    ret
read_file endp

close_file proc
    mov ah, 3Eh
    xor al, al
    mov bx, file_handle
    int 21h
    ret
close_file endp

end start

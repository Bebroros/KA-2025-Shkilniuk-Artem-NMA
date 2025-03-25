.model tiny
.code
org 100h
.data
filename db 255 dup(?), '$'
buffer db 32000 dup(?)
buffer_size dw 32000
string db 32768 dup(?), '$'
start_of_rules dw ?
len_of_string dw ?
file_handle dw ?
start:
    call get_filename
    call open_file
    call read_file
    call close_file
    call writing_string
    call print_message

exit:
    mov ax, 4C00h
    int 21h

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

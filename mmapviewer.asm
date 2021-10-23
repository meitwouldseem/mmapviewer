[org 0x7c00]
[bits 16]

xor ax, ax
mov ds, ax
mov ss, ax
mov es, ax
mov bp, 0x7b00
mov sp, bp

;push 0xabcd
;call printint16

mov di, 0x8004;location we want to write the output too
mov eax, 0xe820;bios memeory map function code
xor ebx, ebx;ebx should be zero
mov ecx, 24;number of bytes requested
mov edx, 0x0534d4150;signature checked by the bios
int 0x15;pull the trigger
jc unsupported;if carry is set, the function is unsupported
mov edx, 0x0534d4150;this register may get trashed
cmp eax, edx;eax is set to 'SMAP' to indicate success
jne error

push startmsg
call biosprint

e820loop:
push di
call printint64
push divider
call biosprint
add di, 8
push di
call printint64

push divider
call biosprint

mov al, [di+8]
add al, '0'
mov ah, 0x0e
int 0x10

push newline
call biosprint

cmp ebx, 0
je stop;if ebx became zero after the last bios call then this is the last entry

mov di, 0x8004
mov eax, 0xe820
mov ecx, 24
mov edx, 0x0534d4150
int 0x15
jc stop;if carry is set now it just means that we are done reading
mov edx, 0x0534d4150
cmp eax, edx
jne error
jmp e820loop

stop:
hlt
jmp stop

startmsg:
	db 'base             | length           | type',0x0a,0x0d,0

divider:
	db ' | ',0

newline:
	db 0x0a,0x0d,0

error:
	push errormsg
	call biosprint
	jmp stop

errormsg:
	db 'An error occoured',0

unsupported:
	push unsupportedmsg
	call biosprint
	jmp stop

unsupportedmsg:
	db 'memory map function is unsupported by the BIOS',0

;expects pointer to the start of a 64 bit int
printint64:
	push bp
	mov bp, sp

	push ax
	push bx

	mov bx, [bp+4];grab pointer
	mov ax, bx
	sub ax, 2
	add bx, 6;we need to print in reverse order
	.loop:
		push word [bx]
		call printint16
		sub bx, 2
		cmp bx, ax
		jne .loop

	pop bx
	pop ax
	pop bp
	ret 2

;expects 16bit value
printint16:
	push bp
	mov bp, sp
	
	push ax
	push bx
	push cx

	mov cx, [bp+4];fetch argument.
	mov bx, printbuffer+3

	.loop:
		mov ax, cx;copy value into ax
		and ax, 0x000f;mask out least significant hex char
		cmp ax, 9;is the hex character in the range 1-9 or A-F?
		jg .greater
		add ax, 48
		jmp .lesser
	.greater:
		add ax, 55
	.lesser:
		mov [bx], al;copy the hex character into the buffer
		dec bx
		shr cx, 4;shift out the bits we just processed
		cmp bx, printbuffer-1;have we filled the buffer?
		jne .loop

	;from here its just a normal null terminated string
	push printbuffer
	call biosprint

	pop cx
	pop bx
	pop ax
	pop bp
	ret 2;we passed a two byte argument to the stack

printbuffer:
	db '????',0

biosprint:
	push bp
	mov bp, sp

	push ax
	push bx

	mov ah, 0x0e
	mov bx, [bp+4]

	.loop:
		cmp [bx], byte 0
		je .exit
		mov al, [bx]
		int 0x10
		inc bx
		jmp .loop
	.exit:

	pop bx
	pop ax
	pop bp

	ret 2

times 510 - ($ - $$) db 0
dw 0xaa55

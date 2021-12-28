datarea segment
	string1 db 'Move the cursor backward.' ;一个字符大小为一个Byte
	string2 db 'Move the cursor forward.'

	mess1 db 'Match.', 13, 10, '$'
	mess2 db 'No match!', 13, 10, '$'
datarea ends

prognam segment

main	proc	far
		assume cs:prognam, ds:datarea, es:datarea
start:
;set up stack for return
		push ds
		sub ax,ax
		push ax
		
		mov ax,datarea
		mov ds,ax
		mov es,ax
		
		lea si,string1 ;lea:加载有效地址
		lea di,string2
		cld			   ;使si和di的地址指针自动增加
		mov cx,25 	   ;要比较的字符串一共25个Byte
		repz cmpsb 	   ;如果ds:si和es:di所指向的两个字节相等，则继续比较。若两字符串相等，则零标志置1
		jz match	   ;零标志为1就跳转
		lea dx,mess2
		jmp short disp
match:
	lea dx,mess1
disp:
	mov ah,09
	int 21h
	ret
main endp

prognam ends
		end start
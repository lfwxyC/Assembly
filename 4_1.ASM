data	segment
	PgSize		dw	?
	buf_size	db	80
	s_buf		db	?	; 长度
	buf			db	200	dup(?)	; 数据
	cur			dw	?
	handle		dw	?
	mess_getname	db	0dh,0ah,"	Please input filename: $"
	mess_err1		db	0ah,0dh,"	Illegal filename! $"
	mess_err2		db	0ah,0dh,"	File not found! $"
	mess_err3		db	0ah,0dh,"	File read error! $"
	mess_psize		db	0ah,0dh,"	Page Size: $"
	crlf			db	0ah,0dh,"$"
	mess_star		db	0ah,0dh,"* * * * * * * * * * * * * * * * * * * *"
					db	0ah,0dh,"$"
data	ends

code	segment
	assume ds:data, cs:code
	main	proc	far
start:
	push	ds
	sub		ax,ax
	push	ax
	mov		ax,data
	mov		ds,ax
	
	mov		PgSize,12	; 每页有12行
	mov		cur,200		; 文件数据缓冲区为空
	call	getline		; 获取文件名
	call	openf		; 打开文件，(ax)=0表示文件不存在
	or		ax,ax
	jnz		display
	; (ax)=0,输出"	Illegal filename! "
	mov		dx,offset mess_err2
	mov		ah,09h
	int		21h
	
	jmp		file_end
display:
	mov		cx,PgSize
show_page:
	call	read_block	; 从handle中读入一行到buf中
	or		ax,ax
	jnz		next2
	; (ax)=0,输出"	File read error! "
	mov		dx,offset mess_err3
	mov		ah,09h
	int		21h
	jmp		file_end
next2:
	call	show_block	; 显示buf中的一行
	
	or		bx,bx	
	jz		file_end	; (bx)=0表示eof
	or		cx,cx
	jnz		show_page	; (cx)<>0: 不是这一页的最后一行
	; 一页的最后，输出*
	mov		dx,offset mess_star
	mov		ah,09h
	int		21h

wait_space:
	; 获取键盘输入
	mov		ah,1
	int		21h
	
	cmp		al," "
	jnz		psize
	jmp		display	; 输入空格，则继续显示
psize:
	cmp		al,"p"
	jnz		wait_space
	call	change_psize
here:
	mov		ah,1
	int		21h
	cmp		al," "
	jnz		here	; 等待空格
	jmp		display

file_end:
	ret
main	endp

change_psize	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	; 输出"	Page Size: "
	mov		dx,offset mess_psize
	mov		ah,09h
	int		21h
	; 获取新的页大小
	mov		ah,01
	int		21h
	
	cmp		al,0dh
	jz		illeg
	sub		al,"0"
	mov		cl,al
getp:
	; 获取输入
	mov		ah,1
	int		21h
	cmp		al,0dh
	jz		pgot
	sub		al,"0"
	; 交换al和cl
	mov		dl,al
	mov		al,cl
	mov		cl,dl
	
	mov		bl,10
	mul		bl
	add		cl,al
	jmp		getp
pgot:
	; 输出回车
	mov		dl,0ah
	mov		ah,2
	int		21h
	
	cmp		cx,0
	jle		illeg
	cmp		cx,24
	jg		illeg
	mov		PgSize,cx	; 保证新页的大小在(0,24)范围内
illeg:
	; 输出回车
	mov		dl,0ah
	mov		ah,2
	int		21h
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	ret
change_psize	endp

openf	proc	near
	push	bx
	push	cx
	push	dx
	; 打开文件
	mov		dx,offset buf	; 磁盘缓冲区首地址装入buf中
	mov		al,0
	mov		ah,3dh
	int		21h
	mov		handle,ax	; (ax)=文件代号或错误码
	mov		ax,1
	jnc		ok	; jnc:无进位则跳转
	mov		ax,0	; 文件不存在
ok:
	pop		dx
	pop		cx
	pop		bx
	ret
openf	endp

getline	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	; 输出"	Please input filename: "
	mov		dx,offset mess_getname
	mov		ah,09h
	int		21h
	; 获取输入的文件名
	mov		dx,offset buf_size
	mov		ah,0ah
	int		21h
	; 输出回车
	mov		dx,offset	crlf
	mov		ah,09h
	int		21h
	; 在文件名结尾添加0
	mov		bl,s_buf
	mov		bh,0
	mov		[buf+bx],0
	
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	ret
getline	endp

read_block	proc	near
	push	bx
	push	cx
	push	dx
	cmp		cur,200
	jnz		back
	; 若buf中没有更多的字符可以被输出，则读取另外的200个字符
	call	clear	; 读取前先清空buf
	mov		cx,200
	mov		bx,handle
	mov		dx,offset buf
	mov		ah,3fh	; 读文件
	int		21h
	
	mov		cur,0
	mov		ax,1
	jnc		back
	mov		cur,200
	mov		ax,0
back:
	pop		dx
	pop		cx
	pop		bx
	ret
read_block endp

show_block 	proc	near
	push	ax
	push	dx
	mov		bx,cur
loop1:
	cmp		bx,200
	jl		lp
	jmp		exit	; 若buf为空则返回
lp:
	mov		dl,buf[bx]  ; 否则显示当前字符
	cmp		dl,0	    ; search the file end
	jz		exit_eof
	inc		bx
	inc		cur
	; 显示当前字符
	mov		ah,02
	int		21h
	
	cmp		dl,0ah		
	jz		exit_ln		; 如果字符是回车，说明一行已显示完，则返回
	
	jmp		loop1
exit_eof:
	mov		bx,0
exit_ln:
	dec		cx	; (cx)=剩余行数
exit:
	pop		dx
	pop		ax
	ret
show_block	endp

clear	proc	near	; 将buf中的数据全部置0
	push	bx
	push	cx
	
	mov		bx,0
	mov		cx,200
reset:
	mov		buf[bx],0
	inc		bx
	loop	reset
	
	pop		cx
	pop		bx
	ret
clear	endp

code	ends
end	start
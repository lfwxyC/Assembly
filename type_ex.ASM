stack	segment	para	stack	'stack'
		db		256		dup(0)
top		label	word
stack	ends

data	segment	para	public	'data'
buffer	db		16h	dup(0)
bufpt1	dw		0
bufpt2	dw		0
; bufpt1=bufpt2, buffer为空
kbflag	db		0
prompt	db	'	* PLEASE PRACITSE TYPING *', 0dh, 0ah, '$'
scantab	db	0, 0, '1234567890-=', 8, 0
		db	'qwertyuiop[]', 0dh, 0
		db	'asdfghjkl;', 0, 0, 0, 0
		db	'zxcvbnm,./', 0, 0, 0
		db	' ', 0, 0, 0, 0, 0 ,0, 0, 0, 0, 0, 0, 0, 0
		db	'789-456+1230.'
even
oldcs9	dw	?
oldip9	dw	?

str1	db	'abcd efgh ijkl mnop qrst uvwx yz.'
		db	0dh, 0ah, '$'
str2	db	'christmas is a time of joy and love.'
		db	0dh,0ah,'$'
str3	db	'store windows hold togs and gifts.'
		db	0dh,0ah,'$'
str4	db	'people send christmas cards and gifts.'
		db	0dh,0ah,'$'
str5	db	'santa wish all people peace on earth.'
		db	0dh,0ah,'$'
crlf	db	0dh,0ah,0ah,'$'
colon	db	':','$'
even
saddr	dw	str1,str2,str3,str4,str5
count	dw	0
sec		dw	0
min		dw	0
hours	dw	0
save_lc	dw	2	dup(?)
data	ends

code	segment
assume	cs:code, ds:data, ss:stack
main	proc	far
start:
		; set up stack
		mov		ax,stack
		mov		ss,ax
		mov		sp,offset	top
		
		push	ds
		sub		ax,ax
		push	ax
		mov		ax,data
		mov		ds,ax
		mov		es,ax
		
		; 保存键盘中断向量
		mov		ah,35h		; 取中断向量的功能调用
		mov		al,09h		; 中断类型
		int		21h			; 段址放入es,偏址放入bx
		mov		oldcs9,es	; 保存偏移地址
		mov		oldip9,bx	; 保存段地址
		
		; 设置kbint处理程序的中断向量
		push	ds				; 保存ds
		mov		dx,seg	kbint	; 自编中断例行程序偏移地址放入dx
		mov		ds,dx
		mov		dx,offset	kbint	; 自编中断例行程序段地址放入ds
		mov		al,09h			; 中断类型放入al
		mov		ah,25h			; 设置中断向量的功能调用
		int		21h				; 改变中断向量
		pop		ds				; 恢复ds
		
		; 保存timer中断向量
		mov		ah,35h
		mov		al,1ch
		int		21h
		mov		save_lc,bx
		mov		save_lc+2,es
		
		; 设置clint处理程序的中断向量
		push	ds
		mov		dx,seg	clint
		mov		ds,dx
		mov		dx,offset	clint
		mov		al,1ch
		mov		ah,25h
		int		21h
		pop		ds
		
		in		al,21h			; 清空kbd和timer的中断掩码
		and		al,11111100b	; 设置中断掩码
		out		21h,al
first:
		mov		ah,0	; set video mode
		mov		al,3	; 80*25 color text
		int		10h
		
		; 输出'	* PLEASE PRACITSE TYPING *'
		mov		dx,offset	prompt
		mov		ah,9	
		int		21h
		
		mov		si,0
next:
		; 显示句子
		mov		dx,saddr[si]
		mov		ah,09h
		int		21h
		
		; 初始化
		mov		count,0
		mov		sec,0
		mov		min,0
		mov		hours,0
		
		sti	; 开中断
forever:
		call	kbget	; 等待输入
		test	kbflag,80h
		jnz		endint
		push	ax
		call	dispchar	; 显示字符
		pop		ax
		cmp		al,0dh
		jnz		forever
		mov		al,0ah
		call	dispchar	; 显示回车/换行
		
		call	disptime	; 显示打字时间
		
		; 输出回车/换行
		lea		dx,crlf
		mov		ah,09h
		int		21h
		
		add		si,2	; 更新指针
		cmp		si,5*2	; 判断是否到最后一个句子
		jne		next	; 没有，显示下一句
		jmp		first	; 是，显示第一句
endint:	; end of typing
		; 恢复原来的中断向量
		cli
		push	ds	; 保存ds
		mov		dx,save_lc	; 取出保存的段地址
		mov		ax,save_lc+2	; 取出保存的偏移地址
		mov		ds,ax
		mov		al,1ch	; 重置1ch类型的中断向量
		mov		ah,25h	; 设置中断向量
		int		21h		; DOS调用
		pop		ds		; 恢复ds
		
		push	ds
		mov		dx,oldip9
		mov		ax,oldcs9
		mov		ds,ax
		mov		al,09h	; 重置09h类型的中断向量
		mov		ah,25h
		int		21h
		pop		ds
		
		sti
		ret
main	endp

clint	proc	near	; timer int routine
		push	ds		; save ROM data area
		mov		bx,data
		mov		ds,bx
		
		lea		bx,count
		inc		WORD ptr[bx]	; count++
		cmp		WORD ptr[bx],18	; 1秒=18 count
		jne		return	; 不相等则返回
		call	inct	; 更新秒和分
adj:
		cmp		hours,12 ; 更新小时
		jle		return
		sub		hours,12
return:
		pop		ds
		sti
		iret	; 中断返回
clint	endp

inct	proc	near	; 更新秒和分
		mov		WORD ptr[bx],0
		add		bx,2
		inc		WORD ptr[bx]
		cmp		WORD ptr[bx],60
		jne		exit
		call	inct 
exit:
		ret	; 返回到clint
inct	endp

disptime	proc	near
		mov		ax,min
		call	bindec	; 显示分
		
		; 显示':'
		mov		bx,0
		mov		al,':'
		mov		ah,0eh
		int		10h
		
		mov		ax,sec
		call	bindec	; 显示秒
		
		; 显示':'
		mov		bx,0
		mov		al,':'
		mov		ah,0eh
		int		10h
		
		; count转换成秒
		mov		bx,count
		mov		al,55d
		mul		bl
		call	bindec	; 显示毫秒
		
		ret	; 返回到main函数
disptime	endp

bindec	proc	near	; 二进制转十进制，结果存放在ax中
		mov		cx,100d
		call	decdiv
		mov		cx,10d
		call	decdiv
		mov		cx,1
		call	decdiv
		ret	; 返回到disptime
bindec	endp

decdiv	proc	near ; divide number in ax by cx
		mov		dx,0
		div		cx
		
		mov		bx,0
		add		al,30h
		mov		ah,0eh
		int		10h
		
		mov		ax,dx
		ret	
decdiv	endp

kbget	proc	near
		push	bx
		cli
		mov		bx,bufpt1
		cmp		bx,bufpt2
		jnz		kbget2
		cmp		kbflag,0
		jnz		kbget3
		sti
		pop		bx
		jmp		kbget
kbget2:
		mov		al,[buffer+bx]
		inc		bx
		cmp		bx,16
		jc		kbget3
		mov		bx,0
kbget3:
		mov		bufpt1,bx
		pop		bx
		ret
kbget	endp

kbint	proc	far
		push	bx
		push	ax
		
		in		al,60h
		push	ax
		in		al,61h
		or		al,80h
		out		61h,al
		and		al,7fh
		out		61h,al
		
		pop		ax
		test	al,80h
		jnz		kbint2
		mov		bx,offset	scantab
		xlat	scantab
		cmp		al,0
		jnz		kbint4
		mov		kbflag,80h
		jmp		kbint2
kbint4:
		mov		bx,bufpt2
		mov		[buffer+bx],al
		inc		bx
		cmp		bx,16
		jc		kbint3
		mov		bx,0
kbint3:
		cmp		bx,bufpt1
		jz		kbint2
		mov		bufpt2,bx
kbint2:
		cli
		mov		al,20h
		out		20h,al
		pop		ax
		pop		bx
		sti
		iret
kbint	endp

dispchar	proc	near
		push	bx
		mov		bx,0
		mov		ah,0eh
		int		10h
		pop		bx
		ret
dispchar	endp

code	ends
		end		start
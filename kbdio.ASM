stack	segment	para	stack	'stack'
		db		256		dup(0)
stack	ends

data	segment	para	public	'data'
buffer	db		16h		dup(0)
bufpt1	dw		0
bufpt2	dw		0
; bufpt1=bufpt2时，buffer为空
kbflag	db		0
prompt	db	'--- kbd_io program begin ---', 0dh, 0ah, '$'
scantab	db	0, 0, '1234567890-=', 8, 0
		db	'qwertyuiop[]', 0dh, 0
		db	'asdfghjkl;', 0, 0, 0, 0
		db	'zxcvbnm,./', 0, 0, 0
		db	' ', 0, 0, 0, 0, 0 ,0, 0, 0, 0, 0, 0, 0, 0
		db	'789-456+1230.'
even ; 数据对齐的伪指令，使得下一个变量的起始地址是偶数字节
oldcs9	dw	?
oldip9	dw	?
data	ends

code	segment	para	public	'code'
start	proc	far
		assume	cs:code, ds:data
		push	ds
		mov		ax,0
		push	ax
		mov		ax,data
		mov		ds,ax
		
		cli ; 禁止中断发生
		; 保存BIOS中断向量
		mov		al,09
		mov		ah,35h
		int		21h
		mov		oldcs9,es
		mov		oldip9,bx
		
		; 设置kbint的中断向量
		push	ds
		mov		dx,offset	kbint
		mov		ax,seg	kbint
		mov		ds,ax
		mov		al,09
		mov		ah,25h
		int		21h
		pop		ds
		
		; 设置中断掩码
		in		al,21h
		and		al,0fdh
		out		21h,al
		
		; 输出'--- kbd_io program begin ---'
		mov		dx,offset prompt
		mov		ah,9
		int		21h
		sti ; 开中断
forever:
		call	kbget ; 等待输入
		test	kbflag,80h ; test: 对两个操作数进行逻辑按位与
		jnz		endint	; kbflag=80h则跳转
		push	ax	;(ax)=要显示的字符
		call	dispchar ; 显示一个字符
		pop		ax
		cmp		al,0dh
		jnz		forever
		mov		al,0ah
		call	dispchar ; 显示换行/回车
		jmp		forever
endint: ; 恢复旧中断
		mov		dx,oldip9 
		mov		ax,oldcs9
		mov		ds,ax	
		mov		al,09h
		mov		ah,25h
		int		21h
		
		ret
start	endp

kbget	proc	near
		push	bx
		cli ; 关中断
		mov		bx,bufpt1 ; 获取头指针
		cmp		bx,bufpt2 ; 判断buffer是否为空
		jnz		kbget2 ; 不为空则获取一个字符
		cmp		kbflag,0
		jnz		kbget3
		sti ; 开中断
		pop		bx
		jmp		kbget
kbget2:
		mov		al,[buffer+bx] ; 获取ascii码
		inc		bx ; 头指针向后移一个
		cmp		bx,16 ; 判断是否移动到buffer的最后
		jc		kbget3 ;若没有则继续
		mov		bx,0 ; 重置为buffer的开头
kbget3:
		mov		bufpt1,bx ; 保存指针位置
		pop		bx
		ret
kbget	endp

kbint	proc	far ; 键盘中断程序
		push	bx
		push	ax
		
		in		al,60h ; 读取字符
		push	ax ; 保存字符
		in		al,61h	; 获取控制端口
		or		al,80h	; set acknowledge bit for kbd
		out		61h,al
		and		al,7fh	;reset acknowledge bit
		out		61h,al
		
		pop		ax	; 恢复扫描码
		test	al,80h	; is press or release code?
		jnz		kbint2	; is release code, return
		mov		bx,offset	scantab
		xlat	scantab ; xlat: 将ds:[bx+al]送入al
		cmp		al,0
		jnz		kbint4
		mov		kbflag,80h
		jmp		kbint2
kbint4:
		mov		bx,bufpt2	; buffer的尾指针
		mov		[buffer+bx],al ; ascii放入buffer
		inc		bx
		cmp		bx,16 ; 判断是否到达buffer的最后
		jc		kbint3	; 没有
		mov		bx,0 ; 重置到buffer的开头
kbint3:
		cmp		bx,bufpt1	; 判断buffer是否已满
		jz		kbint2	; 是，尾指针不再向后移动
		mov		bufpt2,bx ; 保存buffer的尾指针
kbint2:
		cli
		mov		al,20h	; end of interrupt
		out		20h,al
		pop		ax
		pop		bx
		sti
		iret	; 中断返回
kbint	endp

dispchar	proc	near	; (al)=要显示的字符
		push	bx
		mov		bx,0
		mov		ah,0eh
		int		10h	; call video routine
		pop		bx
		ret
dispchar	endp

code	ends
		end		start
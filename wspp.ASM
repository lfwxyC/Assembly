dseg	segment
	kbd_buf	db	96	dup(' ')	; 输入缓冲区
	cntl	db	16	dup(0)		; 每一行的字符数
	bufpt	dw	0				; 缓冲区的头指针
	buftl	dw	0				; 缓冲区的尾指针
	colpt	db	0				; 当前列指针
	rowpt	db	0				; 当前行指针
	rowmx	dw	0				; 当前最大行数
dseg	ends

curs	macro	row,col			; 设置光标位置
		mov		dh,row
		mov		dl,col
		mov		bh,0
		mov		ah,2
		int		10h
		endm

cseg	segment
main	proc	far
assume	cs:cseg, ds:dseg, es:dseg
start:
		push	ds
		sub		ax,ax
		push	ax
		mov		ax,dseg
		mov		ds,ax
		mov		es,ax
		
		; 初始化指针
		mov		buftl,0
		mov		colpt,0
		mov		rowpt,0
		mov		bufpt,0
		mov		rowmx,0
		; 初始化cntl area
		mov		cx,length cntl
		mov		al,0
		lea		di,cntl
		cld
		rep		stosb	; stosb: 把al的内容送至di中
		
		; 清屏
		mov		ah,6
		mov		al,0
		mov		cx,0
		mov		dh,24
		mov		dl,79
		mov		bh,07
		int		10h
		
		curs	0,0 	; 设置光标位置在(0,0)处
read_k:
		mov		ah,0	; 从kbd中读取字符
		int		16h		; call ROM routine
		cmp		al,1bh	; 判断是否是ESCape
		jnz		arrow
		ret				; 是，返回DOS
arrow:
		cmp		ah,4bh	; 判断是否是←键
		jz		left	; 是，移动光标
		cmp		ah,4dh	; 判断是否是→键
		jz		right	; 是右键则跳转
		
inst:
		jmp		ins_k
left:
		jmp		left_k
right:
		jmp		right_k

ins_k:
		mov		bx,bufpt	; 插入字符
		mov		cx,buftl
		cmp		bx,cx		; bufpt==buftl?
		je		km			; 相等，字符放入buffer
		lea		di,kbd_buf	; 不相等，buffer向后移动一个byte
		add		di,cx
		mov		si,di
		dec		si
		sub		cx,bx 		; (cx)=要移动的字符长度
		std					; 从后往前复制
		rep		movsb
km:
		mov		kbd_buf[bx],al	; 把字符放进buffer
		inc		bufpt	; 头指针向后移动一个
		inc		buftl	; 尾指针向后移动一个
		cmp		al,0dh	; 判断是否要插入回车
		jnz		kn		; 不是
		lea		si,cntl	; 是，move the count of each row backword
		add		si,rowmx
		inc		si
		mov		di,si
		inc		di
		mov		cx,rowmx
		sub		cl,rowpt
		std
		rep		movsb
		
		; 调整当前行和下一行的字符数
		mov		bl,rowpt	
		xor		bh,bh
		mov		cl,colpt	; (cl)=光标前的字符数
		mov		ch,cntl[bx]
		sub		ch,colpt	; (ch)=光标后的字符数
		mov		cntl[bx],cl
		mov		cntl[bx+1],ch
		
		; clear displaying row use scroll function
		mov		ax,rowmx	
		mov		bh,07
		mov		ch,rowpt
		mov		dh,24
		mov		cl,0
		mov		dl,79
		mov		ah,6
		int		10h
		
		inc		rowpt		; 当前行指针指向下一行
		inc		rowmx		; 当前最大行数+1
		mov		colpt,0		; 当前列指针指向第0列
		jmp		short	kp
kn:
		mov		bl,rowpt
		xor		bh,bh
		inc		cntl[bx]	; inc current row count
		inc		colpt		; 列指针指向下一列
kp:
		call	dispbf		; 显示输入的buffer
		curs	rowpt,colpt	; 设置光标
		jmp		read_k
left_k:
		cmp		colpt,0		; 判断是否在第0列
		jnz		k2			; 不是
		cmp		rowpt,0		; 判断是否在第0行
		jz		lret		; 是，光标不移动
		dec		rowpt		; 指向上一行
		mov		al,rowpt
		lea		bx,cntl
		xlat	cntl		; xlat: 将ds:[bx+al]送入al
		mov		colpt,al	; 指向上一行行末
		jmp		k3
k2:
		dec		colpt		; 当前列指针指向前一列
k3:
		dec		bufpt		; 当前buffer指针向前移动一个
		curs	rowpt,colpt	; 设置光标
lret:
		jmp		read_k
right_k:
		mov		bx,bufpt	; 判断是否在文件末尾
		cmp		bx,buftl
		je		rret		; 是，光标不移动
		inc		colpt		; 当前列指针指向下一列
		cmp		kbd_buf[bx],0dh	; 判断是否是回车
		jnz		k4			; 不是
		inc		rowpt		; 是，当前行指针指向下一行的第0列
		mov		colpt,0
k4:
		inc		bufpt		; 调整buffer指针
		curs	rowpt,colpt	; 设置光标
rret:
		jmp		read_k

dispbf	proc	near		; 显示buffer里的字符
		mov		bx,0
		mov		cx,96
		curs	0,0
disp:
		mov		al,kbd_buf[bx]
		push	bx
		mov		bx,0700
		mov		ah,0eh
		int		10h			; call ROM routine
		pop		bx
		cmp		al,0dh		; 判断是否是回车
		jnz		kk
		mov		al,0ah		; 是，显示换行
		mov		ah,0eh
		int		10h			; video call
kk:
		inc		bx
		loop	disp
		ret
dispbf	endp

main	endp

cseg	ends
		end		start
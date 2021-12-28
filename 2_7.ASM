stacksg	segment	para	stack	'stack'
		dw		32 dup(?)
stacksg	ends

datasg	segment	para	'data'
	;存放输入的工作时间
	hrspar		label	byte
	maxhlen		db		6
	acthlen		db		?
	hrstld		db		6 dup(?)
	;存放输入的工资率
	ratepar		label	byte
	maxrlen		db		6
	actrlen		db		?
	ratetld		db		6 dup(?)
	
	messg1		db		'Hours workded?','$'
	messg2		db		'Rate of pay?','$'
	messg3		db		'Wage = '
	ascwage		db		14 dup(30h),13,10,'$' ;要输出的工资
	
	messg4		db		13,10,'Overflow!',13,10,'$'
	adjust		dw		? ;记录舍入值
	binval		dw		0 ;ascii码转换的二进制数
	binhrs		dw		0 ;二进制的工作时间
	binrate		dw		0 ;二进制的工资率
	col			db		0 ;光标的列数
	decind		db		0 ;小数点标志位
	mult10		dw		01
	nodec		dw		0 ;两个输入数的小数点后位数之和
	row			db		0 ;光标的行数
	shift		dw		? ;记录移位因子
	tenwd		dw		10
	tempdx		dw		? ;暂存dx
	tempax		dw		? ;暂存ax
datasg	ends

codesg	segment	para	'code'

begin	proc	far
		assume cs:codesg,ds:datasg,ss:stacksg,es:datasg
		
		push	ds
		sub		ax,ax
		push	ax
		
		mov		ax,datasg
		mov		ds,ax
		mov		es,ax
		
		mov		ax,0600h 
 		call	q10scr ;清除屏幕
 		call	q20curs ;设置光标
a20loop:
		call	b10inpt ;获取工作时间和工资率
		cmp		acthlen,0 ;输入结束
		je		a30
		call	d10hour ;工作时间转二进制
		call	e10rate ;工资率转二进制
		call	f10mult ;工作时间*工资率
		call	g10wage ;工资转ascii码
		call	k10disp ;输出工资
		jmp		a20loop
a30:
		mov		ax,0600h
		call	q10scr ;清屏
		ret
begin	endp

b10inpt	proc	near
		;输出"hours worked?"
		lea		dx,messg1
		mov		ah,09h
		int		21h
		;获取输入的工作时间
		lea		dx,hrspar
		mov		ah,0ah
		int		21h
		
		cmp		acthlen,0 ;没有输入直接返回
		jne		b20
		ret
b20:
		mov		col,25 ;设置列数
		call	q20curs ;设置光标
		;输出"rate of pay?"
		lea		dx,messg2
		mov		ah,09h
		int		21h
		;获取输入的工资率
		lea		dx,ratepar
		mov		ah,0ah
		int		21h
		ret
b10inpt	endp

d10hour	proc	near
		mov		nodec,0
		;si指向hrstld的最右端
		mov		cl,acthlen
		sub		ch,ch
		lea		si,hrstld - 1
		add		si,cx 
		
		call	m10asbi ;转二进制
		mov		ax,binval
		mov		binhrs,ax
		ret
d10hour	endp

e10rate	proc	near
		;si指向ratetld的最右端
		mov		cl,actrlen
		sub		ch,ch
		lea		si,ratetld - 1
		add		si,cx
		
		call	m10asbi ;转二进制
		mov		ax,binval
		mov		binrate,ax
		ret
e10rate	endp

f10mult	proc	near 
		mov		cx,07
		lea		di,ascwage
		mov		ax,3030h
		cld
		rep		stosw ;将ax的内容存入es:di
		
		mov		shift,10
		mov		adjust,0
		mov		cx,nodec
		cmp		cl,06
		ja		f40 ;>6溢出
		dec		cx
		dec		cx
		jle		f30 ;nodec=0,1,2不做舍入及移位处理
		mov		nodec,02 ;输出保留两位小数
		mov		ax,01
f20: ;计算移位因子
		mul		tenwd
		loop	f20
		
		mov		shift,ax
		shr		ax,1 ;ax逻辑右移1位
		mov		adjust,ax ;计算舍入值
f30:
		;计算工资
		mov		ax,binhrs
		mul		binrate
		;舍入工资
		add		ax,adjust
		add		dx,0
		;保存dx,ax
		mov		tempdx,dx
		mov		tempax,ax
		
		cmp		adjust,0 ;没有舍入直接返回
		jz		f50
		
		;做舍入及移位处理
		mov		ax,dx
		mov		dx,0
		div		shift
		mov		tempdx,ax
		mov		ax,tempax
		div		shift
		mov		dx,tempdx
		mov		tempax,ax
		jmp		f50
f40:
		mov		ax,0
		mov		dx,0
f50:
		ret
f10mult	endp

g10wage	proc	near ;dx:ax的二进制转ascii码
		lea		si,ascwage+11 ;输出的整数部分共10位
		mov		BYTE ptr[si],'.'
		add		si,nodec ;si指向ascwage的最右端
g30:
		cmp		BYTE ptr[si],'.'
		jne		g35 ;si指向数字则跳过
		dec		si
g35:
		cmp		dx,0
		jnz		g40 ;dx不为0则跳转
		cmp		ax,0010 ;ax<10则跳转
		jb		g50
g40: ;二进制转ascii码
		mov		ax,dx
		mov		dx,0
		div		tenwd
		mov		tempdx,ax
		mov		ax,tempax
		div		tenwd
		mov		tempax,ax
		or		dl,30h
		mov		[si],dl
		dec		si
		mov		dx,tempdx
		jmp		g30
g50:
		or		al,30h
		mov		[si],al
		ret
g10wage	endp

k10disp	proc	near
		mov		col,50 ;设置列数
		call	q20curs ;设置光标
		mov		cx,10 ;循环小数点前的10位整数
		lea		si,ascwage
k20:
		cmp		BYTE ptr[si],30h
		jne		k30 ;高位的0不输出
		mov		BYTE ptr[si],20h ;高位的0置为blank
		inc		si
		loop	k20
k30:
		;输出"wage = "
		lea		dx,messg3
		mov		ah,09
		int		21h
		
		cmp		row,20 ;判断是否到屏幕底部
		jae		k80 ;>=20则跳转
		inc		row
		jmp		k90
k80:
		mov		ax,0601h ;滚动屏幕
		call	q10scr ;清屏
		mov		col,0 ;设置列数
		call	q20curs ;设置光标
k90:	ret
k10disp	endp

m10asbi	proc	near ;ascii码转二进制
		mov		mult10,01
		mov		binval,0
		mov		decind,0
		sub		bx,bx ;记录小数位数
m20:
		mov		al,[si]
		cmp		al,'.'
		jne		m40 ;处理数字
		mov		decind,01 ;有小数点则标志位置1
		jmp		m90
m40:
		and		ax,000fh
		mul		mult10
		jc		overflow ;jc:运算进位则跳转
		add		binval,ax
		jc		overflow
		;mult10 *= 10
		mov		ax,mult10
		mul		tenwd
		mov		mult10,ax
		
		cmp		decind,0
		jnz		m90 ;小数点后的数处理完了
		inc		bx
m90:
		dec		si
		loop	m20
		
		cmp		decind,0
		jz		m100
		add		nodec,bx
		jmp		m100
overflow:
		mov		binval,0
m100:	ret
m10asbi	endp

q10scr	proc	near
		mov		bh,07
		sub		cx,cx
		mov		dx,184fh
		int		10h
		ret
q10scr	endp

q20curs	proc	near
		mov		ah,2
		sub		bh,bh
		mov		dh,row
		mov		dl,col
		int		10h
		ret
q20curs	endp

codesg	ends
		end		begin
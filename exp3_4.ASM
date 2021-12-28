dseg	segment
	;左窗口光标位置
	lx	db	15
	ly	db	10
	;右窗口光标位置
	rx	db	15
	ry	db	50
	;下窗口光标位置
	dwx	db	22
	dwy	db	15
	
	win	db	1	;当前光标所在窗口，0表示左窗口，1表示右窗口
dseg	ends

scroll	macro	ulrow,ulcol,lrrow,lrcol,att,cont	;向上卷动
		mov		ah,6
		mov		al,cont
		mov		ch,ulrow
		mov		cl,ulcol
		mov		dh,lrrow
		mov		dl,lrcol
		mov		bh,att
		int		10h
		endm

clear	macro			;清屏
		mov	ah,6
		mov	al,0
		mov	ch,0
		mov	cl,0
		mov	dh,24
		mov	dl,79
		mov	bh,7
		int	10h
		endm

get_char	macro	;接收输入字符，并判断是否是ESCape、←或→键
input:
		mov	ah,0
		int	16h
		
 		cmp	ah,4bh
 		jnz	no_left	;不是←键则跳转
 		
 		pos_curse	lx,ly	;光标移动到左窗口
 		mov	win,0
 		jmp	input
no_left:
 		cmp	ah,4dh
 		jnz	no_right	;不是→键则跳转
 		
 		pos_curse	rx,ry	;光标移动到右窗口
 		mov	win,1
 		jmp	input
no_right:
 		cmp	ah,01
 		jnz	disp	;不是ESCape则跳转
 		
 		ret	;结束运行
disp:
 		display	;在左或右窗口输出
 		;在下窗口输出
 		pos_curse	dwx,dwy
 		display
 		
 		inc	dwy	;下窗口光标右移
 		mov	al,dwy
 		cmp	al,65	;判断下窗口一行字符是否显示满
 		jl	left_win
 		
 		scroll 18,15,22,65,70h,1 ;显示满则下窗口向上卷动一行
 		mov	dwy,15	;重置下窗口光标
left_win:
 		cmp	win,0	;判断当前光标在左还是右窗口
 		jnz	right_win
 		
 		inc	ly	;左窗口光标右移
 		mov	al,ly
 		cmp	al,30		;判断左窗口一行字符是否显示满
 		jl	left_next
 		
 		scroll	5,10,15,30,70h,1	;显示满则左窗口向上卷动一行
 		mov	ly,10	;重置左窗口光标
left_next:
		pos_curse	lx,ly
		jmp	input
right_win:
		inc	ry	;右窗口光标右移
		mov	al,ry
		cmp	al,70	;判断右窗口一行字符是否显示满
		jl	right_next
		
		scroll	5,50,15,70,70h,1	;显示满则右窗口向上卷动一行
		mov	ry,50	;重置右窗口光标
right_next:
		pos_curse	rx,ry
 		jmp	input
		endm

display	macro	;在屏幕上显示字符
		mov	ah,0ah
		mov	bh,0
		mov	cx,1
		int	10h
endm

pos_curse	macro	row,col	;光标定位
		mov	ah,2
		mov	dh,row
		mov	dl,col
		mov	bh,0
		int	10h
		endm

cseg	segment
		assume cs:cseg, ds:dseg
main	proc	far
		push	ds
		sub		ax,ax
		push	ax
		mov		ax,dseg
		mov		ds,ax
		
		clear
		;显示三个窗口
		scroll	5,10,15,30,70h,10
		scroll	5,50,15,70,70h,10
		scroll	18,15,22,65,70h,4
		;光标首先定位在右窗口最下面一行的行首
		pos_curse	rx,ry

		get_char	;从键盘输入字符
main	endp

cseg	ends
		end	main
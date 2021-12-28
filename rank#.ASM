datarea	segment
	grade	dw	50 dup(?)
	rank	dw	50 dup(?)
	count	dw	? ;学生人数
	mess1	db	'Grade?$'
	mess2	db	13,10,'Input Error!',13,10,'$'
	mess3	db	'Rank:$'
datarea	ends

prognam	segment
main	proc	far
		assume cs:prognam, ds:datarea
start:
		push	ds
		sub		ax,ax
		push	ax
		
		mov		ax,datarea
		mov		ds,ax
		
		call	input
		call	rankp
		call	output
		ret
main	endp

input	proc	near
		;输出"Grade?"
		lea		dx,mess1
		mov		ah,09
		int		21h
		
		mov		si,0 ;指向grade的指针
		mov		count,0 ;初始化count=0
enter:
		call	decibin
		inc		count
		cmp		dl,','
		je		store
		cmp		dl,13 ;读到回车则停止输入
		je		exit2
		jne		error
store:
		mov		grade[si],bx
		add		si,2
		jmp		enter
error:
		;输出"input error!"
		lea		dx,mess2 
		mov		ah,09
		int		21h
exit2:
		mov		grade[si],bx
		call	crlf
		ret
input	endp

rankp	proc	near
		mov		di,count ;外层循环次数
		mov		bx,0 ;指向grade的指针
loop1:
		mov		ax,grade[bx]
		mov		WORD ptr rank[bx],0 ;初始化rank[i]=0
		mov		cx,count ;内层循环次数
		lea		si,grade
next:
		cmp		ax,[si] ;>则跳转
		jg		no_count
		inc		WORD ptr rank[bx]
no_count:
		add		si,2
		loop	next
		add		bx,2
		dec		di
		jne		loop1
		ret
rankp	endp

output	proc	near
		;输出"rank:"
		lea		dx,mess3
		mov		ah,09
		int		21h
		
		mov		si,0 ;指向rank的指针
		mov		di,count ;循环次数
next1:
		mov		bx,rank[si]
		call	binidec
		;输出','
		mov		dl,','
		mov		ah,02
		int		21h
		
		add		si,2
		dec		di
		jnz		next1
		call	crlf
		ret
output	endp

decibin	proc	near ;将输入的十进制转二进制
		mov		bx,0 ;bx存放number
newchar:
		;获取键盘输入
		mov		ah,1
		int		21h
		
		mov		dl,al ;保存键盘输入
		sub		al,30h ;ascii码转二进制
		jl		exit1 ;<0返回
		cmp		al,9d ;>9d返回
		jg		exit1
		cbw ;BYTE in AL to WORD in AX
		
 		xchg	ax,bx ;交换ax和bx
 		mov		cx,10d
 		mul		cx ;cx * ax
 		xchg	ax,bx
		
		add		bx,ax
		jmp		newchar
exit1:
		ret
decibin	endp

binidec	proc	near ;二进制转十进制
		push	bx
		push	cx
		push	si
		push	di
		mov		cx,100d ;百位
		call	dec_div
		mov		cx,10d ;十位
		call	dec_div
		mov		cx,1d ;个位
		call	dec_div
		pop		di
		pop		si
		pop		cx
		pop		bx
		ret
binidec	endp

dec_div	proc	near ;计算bx/dx
		mov		ax,bx ;ax:除数和商
		mov		dx,0 ;dx:余数
		div		cx ;ax/cx
		mov		bx,dx
		mov		dl,al
		
		add		dl,30h ;转ascii码
		;输出dl
		mov		ah,02h
		int		21h
		ret
dec_div	endp

crlf	proc	near ;输出换行和回车
		mov		dl,0ah
		mov		ah,02h
		int		21h
		
		mov		dl,0dh
		mov		ah,02h
		int		21h
		ret
crlf	endp

prognam	ends
		end		start
datarea segment
	grade	dw	88,75,95,63,98,78,87,73,90,60
	rank	dw	10 dup(?)
datarea ends

prognam segment

main	proc	far
		assume cs:prognam, ds:datarea
start:
		push	ds
		sub		ax,ax
		push	ax
		
		mov		ax,datarea
		mov		ds,ax
		
		mov		di,10 ;外循环计数值
		mov		bx,0  ;i
loop1:
		mov		ax,grade[bx]
		mov		dx,0  ;名次
		mov		cx,10 ;内循环计数值
		lea		si,grade
next:
		cmp		ax,[si]
		jg		no_count ;jg:大于则跳转
		inc		dx
no_count:
		add		si,2
		loop	next
		mov		rank[bx],dx
		add		bx,2
		dec		di
		jne		loop1
		ret
main	endp
prognam ends
		end		start
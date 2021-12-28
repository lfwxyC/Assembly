datarea		segment
	grade	dw		56, 69, 84, 82, 73, 88, 99, 63, 100, 80
	s5		dw		0
	s6		dw		0
	s7		dw		0
	s8		dw		0
	s9		dw		0
	s10		dw		0
datarea		ends

prognam		segment

main		proc	far
			assume cs:prognam, ds:datarea ;将段和寄存器关联起来
start:
			push	ds
			sub		ax,ax
			push	ax
			
			mov		ax,datarea
			mov		ds,ax
			
			mov		s5,0
			mov		s6,0
			mov		s7,0
			mov		s8,0
			mov		s9,0
			mov		s10,0
			mov		cx,10 ;循环遍历10个成绩
			mov		bx,offset grade ;取得标号grade的偏移地址
compare:
			mov		ax,[bx]
			cmp		ax,60
			jl		five ;jl:小于时跳转
			cmp		ax,70
			jl		six
			cmp		ax,80
			jl		seven
			cmp		ax,90
			jl		eight
			cmp		ax,100
			jne		nine ;jne:不等于则跳转
			inc		s10
			jmp		short change_addr
nine:		inc		s9
			jmp		short change_addr
eight:		inc		s8
			jmp		short change_addr
seven:		inc		s7
			jmp		short change_addr
six:		inc		s6
			jmp		short change_addr
five:		inc		s5
change_addr:
			add		bx,2
			loop	compare
			ret
main		endp

prognam		ends
			end		start
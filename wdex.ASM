dseg	segment
cury	db		0		;current row
curx	db		0		;current column
luy		db		10		;upper_left row
lux		db		30		;upper_left col
rdy		db		15		;lower_right row
rdx		db		40		;lower_right col
cont	db		5		;row num of window
dseg	ends

clear	macro			;clear screen macro
		mov	ah,6
		mov	al,0
		mov	ch,0
		mov	cl,0
		mov	dh,24
		mov	dl,79
		mov	bh,7
		int	10h
		endm
scroll	macro	cont	;make a window macro
		mov		ah,6
		mov		al,cont
		mov		ch,luy
		mov		cl,lux
		mov		dh,rdy
		mov		dl,rdx
		mov		bh,70h
		int		10h
		endm
postc	macro			;position cursor macro
		mov	ah,2
		mov	dh,cury
		mov	dl,curx
		mov	bh,0
		int	10h
		endm

cseg	segment
		assume cs:cseg, ds:dseg
main	proc	far
		push	ds		;save for return
		sub		ax,ax
		push	ax
		mov		ax,dseg	;set data segment addr.
		mov		ds,ax
		
		clear			;clear screen
		scroll	cont	;make a window in centre
		postc			;position cursor at (0,0)
input:
		mov		ah,0	;keyboard input function
		int		16h
		
		cmp		ah,4bh
		jnz		no_left
		
		cmp		curx,0
		jnz		l1
		cmp		cury,0
		jnz		l3
		jmp		input
l1:
		dec		curx
		jmp		l5
l3:
		dec		cury
		mov		curx,79
l5:
		postc
		jmp		input

no_left:
		cmp		ah,4dh
		jnz		no_right
		
		cmp		curx,79
		jnz		r1
		cmp		cury,24
		jnz		r3
		jmp		input
r1:
		inc		curx
		jmp		r5
r3:
		inc		cury
		mov		curx,0
r5:
		postc
		jmp		input

no_right:
		cmp		ah,48h
		jnz		no_up
		
		cmp		cury,0
		jz		up1
		dec		cury
		postc
up1:
		jmp		input

no_up:
		cmp		ah,50h
		jnz		no_down
		
		cmp		cury,24
		jz		d1
		inc		cury
		postc
d1:
		jmp		input

no_down:
		cmp		ah,4fh
		jz		setxy
		cmp		ah,01
		jnz		disp
		
		ret
		
disp:
		mov		ah,0ah	;display a character
		mov		bh,0	;video page
		mov		cx,1	;count of repeat
		int		10h		;video ROM call
		inc		curx
		mov		al,curx
		cmp		al,rdx
		jl		next
		scroll	1
		mov		al,lux
		mov		curx,al
next:
		postc
		jmp		input

setxy:
		mov		al,cury
		mov		bl,curx
		cmp		al,luy
		jl		s1
		cmp		bl,lux
		jl		s2
		mov		rdy,al
		mov		rdx,bl
		jmp		new
s1:
		cmp		bl,rdx
		jle		s3
		jmp		input
s2:
		cmp		al,rdy
		jg		s5
s3:
		mov		luy,al
		mov		lux,bl
new:
		mov		al,rdy
		sub		al,luy
		inc		al
		mov		cont,al
		clear
		scroll	cont
s5:
		jmp		input

main	endp

cseg	ends
		end		main
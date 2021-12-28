dataseg		segment
	freq	dw 262,294,330,262,262,294,330,262			;do re mi do do re mi do
			dw 330,349,392,330,349,392					;mi fa sol mi fa sol
			dw 392,440,392,349,330,262					;sol la sol fa mi do
			dw 392,440,392,349,330,262					;sol la sol fa mi do
			dw 294,196,262,294,196,262					;re so do re so do

    time   dw 2500,2500,2500,2500,2500,2500,2500,2500 ;节拍决定音长
 		   dw 2500,2500,5000,2500,2500,5000
 		   dw 1200,1200,1200,1200,2500,2500
           dw 1200,1200,1200,1200,2500,2500
           dw 2500,2500,5000,2500,2500,5000
dataseg		ends
;
prog	segment
main 	proc 	far
	assume cs:prog, ds:dataseg
	org	   100h
start:
	push 	ds
	mov 	ax, 0
	push 	ax
	mov 	ax, dataseg
	mov 	ds, ax	
	lea 	di, freq		
	lea 	si, time		
	mov 	cx, 32d			
new_one:
	push	cx ; 保存外循环次数		
	call 	sound	
	add		di,2 ; 取下一个频率
	add		si,2 ; 取下一个节拍
	mov		cx,4000h ; 设置延迟时间	
silent:loop	silent	; 延迟
	pop		cx ; 获取外循环次数
	loop	new_one		
	mov		al,48h
	out		61h,al ; 重置输出端口
	ret
main 	endp
;
sound	proc	near
	in 		al, 61h
	and 	al, 11111100b
sing:
	xor		al,2 ; 打开扬声器
	out 	61h, al			
	push	ax ; 保存ax
	call 	widt			
	pop		ax ; 获取ax
	mov 	cx, dx			; the number of loop instruction
waits:
	loop 	waits
	dec 	WORD ptr[si] ; 循环次数为节拍数
	jnz 	sing
	and 	al, 11111100b
	out 	61h, al
	ret
sound	endp
;
widt	proc	near
	mov 	ax, 2801
	mov		bx,50
	mul		bx
	div		WORD ptr[di] ; div(di)
	mov		dx,ax
	ret
widt	endp
prog	ends
	end 	start
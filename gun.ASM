prognam	segment

main	proc	far
		assume	cs:prognam
		org		100h
start:
		mov		cx,50d ; 射击的次数
new_shot:
		push	cx ; 保存次数
		call	shoot
		mov		cx,4000h ; set up silent delay
silent:
		loop	silent ; silent delay
		pop		cx ; 获取次数
		loop	new_shot ; 循环射击
		mov		al,48h
		out		61h,al ; 重置输出端口
		int		20h
main	endp

shoot	proc	near
		mov		dx,140h ; 等待时长
		mov		bx,20h
		; 采用位触发方式发声
		in		al,61h 
		and		al,11111100b ; 关断定时器通道2的门控
sound:
		xor		al,2 ; 触发61H端口第1位
		out		61h,al ; 输出到61H端口
		add		dx,9248h ; add random pattern
		; dx循环右移3位
		mov		cl,3
		ror		dx,cl
		mov		cx,dx ; (dx)=控制脉宽的计数值
		and		cx,1ffh
		or		cx,10 ; 保证间隔不会太短
wait1:	
		loop	wait1 ; 延时循环
		
		dec		bx ;(bx)=脉冲持续的时间
		jnz		sound
		
		and		al,11111100b
		out		61h,al ; 恢复61H端口
		ret
shoot	endp

prognam	ends

		end	start
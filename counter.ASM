datasg		segment	para	'data'
	counter	db		3 dup(0) ;存放结果，数字，大写字母，小写字母
	mess	db		'string?', 13, 10, '$' ;输出提示内容
	;存放输入字符串
	strnin	label	byte
		max	db		100
		act	db		?
	   strn	db		100 dup(?)
datasg		ends

codesg		segment	para	'code'
			assume cs:codesg, ds:datasg
main		proc	far
			push	ds
			sub		ax,ax
			push	ax
			
			mov		ax,datasg
			mov		ds,ax
			
start:
			;输出提示内容
			lea		dx,mess
			mov		ah,09
			int 	21h
			
			;获取输入
			lea		dx,strnin
			mov		ah,0ah
			int 	21h
			
			;回显输入
			mov		dl,13
			mov		ah,02
			int		21h
			mov		dl,10
			mov		ah,02
			int		21h
			
			mov		cx,100 ;循环遍历每个字符
			mov		bx,offset strn
count:
			mov		al,[bx]
			cmp		al,58 ;<'9'
			jl		number
			cmp		al,91 ;<'Z'
			jl		upper
			cmp		al,123 ;<'z'
			jl		lower
number:
			cmp		al,48 ;<'0'
			jl		short change_addr
			mov		si,0
			inc		counter[si]
			jmp		short change_addr
upper:
			cmp		al,65 ;<'A'
			jl		short change_addr
			mov		si,1
			inc		counter[si]
			jmp		short change_addr
lower:
			cmp		al,97 ;<'a'
			jl		short change_addr
			mov		si,2
			inc		counter[si]
change_addr:
			inc		bx
			loop	count
			ret
main		endp

codesg		ends
			end		main
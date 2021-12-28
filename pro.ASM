codesg		segment	para	'code'
			assume cs:codesg

main		proc	far
			push	ds
			sub		ax,ax
			push	ax
			
start:
			mov		di,15 ;外层循环次数，11行
			mov		dl,10h ;从21h开始输出
row:
			mov		cx,16 ;内层循环次数，20列
col:
			mov		ah,02h ;输出要求的字符
			int		21h
			
			;输出空白字符
			push	dx ;保存要求的字符
			mov		ah,02h
			mov		dl,0
			int		21h
			pop		dx
			
			inc		dl ;取得下一个要求的字符
			loop	col
			
			;输出回车和换行
			push	dx
			mov		ah,02h
			mov		dl,0dh
			int		21h
			mov		ah,02h
			mov		dl,0ah
			int		21h
			pop		dx
			
			dec		di ;外层循环次数-1
			jne		row
			ret
main		endp

codesg		ends
			end		main

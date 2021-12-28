datasg		segment	para	'data'
	three	db		3
	mess	db		'month?', 13, 10, '$'
	monin	label	byte
		max	db		3
		act	db		?
		mon	db		3 dup(?)
		
	alfmon	db		'???', 13, 10, '$' ;输出的字符串
	montab	db		'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'
			db		'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
			
datasg		ends

codesg		segment	para	'code'
			assume cs:codesg, ds:datasg, es:datasg
main		proc	far
			push	ds
			sub		ax,ax
			push	ax
			
			mov		ax,datasg
			mov		ds,ax
			mov		es,ax
			
start:
			lea		dx,mess
			mov		ah,09
			int		21h
			
			lea		dx,monin
			mov		ah,0ah
			int		21h
			
			mov		dl,13 ;回车
			mov		ah,02 ;屏幕显示dl中的字符
			int		21h
			mov		dl,10 ;输出换行符
			mov		ah,02
			int		21h
			
			cmp		act,0
			je		exit ;je:等于则跳转
			
			;ascii转二进制
			mov		ah,30h
			cmp		act,2 ;输入有两个字符
			je		two
			mov		al,mon
			jmp		conv
two:
			mov		al,mon+1
			mov		ah,mon
conv:		xor		ax,3030h
			cmp		ah,0
			jz		loc ;month 01-09跳转
			sub		ah,ah
			add		al,10
			
loc:		lea		si,montab
			dec		al
			mul		three
			add		si,ax
			mov		cx,03
			cld ;使si的地址指针自动增加
			lea		di,alfmon
			rep		movsb ;把montab的内容送至alfmon
			
			lea		dx,alfmon
			mov		ah,09
			int		21h
			jmp		start
exit:		ret
main		endp

codesg		ends
			end 	main
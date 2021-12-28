datasg	segment
	mess1	db	'Input name:', '$'
	mess2	db	'Input a telephone number:', '$'
	mess3	db 	'Do you want a telephone number?(Y/N):', '$'
	mess4	db	'name', 17 dup(' '), 'tel.', 13, 10, '$' 
	mess5	db	'Not Found', 13, 10, '$'
	tel_tab	db	50 dup(29 dup(' '), '$')  ; 20+1+8+1
	tel_cnt db	0
	strinp	label	byte
	strmax	db	21
	strlen	db	?
	strdata	db	21 dup(?)
datasg	ends

prognam	segment
main	proc	far
		assume 	cs:prognam,ds:datasg,es:datasg
start:
		push	ds
		sub		ax,ax
		push	ax
		
		mov		ax,datasg
		mov		ds,ax
		mov		es,ax
input:	
		; 显示提示符'Input name:'
		lea		dx,mess1
		mov		ah,09
		int		21h
		
		call	input_name
		; 判断输入是否结束
		cmp		strlen,0
		jz		find
		
		call	stor_name
		
		; 显示提示符'Input a telephone number:'
		lea		dx,mess2
		mov		ah,09
		int		21h
		
		call	inphone
		jmp		input ; 循环获取要保存的人名和电话号码
find:
		; 显示提示符'Do you want a telephone number?(Y/N)'
		lea		dx,mess3
		mov		ah,09
		int		21h
		
		mov		ah,1
		int		21h
		mov		bl,al
		call	crlf
		; 回答N则退出程序
		cmp		bl,'N'
		jz		exit1
		
		; 显示提示符'Input name:'
		lea		dx,mess1
		mov		ah,09
		int		21h
		
		call	input_name
		call	name_search
		call	printline
		jmp		find ; 循环提示查找
exit1:
		ret
main	endp

input_name	proc	near ; 接收人名
		lea		dx,strinp
		mov		ah,0ah
		int		21h
		call	crlf
		ret
input_name	endp

stor_name	proc	near
		; 把strdata送至tel_tab的相应位置
		lea		si,strdata
		lea		di,tel_tab
		; 计算count * 30
		mov		al,tel_cnt
		sub		ah,ah
		mov		cx,30d
		mul		cx
		
		add		di,ax ; 人名应存放在tel_tab+count*30的位置
		mov		cl,strlen
		sub		ch,ch
		rep		movsb
		
		inc		tel_cnt ; 电话号码表中条目+1
		ret
stor_name	endp

inphone		proc	near ; 接收电话号码并存入tel_tab中
		lea		di,tel_tab
		; 计算(count-1) * 30
		mov		al,tel_cnt
		sub		ah,ah
		dec		ax
		mov		cx,30d
		mul		cx
		; 计算应存放的位置
		add		di,ax
		add		di,20d
input_number:
		; 接收电话号码
		mov		ah,1
		int		21h
		mov		dl,al ; 电话号码保存在dl中
		
		cmp		dl,13 ; 读到回车则停止
		jz		exit2
		
		mov		[di],dl ; 存放电话号码
		inc		di
		jmp		input_number
exit2:
		ret
inphone	endp

name_search		proc	far ; 在电话号码表中查找所要的电话号码
		mov		bl,tel_cnt
		lea		di,tel_tab
search:
		lea		si,strdata
		push	di ; 保存一个条目的起始位置，便于输出
		cld
		mov		cl,strlen
		sub		ch,ch
		repz	cmpsb
		jz		match ; 找到
		
		pop		di
		add		di,30d ; 找下一条
		dec		bl
		jnz		search ; 循环查找
		
		jmp		exit3
match:
		pop		di ; 恢复di
exit3:
		ret
name_search	endp

printline	proc	near ; 按要求格式显示人名及电话号码
		cmp		bl,0
		jz		no_match ; 未找到
		; 输出'name		tel.'
		lea		dx,mess4
		mov		ah,09
		int		21h
		; 输出人名和电话号码
		lea		dx,[di]
		mov		ah,09
		int		21h
		call	crlf
		jmp		exit4
no_match:
		; 输出'Not Found'
		lea		dx,mess5
		mov		ah,09
		int		21h
exit4:
		ret
printline	endp

crlf	proc	near
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
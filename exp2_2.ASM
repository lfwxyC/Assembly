datasg		segment	para	'data'
mess1		db		'Enter keyword:','$'
mess2		db		'Enter Sentence:','$'

;输入的keyword
keyin		label	byte
	key_max	db		10
	key_act	db		?
	key		db		10 dup(?)
;输入的sentence
senin		label	byte
	sen_max	db		100
	sen_act	db		?
	sen		db		100 dup(?)

string1		db		'Match at location:','$'
string2		db		'H of the sentence.',13,10,'$'
string3		db		'No match.',13,10,'$'
keylen		db		0 ;keyword的长度
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
			;输出'Enter keyword:'
			lea		dx,mess1
			mov		ah,09
			int		21h
			
			;获取输入keyword
			lea		dx,keyin
			mov		ah,0ah
			int		21h
			
			;回显输入
			mov		dl,13
			mov		ah,02
			int		21h
			mov		dl,10
			mov		ah,02
			int		21h
			
			mov		dx,0 ;keyword长度
			mov		bx,offset key
count_key:
			mov		al,[bx]
			cmp		al,0dh
			je		save_key ;相等则跳转
			inc		bx
			inc		dx
			jmp		count_key
save_key:	
			mov		bx,offset keylen
			mov		[bx],dx
sentence:
			;输出'Enter Sentence:'
			lea		dx,mess2
			mov		ah,09
			int		21h
			
			;获取输入sentence
			lea		dx,senin
			mov		ah,0ah
			int		21h
			
			;回显输入
			mov		dl,13
			mov		ah,02
			int		21h
			mov		dl,10
			mov		ah,02
			int		21h
			
			mov		dx,0 ;sentence长度
			mov		bx,offset sen
count_sen:
			mov		al,[bx]
			cmp		al,0dh
			je		init ;相等则跳转
			inc		bx
			inc		dx
			jmp		count_sen
init:	
			mov		bx,offset keylen ;[bx]=keyword长度
			cmp		dx,[bx] ;sentence长度<keyword长度
			jl		no_match
			
			sub		dx,[bx] ;dx=sentence长度-keyword长度
			inc		dx ;sentence长度-keyword长度+1
			mov		bx,0
compare:
			;串比较指令
			lea		si,key
			lea		di,sen+[bx]
			cld
			push	bx;
			mov		bx,offset keylen
			mov		cx,[bx]
			pop		bx;
			repz	cmpsb
			jz		match
			
			inc		bx
			dec		dx
			jne		compare
no_match:
			lea		dx,string3
			mov		ah,09
			int 	21h
			jmp		sentence
match:
			;输出"match at location:"
			lea		dx,string1
			mov		ah,09
			int		21h
			
			;二进制转十六进制
			inc		bx
			mov		ch,2 ;要显示的数字个数
rotate:
			mov		cl,4 ;每4位二进制转为1位十六进制
			rol		bl,cl ;循环右移
			mov		al,bl
			and		al,0fh ;清空高4位
			add		al,30h ;转ascii码
			cmp		al,3ah ;<9直接输出
			jl		printit
			add		al,7h ;转A-F的ascii码
printit:
			mov		dl,al
			mov		ah,02h
			int		21h
			dec		ch
			jnz		rotate
			
			;输出"H of the sentence."
			lea		dx,string2
			mov		ah,09
			int		21h
			jmp		sentence
main		endp

codesg		ends

			end		main
data	segment 
Pgsize			dw	?

buf_size    	db	80
s_buf			db	?
buf   			db	200 dup(?)

names			db	20 dup(?)
cur    	 		dw	?
handle  		dw	?
buf_tmp			db  24*80 dup(?)
cur_tmp			dw	?
name_tmp		db  "t0m1p",0
handle_tmp		dw	?
mark			db  ?
mess_getname	db  0dh,0ah,"    Please input filename: $"
mess_err1		db  0ah,0dh,"    Illegal filename ! $"
mess_err2		db  0ah,0dh,"    File not found !$"
mess_err3		db  0ah,0dh,"    File read error !$"
mess_psize		db  0ah,0dh,"    Page Size : $"
mess_dele		db  0dh,0ah,"    The last page is deleted !"
crlf			db  0ah,0dh,"$"
mess_star		db  0ah,0dh,"*********************************************"
              	db  0ah,0dh,"$"
data	ends

code	segment
		assume ds:data, cs:code
main proc far
start:
	; 保存ds:0用于返回
    push	ds
    sub		ax, ax
    ; 让ds指向data段
    push	ax
    mov		ax, data
    mov		ds, ax
    ; 初始化
    mov		mark, 0
    mov		PgSize, 12
    mov		cur, 200  
    ; 获取文件名
    call	getline      
    ; 打开文件并创建临时文件
    call	openf
    or		ax, ax ; 判断ax是否为0
    ; ax不为0，显示一页
    jnz		display
    ; (ax)=0，输出"File not found !"并跳转至file_end
    mov		dx, offset mess_err2
    mov		ah, 09h
    int		21h
    jmp		file_end
display:
    mov		cx, Pgsize ; 显示Pgsize行
    mov		cur_tmp, 0
show_page:
    call	read_block ; 从handle读入一行到buf
    or		ax, ax
    jnz		next2
    ; 读文件错误，跳转至file_end
    mov		dx, offset mess_err3
    mov		ah, 09h
    int		21h; 输出"File read error !"
    jmp		file_end
next2:
	; 显示buf中的一行，并将这一行放入buf_tmp
    call	show_and_reserve
    ; (bx)=0表示是文件尾
    or		bx, bx
    jz		file_end
    ; 判断一页是否结束，若未结束则继续显示，否则输出一行*
    or		cx, cx
    jnz		show_page
    mov		dx, offset mess_star
    mov		ah, 09h
    int		21h
 	; 等待输入
wait_space:
    mov		ah, 1
    int		21h
    ; 判断输入是否为空格，若是空格则显示下一页，并把上一页写入临时文件；否则继续判断
    cmp		al, " "
    jnz		psize
    call	write_buf_tmp
    jmp		display
psize:
	; 判断输入是否为p, 若是则把改变页大小，并把上一页写入临时文件；否则继续判断
    cmp		al,"p"
    jnz		delete
    call	write_buf_tmp
    call	change_psize
    jmp		stick
delete:
    cmp		al, "d"
    jnz		wait_space
    mov		mark, 1    ; mark=1表示原文件已被修改
    ; 输出"The last page is deleted !"
    mov		dx, offset mess_dele
    mov		ah, 09h
    int		21h
; 等待输入空格后继续执行程序
stick:
    mov		ah, 1
    int		21h
    cmp		al, " "
    jnz		stick
    jmp		display
file_end:
    call	write_buf_tmp
    cmp		mark,0
    jz		ok
    call	write_tmp_back ; 若mark=1，则将临时文件写回原文件
ok:
    ret
main	endp

; 改变页大小
change_psize proc near
    push	ax
    push	bx
    push	cx
    push	dx
    ; 输出"Page Size : "
    mov		dx, offset mess_psize
    mov		ah, 09h
    int		21h
    ; 获取输入
    mov		ah, 01
    int		21h
    ; 判断是否输入回车，若是回车则说明输入非法，跳转至illeg
    cmp		al, 0dh
    jz		illeg
    ; 将ascii码转为二进制
    sub		al, "0"
    mov		cl, al
getp:
    ; 获取输入
    mov		ah, 1
    int		21h
    ; 判断是否输入回车，若是回车则说明输入结束，跳转至pgot
    cmp		al, 0dh
    jz		pgot
    ; 将ascii码转为二进制，并与之前的数字组成新的数
    sub		al, "0"
    mov		dl, al
    mov		al, cl
    mov		cl, dl
    mov		bl, 10
    mul		bl
    add		cl, al
    jmp		getp
pgot:
	; 输出换行
    mov		dl, 0ah
    mov		ah, 2
    int		21h  
	; 判断cx是否在(0,24)范围内，若在则修改PgSize, 否则跳转至illeg
    cmp		cx, 0
    jle		illeg
    cmp		cx, 24
    jg		illeg
    mov		PgSize, cx
illeg:
	; 输出换行，并恢复dx,cx,bx,ax的值，返回main函数
    mov		dl, 0ah
    mov		ah, 2         ; 实验书pdf 和 实体书不一样的地方
    int		21h   
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    ret
change_psize endp

; 打开文件并创建临时文件
openf proc near
    push	bx
    push	cx
    push	dx
    ; 根据输入的文件名打开文件
    mov		dx, offset names ; ds:dx指向要打开的文件名
    mov		al, 2            ; 以读/写方式打开文件
    mov		ah, 3dh  
    int		21h
    ; handle保存文件代号
    mov		handle, ax
    mov		ax, 0
    jc		quit        ; jc:产生进位则跳转，说明打开文件失败
    ; 创建临时文件
    mov		dx, offset name_tmp
    mov		cx, 0
    mov		ah, 3ch
    int		21h
    mov		handle_tmp, ax
    jc		quit
    mov		ax, 1
quit:
    pop		dx
    pop		cx
    pop		bx
    ret
openf  endp

; 获取文件名
getline  proc near
    push	ax
    push	bx
    push	cx
    push	dx
    ; 输出"Please input filename: "
    mov		dx, offset mess_getname
    mov		ah, 09h
    int		21h
    ; 获取文件名，保存到buf中
    mov		dx, offset buf_size
    mov		ah, 0ah
    int		21h
	; 输出换行
    mov		dx, offset crlf
    mov		ah, 09h
    int		21h
 	; 在文件名末尾添加0
    mov		bl, s_buf
    mov		bh, 0
    mov		names[bx],0
    ; 将文件名复制到names中，并恢复dx,cx,bx,ax的值，返回到main函数
name_move:
	dec		bx
	mov		al, buf[bx]
	mov		names[bx], al
	jnz		name_move
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    ret
getline  endp

; 从原文件读取一块数据，若还有数据未显示则不读取
read_block	proc	near
	push	bx
	push	cx
	push	dx
	mov		ax, 1
	cmp		cur, 200
	jnz		back  
	
	call	clear
	; 读文件
	mov		cx, 200        ; 读取200个字符
	mov		bx, handle     ; (bx)=文件代号
	mov		dx, offset buf ; ds:dx为数据缓冲区地址
	mov		ah, 3fh
	int		21h
	; 判断读取是否成功
	mov		cur, 0
	mov		ax, 1
	jnc		back           ; 读取成功，返回
	mov		cur, 200 
	mov		ax, 0
back:
	pop		dx
	pop		cx
	pop		bx
	ret
read_block endp

; 显示buf中的一行，并将这一行放入buf_tmp
show_and_reserve proc near
    push	ax
    push	dx
    mov		bx, cur
    mov		bp, cur_tmp
loop1:
	cmp		bx, 200
    jl		lp
    jmp		exit            ; buf为空，直接返回
lp:
    mov		dl, buf[bx]
    mov		ds:buf_tmp[bp], dl; 把buf中的内容放入buf_tmp
    ; 指针均向后移动一位
    inc		bx
    inc		cur
    inc		bp
    inc  	cur_tmp
	; 判断是否到文件末尾，若是则跳转至exit_eof
    cmp		dl, 0
    jz		exit_eof
	; 输出(dl)
    mov		ah, 02     
    int		21h
    ; 判断dl是否为回车，若是则显示换行，否则继续显示字符
    cmp		dl, 0ah
    jz		exit_ln
    jmp		loop1
exit_eof:
    mov		bx,0
exit_ln:
    dec		cx ; 剩余行数-1
exit:
    pop		dx
    pop		ax
    ret
show_and_reserve endp

; 把上一页写入临时文件
write_buf_tmp proc near
    push	ax
    push	bx
    push	cx
    push	dx
    ; 把buf_tmp的内容写入文件handle_tmp中
    mov		dx, offset buf_tmp
    mov		cx, cur_tmp
    mov		bx, handle_tmp
    mov		ah, 40h
    int		21h
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    ret
write_buf_tmp endp


write_tmp_back  proc near
    push	ax
    push	bx
    push	cx
    push	dx
; 
	; 关闭临时文件
    mov		bx, handle_tmp
    mov		ah, 3eh
    int		21h
    ; 关闭原文件
    mov		bx, handle
    mov		ah, 3eh
    int		21h
    ; 以读方式打开临时文件
    mov		dx, offset name_tmp
    mov		al, 0
    mov		ah, 3dh
    int		21h 
    mov		handle_tmp, ax
    ; 以写方式打开原文件
    mov		dx, offset names
    mov		al, 1
    mov		ah, 3dh
    int		21h
    mov		handle,ax
    
    mov		si, 1
wrt_back:
	; 从handle_tmp中读取一页到buf中
    mov		bx, handle_tmp
    mov		ah, 3fh
    mov		cx, 200
    mov		dx, offset buf
    int		21h
    jc		wrt_end        ; 若写失败则跳转至wrt_end

    mov		si, ax          ; si保存实际读入的字节数
   	; 从buf中写一页数据到原文件中
    mov		bx, handle
    mov		ah, 40h
    mov		cx, si           ; 实验书pdf 和 实体书不一样的地方  
    mov		dx, offset buf
    int		21h
    ; 判断是否读取完毕，若读完则关闭原文件，否则继续读取
    or		si, si
    jnz		wrt_back 
    mov		ah, 3eh
    mov		bx, handle
    int		21h
wrt_end:
    pop		dx
    pop		cx
    pop		bx
    pop		ax
    ret
write_tmp_back endp

clear	proc	near	; 将buf中的数据全部置0
	push	bx
	push	cx
	
	mov		bx,0
	mov		cx,200
reset:
	mov		buf[bx],0
	inc		bx
	loop	reset
	
	pop		cx
	pop		bx
	ret
clear	endp

code	ends
		end	start
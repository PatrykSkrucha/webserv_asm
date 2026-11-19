# ------------------------
#
#	r12	-	socket server
#	r13 -	client fd
#	r14	-	ptr to file for POST req
#	rbx	-	read length
# ------------------------

.intel_syntax noprefix
.global _start

_start:
	#	socket creation
	mov rdi, 2
	mov rsi, 1
	mov rax, 41
	mov rdx, 0
	syscall 
	# ----------------------------
	#	making sockaddr on the stack
	mov r12, rax
	sub rsp, 16
	mov qword ptr [rsp], 0
	mov qword ptr [rsp + 8], 0
	mov qword ptr [rsp], 2
	mov qword ptr [rsp + 2], 0x5000
	# --------------
	#	binding socket
	mov rsi, rsp
	mov rdi, rax
	mov rax, 49
	mov rdx, 16
	syscall
	# -------------------
	#	listening on socket
	mov rax, 50
	mov rdi, r12
	mov rsi, 0
	syscall
	sub rsp, 1024
.accept_client:
	# -------------------
	# accept
	mov rax, 43
	mov rdi, r12
	mov rsi, 0
	mov rdx, 0
	syscall
	mov r13, rax
	# -------------------
	# fork process
	mov rax, 57
	syscall
	test eax, eax
	jz .child_process
	# -------------------
	# close client's fd
	mov rdi, r13
	mov rax, 3
	syscall
	jmp .accept_client
.child_process:
	# -------------------
	# close server's fd
	mov rdi, r12
	mov rax, 3
	syscall
	# -------------------
	# read request
	mov rax, 0
	mov rdi, r13
	mov rsi, rsp
	mov rdx, 1024
	syscall
	mov rbx, rax
	# -------------------
	# GET or POST
	cmp DWORD PTR [rsp],0x54534F50 # 'POST'
	je .is_post
	cmp DWORD PTR [rsp],0x20544547 # 'GET '
	je .is_get
.is_post:
	lea rdi, [rsp + 4]
	mov rsi, rdi
.find_space_post:
	inc rsi
	cmp BYTE PTR [rsi], ' '
	jne .find_space_post
	
	# -------------------
	# terminate a string with path to file with \0
	mov BYTE PTR [rsi], 0
	mov r14, rdi
	# -------------------
	# find \r\n\r\n where body starts
	xor rax, rax
	xor rcx, rcx
	lea rdi, [rsp]
	mov rsi, rdi
.find_body:
	cmp DWORD PTR [rsi], 0x0a0d0a0d
	je .calc_len
	inc rsi
	inc rcx
	jmp .find_body
.calc_len:
	add rsi, 4
	sub rbx, rsi # now rbx holds actuall content length
	# -------------------
	# open file

	mov rax, 2
	mov rdi, r14
	mov rsi, 0x01 | 0x40 #	O_WRONLY | O_CREAT
	mov rdx, 0777 # chmod for O_CREAT flag 
	syscall

	# -------------------
	# write body to a file
	mov rax, 1
	mov rdi, 
	syscall
	
.is_get:
	# -------------------
	# get path to file
	# save a file name, find msg lenght
	# -------------------
	lea rdi, [rsp + 4]
	mov rsi, rdi
.find_space_get:
	cmp BYTE PTR [rsi], ' '
	je .insert_zero_get
	inc rsi
	jmp .find_space_get
.insert_zero_get:
	mov BYTE PTR [rsi], 0
	# -------------------
	# open file
	mov rsi, 0
	mov rax, 2
	syscall
	mov rbx, rax
	# -------------------
	# read file
	mov rdi, rax
	mov rsi, rsp
	mov rdx, 1024
	mov rax, 0
	syscall
	mov r14, rax
	# -------------------
	# close file
	mov rdi, rbx
	mov rax, 3
	syscall
	# -------------------
	# send header
	mov rdi, r13
	lea rsi, [rip + response_ok]
	mov rdx, response_ok_end - response_ok
	mov rax, 1
	syscall
	# -------------------
	# response to client
	mov rdx, r14
	mov rax, 1
	mov rdi, r13
	mov rsi, rsp
	syscall
	# -------------------
	# close client
	mov rax, 3
	mov rdi, r13
	syscall
	# -------------------
	# exit
	mov rax, 60
	mov rdi, 0
	add rsp, 1024
	add rsp, 16
	syscall

response_ok:
.ascii "HTTP/1.0 200 OK\r\n\r\n"
response_ok_end:


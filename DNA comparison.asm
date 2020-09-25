
INCLUDE Irvine32.inc
.DATA	
	const_row EQU 100
	diagonal_move EQU 101
	left_move EQU 1
	string_string1 byte "Please enter the first string : ",0
	string_string2 byte "Please enter the second string : ",0
	string_matching byte "Please enter the value of matching : ",0
	string_mismatching byte "Please enter the value of mismatching : ",0
	string_gap byte "Please enter the value of gap : ",0
	string1 byte 100 dup(?)
	string2 byte 100 dup(?)
	size1_string1 dword 100
	size2_string2 dword 100
	matching     dword ?
	mis_matching dword ?
	gap_penalty  dword ?
	tmp_up      dword ?
	tmp_left    dword ?
	tmp_digonal dword ?
	tmp_up_val     dword ?
	tmp_left_val    dword ?
	tmp_digonal_val dword ?
	table byte 100*100 dup (?)
	I dword ?
	J dword ?
	tmp_I dword ?
	tmp_J dword ?
	tmp_it dword ?
	res_str1 byte 100 dup(?)
	res_str2 byte 100 dup(?)
	path_arr byte 100*100 dup(?)
	size_res dword 0
	res_str1_rev byte 100 dup(?)
	res_str2_rev byte 100 dup(?)

.code
main PROC
	call read_input
	call fill_building_table
	call get_path
	exit
main ENDP

read_input proc

	mov edx , offset string_string1
	call writestring
	mov edx, offset string1
	mov ecx, size1_string1
	call readstring 
	mov size1_string1, eax

	mov edx , offset string_string2
	call writestring
	mov edx, offset string2
	mov eax, size2_string2
	call readstring 
	mov size2_string2, eax
	
	mov edx , offset string_matching
	call writestring
	call readint
	mov matching, eax

	mov edx , offset string_mismatching
	call writestring
	call readchar
	mov eax , 0
	call readint
	neg eax
	mov mis_matching, eax

	mov edx , offset string_gap
	call writestring
	call readchar
	mov eax , 0
	call readint
	neg eax
	mov gap_penalty, eax
	ret
read_input endp

fill_building_table proc
	; ebx has the offset of 1D array table
	mov ebx, offset table

	; esi has the offset of string 1
	mov esi, offset string1
	dec esi

	; rows are size of string1 + 1 to calculate the empty string at first 
	mov ecx, size1_string1
	inc ecx

	mov I,0
	LI:		
		push ecx ; to save ecx before the second loop

		; columns are size of string2 + 1 to calculate the empty string at first 
		mov ecx, size2_string2
		inc ecx

		; edi has the offset of string 2
		mov edi , offset string2
		dec edi

		mov J,0
		LJ:

			cmp I, 0 ; base case if row(I) = 0
			Jz base_case_rw

			cmp J, 0 ; base case if column(J) = 0
			jz base_case_col

			;get index of up, left, digonal
			call get_indices
			call get_values

			; if it is not a base case we calculate the values of this index
			movsx edx, byte ptr [edi]
			movsx eax , byte ptr [esi]
			cmp eax, edx
			je cal_match

				; if it doesn't match
				call calculate_mismatching
				jmp out_condition

			cal_match:
				call calculate_matching
				jmp out_condition

			base_case_col:
				; get the actual index in the 1D array tmp_I=(I*100)
				; to calculate the gap penalty for the current index (I*gap_penalty) 
				call base_case_column
				jmp out_condition

			base_case_rw:
				; the actual index in the 1D is J as I=0 so (I*100+J)=J
				; the gap_penalty for this index is (gap_penalty*J)
				call base_case_row

			 out_condition:
			 inc edi
			 inc J
		loop LJ
		pop ecx
		inc esi
		inc I
	loop LI
	ret
fill_building_table endp

base_case_column proc
	mov eax, const_row
	Imul I
	mov tmp_I, eax ;current index
	; to calculate the gap penalty for the current index (I*gap_penalty) 
	mov eax, gap_penalty
	Imul I
	add ebx , tmp_I
	mov [ebx], al
	sub ebx , tmp_I
	ret
base_case_column endp

base_case_row proc
	mov eax, gap_penalty
	Imul J
	add ebx , J
	mov [ebx], al
	sub ebx , J
	ret
base_case_row endp

get_index_up proc
	mov eax, const_row
	mov edx, I
	dec edx
	Imul edx
	add eax, J
	mov tmp_up, eax
	ret
get_index_up endp

get_value_up proc
	;cal tmp_up + ge
	add ebx , tmp_up
	movsx edx, byte ptr [ebx]
	sub ebx , tmp_up
	add edx, gap_penalty
	mov tmp_up_val, edx
	ret
get_value_up endp

get_index_left proc
	mov eax, const_row
	Imul I
	mov edx, J
	dec edx
	add eax, edx
	mov tmp_left, eax
	ret
get_index_left endp

get_value_left proc 
	;cal tmp_left + ge
	add ebx , tmp_left
	movsx edx, byte ptr [ebx]
	sub ebx , tmp_left
	add edx, gap_penalty
	mov tmp_left_val, edx
	ret
get_value_left endp

get_index_diagonal proc
	mov eax, const_row
	mov edx, I
	dec edx
	Imul edx
	add eax, J
	dec eax
	mov tmp_digonal, eax

	ret
get_index_diagonal endp

get_row proc
	mov eax, size1_string1
	inc eax
	mov I, eax
	sub I, ecx
	ret
get_row endp

get_column proc
	; calculates the current iteration number J=(size of string2 +1 - ecx) as the column number
	mov eax, size2_string2
	mov J, eax
	sub J, ecx
	ret
get_column endp

calculate_mismatching proc
	;cal tmp_digonal + mis_matching
	add ebx , tmp_digonal
	movsx edx, byte ptr [ebx]
	sub ebx , tmp_digonal

	add edx , mis_matching
	mov tmp_digonal_val, edx 

	call calculate_max_up_left_diagonal
	push edx
	mov eax, tmp_left
	inc eax
	add ebx , eax
	pop edx
	mov [ebx], dl
	sub ebx , eax
	ret
calculate_mismatching endp

calculate_matching proc
	;cal tmp_digonal + matching
	add ebx , tmp_digonal      ; get the value of the diagonal from the address
	movsx edx, byte ptr [ebx]
	sub ebx , tmp_digonal

	add edx , matching
	mov tmp_digonal_val, edx 

	call calculate_max_up_left_diagonal
	push edx
	mov eax, tmp_left
	inc eax
	add ebx , eax
	pop edx
	mov [ebx], dl
	sub ebx , eax

	ret
calculate_matching endp

calculate_max_up_left_diagonal proc
	push ebx
	mov ebx , offset path_arr

	mov edx , tmp_left_val
	cmp edx , tmp_up_val
	jge left_is_greater
	mov edx , tmp_up_val
	jmp up_is_greater

	left_is_greater:
		cmp edx , tmp_digonal_val
		jge edx_is_left
		jmp edx_is_diagonal

	up_is_greater:
		cmp edx , tmp_digonal_val
		jge edx_is_up
		jmp edx_is_diagonal

	edx_is_up:
		add ebx , tmp_left
		inc ebx
		mov eax , 'u'
		mov [ebx] , al
		sub ebx , tmp_left
		dec ebx
		mov edx , tmp_up_val
		jmp ret_label

	edx_is_left:
		add ebx , tmp_left
		inc ebx
		mov eax , 'l'
		mov [ebx] , al
		sub ebx , tmp_left
		dec ebx
		mov edx , tmp_left_val
		jmp ret_label

	edx_is_diagonal:
		add ebx , tmp_left
		inc ebx
		mov eax , 'd'
		mov [ebx] , al
		sub ebx , tmp_left
		dec ebx
		mov edx , tmp_digonal_val

	ret_label:
		pop ebx

	ret
calculate_max_up_left_diagonal endp

output proc
	mov ebx , offset table
	mov ecx , size1_string1
	inc ecx
	mov I,0
	L7:
		push ecx
		mov ecx , size2_string2
		inc ecx
		mov J,0
		L8:
			mov eax , const_row
			Imul I
			add eax , J
			mov edx , eax
			add ebx , edx
			movsx eax , byte ptr [ebx]
			sub ebx , edx
			call writeint
			mov eax , ' '
			call writechar
			call writechar
			call writechar
			call writechar
			inc J
		loop L8
		call crlf
		inc I
		pop ecx
	loop L7

	mov edx , offset res_str1
	add edx , size_res
	dec edx
	mov ebx , offset res_str1_rev
	mov ecx , size_res
	Lstr1:
		movsx eax , byte ptr [edx]
		mov [ebx] , al
		inc ebx
		dec edx
	loop Lstr1
	mov edx , offset res_str1_rev
	call writestring
	call crlf

	mov edx , offset res_str2
	add edx , size_res
	dec edx
	mov ebx , offset res_str2_rev
	mov ecx , size_res
	Lstr2:
		movsx eax , byte ptr [edx]
		mov [ebx] , al
		inc ebx
		dec edx
	loop Lstr2
	mov edx , offset res_str2_rev
	call writestring
	call crlf
	ret
output endp

get_indices proc
	;up (100*(I-1))+J
	call get_index_up
	;left (100*I)+(J-1)
	call get_index_left
	;digonal (100*(I-1))+(J-1)
	call get_index_diagonal
	ret
get_indices endp

get_values proc
	call get_value_up
	call get_value_left
	ret
get_values endp

get_path proc
	;; GOLDEN RULE ana w gy mn t7t ele gy mn 3ndo hwa ele b7ot el da4 feh incase mismatch
	mov edi , offset string1
	mov esi , offset string2
	
	add edi , size1_string1
	add esi , size2_string2

	dec edi
	dec esi

	; used for getting the up , left , diagonal indices right
	mov eax , size1_string1
	mov I , eax
	mov eax , size2_string2
	mov J , eax

	push offset res_str1
	push offset res_str2

	call get_indices
	
	directions:
			mov ebx , offset path_arr
			add ebx , tmp_left
			inc ebx

			cmp tmp_up , 0
			jl out_condition
			cmp tmp_left , 0
			jl out_condition

			inc size_res
			mov eax , 'u'
			cmp [ebx] , al
			je move_up

			mov eax , 'l'
			cmp [ebx] , al
			je move_left

			; move diagonal
				movsx ecx ,byte ptr [edi]
				pop edx
				pop eax

				mov [eax] , cl ; res_str1
				movsx ecx , byte ptr [esi]
				mov [edx] , cl ; res_str2

				inc eax
				inc edx
				push eax
				push edx

				dec edi
				dec esi
				sub tmp_left , diagonal_move ;; 100 the row above  1 the previous column 
				sub tmp_up , diagonal_move
				sub tmp_digonal , diagonal_move

				jmp directions

			move_up:
				; h7ot fe str2 el gap

				pop edx
				pop eax

				mov ecx , '-'
				mov [edx] , cl
				movsx ecx , byte ptr [edi]
				mov [eax] , cl

				inc eax
				inc edx
				push eax
				push edx

				sub tmp_left , const_row ;; 100 the row above  
				sub tmp_up , const_row
				sub tmp_digonal , const_row

				dec edi
				jmp directions

			move_left:
				; h7ot fe str1 el gap
				pop edx
				pop eax

				mov ecx , '-'
				mov [eax] , cl
				movsx ecx , byte ptr [esi]
				mov [edx] , cl

				inc eax
				inc edx
				push eax
				push edx

				sub tmp_left , left_move ;; 100 the row above  
				sub tmp_up , left_move
				sub tmp_digonal , left_move

				dec esi

	jmp directions

	out_condition:
		pop eax
		mov ecx , 0
		mov [eax] , cl

		pop eax
		mov ecx , 0
		mov [eax] , cl

		call output
	ret
get_path endp


END main
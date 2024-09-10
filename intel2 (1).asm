;Sobre a sequência dos passos, eu não entendi direito se é para a rainha se mover até onde ela consegue se uma outra bloquear,
;Ou se é pra ela não tentar se mover. Eu fui com a segunda.
;
;
.model small
.stack 800h

.data  


tabuleiro db 4096 dup (-1) 	;Para testar os movimentos de uma forma mais simples, apesar de que mais demorada,

nome_arquivo_entrada db "in.txt", 0
erro_arquivo db "Erro na abertura do arquivo de entrada.", '$'
rainha db "Rainha ", 0
nao_pode_ser_colocada db " posicionada nas mesmas coordenadas da rainha ", 0
saiu_do_tabuleiro db " saiu do tabuleiro na posicao (", 0
bloqueada_pela_rainha db " bloqueada pela rainha ", 0
rainha_invalida db "Tentativa de movimento em rainha nao listada."
numero_rainha_invalido_insert_msg db "Tentativa de posicionar rainha com um numero fora do intervalo [0, 9].", 10, 13, '$'
coord_invalida_insert_msg_x db "Coordenada X invalida.", 10, 13, '$'
coord_invalida_insert_msg_y db "Coordenada Y invalida.", 10, 13, '$'
ja_posicionou_essa_rainha_msg db "Redefinicao de identificador de rainha.", '$'
malformed_line db "Linha mal formada detectada.", 10, 13, '$'
orientacao_invalida_msg db "Direcao de movimentacao invalida.", 10, 13, '$'
max_movs_msg db "Espacos de movimentacao invalido.", 10, 13, '$'
rainha_nao_posicionada db "Rainha nao posicionada.", 10, 13, '$'
rainha_malformada db "Identificar de rainha nao reconhecido.", 10, 13, '$'

handle_arquivo dw 0


tabela_rainhas db 64 dup (-1) 	;Para imprimir no final sem ter que percorrer a matriz 64x64

buffer_leitura db 256 dup (-1)	;Para ler linha a linha

numero_linha dw 0

buffer_itos db 64 dup(0)

buffer_escrita db 128 dup (0)

LF equ 10
CR equ 13

L_C dw 0001h ;No carregamento disso aqui em AX teremos o i em al e o j em ah
O_C dw 00ffh
N_C dw 0100h
S_C dw 0ff00h
NE_C dw 0101h
NO_C dw 01ffh
SO_C dw 0ffffh
SE_C dw 0ff01h

NE_T dw 17742 ;Esses numeros magicos sao para nao ter que implementar uma strcmp
NO_T dw 20302
SO_T dw 20307
SE_T dw 17747
L_T dw 76
O_T dw 79
N_T dw 78
S_T dw 83

string_debug db "String de debug", 10, 13, '$'

.code  
main proc near
	mov ax, @data
	mov ds, ax
  	lea dx, nome_arquivo_entrada ;Abre o arquivo e imprime erro em falha
	mov ah, 3dh
	xor al, al
	int 21h
	jc falhou_abertura_arquivo
	mov handle_arquivo, ax
	jmp carrega_tabuleiro
	
falhou_abertura_arquivo:
	lea dx, erro_arquivo
	mov ah, 09h
	mov al, 0
	int 21h
	jmp saida

carrega_tabuleiro:
	lea dx, buffer_leitura
	mov cx, 64
	mov di, handle_arquivo
	call fgets
	test ax, ax
	je eof
	lea dx, buffer_leitura
	inc numero_linha
	call processa_linha
	jmp carrega_tabuleiro
eof:
	mov ah, 3eh
	mov al, 0
	mov bx, handle_arquivo
	int 21h

saida:
	call imprime_lista_final
fim_do_programa:
	mov ah, 4ch
	mov al, 0
	int 21h

processa_linha:
	lea si, buffer_leitura
	mov al, [si]
	cmp al, '#'
	je insercao
	cmp al, ':'
	je movimento
	ret
insercao:
	push bp
	mov bp, sp
	mov dx, si
	inc dx
	call atoi
	jc processa_linha_malformada_rainha_ruim
	push ax
	mov dx, si
	mov cl, ','
	call strtok
	mov si, ax
	mov dx, ax
	call atoi
	jc processa_linha_malformada
	push ax
	mov dx, si
	mov cl, ','
	call strtok
	mov dx, ax
	call atoi
	jc processa_linha_malformada
	push ax ;A partir daqui, no topo da pilha temos o Y, logo depois o X e em baixo o número da rainha
	pop dx
	pop cx
	pop di
	cmp di, 10
	jae processa_linha_malformada_rainha_ruim
	cmp cx, 64
	jae coord_invalida_x_insert
	cmp dx, 64
	jae coord_invalida_y_insert
	call posiciona_rainha
	mov sp, bp
	pop bp
	ret
processa_linha_malformada_rainha_ruim:
	lea dx,	rainha_malformada
	mov ah, 09h
	mov al, 0
	call putlinenum
	int 21h
	jmp fim_do_programa
pos_saida:
	mov sp, bp
	pop bp
	ret
processa_linha_malformada:
	call putlinenum
	lea dx, malformed_line
	mov ah, 09h
	mov al, 0
	int 21h
	jmp pos_saida
numero_rainha_invalido_insert:
	call putlinenum
	lea dx, numero_rainha_invalido_insert_msg
	mov ah, 09h
	mov al, 0
	int 21h
	jmp pos_saida
coord_invalida_x_insert:
	call putlinenum
	lea dx, coord_invalida_insert_msg_x
	mov ah, 09h
	mov al, 0
	int 21h
	jmp fim_do_programa

coord_invalida_y_insert:
	call putlinenum
	lea dx, coord_invalida_insert_msg_y
	mov ah, 09h
	mov al, 0
	int 21h
	jmp fim_do_programa


nao_encontrada:
	call putlinenum
	lea dx, rainha_nao_posicionada
	mov ah, 09h
	mov al, 0	
	int 21h
	jmp fim_do_programa

movimento_malformada:
	call putlinenum
	lea dx, malformed_line
	mov ah, 09h
	mov al, 0
	int 21h
	jmp saida_movimento

movimento:
	push bp
	mov bp, sp
	inc si
	mov dx, si
	call atoi
	jc processa_linha_malformada_rainha_ruim
	cmp ax, 10
	jae processa_linha_malformada_rainha_ruim
	lea bx, tabela_rainhas
	add bx, ax
	add bx, ax
	mov dx, [bx]
	cmp dx, -1
	je nao_encontrada
	push dx
	mov dx, si
	mov cl, ','
	call strtok
	mov si, ax
	mov dx, si
	call atoi
	jc processa_linha_malformada
	cmp ax, 128
	jae mais_movimentos_do_que_max
	push ax
	mov dx, si
	call strtok
	mov si, ax
	mov dx, [si]
	cmp dh, 32
	ja nao_eh_espaco
	mov dh, 0
nao_eh_espaco:
	and dl, 0dfh
	and dh, 0dfh
	call procura_orientacao
	test ax, ax
	je orientacao_invalida_move
	push ax
	pop cx
	pop dx
	pop di
	call move_rainha
saida_movimento:
	mov sp, bp
	pop bp
	ret
mais_movimentos_do_que_max:
	call putlinenum
	lea dx, max_movs_msg
	mov ah, 09h
	mov al, 0
	int 21h
	jmp fim_do_programa


orientacao_invalida_move:
	call putlinenum
	lea dx, orientacao_invalida_msg
	mov ah, 09h
	mov al, 0
	int 21h
	jmp fim_do_programa

posiciona_rainha: ;di = Numero, cx = X, dx = Y
	push bp
	push dx
	push cx
	push bx
	push si
	push di
	mov bp, sp
	push di ;[bp - 2] = numero, [bp - 4] = x, [bp - 6] = y
	push cx
	push dx
	
	lea bx, tabela_rainhas
	mov di, [bp - 2]
	shl di, 1
	add bx, di
	mov ax, [bx]
	cmp ax, -1
	jne ja_posicionou_esse_numero
	push bx ;[bp - 8] = &tabela_rainhas[numero]
	lea bx, tabuleiro
	mov cx, [bp - 4]
	mov dl, cl
	mov cx, [bp - 6]
	mov dh, cl
	call traduz
	add bx, ax
	mov dl, [bx]
	mov dh, 0
	cmp dl, -1
	je nao_tem_nessa_coord
	jmp ja_tem_rainha
nao_tem_nessa_coord:
	mov dx, [bp - 2]
	mov [bx], dl
	mov cx, [bp - 4]
	mov dl, cl
	mov cx, [bp - 6]
	mov dh, cl
	mov bx, [bp - 8]
	mov [bx], dx
saida_posiciona_rainha:
	mov sp, bp
	pop di
	pop si
	pop bx
	pop cx
	pop dx
	pop bp
	ret

ja_posicionou_esse_numero:
	call putlinenum
	lea dx, ja_posicionou_essa_rainha_msg
	mov ah, 09h
	mov al, 0
	int 21h
	jmp fim_do_programa

ja_tem_rainha: ;Imprime o erro de já ter achado uma rainha naquele quadrado.
	push dx
	lea dx, buffer_escrita
	mov si, dx
	lea cx, rainha
	call strcpy
	add si, ax
	mov dx, [bp - 2]
	call itos
	mov cx, ax
	mov dx, si
	call strcpy
	add si, ax
	lea cx, nao_pode_ser_colocada
	mov dx, si
	call strcpy
	add si, ax
	pop dx
	call itos
	mov dx, si
	mov cx, ax
	call strcpy
	add si, ax
	mov [si], byte ptr '$'
	call putlinenum
	lea dx, buffer_escrita
	mov ah, 09h
	mov al, 0
	int 21h
	mov dl, 10
	mov ah, 06h
	int 21h
	mov dl, 13
	mov ah, 06h
	int 21h
	jmp saida_posiciona_rainha

procura_orientacao:
	cmp dx, NE_T
	jne po0
	mov ax, NE_C
	ret
po0:
	cmp dx, NO_T
	jne po1
	mov ax, NO_C
	ret
po1:
	cmp dx, SE_T
	jne po2
	mov ax, SE_C
	ret
po2:
	cmp dx, SO_T
	jne po3
	mov ax, SO_C
	ret
po3:
	cmp dx, S_T
	jne po4
	mov ax, S_C
	ret
po4:
	cmp dx, N_T
	jne po5
	mov ax, N_C
	ret
po5:
	cmp dx, L_T
	jne po6
	mov ax, L_C
	ret
po6:
	cmp dx, O_T
	jne po7
	mov ax, O_C
	ret
po7:
	xor ax, ax
	ret

nao_ha_rainha:
	call putlinenum
	lea dx, rainha_invalida
	mov ah, 09h
	mov al, 0
	int 21h
	jmp saida_move_rainha

move_rainha:
	;dx = No de movimentos, cx = orientacao, di = coord_inicial
	push dx
	push cx
	push bx
	push di
	push si
	push bp
	mov bp, sp
	push di ;Ini ;bp - 2
	push cx ;Orie ;bp - 4
	push dx ;No Movs ;bp - 6
	sub sp, 4 ;bp - 8 = numero_rainha, bp - 10 var
	lea bx, tabuleiro
	mov dx, [bp - 2]
	call traduz
	add bx, ax
	mov dl, [bx]
	mov dh, 0
	mov [bp - 8], dx
	mov si, bx
	mov dx, [bp - 2]
	mov [bp - 10], dx
	mov cx, [bp - 6]
	lea bx, tabuleiro
move_l0:
	test cx, cx
	je move_lf
	mov ax, [bp - 10]
	mov dx, [bp - 4]
	add al, dl
	add ah, dh
	cmp al, 64
	jae oob
	cmp ah, 64
	jae oob
	mov [bp - 10], ax
	push ax
	mov dx, ax
	call traduz
	mov di, ax
	mov dl, [bx + di]
	pop ax
	cmp dl, -1
	jne bateu_em_outra_rainha
	dec cx
	jmp move_l0
move_lf:
	mov dx, [bp - 10]
	call traduz
	mov dx, [bp - 8]
	mov di, ax
	mov [bx + di], dl
	mov di, [bp - 8]
	shl di, 1
	lea bx, tabela_rainhas
	mov ax, [bp - 10]
	mov dx, [bp + di]
	mov [bx + di], ax
	call traduz
	lea bx, tabuleiro
	add bx, ax
	mov [bx], byte ptr -1
saida_move_rainha:
	mov sp, bp
	pop bp
	pop si
	pop di
	pop bx
	pop cx
	pop dx
	ret
oob:
	sub al, dl
	sub ah, dh
	mov [bp - 10], ax ;[bp - 10] = coord final
	mov dx, [bp - 4]
	mov ax, [bp - 8]
	shl ax, 1
	lea si, tabela_rainhas
	add si, ax
	mov [si], word ptr -1
	lea dx, buffer_escrita
	lea cx, rainha
	mov si, dx
	call strcpy
	add si, ax
	mov dx, [bp - 8]
	call itos
	mov cx, ax
	mov dx, si
	call strcpy
	add si, ax
	mov dx, si
	lea cx, saiu_do_tabuleiro
	call strcpy
	add si, ax
	mov dx, [bp - 10]
	mov dh, 0
	call itos
	mov cx, ax
	mov dx, si
	call strcpy
	add si, ax
	mov [si], byte ptr ','
	inc si
	mov dx, [bp - 10]
	mov dl, dh
	mov dh, 0
	call itos
	mov cx, ax
	mov dx, si
	call strcpy
	add si, ax
	mov [si], byte ptr ')'
	inc si
	mov [si], byte ptr '$'	
	call putlinenum
	lea dx, buffer_escrita
	mov ah, 09h
	mov al, 0
	int 21h
	mov dl, 10
	mov ah, 06h
	mov al, 0
	int 21h
	mov ah, 06h
	mov al, 0
	mov dl, 13
	int 21h
	jmp saida_move_rainha
bateu_em_outra_rainha:
	push dx
	lea dx, buffer_escrita
	mov si, dx
	lea cx, rainha
	call strcpy
	add si, ax
	mov dx, [bp - 8]
	call itos
	mov cx, ax
	mov dx, si
	call strcpy
	add si, ax
	lea cx, bloqueada_pela_rainha
	mov dx, si
	call strcpy
	add si, ax
	pop dx
	mov dh, 0
	call itos
	mov cx, ax
	mov dx, si
	call strcpy
	add si, ax
	mov [si], byte ptr '$'
	call putlinenum
	lea dx, buffer_escrita
	mov ah, 09h
	mov al, 0
	int 21h
	mov dl, LF
	mov ah, 06h
	mov al, 0
	int 21h
	mov dl, CR
	mov ah, 06h
	mov al, 0
	int 21h
	mov ax, [bp - 10]
	mov dx, [bp - 4]
	sub al, dl
	sub ah, dh
	mov [bp - 10], ax
	jmp move_lf

putlinenum: ;Procedimento silencioso só pra colocar o numero da linha
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov dl, '['
	mov ah, 06h
	mov al, 0
	int 21h
	mov ax, numero_linha
	mov cx, 10
	xor dx, dx
	div cx
	or dx, 48
	push dx
	xor dx, dx
	div cx
	or dx, 48
	push dx
	xor dx, dx
	div cx
	or dx, 48
	mov ah, 06h
	mov al, 0
	int 21h
	pop dx
	mov ah, 06h
	mov al, 0	
	int 21h
	pop dx
	mov ah, 06h
	mov al, 0
	int 21h
	mov dl, ']'
	mov al, 0
	mov ah, 06h
	int 21h
	mov dl, ' '
	mov al, 0
	mov ah, 06h
	int 21h
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

transforma_em_coord: ;Auxiliar que traduz offset para coords
	push dx
	push cx
	mov cx, 64
	push dx
	mov ax, dx
	xor dx, dx
	div cx
	mov ah, al
	pop dx
	push ax
	mov ax, dx
	xor dx, dx
	div cx
	pop ax
	mov al, dl
	pop cx
	pop dx
	ret

traduz:	;Auxiliar que traduz coords para offset da matriz
	push bx
	push cx
	push dx
	mov cx, 64
	mov al, dh
	mov ah, 0
	push dx
	xor dx, dx
	mul cx
	pop dx
	mov dh, 0
	add ax, dx
	pop dx
	pop cx
	pop bx
	ret

strtok:
	push si
	mov si, dx
strtok_loop:
	mov al, [si]
	cmp al, cl
	je strtok_loop_fim
	test al, al
	je strtok_fim_de_linha
	inc si
	jmp strtok_loop
strtok_loop_fim:
	inc si
	mov ax, si
	pop si
	ret
strtok_fim_de_linha:
	xor ax, ax
	pop si
	ret

atoi: ;Converte uma string para um numero
	push di
	push dx
	push cx
	push si
	push bx
	mov si, dx
	xor ax, ax
	xor dx, dx
	mov cx, 10
	mov bl, [si]
atoi_test:
	mov bl, [si]
	cmp bl, '+'
	jne atoi_isnum
	inc si
atoi_isnum:
	mov bl, [si]
	cmp bl, '0'
	jb atoi_malformed
	cmp bl, '9'
	ja atoi_malformed
	
atoi_loop:
	mov bl, [si]
	inc si
	cmp bl, 48
	jb atoi_fim_loop
	cmp bl, 57
	ja atoi_fim_loop
	xor dx, dx
	mul cx
	and bl, 0fh
	mov bh, 0
	add ax, bx
	jmp atoi_loop
atoi_fim_loop:	
	xor bx, bx
	add bx, 1
atoi_malformed_fim:
	pop bx
	pop si
	pop cx
	pop dx
	pop di
	ret
atoi_malformed:
	mov ax, -1
	add ax, -1
	jmp atoi_malformed_fim

strlen:
	push si
	push dx
	xor ax, ax
	mov si, dx
strlen_loop:
	mov dl, [si]
	test dl, dl
	je strlen_loop_fim
	inc si
	inc ax
	jmp strlen_loop
strlen_loop_fim:
	pop dx
	pop si
	ret

strcpy: ;Strcpy(dx, cx)
	push bx
	push bp
	push di
	push si
	push cx
	push dx
	mov si, cx
	mov di, dx
strcpy_loop:
	mov al, [si]
	mov [di], al
	test al, al
	je strcpy_fim
	inc si
	inc di
	jmp strcpy_loop
strcpy_fim:
	pop dx
	push dx
	call strlen
	pop dx
	pop cx
	pop si
	pop di
	pop bp
	pop bx
	ret

fgets:	;funcao padrao do C. Recebe um buffer o tamanho do buffer e um handle de arquivo. Le do handle no buffer até o eof.
	;dx = buffer, cx = n, di = stream. Para facilitar a vida, ela tambem tira os espaços
	push bx
	push dx
	mov bx, di
	mov di, dx
	mov si, cx
fgets_loop:
	cmp si, 1
	je fgets_eof
	mov dx, di
	mov ah, 3fh
	mov cx, 1
	int 21h
	test ax, ax
	je fgets_eof
	mov al, [di]
	inc di
	dec si
	cmp al, LF
	je fgets_testa_fim_de_linha
	cmp al, CR
	je fgets_testa_fim_de_linha
	cmp al, ' '
	je fgets_espaco
	jmp fgets_loop
fgets_espaco:
	inc si
	dec di
	jmp fgets_loop
fgets_eof:
	mov [di], byte ptr '$'
	pop dx
	mov ax, di
	sub ax, dx
	pop bx
	ret
fgets_testa_fim_de_linha:
	cmp si, 1
	je fgets_eof
	mov dx, di
	mov ah, 3fh
	mov cx, 1
	int 21h
	test ax, ax
	je fgets_eof
	mov al, [di]
	inc di
	cmp al, LF
	je fgets_eof
	cmp al, CR
	je fgets_eof
	dec di
	mov cx, -1
	mov dx, -1
	mov ah, 42h
	mov al, 1
	int 21h
	jmp fgets_eof

itos:
	push bx
	push cx
	push dx
	push di
	mov ax, dx
	xor dx, dx
	lea di, buffer_itos
	mov bx, 10
	xor cx, cx
itos_loop:
	div bx
	inc cx
	or dl, 48
	push dx
	test ax, ax
	je itos_loop_fim
	xor dx, dx
	jmp itos_loop
itos_loop_fim:
	pop dx
	mov [di], dl
	inc di
	loop itos_loop_fim
	mov [di], byte ptr 0
	lea ax, buffer_itos
	pop di
	pop dx
	pop cx
	pop bx
	ret

imprime_debug:
	push dx
	push di
	push si
	push cx
	push ax
;	call itos
;	mov dx, ax
;	call strlen
;	add dx, ax
;	mov di, dx
;	mov [di], byte ptr '$'
;	lea dx, buffer_itos
	mov ah, 09h
	mov al, 0
	int 21h
	mov ah, 06h
	mov al, 0
	mov dl, 10
	int 21h
	mov ah, 06h
	mov al, 0
	mov dl, 13
	int 21h
	pop ax
	pop cx
	pop si
	pop di
	pop dx
	ret
	jmp fim_do_programa

imprime_lista_final:
	lea bx, tabela_rainhas
	mov si, 1
imprime_lista_final_loop:
	cmp si, 10
	jae imprime_lista_final_loop_fim
	mov di, si
	shl di, 1
	mov cx, [bx + di]
	cmp cx, -1
	je nao_imprime_linha
	push cx
	lea dx, buffer_escrita
	lea cx, rainha
	mov di, dx
	call strcpy
	add di, ax
	mov dx, si
	call itos
	mov cx, ax
	mov dx, di
	call strcpy
	add di, ax
	mov [di], byte ptr ':'
	inc di
	mov [di], byte ptr ' '
	inc di
	mov [di], byte ptr '('
	inc di
	pop dx
	push dx
	mov dh, 0
	call itos
	mov dx, di
	mov cx, ax
	call strcpy
	add di, ax
	mov [di], byte ptr ','
	inc di
	pop dx
	mov dl, dh
	mov dh, 0
	call itos
	mov cx, ax
	mov dx, di
	call strcpy
	add di, ax
	mov [di], byte ptr ')'
	inc di
	mov [di], byte ptr LF
	inc di
	mov [di], byte ptr CR
	inc di
	mov [di], byte ptr '$'
	lea dx, buffer_escrita
	mov ah, 09h
	mov al, 0
	int 21h
nao_imprime_linha:
	inc si
	jmp imprime_lista_final_loop
imprime_lista_final_loop_fim:
	ret
main endp  
end main  

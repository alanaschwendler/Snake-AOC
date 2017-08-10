# Alana Schwendler e Felipe C. Gruendemann
# Trabalho Final AOCI - 2017/01 - Turma M1

########################## SNAKE ##############################
# Usar bitmap display com as seguintes configurações:
# Unit width in pixels: 16
# Unit height in pixels: 16
# Display width in pixels: 512
# Display height in pixels: 512
# Base address for display: 0x10010000(static data)
#
#
#
#
################################################################

######################## MACROS ################################
	
.macro push %reg #macro para empilhar registrador
	addi $sp, $sp, -4
	sw %reg, ($sp)
.end_macro

.macro pop %reg #macro para desempilhar registrador
	lw %reg, ($sp)
	addi $sp, $sp, 4
.end_macro

.macro done #macro para encerrar o programa 
	li $v0, 10
	syscall #usa syscall
.end_macro

# macro para deslocar por quantidade de pixeis
.macro deslocamentoPixel %qt
	move $a0, %qt
	ori $a1, $zero, 4
	mult $a0, $a1
	mflo $a2
	add $s0, $s0, $a2
.end_macro

.macro deslocamentoLinha %qt
	move $a0, %qt
	ori $a1, $zero, 32
	mult $a0, $a1
	mflo $a2
	deslocamentoPixel $a2
.end_macro

#################################################################

.data
	#tamanho da arena
	tamX: .word 512
	tamY: .word 512
	
	#cores do jogo
	corFundo: .word 0xacc4f6
	corComida: .word 0xd41a1a
	corCobra: .word 0x000080080 
	corBorda: .word 0x000080080 
	
	#tamanho inicial do jogador
	tamanhoInicial: .half 5
	
	#posição inicial do jogador
	posJogX: .half 10
	posJogY: .half 10
	
	#posição inicial da comida
	posComX: .half 5
	posComY: .half 5
	
	#movimentos
	cima: .ascii "w"
	baixo: .ascii "s"
	esquerda: .ascii "a"
	direita: .ascii "d"
.text

MAIN: 
	lui $s0, 0x1001		#s0 é base 0x10010000
	lw $s1, corFundo	#carrega as cores
	lw $s2, corComida
	lw $s3, corCobra
	lw $s4, corBorda
	lw $s5, tamX		#carrega os tamanhos
	lw $s6, tamY
	lw $t9, 0xffff0004	#vai ver a tecla pressionada
	or $t0, $zero, 0	#contador
	push $s0		#empilha a base de endereço
	
	jal MENU
	nop
	
	j ESCOLHA
	nop
	
	done			#macro para finalizar o programa
	
MENU:
	push $ra
	push $s0
	
	ori $t0, $zero, 0
	
	pop $s0
	push $s0
	jal LOOP_ARENA		#preenche o fundo do menu
	nop
	
	pop $s0
	push $s0
	jal MENU_JOGAR
	nop
	
	pop $s0
	pop $ra
	jr $ra
	nop	
	
ESCOLHA:
	lw $t9, 0xffff0004
	
	beq $t9, 0x00000077, CHAMA_ARENA
	nop
	
	beq $t9, 0x00000032, FIM
	nop
	
	j ESCOLHA
	nop
	
CHAMA_ARENA:
	jal ARENA
	nop
	
	j FIM
	nop
	
ARENA:				#subrotina que preenche a arena
	push $ra		#empilha o ra
	push $s0		#empilha o s0
	
	ori $t0, $zero, 0
	jal LOOP_ARENA		#subrotina que preenche o fundo
	nop
	
	pop $s0
	
	li $a0, 80		#emite som quando monta a arena
	li $a1, 80
	li $a2, 32
	li $a3, 127
	li $v0, 31
	syscall
	
	jal COBRA		#subrotina para imprimir a cobra
	nop
	
	push $s0
	jal BORDA		#subrotina para preencher as bordas da arena
	nop
	pop $s0
	
	push $s0	
	jal COMIDA		#subrotina para preencher a comida
	nop
	pop $s0
	
	pop $ra			#desempilha o ra
	jr $ra			#volta e executa a proxima instrução
	nop
	
LOOP_ARENA:			#subrotina com loop para pintar os pixels do fundo
	
	#pintando o fundo da tela
	sw $s1, 0($s0)		#armazena o valor de s1(cor de fundo) de acordo com o valor de s0
	add  $s0, $s0, 0x4	#vai pra próxima posição a ser escrita
	add $t0, $t0, 1		#incrementa o contador 
	beq $t0, 1024, LOOP_ARENA_END	#testa pelo contador se todos os pixeis de fundo já foram pintados
	nop
	j LOOP_ARENA		#caso necessário, volta pra mesma subrotina e continua pintando os pixeis
	nop
	
LOOP_ARENA_END:			#subrotina que finaliza o loop da arena
	jr $ra
	nop
	
COBRA:				#subrotina que pinta o personagem
	or $t1, $zero, $s0	#faz uma cópia do s0 pra t1
	push $ra		#empilha o ra
	
	ori $a0, $zero, 0x1980
	
	sw $s3, 1980($t1)	#pinta o personagem no meio da tela
	add $t1, $t1, 0x4	#faz isso pra 3 pixels
	sw $s3, 1980($t1)
	add $t1, $t1, 0x4
	sw $s3, 1980($t1)
	
	pop $ra			#desempilha o ra
	jr $ra			#volta pra subrotina chamadora
	nop
	
BORDA:				#subrotina para preencher as bordas da tela
	#or $t1, $zero, $s0 	#faz uma cópia da base pra t1
	push $ra		#empilha o ra
	push $s0		#empilha o s0
	or $t0, $zero, 0	#zera o contador
		
	jal BORDA_TOPO
	nop
	
	pop $s0			#desempilha s0
	push $s0		#empilha o s0
	
	jal BORDA_BASE		#vai pro preenchimento da borda da base
	nop
	
	pop $s0			#desempilha s0
	push $s0		#empilha s0
	
	jal BORDA_ESQUERDA	#subrotina que pinta a borda da esquerda
	nop
	
	pop $s0			#desempilha s0
	push $s0		#empilha s0
	
	jal BORDA_DIREITA	#subrotina que imprime a borda da direita
	nop
	
	pop $s0			#desempilha o s0
	pop $ra			#desempilha o ra
	jr $ra			#volta pra subrotina chamadora
	nop
	
BORDA_TOPO:			#inicio borda topo com inicialização de registradores
	push $ra
	or $t0, $zero, 0	#zera o contador
	j LOOP_BORDA_TOPO	#vai pro loop
	nop
	
LOOP_BORDA_TOPO:		#preenchimento da borda com loop
	
	sw $s4, 0($s0)		#pinta o pixel com o valor da cor de borda
	add $s0, $s0, 0x4	#soma um pixel na base
	add $t0, $t0, 1		#incrementa o contador
		
	beq $t0, 32, END_BORDA_TOPO	#se o contador chegar em 32, termina o loop. O valor é 32 porque são 512 pixeis divididos por 16 (tamanho do pixel) = 32
	nop
	
	j LOOP_BORDA_TOPO	#caso o contador não seja 32 ainda, continua no loop
	nop
	
END_BORDA_TOPO:
	pop $ra
	jr $ra
	nop
	
BORDA_BASE:
	push $ra
	or $t0, $zero, 0	#zera o contador
	ori $t2, $zero, 31	#carrega 31 pra poder preencher a linha da base
	deslocamentoLinha $t2 
	j LOOP_BORDA_BASE
	nop

LOOP_BORDA_BASE:
	sw $s4, 0($s0)		#pinta a borda com a cor de borda
	add $s0, $s0, 0x4	#incrementa um pixel na base de endereçamento
	add $t0, $t0, 1		#incrementa o contador
	beq $t0, 32, END_BORDA_BASE	#se o contador é 32, termina o loop
	nop
	j LOOP_BORDA_BASE	#caso contrário, continua no loop
	nop
	
END_BORDA_BASE:			#termina o loop de preenchimento da base
	pop $ra
	jr $ra
	nop
	
BORDA_ESQUERDA:
	push $ra		#empilha o ra
	or $t0, $zero, 0 	#zera o contador
	ori $t1, $zero, 32	#t1 recebe 32 pra deslocar esta quantidade de pixeis e pintar só a borda
	j LOOP_BORDA_ESQUERDA	#vai pro loop de preencher a borda da esquerda
	nop
	
LOOP_BORDA_ESQUERDA:		#loop de preenchimento da borda esquerda
	deslocamentoPixel $t1	#manda o macro fazer o deslocamento de 32 pixeis (equivalente a uma linha)
	sw $s4, 0($s0)		#pinta um pixel (primeiro de cada linha)
	add $t0, $t0, 1		#incrementa o contador
	beq $t0, 32, END_LOOP_BORDA_ESQUERDA	#caso o contador tenha chegado em 32, ou seja, imprimiu o primeiro pixel de todas as linhas, termina
	nop	
	j LOOP_BORDA_ESQUERDA	#caso contrário, continua no loop até imprimir de todas as linhas
	nop
	
END_LOOP_BORDA_ESQUERDA:	#termina o loop de preenchimento da borda esquerda
	pop $ra
	jr $ra
	nop
	
BORDA_DIREITA:
	push $ra		#empilha o ra
	or $t0, $zero, 0 	#zera o contador
	ori $t1, $zero, 32	#t1 recebe 32 pra deslocar esta quantidade de pixeis e pintar só a borda
	j LOOP_BORDA_DIREITA	#vai pro loop de preencher a borda da direita
	nop
	
LOOP_BORDA_DIREITA:		#loop para preencher a borda da direita
	deslocamentoPixel $t1	#faz o deslocamento de 32 bits e vai preencher uma coluna inteira, ao final
	sw $s4, 124($s0)	#pega cada pixel da coluna e desloca 124, até fiacar a coluna toda na borda direita
	add $t0, $t0, 1		#incrementa 
	beq $t0, 32, END_LOOP_BORDA_DIREITA	#caso já tenha feito preenchimento para todas as linhas, termina o loop
	nop
	j LOOP_BORDA_DIREITA	#caso contrário, continua no loop
	nop

END_LOOP_BORDA_DIREITA:
	pop $ra			#desempilha o ra
	jr $ra			#volta pra subrotina chamadora
	nop
	
COMIDA:
	push $ra
	sw $s2, 1088($s0)
	pop $ra
	jr $ra
	nop
	
MENU_JOGAR:
	push $ra
	
	#J
	sw $s4, 1552($s0)
	sw $s4, 1556($s0)
	sw $s4, 1560($s0)
	sw $s4, 1564($s0)
	sw $s4, 1568($s0)
	sw $s4, 1688($s0)
	sw $s4, 1816($s0)
	sw $s4, 1944($s0)
	sw $s4, 1936($s0)
	sw $s4, 2072($s0)
	sw $s4, 2068($s0)
	
	#O
	sw $s4, 1576($s0)
	sw $s4, 1580($s0)
	sw $s4, 1584($s0)
	sw $s4, 1588($s0)
	sw $s4, 1704($s0)
	sw $s4, 1716($s0)
	sw $s4, 1832($s0)
	sw $s4, 1844($s0)
	sw $s4, 1960($s0)
	sw $s4, 1972($s0)
	sw $s4, 2088($s0)
	sw $s4, 2088($s0)
	sw $s4, 2092($s0)
	sw $s4, 2096($s0)
	sw $s4, 2100($s0)
	
	#G
	sw $s4, 1596($s0)
	sw $s4, 1600($s0)
	sw $s4, 1604($s0)
	sw $s4, 1608($s0)
	sw $s4, 1724($s0)
	sw $s4, 1852($s0)
	sw $s4, 1860($s0)
	sw $s4, 1864($s0)
	sw $s4, 1980($s0)
	sw $s4, 1992($s0)
	sw $s4, 2108($s0)
	sw $s4, 2112($s0)
	sw $s4, 2116($s0)
	sw $s4, 2120($s0)
	
	#A
	sw $s4, 1616($s0)
	sw $s4, 1620($s0)
	sw $s4, 1624($s0)
	sw $s4, 1628($s0)
	sw $s4, 1744($s0)
	sw $s4, 1756($s0)
	sw $s4, 1872($s0)
	sw $s4, 1876($s0)
	sw $s4, 1880($s0)
	sw $s4, 1884($s0)
	sw $s4, 2000($s0)
	sw $s4, 2012($s0)
	sw $s4, 2128($s0)
	sw $s4, 2140($s0)
	
	
	#R
	sw $s4, 1636($s0)
	sw $s4, 1640($s0)
	sw $s4, 1644($s0)
	sw $s4, 1648($s0)
	sw $s4, 1764($s0)
	sw $s4, 1776($s0)
	sw $s4, 1892($s0)
	sw $s4, 1896($s0)
	sw $s4, 1900($s0)
	sw $s4, 1904($s0)
	sw $s4, 2020($s0)
	sw $s4, 2028($s0)
	sw $s4, 2148($s0)
	sw $s4, 2160($s0)
	
	
	pop $ra
	jr $ra
	nop


FIM:
	nop

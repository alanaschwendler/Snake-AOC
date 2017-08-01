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
	#sll $a1, $a1, 2
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
	corComida: .word 0x82acf2
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
	
.text

MAIN: 
	lui $s0, 0x1001		#s0 é base 0x10010000
	lw $s1, corFundo	#carrega as cores
	lw $s2, corComida
	lw $s3, corCobra
	lw $s4, corBorda
	lw $s5, tamX		#carrega os tamanhos
	lw $s6, tamY
	or $t0, $zero, 0	#contador
	push $s0		#empilha a base de endereço
	
	jal ARENA		#subrotina para preencher a arena
	nop
	
	done			#macro para finalizar o programa
	
ARENA:				#subrotina que preenche a arena
	push $ra		#empilha o ra
	push $s0		#empilha o s0
	jal LOOP_ARENA		#subrotina que preenche o fundo
	nop
	
	pop $s0
	
	jal COBRA		#subrotina para imprimir a cobra
	nop
	
	push $s0
	jal BORDA
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
	pop $s0			#desempilha o s0
	pop $ra			#desempilha o ra
	jr $ra			#volta pra subrotina chamadora
	nop
	
BORDA_TOPO:
	push $ra
	or $t0, $zero, 0	#zera o contador
	j LOOP_BORDA_TOPO
	nop
	
LOOP_BORDA_TOPO:		#preenchimento da borda
	
	sw $s4, 0($s0)		#pinta o pixel com o valor da cor de borda
	add $s0, $s0, 0x4	#soma um pixel na base
	add $t0, $t0, 1		#incrementa o contador
		
	beq $t0, 32, END_BORDA_TOPO
	nop
	
	j LOOP_BORDA_TOPO
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
	sw $s4, 0($s0)
	add $s0, $s0, 0x4
	add $t0, $t0, 1
	beq $t0, 32, END_BORDA_BASE
	nop
	j LOOP_BORDA_BASE
	nop
	
END_BORDA_BASE:
	pop $ra
	jr $ra
	nop

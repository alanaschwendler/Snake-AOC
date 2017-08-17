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
# PRESSIONE W PARA COMEÇAR
# PRESSIONE S PARA SAIR
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
	corFundo: .word 0xa6a4a4
	corComida: .word 0xd41a1a
	corCobra: .word 0xFF7777
	#corBorda: .word 0x00ffee
	corBorda: .word 0x2d6965
	corFim: .word 0x00000000

	#tamanho inicial do jogador
	tamanhoInicial: .half 5

	#posição inicial da comida
	posComX: .half 5
	posComY: .half 5

	#movimentos
	cima: .ascii "w"
	baixo: .ascii "s"
	esquerda: .ascii "a"
	direita: .ascii "d"
	
	espaco: .space 4096
	dead: .asciiz "Morreu!"
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
	li $v1,	10000		#velocidade da snake
	or $t0, $zero, 0	#contador
	push $s0		#empilha a base de endereço

	jal MENU
	nop

	jal ESCOLHA
	nop

##----------------- Configurações de gameplay ------------------------##

	li $v0, 9		# Aloca memória para salvar os endereços da cobra
	li $t2, 1024		# espaço que vai ser alocado
	syscall
	move $t3, $v0		# inicio do vetor da cobra em $t3
	move $t4, $t3		# copia inicio do vetor para $t4

	addi $t2, $s0, 1080	# posicao de inicio da cabeça

	sw $t2, 0($t4)		# essa secao desenha a cabeça da cobra
	addi $t4, $t4, 4	# e o resto do corpo inicial
	addi $t2, $t2, -4	# além disso, armazena cada parte
	sw $t2, 0($t4)		# no vetor da cobra
	addi $t4, $t4, 4
	addi $t2, $t2, -4
	sw $t2, 0($t4)
	
	li $a2, 3		# tamanho da cobra inicial
	li $t9, 0x00000064	# direcao de movimento inicial
	move $t7, $t9

PLAY:
	beq $zero, 1, DONE
	nop

	li $t0, 2		# comeca contador
	move $t4, $t3		# vai pro inicio do vetor

	lw $t2, 0($t4)		# carrega cabeca
	move $t5, $t2		# salva a posicao em $t5

	beq $t9, 0x00000064, cdireita
	nop
	beq $t9, 0x00000061, cesquerda
	nop
	beq $t9, 0x00000077, ccima
	nop
	beq $t9, 0x00000073, cbaixo
	nop

	j PLAY
	nop

cbaixo:
	addi $t1, $t2, 128	# testa se vai bater na parede
	lw $t1, 0($t1)
	beq $t1, $s4, MORREU	# se sim, morreu
	nop
	beq $t1, $s3, MORREU
	nop
	
	addi $t2, $t2, 128	# atualiza cabeca
	j sai
	nop
ccima:
	addi $t1, $t2, -128	# testa se vai bater na parede
	lw $t1, 0($t1)
	beq $t1, $s4, MORREU	# se sim, morreu
	nop
	beq $t1, $s3, MORREU
	nop

	addi $t2, $t2, -128	# atualiza cabeca
	j sai
	nop
cesquerda:
	addi $t1, $t2, -4	# testa se vai bater na parede
	lw $t1, 0($t1)
	beq $t1, $s4, MORREU	# se sim, morreu
	nop
	beq $t1, $s3, MORREU
	nop

	addi $t2, $t2, -4	# atualiza cabeca
	j sai
	nop
cdireita:
	addi $t1, $t2, 4	# testa se vai bater na parede
	lw $t1, 0($t1)
	beq $t1, $s4, MORREU	# se sim, morreu
	nop
	beq $t1, $s3, MORREU
	nop
	
	addi $t2, $t2, 4	# atualiza cabeca
	j sai
	nop

sai:
	sw $t2, 0($t4)		# salva na memoria
	sw $s3, 0($t2) 		# pinta na tela
	addi $t4, $t4, 4	# proxima posicao do vetor

mov:	beq $t0, $a2, pronta
	nop

	lw $t2, 0($t4)		# carrega posicao do pedaço
	sw $t5, 0($t4)		# salva no vetor a posicao do pedaco anterior
	sw $s3, 0($t2)		# pinta na tela
	move $t5, $t2		# salva para proxima posicao em $t5
	addi $t4, $t4, 4	# atualiza apontador
	addi $t0, $t0, 1	# atualiza contador
	j mov
	nop

pronta:
	
	move $t6, $v1 		# variavel do delay
	
	lw $t2, 0($t4)		# carrega cauda
	sw $t5, 0($t4)		# atualiza cauda na memoria
	
	seq $t1, $t1, $s2	# carrega o teste da comida
	beq $t1, 1, comeu
	nop
	
	sw $s1, 0($t2)		# apaga cauda
	j delay
	nop

comeu:		
	addi $t4, $t4, 4	# atualiza apontador
	sw $t2, 0($t4)		# salva nova cauda 	
	addi $a2, $a2, 1	# aumenta o tamanho
	subi $v1, $v1, 200	# aumenta a velocidade
	
rand:	

	li $v0, 30		# get time in milliseconds (as a 64-bit value)
	syscall

	move $s7, $a0		# save the lower 32-bits of time

	li $a0, 1		# random generator id (will be used later)
	move $a1, $s7		# seed from time
	li $v0, 40		# seed random number generator syscall
	syscall
	
	li $a0, 1		# as said, this id is the same as random generator id
	li $a1, 255		# upper bound of the range
	li $v0, 42		# random int range
	syscall
	
	sll $a0, $a0, 2
	addi $a0, $a0, 0x10010000
	lw $a1, 0($a0)
	
	bne $s1, $a1, rand
	nop
	
	sw $s2, 0($a0)
	
	
	
delay:
	beq $t6, $zero, fdelay
	nop
	addi $t6, $t6, -1
	
	
	lw $t7, 0xffff0004
	
	beq $t7, 0x00000077, atualiza_movimento	
	nop
	
	beq $t7, 0x00000073, atualiza_movimento	
	nop
	
	beq $t7, 0x00000064, atualiza_movimento	
	nop
	
	beq $t7, 0x00000061, atualiza_movimento	
	nop
	

	nop
	j delay
	nop

atualiza_movimento: #a0, a1, v0, s7

	seq $a0, $t9, 0x00000077
	seq $a1, $t7, 0x00000073
	add $a0, $a0, $a1
	
	beq $a0, 2, delay
	nop
	
	seq $a0, $t9, 0x00000073
	seq $a1, $t7, 0x00000077
	add $a0, $a0, $a1
	
	beq $a0, 2, delay
	nop
	
	seq $a0, $t9, 0x00000064
	seq $a1, $t7, 0x00000061
	add $a0, $a0, $a1
	
	beq $a0, 2, delay
	nop
	
	seq $a0, $t9, 0x00000061
	seq $a1, $t7, 0x00000064
	add $a0, $a0, $a1
	
	beq $a0, 2, delay
	nop
	
	move $t9, $t7
	
	j delay
	nop

fdelay:	j PLAY
	nop


DONE:  
	lui $s1, 0
	lui $s2, 0
	lui $s3, 0
	lui $s4, 0
	
	jal ARENA
	nop
	
	li $v0, 10
	syscall
	
morreu:
       j DONE
       nop
       
	


###############################################################################################################################################

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
	#jal MORREU
	nop

	pop $s0
	pop $ra
	jr $ra
	nop

ESCOLHA:	
	push $ra
	lw $t9, 0xffff0004			#t9 tem o endereço de onde fica salva a entrada do teclado
	
	ori $t0, $zero, 0			#zera o contador
	
	j LOOP_ESCOLHA
	nop

LOOP_ESCOLHA:
	lw $t9, 0xffff0004
	
	beq $t9, 0x00000077, CHAMA_ARENA	#se for w, chama a arena
	nop

	beq $t9, 0x00000073, DONE		#se for s chama o fim
	nop
	
	add $t0, $t0, 1
	beq $t0, 0xFFFFFFFF, FIM_LOOP
	nop
	
	j LOOP_ESCOLHA				#repete a função até ler algo
	nop
	
FIM_LOOP:
	pop $ra
	jr $ra
	nop

CHAMA_ARENA:
	jal ARENA
	nop

	j FIM_LOOP
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
	
	sw $s2,1808($s0)		#pinta a comida com base no s0
	
	pop $ra
	jr $ra
	nop

MENU_JOGAR:
	push $ra

	
	#J
	sw $s4, 784($s0)
	sw $s4, 788($s0)
	sw $s4, 792($s0)
	sw $s4, 796($s0)
	sw $s4, 800($s0)
	sw $s4, 920($s0)
	sw $s4, 1048($s0)
	sw $s4, 1176($s0)
	sw $s4, 1168($s0)
	sw $s4, 1304($s0)
	sw $s4, 1300($s0)

	#O
	#sw $s4, 808($s0)
	sw $s4, 812($s0)
	sw $s4, 816($s0)
	#sw $s4, 820($s0)
	sw $s4, 936($s0)
	sw $s4, 948($s0)
	sw $s4, 1064($s0)
	sw $s4, 1076($s0)
	sw $s4, 1192($s0)
	sw $s4, 1204($s0)
	#sw $s4, 1320($s0)
	sw $s4, 1324($s0)
	sw $s4, 1328($s0)
	#sw $s4, 1332($s0)

	#G
	#sw $s4, 828($s0)
	sw $s4, 832($s0)
	sw $s4, 836($s0)
	sw $s4, 840($s0)
	sw $s4, 956($s0)
	sw $s4, 1084($s0)
	sw $s4, 1092($s0)
	sw $s4, 1096($s0)
	sw $s4, 1212($s0)
	sw $s4, 1224($s0)
	#sw $s4, 1340($s0)
	sw $s4, 1344($s0)
	sw $s4, 1348($s0)
	#sw $s4, 1352($s0)

	#A
	#sw $s4, 848($s0)
	sw $s4, 852($s0)
	sw $s4, 856($s0)
	#sw $s4, 860($s0)
	sw $s4, 976($s0)
	sw $s4, 988($s0)
	sw $s4, 1104($s0)
	sw $s4, 1108($s0)
	sw $s4, 1112($s0)
	sw $s4, 1116($s0)
	sw $s4, 1232($s0)
	sw $s4, 1244($s0)
	sw $s4, 1360($s0)
	sw $s4, 1372($s0)


	#R
	#sw $s4, 868($s0)
	sw $s4, 872($s0)
	sw $s4, 876($s0)
	#sw $s4, 880($s0)
	sw $s4, 996($s0)
	sw $s4, 1008($s0)
	sw $s4, 1124($s0)
	sw $s4, 1128($s0)
	sw $s4, 1132($s0)
	sw $s4, 1136($s0)
	sw $s4, 1252($s0)
	sw $s4, 1260($s0)
	sw $s4, 1380($s0)
	sw $s4, 1392($s0)
	
	
	#S
	sw $s4, 2328($s0)
	sw $s4, 2332($s0)
	sw $s4, 2336($s0)
	sw $s4, 2340($s0)
	sw $s4, 2456($s0)
	sw $s4, 2584($s0)
	sw $s4, 2588($s0)
	sw $s4, 2592($s0)
	sw $s4, 2596($s0)
	sw $s4, 2724($s0)
	sw $s4, 2840($s0)
	sw $s4, 2844($s0)
	sw $s4, 2848($s0)
	sw $s4, 2852($s0)
	
	#A
	#sw $s4, 2348($s0)
	sw $s4, 2352($s0)
	sw $s4, 2356($s0)
	#sw $s4, 2360($s0)
	sw $s4, 2476($s0)
	sw $s4, 2488($s0)
	sw $s4, 2604($s0)
	sw $s4, 2608($s0)
	sw $s4, 2612($s0)
	sw $s4, 2616($s0)
	sw $s4, 2732($s0)
	sw $s4, 2744($s0)
	sw $s4, 2860($s0)
	sw $s4, 2872($s0)
	
	#I
	sw $s4, 2368($s0)
	sw $s4, 2372($s0)
	sw $s4, 2376($s0)
	sw $s4, 2380($s0)
	sw $s4, 2384($s0)
	sw $s4, 2504($s0)
	sw $s4, 2632($s0)
	sw $s4, 2760($s0)
	sw $s4, 2880($s0)
	sw $s4, 2884($s0)
	sw $s4, 2888($s0)
	sw $s4, 2892($s0)
	sw $s4, 2896($s0)
	
	#R
	#sw $s4, 2392($s0)
	sw $s4, 2396($s0)
	sw $s4, 2400($s0)
	#sw $s4, 2404($s0)
	sw $s4, 2520($s0)
	sw $s4, 2532($s0)
	sw $s4, 2648($s0)
	sw $s4, 2652($s0)
	sw $s4, 2656($s0)
	sw $s4, 2660($s0)
	sw $s4, 2776($s0)
	sw $s4, 2784($s0)
	sw $s4, 2904($s0)
	sw $s4, 2916($s0)
	
	pop $ra
	jr $ra
	nop

MORREU:
	#push $ra
	li $v1,	10000		#velocidade da snake
	li $a0, 80		#emite som quando monta a arena
	li $a1, 250		#duração em milissegundos
	li $a2, 126		#qual som
	li $a3, 127		#volume 
	li $v0, 31
	syscall
	
	#G
	#sw $s4, 828($s0)
	sw $s2, 788($s0)
	sw $s2, 792($s0)
	sw $s2, 796($s0)
	sw $s2, 912($s0)
	sw $s2, 1040($s0)
	sw $s2, 1048($s0)
	sw $s2, 1052($s0)
	sw $s2, 1168($s0)
	sw $s2, 1180($s0)
	sw $s2, 1300($s0)
	sw $s2, 1304($s0)

	#A
	sw $s2, 808($s0)
	sw $s2, 812($s0)
	sw $s2, 932($s0)
	sw $s2, 944($s0)
	sw $s2, 1060($s0)
	sw $s2, 1064($s0)
	sw $s2, 1068($s0)
	sw $s2, 1072($s0)
	sw $s2, 1188($s0)
	sw $s2, 1200($s0)
	sw $s2, 1316($s0)
	sw $s2, 1328($s0)
	
	#M
	sw $s2, 824($s0)
	sw $s2, 840($s0)
	sw $s2, 952($s0)
	sw $s2, 956($s0)
	sw $s2, 964($s0)
	sw $s2, 968($s0)
	sw $s2, 1080($s0)
	sw $s2, 1088($s0)
	sw $s2, 1096($s0)
	sw $s2, 1208($s0)
	sw $s2, 1224($s0)
	sw $s2, 1336($s0)
	sw $s2, 1352($s0)
	
	#E
	sw $s2, 848($s0)
	sw $s2, 852($s0)
	sw $s2, 856($s0)
	sw $s2, 860($s0)
	sw $s2, 976($s0)
	sw $s2, 1104($s0)
	sw $s2, 1108($s0)
	sw $s2, 1112($s0)
	sw $s2, 1116($s0)
	sw $s2, 1232($s0)
	sw $s2, 1360($s0)
	sw $s2, 1364($s0)
	sw $s2, 1368($s0)
	sw $s2, 1372($s0)
	
	#O
	sw $s2, 1812($s0)
	sw $s2, 1816($s0)
	sw $s2, 1936($s0)
	sw $s2, 1948($s0)
	sw $s2, 2064($s0)
	sw $s2, 2076($s0)
	sw $s2, 2192($s0)
	sw $s2, 2204($s0)
	sw $s2, 2324($s0)
	sw $s2, 2328($s0)
	
	#V
	sw $s2, 1828($s0)
	sw $s2, 1844($s0)
	sw $s2, 1956($s0)
	sw $s2, 1972($s0)
	sw $s2, 2084($s0)
	sw $s2, 2100($s0)
	sw $s2, 2216($s0)
	sw $s2, 2224($s0)
	sw $s2, 2348($s0)
	
	#E
	sw $s2, 1852($s0)
	sw $s2, 1856($s0)
	sw $s2, 1860($s0)
	sw $s2, 1864($s0)
	sw $s2, 1980($s0)
	sw $s2, 2108($s0)
	sw $s2, 2112($s0)
	sw $s2, 2116($s0)
	sw $s2, 2120($s0)
	sw $s2, 2236($s0)
	sw $s2, 2364($s0)
	sw $s2, 2368($s0)
	sw $s2, 2372($s0)
	sw $s2, 2376($s0)
	
	#R
	sw $s2, 1876($s0)
	sw $s2, 1880($s0)
	sw $s2, 2000($s0)
	sw $s2, 2012($s0)
	sw $s2, 2128($s0)
	sw $s2, 2132($s0)
	sw $s2, 2136($s0)
	sw $s2, 2140($s0)
	sw $s2, 2256($s0)
	sw $s2, 2264($s0)
	sw $s2, 2384($s0)
	sw $s2, 2396($s0)
	
	#pop $ra
	li $t9, 0
	sw $t9, 0xffff0004
	
	j ESCOLHA
	nop 
	
	j DONE
	nop
	
	

FIM:
	pop $ra
	jr $ra
	nop

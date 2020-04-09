.eqv BITMAP_WIDTH 32
.eqv BITMAP_HEIGHT 32
.eqv VERTEX1_X 16
.eqv VERTEX1_Y 2
.eqv VERTEX1_BGR 0x00ff0000
.eqv VERTEX2_X 2
.eqv VERTEX2_Y 30
.eqv VERTEX2_BGR 0x0000ff00
.eqv VERTEX3_X 30
.eqv VERTEX3_Y 30
.eqv VERTEX3_BGR 0x000000ff
.eqv BKG_COLOR 0x0030d5c8

.data
	.half -1 # padding (for word-aligning bitmap header)
	BITMAPFILEHEADER:
	.ascii "BM" # (+0x0) bfType
	.word 14    # (+0x2) bfSize
	.half 0     # (+0x6) bfReserved1
	.half 0     # (+0x8) bfReserved2
	.word 54    # (+0xa) bfOffBits

	BITMAPINFOHEADER:
	.word 40 # (+0x00) biSize
	.word 0  # (+0x04) biWidth (to specify)
	.word 0  # (+0x08) biHeight (to specify)
	.half 1  # (+0x0c) biPlanes
	.half 24 # (+0x0e) biBitCount
	.word 0  # (+0x10) biCompression
	.word 0  # (+0x14) biSizeImage (to specify)
	.word 0  # (+0x18) biXPelsPerMeter (ignored)
	.word 0  # (+0x1c) biYPelsPerMeter (ignored)
	.word 0  # (+0x20) biClrUsed
	.word 0  # (+0x24) biClrImportant

	output_filename:
	.asciiz "result.bmp"
	
	vertex_data:
	# vertex1
	.word VERTEX1_X   # (+0x00) x
	.word VERTEX1_Y   # (+0x04) y
	.word VERTEX1_BGR # (+0x08) b
	                  # (+0x09) g
	                  # (+0x0a) r
	# vertex2
	.word VERTEX2_X   # (+0x0c) x
	.word VERTEX2_Y   # (+0x10) y
	.word VERTEX2_BGR # (+0x14) b
	                  # (+0x15) g
	                  # (+0x16) r
	# vertex3
	.word VERTEX3_X   # (+0x18) x
	.word VERTEX3_Y   # (+0x1c) y
	.word VERTEX3_BGR # (+0x20) b
	                  # (+0x21) g
	                  # (+0x22) r

.text
main:
	# [prepare bitmap header and data]
	li $a0, BITMAP_WIDTH	
	li $a1, BITMAP_HEIGHT
	jal generate_bitmap
	move $s0, $v0
	move $s1, $v1

	la $s2, vertex_data
	# [rearrange vertices]
	move $a0, $s2
	jal rearrange_vertices

	# [process bitmap]
	move $a0, $s0
	move $a1, $s1
	move $a2, $s2
	jal draw_triangle
	
	# [save to file]
	write_file:
	# open output file
	li $v0, 13
	la $a0, output_filename
	li $a1, 1 # write-only mode
	syscall
	bltz $v0, exit
	move $t0, $v0

	# write BMP headers to file
	li $v0, 15
	move $a0, $t0
	la $a1, BITMAPFILEHEADER
	lw $a2, 2($a1)
	syscall

	li $v0, 15
	move $a0, $t0
	move $a1, $s0
	lw $a2, ($a1)
	syscall
	# TODO: error check

	# write image contents to file
	li $v0, 15
	move $a0, $t0
	move $a1, $s1
	lw $a2, 20($s0)
	syscall
	# TODO: error check

	# close the file
	li $v0, 16
	move $a0, $t0
	syscall

	exit:
	li $v0, 10
	syscall


	# parameters:
	# $a0 - width
	# $a1 - height
	# returns:
	# $v0 - pointer to BITMAPINFOHEADER
	# $v1 - pointer to image data
generate_bitmap:
	move $t0, $a0
	move $t1, $a1
	lw $t2, BITMAPINFOHEADER
	# allocate memory for bitmap header
	li $v0, 9
	move $a0, $t2
	syscall
	move $t3, $v0
	# copy template data to allocated header
	move $t4, $zero
	header_copy_loop:
	lw $t5, BITMAPINFOHEADER($t4)
	addu $t6, $t3, $t4
	sw $t5, ($t6)
	addiu $t4, $t4, 4
	blt $t4, $t2, header_copy_loop
	# set variable header data
	sw $t0, 4($t3) # width
	sw $t1, 8($t3) # height
	sll $t4, $t0, 1    #
	addu $t4, $t4, $t0 # multiply width by 3
	addiu $t4, $t4, 3 #
	andi $t4, -4      # round up to nearest word
	mulu $t4, $t4, $t1
	sw $t4, 20($t3) # pixel data size
	# TODO: error on too large data
	# allocate space for pixel data
	li $v0, 9
	move $a0, $t5
	syscall
	# place returned pointers in v-registers
	move $v1, $v0
	move $v0, $t3
	jr $ra
	
	
	# parameters:
	# $a0 - pointer to data of three vertices
rearrange_vertices:
	move $t0, $a0
	lw $t1, 4($t0)
	lw $t2, 16($t0)
	lw $t3, 28($t0)
	bne $t1, $t2, second_check
	lw $t4, ($t0)
	lw $t5, 12($t0)
	sw $t4, 12($t0)
	sw $t5, ($t0)
	lw $t4, 4($t0)
	lw $t5, 16($t0)
	sw $t4, 16($t0)
	sw $t5, 4($t0)
	lw $t4, 8($t0)
	lw $t5, 20($t0)
	sw $t4, 20($t0)
	sw $t5, 8($t0)
	j sanity_check
	
	second_check:
	bne $t1, $t3, arranged
	lw $t4, ($t0)
	lw $t5, 24($t0)
	sw $t4, 24($t0)
	sw $t5, ($t0)
	lw $t4, 4($t0)
	lw $t5, 28($t0)
	sw $t4, 28($t0)
	sw $t5, 4($t0)
	lw $t4, 8($t0)
	lw $t5, 32($t0)
	sw $t4, 32($t0)
	sw $t5, 8($t0)
	
	sanity_check:
	bne $t1, $t2, arranged
	# error: not a triangle
	
	arranged:
	jr $ra
	
	
	# parameters:
	# $a0 - pointer to bitmap details (BITMAPINFOHEADER)
	# $a1 - pointer to bitmap data
	# $a2 - pointer to vertices data
draw_triangle:
	# prologue
	subiu $sp, $sp, 4
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	
	# stack layout
	# (+0x24) vertex max Y
	# (+0x20) vertex min Y
	# (+0x00) saved registers (8 * 4 bytes)
	
	# saved registers layout
	# $s0 - row counter
	# $s1 - column counter
	# $s2 - pixel memory offset
	# $s3 - left side X position
	# $s4 - left side color
	# $s5 - right side X position
	# $s6 - right side color
	# $s7 - background color

	# temporary registers layout
	# $t0 - current color
	# $t1-$t9 - temporary
	
	lw $s0, 8($a0)
	subiu $s0, $s0, 1
	li $s7, BKG_COLOR



	# calculate min and max vertex Y
	lw $t7, 4($a2)
	move $t9, $t7 # max Y
	move $t8, $t7 # min Y
	lw $t7, 16($a2)
	sgtu $t6, $t7, $t9
	movn $t9, $t7, $t6
	sltu $t6, $t7, $t8
	movn $t8, $t7, $t6
	lw $t7, 28($a2)
	sgtu $t6, $t7, $t9
	movn $t9, $t7, $t6
	sltu $t6, $t7, $t8
	movn $t8, $t7, $t6
	sw $t8, 32($sp)
	sw $t9, 36($sp)
	
	# initialize the loop
		
	row_loop:
	bltz $s0, draw_end
	lw $s1, 4($a0)
	subiu $s1, $s1, 1
	
	subiu $s3, $zero, 1
	subiu $s5, $zero, 1
	# check if Ymin <= Y <= Ymax
	lw $t8, 32($sp)
	lw $t9, 36($sp)
	subu $t8, $s0, $t8
	subu $t9, $s0, $t9
	mul $t8, $t8, $t9
	mfhi $t9
	slti $t9, $t9, 0
	seq $t8, $t8, 0
	or $t9, $t8, $t9
	beqz $t9, calc_offset # $t9 == 0 (positive product, not in range)
	
	# calculate left and right side
	#left
	lw $t9, ($a2)
	lw $t8, 4($a2)
	lw $t7, 12($a2)
	lw $t6, 16($a2)
	subu $t7, $t9, $t7
	subu $t6, $t8, $t6
	subu $t5, $t8, $s0
	mul $t7, $t7, $t5
	div $t7, $t7, $t6
	# TODO: better division
	subu $t7, $t9, $t7
	move $s3, $t7
	#right
	lw $t7, 24($a2)
	lw $t6, 28($a2)
	subu $t7, $t9, $t7
	subu $t6, $t8, $t6
	mul $t7, $t7, $t5
	div $t7, $t7, $t6
	subu $t7, $t9, $t7
	move $s5, $t7

	# calculate memory offset of the last column in the row
	calc_offset:
	lw $s2, 4($a0)
    addiu $s2, $s2, 3
    andi $s2, -4
	mulu $s2, $s2, $s0 # multiply padded image width by current row number
	addu $s2, $s2, $s1 # add last column offset
	sll $t9, $s2, 1    #
	addu $s2, $t9, $s2 # multiply by 3 (bytes per pixels)

	column_loop:
	bltz $s1, row_loop_end
	
	# color = background
	move $t0, $s7
	# check if Xmin <= X <= Xmax
	move $t8, $s3
	move $t9, $s5
	subu $t8, $s1, $t8
	subu $t9, $s1, $t9
	mul $t8, $t8, $t9
	mfhi $t9
	slti $t9, $t9, 0
	seq $t8, $t8, 0
	or $t9, $t8, $t9
	beqz $t9, store_pixel # $t9 == 0 (positive product, not in range)
	# calculate color (not background)
	move $t0, $zero

	# add offset to image address
	store_pixel:
	addu $t9, $a1, $s2

	sb $t0, ($t9)
	srl $t0, $t0, 8
	sb $t0, 1($t9)
	srl $t0, $t0, 8
	sb $t0, 2($t9)
	
	subiu $s2, $s2, 3
	subiu $s1, $s1, 1
	j column_loop
	
	row_loop_end:
	subiu $s0, $s0, 1
	j row_loop
	
	draw_end:
	# epilogue
	lw $s7, 28($sp)
	lw $s6, 24($sp)
	lw $s5, 20($sp)
	lw $s4, 16($sp)
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addiu $sp, $sp, 32
	jr $ra

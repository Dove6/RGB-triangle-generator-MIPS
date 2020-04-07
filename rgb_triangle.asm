.eqv BITMAP_WIDTH 256
.eqv BITMAP_HEIGHT 256

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
	.word 128 # (+0x00) x
	.word 10  # (+0x04) y
	.byte 0   # (+0x08) b
	.byte 0   # (+0x09) g
	.byte 255 # (+0x0a) r
	# vertex2
	.word 10  # (+0x0c) x
	.word 240 # (+0x10) y
	.byte 0   # (+0x14) b
	.byte 255 # (+0x15) g
	.byte 0   # (+0x16) r
	# vertex3
	.word 245 # (+0x18) x
	.word 230 # (+0x1c) y
	.byte 255 # (+0x20) b
	.byte 0   # (+0x21) g
	.byte 0   # (+0x22) r

	bkg_color:
	.align 2
	.byte 0   # b
	.byte 255 # g
	.byte 255 # r

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
#	jal draw_triangle
	
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
	# place useful data in registers
	# s0 - left side X position
	# s1 - left side color
	# s2 - right side X position
	# s3 - right side color
	# s4 - background color
#	lw $s4, bkg_color
	# s5 - memory row base
	
	# initialize the loop
	# t0 - row counter
#	lw $t0, biHeight
	subiu $t0, $t0, 1
	# t1 - column counter
	# t2 - ?
	# t3 - fill color
	move $t3, $zero
		
	row_loop:
	bltz $t0, write_file
#	lw $t1, biWidth
	subiu $t1, $t1, 1
	# calculate left and right side
		
	# calculate row memory offset
#	lw $s5, biHeight
	subiu $s5, $s5, 1
	subu $s5, $s5, $t0
	sll $s5, $s5, 8 # multiply by 256
	move $t9, $s5
	sll $s5, $s5, 1
	addu $s5, $s5, $t9 # multiply by 3 (bytes per pixel)
		
	column_loop:
	bltz $t1, row_loop_end
	move $t3, $s4
	# calculate row + column memory offset
	move $t9, $s5
	sll $t8, $t1, 1
	addu $t8, $t8, $t1 # multiply by 3 (bytes per pixel)
	addu $t9, $t9, $t8
		
#	sb $t3, image_data($t9)
	srl $t3, $t3, 8
#	sb $t3, image_data+1($t9)
	srl $t3, $t3, 8
#	sb $t3, image_data+2($t9)
	subiu $t1, $t1, 1
	j column_loop
	
	row_loop_end:
	subiu $t0, $t0, 1
	j row_loop
	
	draw_end:
	jr $ra

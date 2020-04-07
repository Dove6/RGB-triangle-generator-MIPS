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
	vertex1_position:
	.word 128 # x
	.word 10  # y
	vertex1_color:
	.byte 0   # b
	.byte 0   # g
	.byte 255 # r
	vertex2_position:
	.word 10  # x
	.word 240 # y
	vertex2_color:
	.byte 0   # b
	.byte 255 # g
	.byte 0   # r
	vertex3_position:
	.word 245 # x
	.word 230 # y
	vertex3_color:
	.byte 255 # b
	.byte 0   # g
	.byte 0   # r
	bkg_color:
	.align 2
	.byte 0   # b
	.byte 255 # g
	.byte 255 # r
	image_data:
	.align 2
	.space 196608

.text
main:
	# [prepare bitmap header and data]
	li $a0, BITMAP_WIDTH	
	li $a1, BITMAP_HEIGHT
	jal generate_bitmap

	# [process bitmap]
	# [save to file]
	# [destroy bitmap]
	# <nothing>

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
	lb $t5, BITMAPINFOHEADER($t4)
	addu $t6, $t3, $t4
	sb $t5, ($t6)
	addiu $t4, $t4, 1
	blt $t4, $t2, header_copy_loop
	# set variable header data
	sw $t0, 4($t3) # width
	sw $t1, 8($t3) # height
	mulu $t4, $t0, $t1
	sll $t5, $t4, 1    # }
	addu $t5, $t5, $t4 # } multiply by 3
	sw $t5, 20($t3) # pixel data size
	# TODO: error on too large data
	# allocate space for pixel data
	li $v0, 9
	move $a0, $t5
	syscall
	# place returned pointers in v-registers
	move $v1, $v0
	move $v0, $t3
	jr $ra
	



		# rearrange vertices
		
		# place useful data in registers
		# s0 - left side X position
		# s1 - left side color
		# s2 - right side X position
		# s3 - right side color
		# s4 - background color
#		lw $s4, bkg_color
		# s5 - memory row base
		
		# initialize the loop
		# t0 - row counter
#		lw $t0, biHeight
#		subiu $t0, $t0, 1
		# t1 - column counter
		# t2 - ?
		# t3 - fill color
#		move $t3, $zero
		
#	row_loop:
#		bltz $t0, write_file
#		lw $t1, biWidth
#		subiu $t1, $t1, 1
		# calculate left and right side
		
		# calculate row memory offset
#		lw $s5, biHeight
#		subiu $s5, $s5, 1
#		subu $s5, $s5, $t0
#		sll $s5, $s5, 8 # multiply by 256
#		move $t9, $s5
#		sll $s5, $s5, 1
#		addu $s5, $s5, $t9 # multiply by 3 (bytes per pixel)
		
#	column_loop:
#		bltz $t1, row_loop_end
#		move $t3, $s4
		# calculate row + column memory offset
#		move $t9, $s5
#		sll $t8, $t1, 1
#		addu $t8, $t8, $t1 # multiply by 3 (bytes per pixel)
#		addu $t9, $t9, $t8
		
#		sb $t3, image_data($t9)
#		srl $t3, $t3, 8
#		sb $t3, image_data+1($t9)
#		srl $t3, $t3, 8
#		sb $t3, image_data+2($t9)
#		subiu $t1, $t1, 1
#		j column_loop
	
#	row_loop_end:
#		subiu $t0, $t0, 1
#		j row_loop

#	write_file:
		# open output file
#		li $v0, 13
#		la $a0, output_filename
#		li $a1, 1 # write-only mode
#		syscall
#		bltz $v0, exit
#		move $t0, $v0

		# write BMP headers to file
#		li $v0, 15
#		move $a0, $t0
#		la $a1, BITMAPFILEHEADER
#		lw $a2, bfSize
#		lw $t9, biSize
#		addu $a2, $a2, $t9
#		syscall
		# TODO: error check

		# write image contents to file
#		li $v0, 15
#		move $a0, $t0
#		la $a1, image_data
#		lw $a2, biSizeImage
#		syscall
		# TODO: error check

		# close the file
#		li $v0, 16
#		move $a0, $t0
#		syscall

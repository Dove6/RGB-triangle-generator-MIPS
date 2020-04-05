.data
		.half -1 # padding
	BITMAPFILEHEADER:
	bfType:
		.ascii "BM"
	bfSize:
		.word 14
	bfReserved1:
		.half 0
	bfReserved2:
		.half 0
	bfOffBits:
		.word 54

	BITMAPINFOHEADER:
	biSize:
		.word 40
	biWidth:
		.word 256
	biHeight:
		.word 256
	biPlanes:
		.half 1
	biBitCount:
		.half 24
	biCompression:
		.word 0
	biSizeImage:
		.word 196608
	biXPelsPerMeter:
		.word 0
	biYPelsPerMeter:
		.word 0
	biClrUsed:
		.word 0
	biClrImportant:
		.word 0

	output_filename:
		.asciiz "result.bmp"
	vertex1_position:
		.half 128 # x
		.half 10  # y
	vertex1_color:
		.byte 0   # b
		.byte 0   # g
		.byte 255 # r
	vertex2_position:
		.half 10  # x
		.half 240 # y
	vertex2_color:
		.byte 0   # b
		.byte 255 # g
		.byte 0   # r
	vertex3_position:
		.half 245 # x
		.half 230 # y
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
		# rearrange vertices
		
		# place useful data in registers
		# s0 - left side X position
		# s1 - left side color
		# s2 - right side X position
		# s3 - right side color
		# s4 - background color
		lw $s4, bkg_color
		# s5 - memory row base
		
		# initialize the loop
		# t0 - row counter
		lw $t0, biHeight
		subiu $t0, $t0, 1
		# t1 - column counter
		# t2 - ?
		# t3 - fill color
		move $t3, $zero
		
	row_loop:
		bltz $t0, write_file
		lw $t1, biWidth
		subiu $t1, $t1, 1
		# calculate left and right side
		
		# calculate row memory offset
		lw $s5, biHeight
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
		
		sb $t3, image_data($t9)
		srl $t3, $t3, 8
		sb $t3, image_data+1($t9)
		srl $t3, $t3, 8
		sb $t3, image_data+2($t9)
		subiu $t1, $t1, 1
		j column_loop
	
	row_loop_end:
		subiu $t0, $t0, 1
		j row_loop

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
		lw $a2, bfSize
		lw $t9, biSize
		addu $a2, $a2, $t9
		syscall
		# TODO: error check

		# write image contents to file
		li $v0, 15
		move $a0, $t0
		la $a1, image_data
		lw $a2, biSizeImage
		syscall
		# TODO: error check

		# close the file
		li $v0, 16
		move $a0, $t0
		syscall

		# exit
	exit:
		li $v0, 10
		syscall

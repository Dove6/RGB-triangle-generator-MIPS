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
		# do drawing
		move $t0, $zero
		lw $t1, biSizeImage
		lw $t8, bkg_color
	loop:
		andi $t9, $t8, 255
		sb $t9, image_data($t0)
		srl $t9, $t8, 8
		andi $t9, $t9, 255
		sb $t9, image_data+1($t0)
		srl $t9, $t8, 16
		andi $t9, $t9, 255
		sb $t9, image_data+2($t0)
		addiu $t0, $t0, 3
		blt $t0, $t1, loop

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

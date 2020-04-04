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
		.align 2
	image_data:
		.space 196608

.text
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

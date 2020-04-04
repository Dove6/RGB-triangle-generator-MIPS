.data
	# BITMAPFILEHEADER
		.half -1 # padding
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
	# BITMAPINFOHEADER
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
	# end marker
		.byte 255
		.byte 255
		.byte 255
		.byte 255

.text
		# exit
		li $v0, 10
		syscall

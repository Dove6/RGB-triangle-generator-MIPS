##### USER-DEFINED SYMBOLS #####
# given vertices
.eqv VERTEX1_X 148
.eqv VERTEX1_Y 51
.eqv VERTEX1_COLOR 0xa9f7d1  # 0xRRGGBB
.eqv VERTEX2_X 212
.eqv VERTEX2_Y 121
.eqv VERTEX2_COLOR 0xaa3af1  # 0xRRGGBB
.eqv VERTEX3_X 72
.eqv VERTEX3_Y 197
.eqv VERTEX3_COLOR 0xeb6f24  # 0xRRGGBB

# settings
.eqv BITMAP_WIDTH 256
.eqv BITMAP_HEIGHT 256
.eqv RESULT_FILENAME "result.bmp"


##### INTERNAL DATA #####
.data
	.half -1  # padding (for word-aligning bitmap header)
	bitmap_file_header:  # BITMAPFILEHEADER structure template
	.ascii "BM"  # (+0x0) bfType
	.word 14     # (+0x2) bfSize
	.half 0      # (+0x6) bfReserved1
	.half 0      # (+0x8) bfReserved2
	.word 54     # (+0xa) bfOffBits
    # symbols for info header-related offsets
	.eqv BFSIZE 2

	bitmap_info_header:  # BITMAPINFOHEADER structure template
	.word 40  # (+0x00) biSize
	.word 0   # (+0x04) biWidth (to specify)
	.word 0   # (+0x08) biHeight (to specify)
	.half 1   # (+0x0c) biPlanes
	.half 24  # (+0x0e) biBitCount
	.word 0   # (+0x10) biCompression
	.word 0   # (+0x14) biSizeImage (to specify)
	.word 0   # (+0x18) biXPelsPerMeter (ignored)
	.word 0   # (+0x1c) biYPelsPerMeter (ignored)
	.word 0   # (+0x20) biClrUsed
	.word 0   # (+0x24) biClrImportant
    # symbols for info header-related offsets
	.eqv BISIZE 0
	.eqv BIWIDTH 4
	.eqv BIHEIGHT 8
	.eqv BISIZEIMAGE 20

	output_filename:
	.asciiz RESULT_FILENAME

	vertex_data:  # three vertex structures (3 words each)
	.word VERTEX1_X      # (+0x00) X1
	.word VERTEX1_Y      # (+0x04) Y1
	.word VERTEX1_COLOR  # (+0x08) B1
                         # (+0x09) G1
                         # (+0x0a) R1
	.word VERTEX2_X      # (+0x0c) X2
	.word VERTEX2_Y      # (+0x10) Y2
	.word VERTEX2_COLOR  # (+0x14) B2
                         # (+0x15) G2
                         # (+0x16) R2
	.word VERTEX3_X      # (+0x18) X3
	.word VERTEX3_Y      # (+0x1c) Y3
	.word VERTEX3_COLOR  # (+0x20) B3
                         # (+0x21) G3
                         # (+0x22) R3
    # symbols for vertices-related offsets
    .eqv X1 0
    .eqv Y1 4
    .eqv COLOR1 8
    .eqv B1 8
    .eqv G1 9
    .eqv R1 10
    .eqv X2 12
    .eqv Y2 16
    .eqv COLOR2 20
    .eqv B2 20
    .eqv G2 21
    .eqv R2 22
    .eqv X3 24
    .eqv Y3 28
    .eqv COLOR3 32
    .eqv B3 32
    .eqv G3 33
    .eqv R3 34

	error_strings:  # array of error messages with a maximal length of 63 characters
	.align 3
	.asciiz "An error has occured: "               # common error message
	.double 0, 0, 0, 0, 0 # padding
	.asciiz "Non-positive bitmap size."            # error code 1
	.double 0, 0, 0, 0 # padding
	.asciiz "Vertex outside the bitmap."           # error code 2
	.double 0, 0, 0, 0 # padding
	.asciiz "Specified shape is not a triangle."   # error code 3
	.double 0, 0, 0 # padding
	.asciiz "Too large image size."                # error code 4
	.double 0, 0, 0, 0, 0 # padding
	.asciiz "Couldn't create the output file."     # error code 5
	.double 0, 0, 0 # padding
	.asciiz "Error while writing to output file."  # error code 6
	.double 0, 0, 0 # padding
	.asciiz "Unknown error."                       # unknown error code
	.double 0, 0, 0, 0, 0, 0 # padding


.text
##### MACROS #####
	.macro pad_to_word(%regValue, %regResult)
	# %regValue may be %regResult
	addiu %regResult, %regValue, 3
	andi %regResult, -4
	.end_macro

	.macro min_max_of_three(%regNumber1, %regNumber2, %regNumber3, %regTemporary, %regResultMin, %regResultMax)
	# no register may occur more than once in the argument list
	# (except %regResult1, which can be used as %regTemporary)
	move %regResultMin, %regNumber1
	move %regResultMax, %regNumber1
	sgtu %regTemporary, %regNumber2, %regResultMax
	movn %regResultMax, %regNumber2, %regTemporary
	sltu %regTemporary, %regNumber2, %regResultMin
	movn %regResultMin, %regNumber2, %regTemporary
	sgtu %regTemporary, %regNumber3, %regResultMax
	movn %regResultMax, %regNumber3, %regTemporary
	sltu %regTemporary, %regNumber3, %regResultMin
	movn %regResultMin, %regNumber3, %regTemporary
	.end_macro

	.macro check_if_in_range(%regMin, %regMax, %regChecked, %regTemporary, %regResult)
	# neither %regMax nor %regChecked can be used as %regTemporary
	# %regResult cannot be %regTemporary
	# values of %regTemporary and %regResult are overwritten
	# result:
	#  %regResult - 1 if in range, 0 otherwise
	sge %regTemporary, %regChecked, %regMin
	sle %regResult, %regChecked, %regMax
	and %regResult, %regTemporary, %regResult
	.end_macro

	.macro compare_points(%regX1, %regY1, %regX2, %regY2, %regTemporary, %regResult)
	# neither %regY1 nor %regY2 can be used as %regResult
	# %regResult cannot be %regTemporary
	# values of %regTemporary and %regResult are overwritten
	# result:
	#  %regResult - 1 if points have the same coordinates, 0 otherwise
	seq %regTemporary, %regX1, %regX2
	seq %regResult, %regY1, %regY2
	and %regResult, %regTemporary, %regResult
	.end_macro

	.macro blend_color(%regColor1, %regColor2, %regColor3, %shift, %fpRegWeight1, %fpRegWeight2, %fpRegWeight3, %regResult)
	# $f30 and $f31 are used for calculations internally, so they cannot be used as %fpRegWeight1-3
	# weights in %fpRegWeight1-3 have to be single-precision floating-point values and should sum to 1.0
	# result:
	#  %regResult - blent compound color (range: 0-255)
	srl %regResult, %regColor1, %shift  # first part
	andi %regResult, 0xff
	mtc1 %regResult, $f31
	cvt.s.w $f31, $f31
	mul.s $f31, $f31, %fpRegWeight1
	srl %regResult, %regColor2, %shift  # second part
	andi %regResult, 0xff
	mtc1 %regResult, $f30
	cvt.s.w $f30, $f30
	mul.s $f30, $f30, %fpRegWeight2
	add.s $f31, $f31, $f30
	srl %regResult, %regColor3, %shift  # third part
	andi %regResult, 0xff
	mtc1 %regResult, $f30
	cvt.s.w $f30, $f30
	mul.s $f30, $f30, %fpRegWeight3
	add.s $f31, $f31, $f30
	round.w.s $f31, $f31  # getting result back from coproc 1
	mfc1 %regResult, $f31
	andi %regResult, 0xff
	.end_macro


### MAIN FUNCTION ###
main:
	la $s2, vertex_data
	li $s3, BITMAP_WIDTH
	li $s4, BITMAP_HEIGHT
	## validate input
	move $a0, $s3
	move $a1, $s4
	move $a2, $s2
	jal validate_input
	bltz $v0, print_error  # handle the error on negative return value

	## prepare bitmap header and data buffer
	move $a0, $s3
	move $a1, $s4
	jal generate_bitmap
	bltz $v0, print_error  # handle the error on negative return value
	move $s0, $v0
	move $s1, $v1

	## process the bitmap
	move $a0, $s0
	move $a1, $s1
	move $a2, $s2
	jal draw_triangle

	## save it to file
	move $a0, $s0
	move $a1, $s1
	jal save_bitmap_to_file
	bgez $v0, exit  # jump over the error handling on return value >= 0

	## handle errors
	print_error:
	subu $t3, $zero, $v0
	li $t0, 1
	li $t1, 5
	addu $t2, $t0, $t1
	check_if_in_range($t0, $t1, $t3, $t0, $t1)
	movn $t2, $t3, $t1
	sll $t2, $t2, 6  # multiply by 64 (bytes per string)
	li $v0, 4
	la $a0, error_strings  # output a general error message
	syscall
	li $v0, 4
	la $a0, error_strings($t2)  # print more specific error info
	syscall

	## finish the execution
	exit:
	li $v0, 10
	syscall


##### FUNCTIONS #####
validate_input:
	# parameters:
	#  $a0 - bitmap width
	#  $a1 - bitmap height
	#  $a2 - address of vertices data
	# returns:
	#  $v0 - 0 for valid data, negative error number otherwise

	move $v0, $zero
	subiu $t0, $a0, 1
	subiu $t1, $a1, 1
	slt $t0, $t0, $zero
	slt $t1, $t1, $zero
	or $t0, $t0, $t1
	beqz $t0, validate_vertices
	li $v0, -1  # error: non-positive bitmap size
	jr $ra

	validate_vertices:
	li $t0, 3  # initialize loop counter for three vertices
	move $t1, $a2
	validate_vertices_loop:
	subiu $t0, $t0, 1
	bltz $t0, validate_shape
	lw $t2, ($t1)   # X
	lw $t3, 4($t1)  # Y
	check_if_in_range($zero, $a0, $t2, $t4, $t2)  # check if 0 <= X <= width
	check_if_in_range($zero, $a1, $t3, $t4, $t3)  # check if 0 <= Y <= height
	and $t2, $t2, $t3
	addiu $t1, $t1, 12
	bnez $t2, validate_vertices_loop
	li $v0, -2  # error: vertex outside the bitmap
	jr $ra

	validate_shape:
	li $t9, -3  # error: not a triangle
	lw $t0, X1($a2)
	lw $t1, Y1($a2)
	lw $t2, X2($a2)
	lw $t3, Y2($a2)
	lw $t4, X3($a2)
	lw $t5, Y3($a2)
	compare_points($t0, $t1, $t2, $t3, $t7, $t6)  # point1 and point2
	movn $v0, $t9, $t6  # indicate an error if points are identical
	compare_points($t0, $t1, $t4, $t5, $t7, $t6)  # point1 and point3
	movn $v0, $t9, $t6  # indicate an error if points are identical
	compare_points($t2, $t3, $t4, $t5, $t7, $t6)  # point2 and point3
	movn $v0, $t9, $t6  # indicate an error if points are identical
	jr $ra


generate_bitmap:
	# parameters:
	#  $a0 - bitmap width
	#  $a1 - bitmap height
	# returns:
	#  $v0 - address of adjusted BITMAPINFOHEADER structure describing the bitmap on success, negative error code otherwise
	#  $v1 - address of image data buffer on success

	move $t0, $a0
	move $t1, $a1

	## prepare header
	lw $t2, bitmap_info_header+BISIZE
	# allocate memory for bitmap header
	li $v0, 9
	move $a0, $t2
	syscall
	move $t3, $v0
	# copy template data to allocated header
	move $t4, $zero
	header_copy_loop:
	lw $t5, bitmap_info_header($t4)
	addu $t6, $t3, $t4
	sw $t5, ($t6)
	addiu $t4, $t4, 4
	blt $t4, $t2, header_copy_loop
	# adjust the bitmap header
	sw $t0, BIWIDTH($t3)
	sw $t1, BIHEIGHT($t3)
	sll $t4, $t0, 1     #
	addu $t4, $t4, $t0  # multiply width by 3
	pad_to_word($t4, $t4)
	mulu $t4, $t4, $t1
	mfhi $t5  # check for too big size
	beqz $t5, proceed_with_data_size
	li $v0, -4  # error: size too large
	jr $ra

	proceed_with_data_size:
	sw $t4, BISIZEIMAGE($t3)  # pixel data size
	## allocate space for pixel data
	li $v0, 9
	move $a0, $t4
	syscall
	## place returned addresses in v-registers
	move $v1, $v0
	move $v0, $t3
	jr $ra


draw_triangle:
	# parameters:
	#  $a0 - address of bitmap details (BITMAPINFOHEADER)
	#  $a1 - address of bitmap data
	#  $a2 - address of vertices data

	## prologue
	subiu $sp, $sp, 64
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)

	## stack layout
	#  (+0x3c) [X1 - X3] - helper barycentric equation factor for the second vertex Y position
	#  (+0x38) [X3 - X2] - helper barycentric equation factor for the first vertex Y position
	#  (+0x34) [Y3 - Y1] - helper barycentric equation factor for the second vertex X position
	#  (+0x30) [Y2 - Y3] - helper barycentric equation factor for the first vertex X position
	#  (+0x2c) vertex max Y
	#  (+0x28) vertex min Y
	#  (+0x24) vertex max X
	#  (+0x20) vertex min X
	#  (+0x00) saved registers (8 * 4 bytes)
	.eqv FACTOR_Y2 60
	.eqv FACTOR_Y1 56
	.eqv FACTOR_X2 52
	.eqv FACTOR_X1 48
	.eqv MAX_Y 44
	.eqv MIN_Y 40
	.eqv MAX_X 36
	.eqv MIN_X 32

	## registers layout
	# saved registers layout:
	#  $s0 - row counter
	#  $s1 - column counter
	#  $s2 - pixel memory offset
	#  $s3 - empty (outside the clipping rectangle) row indicator (0 - non-empty, 1 - empty)
	#  $s4 - barycentric equation line constant summand for the first vertex
	#  $s5 - barycentric equation line constant summand for the second vertex
	#  $s6 - background color

	# temporary registers layout:
	#  $t0 - current color

	# floating-point registers layout:
	#  $f0 - zero
	#  $f1 - barycentric equations denominator

	mtc1 $zero, $f0  # place 0 in floating-point register (for further calculations)

	lw $s0, BIHEIGHT($a0)
	## calculate background color
	li $s6, 0xffffff
	lw $t9, COLOR3($a2)
	lw $t8, COLOR2($a2)
	lw $t7, COLOR1($a2)
	li $t6, 0xf0f0f0
	and $t5, $t9, $t6
	seq $t5, $t5, $t6
	move $t3, $t5       # increment if first vertex is whitish
	and $t5, $t8, $t6
	seq $t5, $t5, $t6
	addu $t3, $t3, $t5  # increment if second vertex is whitish
	and $t5, $t7, $t6
	seq $t5, $t5, $t6
	addu $t3, $t3, $t5  # increment if third vertex is whitish
	blt $t3, 2, calc_denominator
	li $s6, 0x000000  # if 2 or more vertices are whitish, make background black

	## calculate constant barymetric equations parts
	# calculate barymetric equations denominator: (Y2 - Y3)(X1 - X3)+(X3 - X2)(Y1 - Y3)
	calc_denominator:
	lw $t9, Y3($a2)
	lw $t8, X3($a2)
	lw $t7, Y2($a2)
	lw $t6, X2($a2)
	lw $t5, Y1($a2)
	lw $t4, X1($a2)
	subu $t3, $t7, $t9
	subu $t2, $t8, $t6
	subu $t1, $t5, $t9
	subu $t0, $t4, $t8
	mul $t3, $t3, $t0
	mul $t2, $t2, $t1
	addu $t3, $t3, $t2
	mtc1 $t3, $f1     #
	cvt.s.w $f1, $f1  # save the denominator in $f1
	# calculate barycentric equations helper factors
	subu $t3, $t7, $t9  # Y2 - Y3
	subu $t2, $t9, $t5  # Y3 - Y1
	sw $t3, FACTOR_X1($sp)
	sw $t2, FACTOR_X2($sp)
	subu $t3, $t8, $t6  # X3 - X2
	subu $t2, $t4, $t8  # X1 - X3
	sw $t3, FACTOR_Y1($sp)
	sw $t2, FACTOR_Y2($sp)

	## calculate clipping rectangle position
	# calculate min and max vertex X position
	min_max_of_three($t8, $t6, $t4, $t1, $t3, $t2)
	sw $t3, MIN_X($sp)
	sw $t2, MAX_X($sp)
	# calculate min and max vertex Y position
	min_max_of_three($t9, $t7, $t5, $t1, $t3, $t2)
	sw $t3, MIN_Y($sp)
	sw $t2, MAX_Y($sp)

	row_loop:
	subiu $s0, $s0, 1
	bltz $s0, drawing_end
	lw $s1, BIWIDTH($a0)

	## calculate barycentric equation summands (constant per line)
	# first: (X3 - X2)(Yp - Y3)
	lw $t9, Y3($a2)
	subu $t9, $s0, $t9
	lw $t8, FACTOR_Y1($sp)
	mul $s4, $t8, $t9  # save the summand in $s4
	# second: (X1 - X3)(Yp - Y3)
	lw $t8, FACTOR_Y2($sp)
	mul $s5, $t8, $t9  # save the summand in $s5

	## calculate memory offset of the last column in the row
	calc_offset:
	lw $s2, BIWIDTH($a0)
	pad_to_word($s2, $s2)
	mulu $s2, $s2, $s0  # multiply padded image width by current row number
	addu $s2, $s2, $s1  # add last column offset
	sll $t9, $s2, 1     #
	addu $s2, $t9, $s2  # multiply by 3 (bytes per pixels)

	## check if row is inside the clipping rectangle
	lw $t9, MIN_Y($sp)
	lw $t8, MAX_Y($sp)
	check_if_in_range($t9, $t8, $s0, $t9, $s3)  # save result in $s3

	column_loop:
	subiu $s1, $s1, 1
	subiu $s2, $s2, 3
	bltz $s1, row_loop
	move $t0, $s6  # current color = background

	## check if pixel is inside the clipping rectangle
	# check vertically
	beqz $s3, store_pixel
	# check horizontally
	lw $t9, MIN_X($sp)
	lw $t8, MAX_X($sp)
	check_if_in_range($t9, $t8, $s1, $t9, $t8)
	beqz $t9, store_pixel

	## calculate barymetric weights
	# W1 = 100*[(Y2 - Y3)(Xp - X3) + (X3 - X2)(Yp - Y3)]/[(Y2 - Y3)(X1 - X3)+(X3 - X2)(Y1 - Y3)]
	lw $t9, FACTOR_X1($sp)  # Y2 - Y3
	lw $t8, X3($a2)
	subu $t8, $s1, $t8
	mul $t9, $t9, $t8
	addu $t9, $t9, $s4
	mtc1 $t9, $f2  # $f2 = W1
	cvt.s.w $f2, $f2
	div.s $f2, $f2, $f1
	c.lt.s $f2, $f0
	bc1t store_pixel
	# W2 = 100*[(Y3 - Y1)(Xp - X3) + (X1 - X3)(Yp - Y3)]/[(Y2 - Y3)(X1 - X3)+(X3 - X2)(Y1 - Y3)]
	lw $t7, FACTOR_X2($sp)  # Y3 - Y1
	mul $t8, $t8, $t7
	addu $t8, $t8, $s5
	mtc1 $t8, $f3  # $f3 = W2
	cvt.s.w $f3, $f3
	div.s $f3, $f3, $f1
	c.lt.s $f3, $f0
	bc1t store_pixel
	# W3 = 100 - W1 - W2
	li $t7, 1         #
	mtc1 $t7, $f4     #
	cvt.s.w $f4, $f4  # li.s $f4, 100.0
	sub.s $f4, $f4, $f2
	sub.s $f4, $f4, $f3  # $f4 = W3
	c.lt.s $f4, $f0
	bc1t store_pixel

	## calculate blent color
	move $t0, $zero
	lw $t9, COLOR1($a2)
	lw $t8, COLOR2($a2)
	lw $t7, COLOR3($a2)
	# red
	blend_color($t9, $t8, $t7, 16, $f2, $f3, $f4, $t6)
	sll $t0, $t6, 16
	# green
	blend_color($t9, $t8, $t7, 8, $f2, $f3, $f4, $t6)
	sll $t6, $t6, 8
	or $t0, $t0, $t6
	# blue
	blend_color($t9, $t8, $t7, 0, $f2, $f3, $f4, $t6)
	or $t0, $t0, $t6

	store_pixel:
	addu $t9, $a1, $s2  # add offset to image address
	sb $t0, ($t9)   # store blue
	srl $t0, $t0, 8
	sb $t0, 1($t9)  # store green
	srl $t0, $t0, 8
	sb $t0, 2($t9)  # store red

	j column_loop

	drawing_end:
	## epilogue
	lw $s7, 28($sp)
	lw $s6, 24($sp)
	lw $s5, 20($sp)
	lw $s4, 16($sp)
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addiu $sp, $sp, 64
	jr $ra


save_bitmap_to_file:
	# parameters:
	#  $a0 - address of bitmap details (BITMAPINFOHEADER)
	#  $a1 - address of bitmap data
	# returns:
	#  $v0 - 0 on success, positive error code otherwise

	move $t0, $a0
	move $t1, $a1

	## open output file
	li $v0, 13
	la $a0, output_filename
	li $a1, 1  # write-only mode
	syscall
	move $t2, $v0
	bgez $t2, write_file_header
	li $v0, -5  # error: could not open the file
	jr $ra

	## write BMP headers to file
	write_file_header:
	li $v0, 15
	move $a0, $t2
	la $a1, bitmap_file_header
	lw $t3, BFSIZE($a1)
	move $a2, $t3
	syscall
	beq $v0, $t3, write_info_header
	li $v0, -6  # error writing to file
	jr $ra

	write_info_header:
	li $v0, 15
	move $a0, $t2
	move $a1, $t0
	lw $t3, BISIZE($a1)
	move $a2, $t3
	syscall
	beq $v0, $t3, write_bitmap
	li $v0, -6  # error writing to file
	jr $ra

	## write image contents to file
	write_bitmap:
	li $v0, 15
	move $a0, $t2
	move $a1, $t1
	lw $t3, BISIZEIMAGE($t0)
	move $a2, $t3
	syscall
	beq $v0, $t3, close_file
	li $v0, -6  # error writing to file
	jr $ra

	## close the file
	close_file:
	li $v0, 16
	move $a0, $t0
	syscall
	move $v0, $zero
	jr $ra

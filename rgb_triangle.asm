# test 256x256 setup
.eqv BITMAP_WIDTH 256
.eqv BITMAP_HEIGHT 256
.eqv VERTEX1_X 128
.eqv VERTEX1_Y 10
.eqv VERTEX1_BGR 0x00ffffff
.eqv VERTEX2_X 10
.eqv VERTEX2_Y 240
.eqv VERTEX2_BGR 0x001c35a3
.eqv VERTEX3_X 245
.eqv VERTEX3_Y 230
.eqv VERTEX3_BGR 0x00f5f7fe

# test 32x32 setup
#.eqv BITMAP_WIDTH 32
#.eqv BITMAP_HEIGHT 32
#.eqv VERTEX1_X 16
#.eqv VERTEX1_Y 2
#.eqv VERTEX1_BGR 0x00ff0000
#.eqv VERTEX2_X 2
#.eqv VERTEX2_Y 30
#.eqv VERTEX2_BGR 0x0000ff00
#.eqv VERTEX3_X 30
#.eqv VERTEX3_Y 28
#.eqv VERTEX3_BGR 0x000000ff

#.eqv BKG_COLOR 0x0030d5c8
.eqv BKG_COLOR 0x00ffffff

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

	# [process bitmap]
	move $a0, $s0
	move $a1, $s1
	la $s2, vertex_data
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


### MACROS ###

	# assumptions:
    #  only %regNumber2 and %regNumber3 values are preserved
    #  no register may occur more than once in the argument list
    .macro min_max_of_three(%regNumber1, %regNumber2, %regNumber3, %regResultMin, %regResultMax)
    move %regResultMin, %regNumber1
    move %regResultMax, %regNumber1
   sgtu %regNumber1, %regNumber2, %regResultMax
    movn %regResultMax, %regNumber2, %regNumber1
    sltu %regNumber1, %regNumber2, %regResultMin
    movn %regResultMin, %regNumber2, %regNumber1
    sgtu %regNumber1, %regNumber3, %regResultMax
    movn %regResultMax, %regNumber3, %regNumber1
    sltu %regNumber1, %regNumber3, %regResultMin
    movn %regResultMin, %regNumber3, %regNumber1
    .end_macro

    # assumptions:
    #  %regValue may be %regResult
    .macro pad_to_word (%regValue, %regResult)
    addiu %regResult, %regValue, 3
    andi %regResult, -4
    .end_macro

	# assumptions:
    #  $f30 and $f31 are used for calculations internally, so they cannot be %fpRegMultiplier1,2,3
    .macro blend_color(%regColor1, %regColor2, %regColor3, %shift, %fpRegMultiplier1, %fpRegMultiplier2, %fpRegMultiplier3, %regResult)
    srl %regResult, %regColor1, %shift
    andi %regResult, 0xff
    mtc1 %regResult, $f31
    cvt.s.w $f31, $f31
    mul.s $f31, $f31, %fpRegMultiplier1
    srl %regResult, %regColor2, %shift
    andi %regResult, 0xff
    mtc1 %regResult, $f30
    cvt.s.w $f30, $f30
    mul.s $f30, $f30, %fpRegMultiplier2
    add.s $f31, $f31, $f30
    srl %regResult, %regColor3, %shift
    andi %regResult, 0xff
    mtc1 %regResult, $f30
    cvt.s.w $f30, $f30
    mul.s $f30, $f30, %fpRegMultiplier3
    add.s $f31, $f31, $f30
    round.w.s $f31, $f31
    mfc1 %regResult, $f31
    andi %regResult, 0xff
    .end_macro

	# assumptions:
    #  %regMin cannot be %regMax
    #  %regChecked can be neither %regMin nor %regMax
    #  %regResult may be %regMin or %regMax
    #  only %regChecked value is preserved (if it is not %regResult)
    # result:
    #  1 if in range
    #  0 if not in range
    .macro check_if_in_range (%regMin, %regMax, %regChecked, %regResult)
    subu %regMin, %regChecked, %regMin
    subu %regMax, %regChecked, %regMax
    mul %regMin, %regMin, %regMax
    mfhi %regMax
    slt %regMax, %regMax, $zero
    seq %regMin, %regMin, $zero
    or %regResult, %regMin, %regMax
    .end_macro


### FUNCTIONS ###
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
	pad_to_word($t4, $t4)
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
	# (+0x34) helper barycentric equation factor for the second vertex
	# (+0x30) helper barycentric equation factor for the first vertex
	# (+0x2c) vertex max Y
	# (+0x28) vertex min Y
	# (+0x24) vertex max X
	# (+0x20) vertex min X
	# (+0x00) saved registers (8 * 4 bytes)

	# saved registers layout
	# $s0 - row counter
	# $s1 - column counter
	# $s2 - pixel memory offset
    #
    # $s4 - barycentric equation line constant summand for the first vertex
    # $s5 - barycentric equation line constant summand for the second vertex
    # $s6 - background color

	# temporary registers layout
	# $t0 - current color
	# $t1-$t9 - temporary

	# floating-point registers layout
	# $f0 - zero
	# $f1 - barycentric equations denominator
	# $f2-$f31 - temporary

	mtc1 $zero, $f0

	lw $s0, 8($a0)
	subiu $s0, $s0, 1
	# calculate background color
	li $s6, 0x00ffffff
	lw $t9, 32($a2)
	lw $t8, 20($a2)
	lw $t7, 8($a2)
	li $t6, 0x00f0f0f0
	and $t5, $t9, $t6
	seq $t5, $t5, $t6
	move $t3, $t5 # first white
	and $t5, $t8, $t6
	seq $t5, $t5, $t6
	addu $t3, $t3, $t5 # second white
	and $t5, $t7, $t6
	seq $t5, $t5, $t6
	addu $t3, $t3, $t5 # third white
	blt $t3, 2, calc_denominator
	li $s6, 0x00000000

	# calculate barycentric denominator
	calc_denominator:
	# (Y2 - Y3)(X1 - X3)+(X3 - X2)(Y1 - Y3)
	lw $t9, 28($a2) # Y3
	lw $t8, 24($a2) # X3
	lw $t7, 16($a2) # Y2
	lw $t6, 12($a2) # X2
	lw $t5, 4($a2)  # Y1
	lw $t4, ($a2)   # X1
	subu $t7, $t7, $t9
	subu $t6, $t8, $t6
	subu $t5, $t5, $t9
	subu $t4, $t4, $t8
	mul $t7, $t7, $t4
	mul $t6, $t6, $t5
	addu $t7, $t7, $t6
	mtc1 $t7, $f1 # save result in $f1
	cvt.s.w $f1, $f1

	# calculate barycentric helper factors
	lw $t8, 16($a2) # Y2
	lw $t7, 4($a2)  # Y1
	subu $t8, $t8, $t9
	subu $t7, $t9, $t7
	sw $t8, 48($sp)
	sw $t7, 52($sp)

	# calculate min and max vertex Y
	lw $t9, 4($a2)
	lw $t8, 16($a2)
	lw $t7, 28($a2)
	min_max_of_three($t9, $t8, $t7, $t6, $t5)
	sw $t6, 40($sp)
	sw $t5, 44($sp)

	# initialize the loop

	row_loop:
	bltz $s0, draw_end
	lw $s1, 4($a0)
	subiu $s1, $s1, 1

	# calculate barycentric equation line summands
	# (X3 - X2)(Yp - Y3)
	lw $t9, 28($a2) # Y3
	lw $t8, 24($a2) # X3
	lw $t7, 12($a2) # X2
	subu $t7, $t8, $t7
	subu $t9, $s0, $t9
	mul $s4, $t7, $t9 # save in $s4
	# (X1 - X3)(Yp - Y3)
	lw $t7, ($a2) # X1
	subu $t7, $t7, $t8
	mul $s5, $t7, $t9 # save in $s5

	# calculate memory offset of the last column in the row
	calc_offset:
	lw $s2, 4($a0)
	pad_to_word($s2, $s2)
	mulu $s2, $s2, $s0 # multiply padded image width by current row number
	addu $s2, $s2, $s1 # add last column offset
	sll $t9, $s2, 1    #
	addu $s2, $t9, $s2 # multiply by 3 (bytes per pixels)

	column_loop:
	bltz $s1, row_loop_end

    # color = background
	move $t0, $s6

	# check barymetric weights
	# W1 = 100*[(Y2 - Y3)(Xp - X3) + (X3 - X2)(Yp - Y3)]/[(Y2 - Y3)(X1 - X3)+(X3 - X2)(Y1 - Y3)]
	lw $t9, 48($sp) # Y2 - Y3
	lw $t8, 24($a2) # X3
	subu $t8, $s1, $t8
	mul $t9, $t9, $t8
	addu $t9, $t9, $s4
	mtc1 $t9, $f2 # $f2 = W1
	cvt.s.w $f2, $f2
	div.s $f2, $f2, $f1
	c.lt.s $f2, $f0
	bc1t store_pixel
	# W2 = 100*[(Y3 - Y1)(Xp - X3) + (X1 - X3)(Yp - Y3)]/[(Y2 - Y3)(X1 - X3)+(X3 - X2)(Y1 - Y3)]
	lw $t7, 52($sp) # Y3 - Y1
	mul $t8, $t8, $t7
	addu $t8, $t8, $s5
	mtc1 $t8, $f3 # $f3 = W2
	cvt.s.w $f3, $f3
	div.s $f3, $f3, $f1
	c.lt.s $f3, $f0
	bc1t store_pixel
	# W3 = 100 - W1 - W2
	li $t7, 1        #
	mtc1 $t7, $f4    #
	cvt.s.w $f4, $f4 # li.s $f4, 100.0
	sub.s $f4, $f4, $f2
	sub.s $f4, $f4, $f3 # $f4 = W3
	c.lt.s $f4, $f0
	bc1t store_pixel

	# calculate color
	move $t0, $zero
	lw $t9, 8($a2)  # C1
	lw $t8, 20($a2) # C2
	lw $t7, 32($a2) # C3
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

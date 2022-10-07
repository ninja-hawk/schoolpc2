/* sample program fact.s 階乗  d1 := d0 ! (d0 >= 0)*/
.section .text
start:
	cmp    #0,%d1
	beq    end_of_program
	cmp    %d1, %d2
	bgt    end_of_program
	moveq  #1, %d0
	cmp    #0, %d2
	beq    end_of_program
loop:
	mulu   %d1,%d0
	subq   #1, %d1
	subq   #1, %d2
	bgt    loop
end_of_program:
	stop      #0x2700 /* 終了*/

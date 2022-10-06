/* sample program fact.s 階乗  d1 := d0 ! (d0 >= 0)*/
.section .text
start:
	moveq  #1,%d1
	cmp    #0,%d0
	beq    end_of_program
	move.l %d0,%d2
loop:
	mulu %d2,%d1
	subq      #1,%d2
	cmp.w  #0,%d2
	bge    loop
end_of_program:
	stop      #0x2700 /* 終了*/

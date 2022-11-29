.global inbyte

.text
.even

inbyte:
		movem.l %D0-%D3, -(%sp)
inbyte_loop:
		move.l #SYSCALL_NUM_GETSTRING, %D0
		move.l #0,   %D1        | ch   = 0
		move.l #In_BUF, %D2        | p    = #BUF
		move.l #1, %D3        | size = 1
		trap   #0
        	cmpi   #1, %d0       | GETSTRINGの返り値が1と一致するか確認
		bne    inbyte_loop | 一致しなければ再受信
		movem.l	(%sp)+, %D0-%D3
        	rts

.section .bss
In_BUF: 
		.ds.b 1

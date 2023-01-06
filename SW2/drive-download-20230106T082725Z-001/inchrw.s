.global inbyte

.text
.even

inbyte:
		movem.l %D1-%D3, -(%sp)
inbyte_loop:
		move.l #1,  %D0         | GETSTRINGを呼び出す
		move.l 16(%sp), %D1     | ch   = 0 or 1
		move.l #In_BUF, %D2     | p    = #BUF
		move.l #1, %D3          | size = 1
		trap   #0
        cmpi   #1, %d0       | GETSTRINGの返り値が1と一致するか確認
		bne    inbyte_loop   | 一致しなければ再受信
		move.b In_BUF, %d0   | 戻り値をd0に追加
		movem.l	(%sp)+, %D1-%D3
        rts

.section .bss
In_BUF: 
		.ds.b 1


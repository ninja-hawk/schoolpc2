.global outbyte

.section .text
.even
*******************************
** outbyte
** 引数：
**       char型のデータ(スタックに格納済)
** 出力：
**       シリアルポート0に出力
*******************************
outbyte:
		movem.l %d0-%d3, -(%sp)
out_byte_loop:	
		move.l #SYSCALL_NUM_PUTSTRING, %d0 | PUTSTRINGを指定
		move.l #0, %d1       | ch   = 0
		move.l %sp, %d2  | data = char[1]
		add.l  #23, %d2
		move.l #1, %d3       | size = 1
		trap   #0
		cmpi.l #1, %d0       | PUTSTRINGの返り値が送信数と一致するか確認
		bne    out_byte_loop | 一致しなければ再送信
end_outbyte:	
		movem.l (%sp)+, %d0-%d3
		rts

.equ SYSCALL_NUM_PUTSTRING,    2

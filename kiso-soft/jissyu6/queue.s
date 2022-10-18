 .section .text
******************************
** メインルーチン
** a0:書き込むデータのアドレス
** d4:書き込み回数
******************************
Start:
	jsr     Init_Q /* キューの初期化処理*/
	lea.l   Data_to_Que, %a0
	move.l  #257, %d4

Loop1:
	subq.w  #1, %d4
	bcs     End_program
	jsr     In_Q/* 書き込み処理*/
	bra     Loop1
End_program:
	stop    #0x2700
**********************
** キューの初期化処理
**********************
Init_Q:
	lea.l   BF_START, %a2
	move.l  %a2, PUT_PTR
	move.l  %a2, GET_PTR
	move.b  #0xff, PUT_FLG
	move.b  #0x00, GET_FLG
	rts

***********************************
** In_Q キューへのデータ書き込み
** a0:書き込むデータのアドレス
** d0:結果(00:失敗, 00以外:成功)
***********************************
In_Q:
	jsr PUT_BUF/* キューへの書き込み*/
	rts
****************************************
** PUT_BUF
** a0:書き込むデータのアドレス
** d0:結果(00:失敗, 00以外:成功)
****************************************
PUT_BUF:
	movem.l %a1-%a3,-(%sp)
	move.b  PUT_FLG, %d0
	cmp.b   #0x00, %d0
	beq     PUT_BUF_Finish
	movea.l PUT_PTR, %a1
	move.b  (%a0)+,(%a1)+
	lea.l   BF_END, %a3
	cmpa.l  %a3, %a1
	bls     PUT_BUF_STEP1
	lea.l   BF_START, %a2
	movea.l %a2,%a1
PUT_BUF_STEP1:
	move.l  %a1,PUT_PTR
	cmpa.l  GET_PTR,%a1
	bne     PUT_BUF_STEP2
	move.b  #0x00,PUT_FLG
PUT_BUF_STEP2:
	move.b  #0xff, GET_FLG
PUT_BUF_Finish:
	movem.l (%sp)+, %a1-%a3 
	rts
.section .data
******************************
** キュー用のメモリ領域確保
******************************
	.equ	B_SIZE, 256
BF_START:	.ds.b	B_SIZE-1
BF_END:		.ds.b	1
PUT_PTR:	.ds.l	1
GET_PTR:	.ds.l	1
PUT_FLG:	.ds.b	1
GET_FLG:	.ds.b	1
******************************
** 書き込むデータ（サンプル）
******************************
Data_to_Que:	.ascii	"ABC"
.end

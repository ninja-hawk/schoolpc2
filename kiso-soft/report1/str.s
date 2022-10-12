.section .text
start:
	move.l #1,%d0    /* STRUCTの引数*/
	jsr    STRUCT    /* STRUCT(%d0.l) → NAME_DATA,ADDRESS_DATA */
	stop   #0x2700   /* プログラム終了*/

**************************************************
** 構造体の構造
**************************************************
.equ        NAME,0      /* NAME は先頭から0byte目*/
.equ        ADDRESS,20  /* ADDRESS は先頭から20byte目*/
.equ        SIZE,60     /* 一人分のデータサイズは60byte */
**************************************************
** 構造体の要素を取り出すサブルーチン
**
** 引数%d0.l = 構造体のインデックス番号
** 戻り値NAME_DATA(名前のデータ)
**         ADDRESS_DATA(住所のデータ)
**************************************************
STRUCT:
	* レジスタ退避
	movem.l  %d0-%d7/%a0-%a6,-(%sp)
	
	mulu    #SIZE,%d0           /* d0.l=取り出すインデックス番号×60 */
	add.l   #ADDRESS_BOOK,%d0   /* d0.l=取り出す要素の先頭アドレス*/
	movea.l %d0,%a0             /* a0.l=d0.l */
	
	moveq.l #0,%d1              /* d1.l=0 ループカウンタの初期化*/
	lea.l   NAME_DATA,%a2       /* 書き出す領域の先頭アドレス*/
	movea.l %a0,%a1             /* a1.l=a0 */
NAME_LOOP:      /* NAMEを書き出すルーチン*/
	move.b  (%a1)+,(%a2)+       /* NAMEの書き出し*/
	addq.l  #1,%d1              /* ループカウンタ++ */
	cmp.l   #20,%d1             /* ループカウンタ<20 ならば*/
	bne     NAME_LOOP           /* NAME_LOOPへ*/
	
	moveq.l #0,%d1              /* d1.l=0 ループカウンタの初期化*/
	lea.l   ADDRESS_DATA,%a2    /* 書き出す領域の先頭アドレス*/
	movea.l %a0,%a1             /* a1.l=a0.l */
	adda.l  #ADDRESS,%a1        /* a1.l=a1.l+ADDRESS */
ADDRESS_LOOP:   /* ADDRESSを書き出すルーチン*/
	move.b  (%a1)+,(%a2)+       /* ADDRESSの書き出し*/
	addq.l  #1,%d1              /* ループカウンタ++ */
	cmp.l   #40,%d1             /* ループカウンタ<40ならば*/
	bne     ADDRESS_LOOP        /* ADDRESS_LOOPへ*/
	
	* レジスタの復帰
	movem.l (%sp)+,%d0-%d7/%a0-%a6
	rts                         /* サブルーチンから復帰*/
**************************************************
** 住所録
** NAME の長さ20byte
** ADDRESS の長さは40byte
**************************************************
.section .data
ADDRESS_BOOK:
	.ascii  "TAROU               "    /* NAME */
	.ascii  "HUKUOKASHI HIGASHIKU                    "  /* ADDRESS */
	.ascii  "HANAKO              "    /* NAME */
	.ascii  "HUKUOKASHI MINAMIKU                     "  /* ADDRESS */
**************************************************
** STRUCTの出力
**************************************************
NAME_DATA:.ds.b 20                /* NAME出力先*/
ADDRESS_DATA:   .ds.b 40          /* ADDRESS出力先*/

.end

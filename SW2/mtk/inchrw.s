.global inbyte

.text
.even
	
inbyte:
	movem.l	%a0-%a1/%d1-%d3,-(%sp)
	lea.l	inbyte_buf, %a0	/* �����¸�ΰ� */
inbyte_do:	
	move.l	#1, %d0	/* GETSTRING�ƤӽФ� */
	move.l	%sp, %a1
	adda.l	#24, %a1
	move.l	(%a1), %d1 /* ch����� */
	move.l	%a0, %d2	/* �����¸�ΰ����¸���� */
	move.l	#1, %d3	/* 1ʸ�������ɤ߹��� */
	trap	#0	/* �ƤӽФ� */
	cmpi.l	#1, %d0	/* ��̳�ǧ */
	bne	inbyte_do	/* ���Ԥ������ϥ�ȥ饤 */
	move.b	(%a0), %d0	/* ��¸����ʸ������������ΰ�˥��ԡ� */
	movem.l	(%sp)+, %a0-%a1/%d1-%d3
	rts

.section .bss
inbyte_buf:	ds.b 1	/* �����¸�ΰ� */
		.even

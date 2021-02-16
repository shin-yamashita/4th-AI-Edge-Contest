/***************************************************************************/
/*
/***************************************************************************/

	.text

	.extern		_start, _stack, irq_handler, eirq_handler
	.section	.vector
	.long		_start	; 0 reset 0
	.long		irqh	; 1 irq   4
	.long		eirqh	; 2       8
	.long		_start	; 3       c
	.long		_start	; 4      10
	.long		_start	; 5
	.long		_start	; 6
	.long		_start	; 7
;	.long		_start	; 8      20
;	.long		_start	; 9
;	.long		write	; a
;	.long		_start	; b
;	.long		_start	; c      30
;	.long		_start	; d
;	.long		_start	; e
;	.long		_start	; f
;	.long		_start	; 10
;

	.section	.text
irqh:
	st	sr, @-sp
	st	rp, @-sp
	st	r0, @-sp
	pushm	r1,r2
	pushm	r3,r4
	pushm	r5,r6
	pushm	r7,r8
	pushm	r9,r10
	pushm	r11,r12
	pushm	r13,r14

	call	irq_handler

	popm	r14,r13
	popm	r12,r11
	popm	r10,r9
	popm	r8,r7
	popm	r6,r5
	popm	r4,r3
	popm	r2,r1
	ld	@sp+, r0
	ld	@sp+, rp
	ld	@sp+, sr
	rti

eirqh:
	st	sr, @-sp
	st	rp, @-sp
	st	r0, @-sp
	pushm	r1,r2
	pushm	r3,r4
	pushm	r5,r6
	pushm	r7,r8
	pushm	r9,r10
	pushm	r11,r12
	pushm	r13,r14

	call	eirq_handler

	popm	r14,r13
	popm	r12,r11
	popm	r10,r9
	popm	r8,r7
	popm	r6,r5
	popm	r4,r3
	popm	r2,r1
	ld	@sp+, r0
	ld	@sp+, rp
	ld	@sp+, sr
	rti

write:
	st	sr, @-sp
	nop
	ld	@sp+, sr
	rti

	.end

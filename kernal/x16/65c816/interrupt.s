.include "banks.inc"

.import iclall, igetin
.import cbinv, cinv, nminv
.import __irq, __irq_65c816_saved, __irq_native_ret
.import key, irq_emulated_impl

.import goto_user, reg_a, reg_x, reg_y, softclock_timer_update, scrorg
.import iecop, ieabort, inirq, inbrk, innmi, incop, inabort
.import nncop_abort_ret
.import stack_ptr

.export c816_clall_thunk, c816_abort_emulated, c816_cop_emulated, c816_irqb, c816_getin_thunk
.export nnirq, nnbrk, nnnmi, nncop, nnabort
.export __irq_65c816_first, __interrupt_65c816_native_kernal_impl_ret

rom_bank = 1

.pushcpu
.setcpu "65816"

.macro c816_interrupt_impl
	rep #$30       ; 16-bit accumulator and index
	.I16
	.A16
	pha
	phd
	lda #0000
	tcd
	sep #$20        ; 8-bit accumulator
	.A8

	phb
	lda #00
	pha
	plb

	lda rom_bank    ;save ROM bank
	pha
	stz rom_bank	;set KERNAL bank

	phk
	pea __irq_native_ret   ;put RTI-style return-address onto the stack
	php

	rep #$20       ; 16-bit accumulator
	.A16

	lda $05,S
	pha
	phx            ; save X and Y
	phy

	.A8
	.I8
.endmacro

.macro intr_common_impl addr, emulated_kernal_vector, emulated_kernal_impl
	.A16
	.I16
	tsx
	tsc
	and #$FF00
	cmp #$0100
	beq :+
	lda stack_ptr
	tcs
:	phx            ; store old stack pointer on new stack

.ifnblank emulated_kernal_impl
	lda addr
	cmp #emulated_kernal_vector
	bne :+
	sep #$30
	jmp emulated_kernal_impl
.endif

:	pea __interrupt_65c816_native_ret ; set up CBM IRQ stack frame
	sec
	xce            ; enter emulation mode
	.A8
	.I8
	clc

	php
.endmacro

.macro irq_brk_common_impl addr, emulated_kernal_vector, emulated_kernal_impl
	intr_common_impl addr, emulated_kernal_vector, emulated_kernal_impl

	lda $0B, S
	pha
	lda $09, S
	pha
	lda $07, S
	pha

	jmp (addr)
.endmacro

.segment "C816_COP_EMULATED"
c816_cop_emulated:
	jmp (iecop)

.segment "C816_ABORT_EMULATED"
c816_abort_emulated:
	jmp (ieabort)

.segment "C816_NMIB"
c816_nmib:
	rep #$30       ; 16-bit accumulator and index
	jmp (innmi)

c816_irqb:
	c816_interrupt_impl
	jmp (inirq)

.segment "C816_BRK"
c816_brk:
	jmp c816_brk_impl

.segment "MEMDRV"
c816_brk_impl:
	c816_interrupt_impl
	jmp (inbrk)

.segment "C816_COP_NATIVE"
c816_cop_native:
	jmp (incop)

.segment "C816_ABORT_NATIVE"
c816_abort_native:
	jmp (inabort)

.segment "MEMDRV"
.A8
.I8
__irq_65c816_first:
	xba
	pha
	xba
	pha
	phd
	lda #00
	xba
	lda #00
	tcd

	phb
	lda #00
	pha
	plb

	lda rom_bank    ;save ROM bank
	pha
	stz rom_bank	;set KERNAL bank

	pea __irq_native_ret   ;put RTI-style return-address onto the stack
	php
	jmp __irq_65c816_saved

nnirq:
	irq_brk_common_impl cinv, key, irq_emulated_impl

nnbrk:
	irq_brk_common_impl cbinv

__interrupt_65c816_native_ret:
	clc
	xce            ; exit emulation mode
__interrupt_65c816_native_kernal_impl_ret:
	rep #$31       ; 16-bit accumulator, clear carry
	.A16
	.I16
	pla            ; pull old stack pointer
	tcs            ; restore stack pointer
	ply
	plx
	pla
	rti

nnnmi:
	c816_interrupt_impl
	intr_common_impl
	jmp nmi

nncop:
nnabort:
	sep #$20
	.A8
	jmp nncop_abort_ret

.popcpu

.segment "C816_CLALL_THUNK"
c816_clall_thunk:
	jmp (iclall)

.segment "C816_GETIN_THUNK"
c816_getin_thunk:
	jmp (igetin)

.assert <c816_abort_native = $4C, error, "c816_abort_native's low byte must be JMP ABS"
.assert >c816_abort_native = <c816_clall_thunk, error, "c816_abort_native's high byte must be equal to c816_clall_thunk's low byte"
.assert <softclock_timer_update = $4C, error, "softclock_timer_update's low byte must be JMP ABS"
.assert >softclock_timer_update = <scrorg, error, "softclock_timer_update's high byte must be equal to scrorg's low byte"
.assert >c816_clall_thunk = $EA, error, "c816_clall_thunk's high byte must be NOP"
.assert <c816_nmib = >c816_clall_thunk, error, "c816_nmib's low byte must be equal to c816_clall_thunk's high byte"
.assert >c816_nmib = $EA, error, "c816_nmib's high byte must be NOP"
.assert <c816_brk = >c816_getin_thunk, error, "c816_brk's low byte must be equal to c816_getin_thunk's high byte"
.assert >c816_brk = $EA, error, "c816_brk's high byte must be NOP"
.assert <c816_cop_native = $4C, error, "c816_cop_native's low byte must be JMP ABS"
.assert >c816_cop_native = <c816_getin_thunk, error, "c816_cop_native's high byte must be equal to c816_getin_thunk's low byte"

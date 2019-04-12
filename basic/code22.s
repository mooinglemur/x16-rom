.pag 'code22'
n0999	.byt @233,@76,@274,@37,@375
n9999	.byt @236,@156,@153,@47,@375
nmil	.byt @236,@156,@153,@50,0
inprt	lda #<intxt
	ldy #>intxt
	jsr strou2
	lda curlin+1
	ldx curlin
linprt	sta facho
	stx facho+1
	ldx #@220
	sec
	jsr floatc
	jsr foutc
strou2	jmp strout
fout	ldy #1
foutc	lda #' 
	bit facsgn
	bpl fout1
	lda #'-
fout1	sta fbuffr-1,y
	sta facsgn
	sty fbufpt
	iny
	lda #'0
	ldx facexp
	bne *+5
	jmp fout19
	lda #0
	cpx #@200
	beq fout37
	bcs fout7
fout37	lda #<nmil
	ldy #>nmil
	jsr fmult
	lda #250-addpr2-addprc
fout7	sta deccnt
fout4	lda #<n9999
	ldy #>n9999
	jsr fcomp
	beq bigges
	bpl fout9
fout3	lda #<n0999
	ldy #>n0999
	jsr fcomp
	beq fout38
	bpl fout5
fout38	jsr mul10
	dec deccnt
	bne fout3
fout9	jsr div10
	inc deccnt
	bne fout4
fout5	jsr faddh
bigges	jsr qint
	ldx #1
	lda deccnt
	clc
	adc #addpr2+addprc+7
	bmi foutpi
	cmp #addpr2+addprc+@10
	bcs fout6
	adc #$ff
	tax
	lda #2
foutpi	sec
fout6	sbc #2
	sta tenexp
	stx deccnt
	txa
	beq fout39
	bpl fout8
fout39	ldy fbufpt
	lda #'.
	iny
	sta fbuffr-1,y
	txa
	beq fout16
	lda #'0
	iny
	sta fbuffr-1,y
fout16	sty fbufpt
fout8	ldy #0
foutim	ldx #@200
fout2	lda faclo
	clc
	adc foutbl+2+addprc,y
	sta faclo
	lda facmo
	adc foutbl+1+addprc,y
	sta facmo
	lda facmoh
	adc foutbl+1,y
	sta facmoh
	lda facho
	adc foutbl,y
	sta facho
	inx
	bcs fout41
	bpl fout2
	bmi fout40
fout41	bmi fout2
fout40	txa
	bcc foutyp
	eor #@377
	adc #@12
foutyp	adc #@57
	iny
	iny
	iny
	iny
	sty fdecpt
	ldy fbufpt
	iny
	tax
	and #@177
	sta fbuffr-1,y
	dec deccnt
	bne stxbuf
	lda #'.
	iny
	sta fbuffr-1,y
stxbuf	sty fbufpt
	ldy fdecpt
	txa
	eor #@377
	and #@200
	tax
	cpy #fdcend-foutbl
	beq fouldy
	cpy #timend-foutbl
	bne fout2
fouldy	ldy fbufpt
fout11	lda fbuffr-1,y
	dey
	cmp #'0
	beq fout11
	cmp #'.
	beq fout12
	iny
fout12	lda #'+
	ldx tenexp
	beq fout17
	bpl fout14
	lda #0
	sec
	sbc tenexp
	tax
.end

; SPDX-FileCopyrightText: © 2023 Ryan Carsten Schmidt <https://github.com/ryandesign>
; SPDX-License-Identifier: MIT

WNDLFT      =         $20       ;left column of scroll window
WNDWDTH     =         $21       ;width of scroll window
WNDTOP      =         $22       ;top of scroll window
WNDBTM      =         $23       ;bottom of scroll window
CH          =         $24       ;cursor horizontal position
CV          =         $25       ;cursor vertical position
BASL        =         $28       ;text row base address low byte
BASH        =         $29       ;text row base address high byte
A1L         =         $3C       ;general purpose A1 register low byte
A1H         =         $3D       ;general purpose A1 register high byte
A2L         =         $3E       ;general purpose A2 register low byte
A2H         =         $3F       ;general purpose A2 register high byte
A3L         =         $4A       ;general purpose A3 register low byte
A3H         =         $4B       ;general purpose A3 register high byte
INBUFF      =        $200       ;input buffer
KBD         =       $C000       ;keyboard value
CLRALTCHAR  =       $C00E       ;select primary character set
SETALTCHAR  =       $C00F       ;select alternate character set
KBDSTRB     =       $C010       ;keyboard strobe
RDALTCHAR   =       $C01E       ;read alternate character set status
AN0OFF      =       $C058       ;annunciator 0 off
AN0ON       =       $C059       ;annunciator 0 on
AN1OFF      =       $C05A       ;annunciator 1 off
AN1ON       =       $C05B       ;annunciator 1 on
AN2OFF      =       $C05C       ;annunciator 2 off
AN2ON       =       $C05D       ;annunciator 2 on
AN3OFF      =       $C05E       ;annunciator 3 off
AN3ON       =       $C05F       ;annunciator 3 on
PREAD       =       $FB1E       ;machine identification byte
INIT        =       $FB2F       ;set text mode, page 1, lores, standard text window
TABV        =       $FB5B       ;set cursor vertical position
VERSION     =       $FBB3       ;machine identification byte
ZIDBYTE2    =       $FBBF       ;machine identification byte
ZIDBYTE     =       $FBC0       ;machine identification byte
BELL1       =       $FBDD       ;machine identification byte
HOME        =       $FC58       ;clear text screen 1 and move cursor to top left
CROUT       =       $FD8E       ;print carriage return
PRHEX       =       $FDE3       ;print low nibble of A as hex
COUT        =       $FDF0       ;print character A
IDROUTINE   =       $FE1F       ;machine identification routine
SETNORM     =       $FE84       ;set normal text
SETKBD      =       $FE89       ;set KSW to KEYIN
SETVID      =       $FE93       ;set CSW to COUT1
RESET       =       $FFFC       ;reset vector

ALTCHARSET  =         $D7       ;whether alternate charset is active

OPASLZP     =         $06       ;asl opcode with zero page addressing
OPSEC       =         $38       ;sec opcode
OPRTS       =         $60       ;rts opcode
OPTXA       =         $8A       ;txa opcode
OPCMPIMM    =         $C9       ;cmp opcode with immediate addressing
OPNOP       =         $EA       ;nop opcode

COLS        =          40
WIDTH       =          16
HEIGHT      =          16

KEYESC      =         $9B       ;esc keycode
KEY1        =         $B1       ;1 keycode
KEY2        =         $B2       ;2 keycode

;define a string in which every char except the last one has the high bit set
.macro defstr name, str
    .ident(.concat(name, "len")) = .strlen(str)
    .ident(name):
    .repeat .strlen(str) - 1, i
        .byte .strat(str, i) | %10000000
    .endrepeat
    .byte .strat(str, .strlen(str) - 1) & $7F
.endmacro

;load the given memory address into A1
.macro ld1 addr
            lda #<addr
            sta A1L
            lda #>addr
            sta A1H
.endmacro

.rodata

defstr "title",     "CHARSET INSPEC][R"
defstr "apple",     "Apple "
space       =       apple+5
defstr "ii",        "]["
defstr "j",         "j-"
defstr "plus",      "plus"
defstr "iii",       "///"
defstr "iie",       "//e"
defstr "enhanced",  " enhanced"
defstr "card",      " card"
defstr "iic",       "//c"
defstr "iigs",      "IIGS"
defstr "primary",   "Primary "
defstr "alternate", "Alternate "
defstr "charset",   "character set"
defstr "tochange",  "1 or 2 = change charset; "
defstr "toexit",    "Esc = exit"

.code

.proc main
                                ;initialization copied from ROM RESET routine:
            jsr SETNORM         ;use normal (not inverse) text
            jsr INIT            ;text mode, page 1, lores, standard text window
            jsr SETVID          ;use standard character output routine
            jsr SETKBD          ;use standard keyboard input routine
            jsr HOME            ;clear screen and move cursor to top left
            lda AN0OFF          ;annunciators to standard
            lda AN1OFF
            lda AN2ON
            lda AN3ON

            jsr printtitle
            jsr CROUT
            jsr CROUT

            ldy #(COLS-WIDTH)/2 ;center the header
            sty CH
            ldx #0
@header:    txa
            jsr PRHEX           ;print column numbers
            inx
            cpx #WIDTH
            bne @header

            dey
            sty WNDLFT
            jsr CROUT
            lda #'+'|%10000000
            jsr COUT
            lda #'-'|%10000000
@underline: jsr COUT            ;underline the header with a line of dashes
            dex
            bne @underline

            stx A1L
            dey
            sty WNDLFT
            jsr CROUT
@row:       txa
            jsr PRHEX           ;print row number
            lda #$A7            ;use apostrophes for the vertical line
            jsr COUT            ; apple ii and ii plus don't have vertical bar
            lda A1L
            ldy #2
@col:       sta (BASL),y        ;store values to the screen directly
            adc #1
            iny
            cpy #WIDTH+2
            bne @col
            sta A1L
            jsr CROUT
            inx
            cpx #HEIGHT
            bne @row
            ldx #0
            stx WNDLFT

            jsr CROUT
            jsr printmodel
            jsr printinstructions

            lda VERSION
            cmp #OPASLZP
            beq @read           ;for iie and later, skip the next bit
            lda #<AN2ON         ;ii j-plus uses annunciator 2 to switch charsets
            sta @clralt+1       ; and it shouldn't hurt on ii and ii plus
            lda #<AN2OFF
            sta @setalt+1
            ldy #$0             ;no way to read state of annunciators
            beq @store          ;always
@read:      ldy RDALTCHAR       ;see which charset is currently active
@store:     sty ALTCHARSET      ;store it in a global
            jsr printcharset    ;print the character set name
@clearkey:  sta KBDSTRB         ;indicate keypress was handled
@key:       lda KBD             ;check keyboard
            bpl @key            ;if no keypress, loop
            cmp #KEY1           ;if 1 key pressed
            bne @check2
@clralt:    sta CLRALTCHAR      ; select primary character set
            ldy #$0
            bpl @store          ;always
@check2:    cmp #KEY2           ;if 2 key pressed
            bne @checkesc
@setalt:    sta SETALTCHAR      ; select alternate character set
            ldy #$FF
            bmi @store          ;always
@checkesc:  cmp #KEYESC         ;if esc key pressed
            bne @clearkey
            sta KBDSTRB         ;indicate keypress was handled
            jsr HOME            ;clear the screen
            jmp (RESET)         ;exit by resetting to BASIC or monitor
.endproc

;print title centered on current line
.proc printtitle
            ldx #0
            ld1 title
            jsr appendstrtobuff
            jmp centerbuff
.endproc

;print computer model centered on current line
.proc printmodel
            ldx #0
            ld1 apple
            jsr appendstrtobuff
            lda IDROUTINE       ;don't call IDROUTINE; that might disturb X
            cmp #OPRTS          ;just check if it's RTS
            bne @iigs
            lda VERSION
            cmp #OPASLZP
            bne @ii
            lda ZIDBYTE
            beq @iic
            ld1 iie
            jsr appendstrtobuff
            lda ZIDBYTE
            cmp #OPNOP
            beq @gotoprint      ;really want @print but it's too far away
            lda BELL1
            cmp #$2
            beq @iiecard
            ld1 enhanced
            bne @append         ;always
@iigs:      ld1 iigs
            bne @append         ;always
@iiecard:   ld1 card
            bne @append         ;always
@iic:       ld1 iic
            jsr appendstrtobuff
            lda ZIDBYTE2
            cmp #$5
            bne @print
            jsr appendspacetobuff
            ld1 plus
            bne @append         ;always
@ii:        lda PREAD
            cmp #OPTXA
            beq @iii
            ld1 ii
            jsr appendstrtobuff
            lda VERSION
            cmp #OPSEC
@gotoprint: beq @print
            jsr appendspacetobuff
            lda VERSION
            cmp #OPCMPIMM
            bne @iiplus
            ld1 j
            jsr appendstrtobuff
@iiplus:    ld1 plus
            bne @append         ;always
@iii:       ld1 iii
@append:    jsr appendstrtobuff
@print:     jmp centerbuff
.endproc

;print instructions centered on line 24
.proc printinstructions
            lda #23
            jsr TABV
            ldx #0
            lda VERSION
            cmp #OPASLZP
            beq @tochange       ;show charset instructions if iie or newer
            cmp #OPCMPIMM       ; or ii j-plus
            bne @toexit         ;otherwise only show exit instructions
@tochange:  ld1 tochange
            jsr appendstrtobuff
@toexit:    ld1 toexit
            jsr appendstrtobuff
            jmp centerbuff
.endproc

;append a space to INBUFF+X
.proc appendspacetobuff
            ld1 space
            ;fall through to appendstrtobuff
.endproc

;copy a string from A1 to INBUFF+X
;
;input: A1L/A1H = address of input string, X = starting offset of output buffer
;output: X = length of string in buffer
.proc appendstrtobuff
            ldy #0              ;start at zeroth character in string
            beq @load           ;always
@loop:      sta INBUFF,x        ;store character in buffer
            iny                 ;increment input string position
            inx                 ;increment output buffer position
@load:      lda (A1L),y         ;load character from string
            bmi @loop           ;loop while high bit is set
            ora #%10000000      ;set high bit
            sta INBUFF,x        ;store character in buffer
            inx                 ;increment output buffer position
            lda #0              ;terminate buffer with null
            sta INBUFF,x
            rts
.endproc

;print the current character set centered on line 23
.proc printcharset
            lda #22
            jsr TABV
            ldx #0
            jsr appendspacetobuff
            lda VERSION
            cmp #OPASLZP
            beq @check          ;check which charset if iie or newer
            cmp #OPCMPIMM       ; or ii j-plus
            bne @charset        ;otherwise don't distinguish charsets
@check:     bit ALTCHARSET
            bmi @alternate
            ld1 primary
            bne @append         ;always
@alternate: ld1 alternate
@append:    jsr appendstrtobuff
@charset:   ld1 charset
            jsr appendstrtobuff
            jsr appendspacetobuff
            ;fall through to centerbuff
.endproc

;print contents of input buffer centered
;
;input: X = length of string
.proc centerbuff
            txa
            eor #%11111111      ;subtract length of string
            sec                 ; from window width
            adc WNDWDTH
            lsr                 ;divide by two
            clc
            adc WNDLFT          ;add window left
            sta CH
            ;fall through to coutbuff
.endproc

;print contents of input buffer
.proc coutbuff
            ldx #0              ;start at zeroth character in buffer
            beq @load           ;always
@loop:      jsr machinecout     ;print character
            inx                 ;incremenet output buffer position
@load:      lda INBUFF,x        ;load character from buffer
            bne @loop           ;loop while character is not null
            rts
.endproc

;output a character appropriate for this machine, converting lowercase to
;uppercase if not iie or newer
;
;input: A = character
.proc machinecout
            ldy VERSION
            cpy #OPASLZP
            beq @cout           ;don't convert if iie or newer
            cmp #'a'|%10000000
            bcc @cout           ;don't convert if not lowercase
            cmp #'z'|%10000000+1
            bcs @cout           ;don't convert if not lowercase
            and #%11011111      ;lowercase to uppercase
@cout:      jmp COUT
.endproc

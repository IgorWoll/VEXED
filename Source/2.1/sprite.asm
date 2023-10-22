\ ******************************************************************
\ *	Zero page vars
\ ******************************************************************

ORG &70
GUARD &9F

.spritenum          skip 1
.x                  skip 1
.y                  skip 1
.foreground_colour  skip 1
.background_colour  skip 1
.scrnaddr           skip 2
.scrnaddr_8         skip 2
.spriteaddr         skip 2
.x_count            skip 1
.y_count            skip 1
.t1                 skip 1  ;temp
.t2                 skip 1
.t3                 skip 1
.t4                 skip 1
.t5		    skip 1
.t6		    skip 1
.down_count         skip 1
.timer_amount       skip 1
.high_nibble        skip 1
.low_nibble         skip 1
.colour             skip 1

\ ******************************************************************
\ *	Code
\ ******************************************************************

ORG &2D50
GUARD &3000

.start

.main

LDA spritenum       ;setup the sprite address
ASL A
TAX			;spritenum * 2
LDA sprite,X		;load sprite adress
STA spriteaddr
LDA sprite+1,X
STA spriteaddr+1
JSR calcscraddr     ;calculate the screen address
LDA #19
JSR &FFF4           ;*FX 19 wait for vertical sync
JSR drawsprite
RTS

\ the sprites are coded as 1 bit per pixel.
\ in MODE 1 there are four pixels in every byte
.drawsprite
{
    LDX #0
    LDA #2
    STA y_count
.looprow
    LDA #2
    STA x_count
.loopcol
    LDY #0
.loopchar
    LDA foreground_colour
    STA colour
    CMP #0
    BEQ colour_0
    LDA (spriteaddr),Y	    
    STA t1                  ;save 1bit coded sprite byte in t1 
    LSR A                   ;process high_nibble (first 4 bits)
    LSR A
    LSR A
    LSR A
    JSR get_colour_byte
    STA high_nibble
    LDA t1       	        
    AND #&0F                ;process low nibble (last 4 bits)
    JSR get_colour_byte
    STA low_nibble
    LDA background_colour   ;if background colour is not zero add second coloured sprite (sprite_mask)
    STA colour
    CMP #0
    BEQ draw
    LDA high_nibble         ;save the high_nibble in t4
    STA t4
    LDA low_nibble
    STA t3                  ;save the low_nibble in t3
    LDA t1                  ;get the original 1 bit encoded sprite byte
    EOR #&FF                ;perform NOT
    AND background_mask_2,X 
    STA t2                  ;store intermediate result in t2
    LSR A                   ;process high_nibble
    LSR A
    LSR A
    LSR A
    JSR get_colour_byte
    ORA t4                  
    STA high_nibble
    LDA t2       	        ;restore the AND operation
    AND #&0F                ;process low_nibble
    JSR get_colour_byte
    ORA t3
    STA low_nibble
    JMP draw
    .colour_0
    LDA #0
    STA high_nibble
    STA low_nibble      
    .draw
    LDA high_nibble
    STA (scrnaddr),Y 
    LDA low_nibble
    STA (scrnaddr_8),Y  
    INX      
    INY
    CPY #8
    BNE loopchar
    JSR next_char
    DEC x_count
    BNE loopcol
    JSR next_row
    DEC y_count
    BNE looprow
    RTS
}

; ON ENTRY A = nibble value (four pixels) to colour, colour
; PRESERVES Y, X
; ON EXIT A holds the coloured bits

.get_colour_byte
{
    STY t5                  ; preserve Y
    STX t6
    LDY colour
    TAX
    LDA colour_table,X
    AND colour_mask,Y    
    LDY t5                  ; restore Y
    LDX t6
    RTS
}


.colour_mask
    EQUB %00000000
    EQUB %00001111
    EQUB %11110000
    EQUB %11111111

.colour_table
    EQUB %00000000
    EQUB %00010001
    EQUB %00100010
    EQUB %00110011
    EQUB %01000100
    EQUB %01010101
    EQUB %01100110
    EQUB %01110111
    EQUB %10001000
    EQUB %10011001
    EQUB %10101010
    EQUB %10111011
    EQUB %11001100
    EQUB %11011101
    EQUB %11101110
    EQUB %11111111

 .calcscraddr
{
    LDX y
    LDA #0
    STA t2
    LDA x
    ASL A               ; x * 2
    ROL t2              ; carry to t2
    ASL A               ; * 4
    ROL t2
    ASL A               ; * 8      x = * 8 because every character cell has 8 bytes. 
    ROL t2
    ADC screen_low,X    ; y + x
    STA scrnaddr
    LDA screen_high,X
    ADC t2
    STA scrnaddr+1
    LDA scrnaddr
    ADC #8
    STA scrnaddr_8
    LDA scrnaddr+1
    ADC #0
    STA scrnaddr_8+1
    RTS
}

 .next_char
{
    CLC
    LDA scrnaddr
    ADC #16
    STA scrnaddr
    BCC skip1
    INC scrnaddr+1
    CLC
.skip1
    LDA scrnaddr_8
    ADC #16
    STA scrnaddr_8
    BCC skip2
    INC scrnaddr_8+1
    CLC
.skip2
    LDA spriteaddr
    ADC #8
    STA spriteaddr
    BCC skip3
    INC spriteaddr+1
.skip3
    RTS
}

 .next_row
{
    CLC
    LDA scrnaddr
    ADC #&60
    STA scrnaddr
    LDA scrnaddr+1
    ADC #2
    STA scrnaddr+1
    LDA scrnaddr_8
    ADC #&60
    STA scrnaddr_8
    LDA scrnaddr_8+1
    ADC #2
    STA scrnaddr_8+1
    RTS
}

.slide_left
{
    JSR slide_four_pixels_left
    JSR slide_four_pixels_left
    JSR slide_four_pixels_left
    JSR slide_four_pixels_left
    RTS
.slide_four_pixels_left
    LDA #4
    STA t3
.slide_left_loop
    DEC x
    JSR move_left
    INC x
    LDA #3
    JSR wait
    DEC t3
    BNE slide_left_loop
    DEC x
    RTS
}

.slide_right
{
    JSR slide_four_pixels_right
    JSR slide_four_pixels_right
    JSR slide_four_pixels_right
    JSR slide_four_pixels_right
    RTS
.slide_four_pixels_right
    LDA #4
    STA t3
.slide_right_loop
    JSR move_right
    LDA #3
    JSR wait
    DEC t3
    BNE slide_right_loop
    INC x
    RTS
}

 .move_left
{
    JSR calcscraddr
    JSR move_row_left

    LDA scrnaddr
    CLC
    ADC #&80
    STA scrnaddr
    LDA scrnaddr+1
    ADC #&2
    STA scrnaddr+1

.move_row_left
    LDA #0
    STA t1

    LDY #32
.move_row_left_loop
    LDA t1
    LSR A
    LSR A
    LSR A
    AND #%00010001
    STA t2
    LDA (scrnaddr),Y
    STA t1
    ASL A
    AND #%11101110
    ORA t2
    STA (scrnaddr),Y
    TYA
    SEC
    SBC #8
    TAY
    BCS move_row_left_loop

    LDX #0
    STX t1
    CLC
    ADC #41
    TAY
    CPY #40
    BNE move_row_left_loop
    RTS
}

.move_right
{
    JSR calcscraddr
    JSR move_row_right
    LDA scrnaddr
    CLC
    ADC #&80
    STA scrnaddr
    LDA scrnaddr+1
    ADC #&2
    STA scrnaddr+1

.move_row_right
    LDA #0
    STA t1

    LDY #0
.move_row_right_loop
    LDA t1
    ASL A
    ASL A
    ASL A
    AND #%10001000
    STA t2
    LDA (scrnaddr),Y
    STA t1
    LSR A
    AND #%01110111
    ORA t2
    STA (scrnaddr),Y
    TYA
    CLC
    ADC #8
    TAY
    CPY #40
    BCC move_row_right_loop

    LDX #0
    STX t1
    SEC
    SBC #39
    TAY
    CPY #8
    BNE move_row_right_loop
    RTS
}

.fall_down
{
    JSR move_down
    JSR move_down
    RTS
.move_down
    LDA #8
    STA down_count
.move_down_loop
    JSR move_down_once
    LDA #2
    JSR wait
    DEC down_count
    BNE move_down_loop
    INC y
    RTS
}

.move_down_once
{
    LDA #4
    STA x_count

.move_down_x_loop
    LDA #3
    STA y_count

    LDA #0
    STA t1
.move_down_y_loop
    LDA t1
    JSR move_one_cell_down
    INC y
    DEC y_count
    BNE move_down_y_loop
    DEC y
    DEC y
    DEC y
    INC x
    DEC x_count
    BNE move_down_x_loop
    DEC x
    DEC x
    DEC x
    DEC x
    RTS

.move_one_cell_down
    STA t3
    JSR calcscraddr
    LDY #7
    LDA (scrnaddr),Y
    STA t1
    DEY
.move_down_loop
    LDA (scrnaddr),Y
    INY
    STA (scrnaddr),Y
    DEY
    DEY
    BPL move_down_loop
    INY
    LDA t3
    STA (scrnaddr),Y
    RTS
}

.wait
{
    STA timer_amount
    JSR set_timer
    JMP check_timer
}

.set_timer                      ;set 20 millisecond timer
{
    LDA #1
    LDX #timer1 MOD 256
    LDY #timer1 DIV 256
    JSR &FFF1
    CLC
    LDA timer1
    ADC timer_amount
    STA timer1
    BCC skip4
    INC timer1+1
.skip4
    RTS
}
.check_timer                    ;wait until set time has passed
{
    LDA #1
    LDX #timer2 MOD 256
    LDY #timer2 DIV 256
    JSR &FFF1
    SEC
    LDA timer1
    SBC timer2
    LDA timer1+1
    SBC timer2+1
    BCS check_timer             ;Carry is cleared on a negative result
    RTS
}
.timer1         skip 5
.timer2         skip 5
.end
\ ******************************************************************
\ *	Data
\ ******************************************************************
ORG &900

\ *	Spritedata 1 bit per pixel
.data1
EQUD &EAD5FF7F : EQUD &EAD5EAD5
EQUD &AB57FFFE : EQUD &AB57AB57
EQUD &EAD5EAD5 : EQUD &7FFFEAD5
EQUD &AB57AB57 : EQUD &FEFFAB57
.data2
EQUD &C1C0FF7F : EQUD &DFCFC7C3
EQUD &8383FFFE : EQUD &FBF38383
EQUD &C1C1CFDF : EQUD &7FFFC1C1
EQUD &C3E3F3FB : EQUD &FEFF0383
.data3
EQUD &C3C3FF7F : EQUD &FCFCC3C3
EQUD &C3C3FFFE : EQUD &3F3FC3C3
EQUD &C3C3FCFC : EQUD &7FFFC3C3
EQUD &C3C33F3F : EQUD &FEFFC3C3
.data4
EQUD &C3C0FF7F : EQUD &D8D8CCC7
EQUD &C303FFFE : EQUD &1B1B33E3
EQUD &C7CCD8D8 : EQUD &7FFFC0C3
EQUD &E3331B1B : EQUD &FEFF03C3
.data5
EQUD &D8C0FF7F : EQUD &C0C0C0D8
EQUD &1B03FFFE : EQUD &0303031B
EQUD &D8C0C0C0 : EQUD &7FFFC0D8
EQUD &1B030303 : EQUD &FEFF031B
.data6
EQUD &CFC0FF7F : EQUD &C6CCD8DF
EQUD &F303FFFE : EQUD &63331BFB
EQUD &C1C1C1C3 : EQUD &7FFFC0C1
EQUD &838383C3 : EQUD &FEFF0383
.data7
EQUD &D8C0FF7F : EQUD &C3C7CEDC
EQUD &1B03FFFE : EQUD &C3E3733B
EQUD &DCCEC7C3 : EQUD &7FFFC0D8
EQUD &3B73E3C3 : EQUD &FEFF031B
.data8
EQUD &C0C0FF7F : EQUD &CCCCCFCF
EQUD &0303FFFE : EQUD &3333F3F3
EQUD &CFCFCCCC : EQUD &7FFFC0C0
EQUD &F3F33333 : EQUD &FEFF0303
.data9
EQUD &C0C0FF7F : EQUD &CFC7C7C1
EQUD &0303FFFE : EQUD &F3E3E383
EQUD &C1C7C7CF : EQUD &7FFFC0C0
EQUD &83E3E3F3 : EQUD &FEFF0303
.data10
EQUD &C0C0FF7F : EQUD &C0C0C0C0
EQUD &0303FFFE : EQUD &03030303
EQUD &C0C0C0C0 : EQUD &7FFFC0C0
EQUD &03030303 : EQUD &FEFF0303
.sprite
EQUW data1
EQUW data2
EQUW data3
EQUW data4
EQUW data5
EQUW data6
EQUW data7
EQUW data8
EQUW data9
EQUW data10
.background_mask_1
EQUD &3F3F0000 : EQUD &3F3F3F3F
EQUD &FCFC0000 : EQUD &FCFCFCFC
EQUD &3F3F3F3F : EQUD &00003F3F
EQUD &FCFCFCFC : EQUD &0000FCFC
.background_mask_2
EQUD &00000000 : EQUD &00000000
EQUD &07030100 : EQUD &7F3F1F0F
EQUD &07030100 : EQUD &7F3F1F0F
EQUD &FFFFFFFF : EQUD &FEFFFFFF

\ *	Screen address lookup table

.screen_low
FOR n, 0, 31
  EQUB LO(&3000 + n * &280)
NEXT
.screen_high
FOR n, 0, 31
  EQUB HI(&3000 + n * &280)
NEXT

.end_data

PUTBASIC "TEST.BAS","TEST"
SAVE "OBJMAIN", start, end
SAVE "OBJDATA", data1, end_data
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
.high_nibble        skip 1
.low_nibble         skip 1
.colour             skip 1

\ ******************************************************************
\ *	Code 
\ ******************************************************************

ORG &2DA0
GUARD &3000

.start

.main

LDA spritenum       ;setup the spriteaddress
ASL A
TAX
LDA sprite,X 
STA spriteaddr
LDA sprite+1,X 
STA spriteaddr+1
JSR calcscraddr     ;calculate the screenaddress
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
    STA colour
    LDA (spriteaddr),Y 
    STA t1
    AND #&F0                ;Isolate the high nibble   
    STA high_nibble         ;is logical colour 2 by default
    LDA (spriteaddr),Y 
    AND #&0F                ;Isolate the low nibble
    STA low_nibble          ;is logical colour 1 by default
    JSR colouring
    LDA background_colour   
    CMP #0
    BEQ draw
    STA colour              ;if backgound colour is not black add an second colour
    LDA low_nibble          ;save coloured low_nibble in t3
    STA t3
    LDA high_nibble         ;save coloured high_nible in t4
    STA t4
    LDA t1                  ;load the sprite byte
    EOR #&FF                ;NOT
    AND background_mask_1,X
    STA t2                  
    AND #&F0                ;get the new high_nibble
    STA high_nibble
    LDA t2
    AND #&0F 
    STA low_nibble          ;get the new low_nibble
    JSR colouring           ;colour the nibbles
    LDA t4
    ORA high_nibble
    STA high_nibble
    LDA t3
    ORA low_nibble
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

 
.colouring 
{
    LDA colour
    CMP #1
    BEQ colour_1
    CMP #2
    BEQ colour_2
    .colour_3
    LDA high_nibble
    LSR A 
    LSR A 
    LSR A 
    LSR A 
    ADC high_nibble
    STA high_nibble
    LDA low_nibble
    ASL A 
    ASL A 
    ASL A
    ASL A 
    ADC low_nibble
    STA low_nibble
    RTS
    .colour_2       ;remember high_nibble is already in colour 2
    LDA low_nibble
    ASL A 
    ASL A 
    ASL A 
    ASL A 
    STA low_nibble
    RTS
    .colour_1       ;remember low_nibble is already in colour 1
    LDA high_nibble
    LSR A 
    LSR A 
    LSR A 
    LSR A
    STA high_nibble
    RTS
}

 .calcscraddr
{
    LDA y              ;calculate rowadress
    ASL A
    TAX
    LDA screen,X 
    STA scrnaddr
    LDA screen+1,x
    STA scrnaddr+1
    LDA #0             ;calculate columnadress
    STA t1
    STA t2
    LDA x 
    STA t1
    CLC                
    ASL t1              ; x * 8
    ROL t2
    ASL t1 
    ROL t2 
    ASL t1
    ROL t2
    LDA scrnaddr
    ADC t1
    STA scrnaddr
    LDA scrnaddr+1
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
    LDA scrnaddr+1
    ADC #0
    STA scrnaddr+1
    LDA scrnaddr_8
    ADC #16
    STA scrnaddr_8
    LDA scrnaddr_8+1
    ADC #0
    STA scrnaddr_8+1
    LDA spriteaddr
    ADC #8
    STA spriteaddr
    LDA spriteaddr+1
    ADC #0
    STA spriteaddr+1
    RTS
}

 .next_row
{
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
    JSR move_left
    JSR wait
    JSR move_left
    JSR wait
    JSR move_left
    JSR wait
    JSR move_left
    RTS
}

.slide_right
{
    JSR move_right
    JSR wait
    JSR move_right
    JSR wait
    JSR move_right
    JSR wait
    JSR move_right
    RTS
}

.fall_down
{
    JSR move_down
    JSR wait
    JSR move_down
    RTS
}

 .move_left
{
    DEC x               ;move left
    JSR main
    SEC
    LDA scrnaddr
    SBC #&E0 
    STA scrnaddr
    LDA scrnaddr+1
    SBC #&4
    STA scrnaddr+1
    JSR clear_side
    RTS    
}

.move_right
{
    INC x 
    JSR main
    SEC
    LDA scrnaddr
    SBC #&08
    STA scrnaddr
    LDA scrnaddr+1
    SBC #&5
    STA scrnaddr+1  
    JSR clear_side
    RTS
}

 .clear_side
{
    LDA #19
    JSR &FFF4           ;*FX 19 wait for vertical sync
    LDX #2
    .loop1
    LDY #0
    .loop2
    LDA #0
    STA (scrnaddr),Y 
    INY
    CPY #8
    BNE loop2
    CLC
    LDA scrnaddr
    ADC #&80
    STA scrnaddr
    LDA scrnaddr+1
    ADC #2
    STA scrnaddr+1
    DEX
    BNE loop1
    RTS
}

.move_down
{
    JSR calcscraddr
    LDY #0
    .loop 
    LDA #0
    STA (scrnaddr),Y 
    INY
    CPY #32
    BNE loop
    INC y 
    JSR main
    RTS
}

.wait
{
    JSR set_timer
    JSR check_timer
    RTS
}

.set_timer                      ;set 20millisecond timer
{
    LDA #1
    LDX #timer1 MOD 256
    LDY #timer1 DIV 256
    JSR &FFF1
    CLC
    LDA timer1
    ADC #15 
    STA timer1
    LDA timer1+1
    ADC #0
    STA timer1+1
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
    BCS check_timer             ;Carry is cleared on a negative reslut. 
    RTS
}
.timer1         skip 5
.timer2         skip 5
.end
\ ******************************************************************
\ *	Data 
\ ******************************************************************
ORG &900

\ *	Spritedata 1bit per pixel
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

\ *	Screenadress lookup table

.screen             
EQUW &3000 : EQUW &3280 : EQUW &3500 : EQUW &3780
EQUW &3A00 : EQUW &3C80 : EQUW &3F00 : EQUW &4180
EQUW &4400 : EQUW &4680 : EQUW &4900 : EQUW &4B80
EQUW &4E00 : EQUW &5080 : EQUW &5300 : EQUW &5580
EQUW &5800 : EQUW &5A80 : EQUW &5D00 : EQUW &5F80
EQUW &6200 : EQUW &6480 : EQUW &6700 : EQUW &6980
EQUW &6C00 : EQUW &6E80 : EQUW &7100 : EQUW &7380
EQUW &7600 : EQUW &7880 : EQUW &7B00 : EQUW &7D80
.end_data

SAVE "OBJMAIN", start, end
SAVE "OBJDATA", data1, end_data
.segment "HEADER"
  .byte $4E, $45, $53, $1A   ; iNES header identifier
  .byte 2                    ; 2x 16KB PRG code
  .byte 1                    ; 1x 8KB CHR data
  .byte $01, $00             ; Mapper 0, vertical mirroring

.segment "ZEROPAGE"
controller1: .res 1          ; Reserve 1 byte for controller state
color_index:  .res 1  ; Reserve 1 byte to store the current index of the color
TimerCounter:      .res 1    ; current timer value (0 to 9)
FrameDelayCounter: .res 1    ; how many frames to wait before incrementing timer  
pressedA: .res 1
sprite1_Xsub:      .res 1   ; fractional part
sprite1_Ysub:      .res 1   ; fractional part
sprite1_Abutton:      .res 1   ; fractional part
    sequence_index: .res 1
    firststloopdone: .res 1

    TimerCounter2:      .res 1    ; current timer value (0 to 9)
    FrameDelayCounter2: .res 1    ; how many frames to wait before incrementing timer      
    unicounter: .res 1

sprite1_Colorbutton:      .res 1   ; fractional part


sprite1_BrushStroke: .res 1
GameState: .res 1

    pointerLo: .res 1    ; pointer variables declared in RAM
    pointerHi: .res 1    ; low byte first, high byte immediately after

.segment "VECTORS"
  .addr NMI                  ; NMI vector
  .addr RESET               ; Reset vector
  .addr 0                    ; IRQ vector (unused)

.segment "STARTUP"

.segment "CODE"

Note = $04
Note2 = $70

CharpNote = $C9
ENote = $A9 
GSharpNote = $42

BrushY = $0200
BrushX = $0203


Paint_Y = $0204
Paint_X = $0207
painted1 = $01
painted2 = $02
painted3 = $03
painted4 = $04
painted5 = $05
painted6 = $06
painted7 = $07
painted8 = $08
painted9 = $09
painted10 = $0A
painted11 = $0B
painted12 = $0C
painted13 = $0D
painted14 = $0E
painted15 = $0E
painted16 = $0F
painted17 = $10
painted18 = $11
painted19 = $12
painted20 = $13
painted21 = $14
painted22 = $15
painted23 = $16
painted24 = $17
painted25 = $18
painted26 = $19
painted27 = $1A
painted28 = $1B
painted29 = $1C
painted30 = $1D
painted31 = $1E
painted32 = $1F
painted33 = $20
painted34 = $21
painted35 = $22
painted36 = $23
painted37 = $24
painted38 = $25
painted39 = $26
painted40 = $27
painted41 = $28
painted42 = $29
painted43 = $2A
painted44 = $2B
painted45 = $2C
painted46 = $2D
painted47 = $2E
painted48 = $2F
painted49 = $30
painted50 = $31
painted51 = $32
painted52 = $33
painted53 = $34
painted54 = $35
painted55 = $36
painted56 = $37
painted57 = $38
painted58 = $39
painted59 = $3A
painted60 = $3B
painted61 = $3D
painted62 = $3E
painted63 = $3F

RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

loadpalettes:
    LDA $2002
    LDA #$3f
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00
loadpalettesloop:
    LDA palette,X   ; load data from adddress (palette + X)
                        ; 1st time through loop it will load palette+0
                        ; 2nd time through loop it will load palette+1
                        ; 3rd time through loop it will load palette+2
                        ; etc
    STA $2007
    INX 
    CPX #$20
    BNE loadpalettesloop

loadsprites:
    LDX #$00
loadspritesloop:
    LDA sprites,X
    STA $0200,X
    INX 
    CPX #$FF
    BNE loadspritesloop 
                
;;; Using nested loops to load the background efficiently ;;;
loadbackground:
    LDA $2002               ; read PPU status to reset the high/low latch
    LDA #$20
    STA $2006               ; write high byte of $2000 address
    LDA #$00
    STA $2006               ; write low byte of $2000 address

    LDA #<background 
    STA pointerLo           ; put the low byte of address of background into pointer
    LDA #>background        ; #> is the same as HIGH() function in NESASM, used to get the high byte
    STA pointerHi           ; put high byte of address into pointer

    LDX #$00                ; start at pointer + 0
    LDY #$00
outsideloop:

insideloop:
    LDA (pointerLo),Y       ; copy one background byte from address in pointer + Y
    STA $2007               ; runs 256*4 times

    INY                     ; inside loop counter
    CPY #$00                
    BNE insideloop          ; run inside loop 256 times before continuing

    INC pointerHi           ; low byte went from 0 -> 256, so high byte needs to be changed now

    INX                     ; increment outside loop counter
    CPX #$04                ; needs to happen $04 times, to copy 1KB data
    BNE outsideloop         


    CLI 
    LDA #%10010000  ; enable NMI, sprites from pattern table 0, background from 1
    STA $2000
    LDA #%00011110  ; background and sprites enable, no left clipping
    STA $2001









forever:
    JMP forever 







NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer














GameEngine:  


  LDA GameState
  CMP #0
  BEQ EngineTitle    ;;game is displaying title screen

  LDA GameState
  CMP #1
  BEQ EnginePlaying   ;;game is playing

GameEngineDone:



EngineTitle:

LDA #$5C
STA $201



LatchControllerT:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons



ReadAT: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadADoneT   ; branch to ReadADone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)




ReadADoneT:        ; handling this button is done


ReadBT: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadBDoneT   ; branch to ReadADone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)

ReadBDoneT:        ; handling this button is done


ReadSLT: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadSLDoneT   ; branch to ReadADone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)

ReadSLDoneT:        ; handling this button is done




ReadSTT: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadSTDoneT   ; branch to ReadADone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)

  JSR changeBG
  LDA #$01
  STA GameState
  LDA #$00
  STA $201
  JMP main
ReadSTDoneT:        ; handling this button is done


JSR TitleMusic
 JMP GameEngineDone


EnginePlaying:

JMP main















main:

;----------------------------------------------------------------------


PhysicsEngine:

;top barrier
  LDA $0200        ; Load sprite Y position
  CMP #$6F         ; Check if at ground level
  BCS NoMove       ; If at or below ground, stop

    ; Move sprite down by 1
  CLC
  ADC #$01
  STA $0200        ; Store updated Y position


NoMove:

;bottom barrier

LDA $0200        ; Load sprite Y position
CMP #$AC         ; Check if at ground level
BCC NoMoveBottom       ; If at or below ground, stop

    ; Move sprite down by 1
SEC
SBC #$01
STA $0200        ; Store updated Y position



NoMoveBottom:


;left screen  barrier

  LDA $0203        ; Load sprite X position
  CMP #$19         ; Check if at left side of screen
  BCS NoMoveLeft      

    ; Move sprite right by 1
  CLC
  ADC #$01
  STA $0203        ; Store updated X position  


NoMoveLeft:


LDA $0203        ; Load sprite Y position
CMP #$50         ; Check if at ground level
BCC NoMoveRight       ; If at or below ground, stop

    ; Move sprite down by 1
SEC
SBC #$01
STA $0203        ; Store updated Y position


NoMoveRight:

   lda #$00
    sta $4015           ; Disable all sound channels
;-----------------------------------------------------------



ReadA: 
  LDA $4016       ; player 1 - A
  AND #%00000001  ; only look at bit 0
  BEQ ReadADone   ; branch to ReadADone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)









LDA sprite1_Abutton
CLC
ADC #$20          ; 128 = 0.5 in 8-bit fraction
STA sprite1_Abutton

BCC NoCarryA       ; if no overflow → don't move yet

JSR Placepaint

NoCarryA:







  



ReadADone:        ; handling this button is done


  
ReadB: 
  LDA $4016       ; player 1 - B
  AND #%00000001  ; only look at bit 0
  BEQ ReadBDone   ; branch to ReadBDone if button is NOT pressed (0)
                  ; add instructions here to do something when button IS pressed (1)
  

LDA sprite1_Colorbutton
CLC
ADC #$40          ; 128 = 0.5 in 8-bit fraction
STA sprite1_Colorbutton

BCC NoCarryC       ; if no overflow → don't move yet

JSR ChangeColor

NoCarryC:



ReadBDone:        ; handling this button is done

ReadSelect: 
  LDA $4016       ; player 1 - B
  AND #%00000001  ; only look at bit 0
  BEQ ReadSelectDone   ; branch to ReadBDone if button is NOT pressed (0)



LDA sprite1_BrushStroke
CLC
ADC #$18          ; 128 = 0.5 in 8-bit fraction
STA sprite1_BrushStroke

BCC NoCarryBrushStroke       ; if no overflow → don't move yet



JSR ChangeBrush

NoCarryBrushStroke:





ReadSelectDone:        ; handling this button is done

ReadStart: 
  LDA $4016       ; player 1 - B
  AND #%00000001  ; only look at bit 0
  BEQ ReadStartDone   ; branch to ReadBDone if button is NOT pressed (0)

BGS:
LDA pressedA
CMP #$01
BEQ indeed
JSR changeBG

LDA #$01
STA pressedA
indeed:

ReadStartDone:

ReadUp:
LDA $4016       ; player 1 - B
AND #%00000001  ; only look at bit 0
BEQ ReadUpDone   ; branch to ReadBDone if button is NOT pressed (0)


;LDA sprite1_Ysub
;CLC
;ADC #$80          ; 128 = 0.5 in 8-bit fraction
;STA sprite1_Ysub

;BCC NoCarryU       ; if no overflow → don't move yet


LDA $0200       ; load sprite1 X position
SEC             ; make sure the carry flag is clear
SBC #$01        ; A = A + 1
STA $0200       ; save sprite X position

;NoCarryU:

ReadUpDone:

down:
LDA $4016       ; player 1 - B
AND #%00000001  ; only look at bit 0
BEQ downdone   ; branch to ReadBDone if button is NOT pressed (0)




;LDA sprite1_Ysub
;CLC
;ADC #$80          ; 128 = 0.5 in 8-bit fraction
;STA sprite1_Ysub

;BCC NoCarryD       ; if no overflow → don't move yet


LDA $0200       ; load sprite1 X position
CLC             ; make sure the carry flag is clear
ADC #$01        ; A = A + 1
STA $0200       ; save sprite X position

;NoCarryD:

downdone:

left:
LDA $4016       ; player 1 - B
AND #%00000001  ; only look at bit 0
BEQ leftdone   ; branch to ReadBDone if button is NOT pressed (0) 

;LDA sprite1_Xsub
;CLC
;ADC #$80          ; 128 = 0.5 in 8-bit fraction
;STA sprite1_Xsub

;BCC NoCarryL       ; if no overflow → don't move yet

LDA $0203
SEC
SBC #1
STA $0203

;NoCarryL:

leftdone:

right:

LDA $4016       ; player 1 - B
AND #%00000001  ; only look at bit 0
BEQ rightdone  ; branch to ReadBDone if button is NOT pressed (0)

;LDA sprite1_Xsub
;CLC
;ADC #$80          ; 128 = 0.5 in 8-bit fraction
;STA sprite1_Xsub

;BCC NoCarry       ; if no overflow → don't move yet

LDA $0203
CLC
ADC #1
STA $0203

;NoCarry:



rightdone:








  LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons

  RTI


















Placepaint:
 

LDA painted1
CMP #$01
BEQ Havepainted1


;drawing 1st sprite
  LDA BrushY
  STA $0204

  LDA BrushX
  STA $0207


; this is for changin paint color, put in every line from now on
LDA $0206
CLC
ADC $0202
STA $0206

;brush stroke
LDA $0201
STA $0205





LDA #$01
STA painted1

JMP end

Havepainted1:


LDA painted2
CMP #$01
BEQ Havepainted2


;drawing 2nd sprite
  LDA BrushY
  STA $0208

  LDA BrushX
  STA $020B
; this is for changin paint color, put in every line from now on
LDA $020A
CLC
ADC $0202
STA $020A


;brush stroke
LDA $0201
STA $0209


LDA #$01
STA painted2

JMP end

Havepainted2:





LDA painted3
CMP #$01
BEQ Havepainted3


;drawing 2nd sprite
  LDA BrushY
  STA $020C

  LDA BrushX
  STA $020F
; this is for changin paint color, put in every line from now on
LDA $020E
CLC
ADC $0202
STA $020E

;brush stroke
LDA $0201
STA $020D


LDA #$01
STA painted3

JMP end

Havepainted3:







LDA painted4
CMP #$01
BEQ Havepainted4


;drawing 2nd sprite
  LDA BrushY
  STA $0210

  LDA BrushX
  STA $0213
; this is for changin paint color, put in every line from now on
LDA $0212
CLC
ADC $0202
STA $0212

;brush stroke
LDA $0201
STA $0211

LDA #$01
STA painted4

JMP end

Havepainted4:









LDA painted5
CMP #$01
BEQ Havepainted5


;drawing 2nd sprite
  LDA BrushY
  STA $0214

  LDA BrushX
  STA $0217
; this is for changin paint color, put in every line from now on
LDA $0216
CLC
ADC $0202
STA $0216

;brush stroke
LDA $0201
STA $0215

LDA #$01
STA painted5

JMP end

Havepainted5:






LDA painted6
CMP #$01
BEQ Havepainted6


;drawing 2nd sprite
  LDA BrushY
  STA $0218

  LDA BrushX
  STA $021B
; this is for changin paint color, put in every line from now on
LDA $021A
CLC
ADC $0202
STA $021A

;brush stroke
LDA $0201
STA $0219

LDA #$01
STA painted6

JMP end

Havepainted6:










LDA painted7
CMP #$01
BEQ Havepainted7


;drawing 2nd sprite
  LDA BrushY
  STA $021C

  LDA BrushX
  STA $021F
; this is for changin paint color, put in every line from now on
LDA $021E
CLC
ADC $0202
STA $021E


;brush stroke
LDA $0201
STA $021D

LDA #$01
STA painted7

JMP end

Havepainted7:






LDA painted8
CMP #$01
BEQ Havepainted8


;drawing 2nd sprite
  LDA BrushY
  STA $0220

  LDA BrushX
  STA $0223
; this is for changin paint color, put in every line from now on
LDA $0222
CLC
ADC $0202
STA $0222


;brush stroke
LDA $0201
STA $0221

LDA #$01
STA painted8

JMP end

Havepainted8:













LDA painted9
CMP #$01
BEQ Havepainted9

;drawing sprite
  LDA BrushY
  STA $0224

  LDA BrushX
  STA $0227
; this is for changin paint color, put in every line from now on
LDA $0226
CLC
ADC $0202
STA $0226

;brush stroke
LDA $0201
STA $0225

LDA #$01
STA painted9

JMP end

Havepainted9:














LDA painted10
CMP #$01
BEQ Havepainted10

;drawing sprite
  LDA BrushY
  STA $0228

  LDA BrushX
  STA $022B
; this is for changin paint color, put in every line from now on
LDA $022A
CLC
ADC $0202
STA $022A  

;brush stroke
LDA $0201
STA $0229

LDA #$01
STA painted10

JMP end

Havepainted10:







LDA painted11
CMP #$01
BEQ Havepainted11

;drawing sprite
  LDA BrushY
  STA $022C

  LDA BrushX
  STA $022F
  ; this is for changin paint color, put in every line from now on
LDA $022E
CLC
ADC $0202
STA $022E  

;brush stroke
LDA $0201
STA $022D

LDA #$01
STA painted11

JMP end

Havepainted11:









LDA painted12
CMP #$01
BEQ Havepainted12

;drawing sprite
  LDA BrushY
  STA $0230

  LDA BrushX
  STA $0233
  ; this is for changin paint color, put in every line from now on
LDA $0232
CLC
ADC $0202
STA $0232  

;brush stroke
LDA $0201
STA $0231

LDA #$01
STA painted12

JMP end

Havepainted12:














LDA painted13
CMP #$01
BEQ Havepainted13
;drawing sprite
  LDA BrushY
  STA $0234

  LDA BrushX
  STA $0237
  ; this is for changin paint color, put in every line from now on
LDA $0236
CLC
ADC $0202
STA $0236    

;brush stroke
LDA $0201
STA $0235

LDA #$01
STA painted13

JMP end
Havepainted13:





LDA painted14
CMP #$01
BEQ Havepainted14
;drawing sprite
  LDA BrushY
  STA $0238

  LDA BrushX
  STA $023B
  ; this is for changin paint color, put in every line from now on
LDA $023A
CLC
ADC $0202
STA $023A 

;brush stroke
LDA $0201
STA $0239

LDA #$01
STA painted14

JMP end
Havepainted14:









LDA painted15
CMP #$01
BEQ Havepainted15
;drawing sprite
  LDA BrushY
  STA $023C

  LDA BrushX
  STA $023F
  ; this is for changin paint color, put in every line from now on
LDA $023E
CLC
ADC $0202
STA $023E 

;brush stroke
LDA $0201
STA $023D

LDA #$01
STA painted15

JMP end
Havepainted15:









LDA painted16
CMP #$01
BEQ Havepainted16
;drawing sprite
  LDA BrushY
  STA $0240

  LDA BrushX
  STA $0243
  ; this is for changin paint color, put in every line from now on
LDA $0242
CLC
ADC $0202
STA $0242 

;brush stroke
LDA $0201
STA $0241





LDA #$01
STA painted16

JMP end
Havepainted16:










LDA painted17
CMP #$01
BEQ Havepainted17
;drawing sprite
  LDA BrushY
  STA $0244

  LDA BrushX
  STA $0247
  ; this is for changin paint color, put in every line from now on
LDA $0246
CLC
ADC $0202
STA $0246 

;brush stroke
LDA $0201
STA $0245

LDA #$01
STA painted17

JMP end
Havepainted17:





LDA painted18
CMP #$01
BEQ Havepainted18
;drawing sprite
  LDA BrushY
  STA $0248

  LDA BrushX
  STA $024B
  ; this is for changin paint color, put in every line from now on
LDA $024A
CLC
ADC $0202
STA $024A 

;brush stroke
LDA $0201
STA $0249

LDA #$01
STA painted18

JMP end
Havepainted18:














LDA painted19
CMP #$01
BEQ Havepainted19
;drawing sprite
  LDA BrushY
  STA $024C

  LDA BrushX
  STA $024F
  ; this is for changin paint color, put in every line from now on
LDA $024E
CLC
ADC $0202
STA $024E

;brush stroke
LDA $0201
STA $024D

LDA #$01
STA painted19

JMP end
Havepainted19:








LDA painted20
CMP #$01
BEQ Havepainted20
;drawing sprite
  LDA BrushY
  STA $0250

  LDA BrushX
  STA $0253
  ; this is for changin paint color, put in every line from now on
LDA $0252
CLC
ADC $0202
STA $0252

;brush stroke
LDA $0201
STA $0251

LDA #$01
STA painted20

JMP end
Havepainted20:







LDA painted21
CMP #$01
BEQ Havepainted21
;drawing sprite
  LDA BrushY
  STA $0254

  LDA BrushX
  STA $0257

   ; this is for changin paint color
LDA $0256
CLC
ADC $0202
STA $0256

;brush stroke
LDA $0201
STA $0255

LDA #$01
STA painted21

JMP end
Havepainted21:









LDA painted22
CMP #$01
BEQ Havepainted22
;drawing sprite
  LDA BrushY
  STA $0258

  LDA BrushX
  STA $025B

   ; this is for changin paint color
LDA $025A
CLC
ADC $0202
STA $025A

;brush stroke
LDA $0201
STA $0259

LDA #$01
STA painted22

JMP end
Havepainted22:




LDA painted23
CMP #$01
BEQ Havepainted23
;drawing sprite
  LDA BrushY
  STA $025C

  LDA BrushX
  STA $025F

   ; this is for changin paint color
LDA $025E
CLC
ADC $0202
STA $025E

;brush stroke
LDA $0201
STA $025D

LDA #$01
STA painted23

JMP end
Havepainted23:








LDA painted24
CMP #$01
BEQ Havepainted24
;drawing sprite
  LDA BrushY
  STA $0260

  LDA BrushX
  STA $0263

   ; this is for changin paint color
LDA $0262
CLC
ADC $0202
STA $0262  

;brush stroke
LDA $0201
STA $0261

LDA #$01
STA painted24

JMP end
Havepainted24:








LDA painted25
CMP #$01
BEQ Havepainted25
;drawing sprite
  LDA BrushY
  STA $0264

  LDA BrushX
  STA $0267

; this is for changin paint color
LDA $0266
CLC
ADC $0202
STA $0266    

;brush stroke
LDA $0201
STA $0265

LDA #$01
STA painted25

JMP end
Havepainted25:







LDA painted26
CMP #$01
BEQ Havepainted26
;drawing sprite
  LDA BrushY
  STA $0268

  LDA BrushX
  STA $026B

; this is for changin paint color
LDA $026A
CLC
ADC $0202
STA $026A  

;brush stroke
LDA $0201
STA $0269

LDA #$01
STA painted26

JMP end
Havepainted26:








LDA painted27
CMP #$01
BEQ Havepainted27
;drawing sprite
  LDA BrushY
  STA $026C

  LDA BrushX
  STA $026F

; this is for changin paint color
LDA $026E
CLC
ADC $0202
STA $026E  

;brush stroke
LDA $0201
STA $026D

LDA #$01
STA painted27

JMP end
Havepainted27:






;running into problems here




LDA painted28
CMP #$01
BEQ Havepainted28
;drawing sprite
  LDA BrushY
  STA $0270

  LDA BrushX
  STA $0273

; this is for changin paint color
LDA $0272
CLC
ADC $0202
STA $0272    

;brush stroke
LDA $0201
STA $0271

LDA #$01
STA painted28

JMP end
Havepainted28:












LDA painted29
CMP #$01
BEQ Havepainted29
;drawing sprite
  LDA BrushY
  STA $0274

  LDA BrushX
  STA $0277

; this is for changin paint color
LDA $0276
CLC
ADC $0202
STA $0276  

;brush stroke
LDA $0201
STA $0275

LDA #$01
STA painted29

JMP end
Havepainted29:





; problem end here








LDA painted30
CMP #$01
BEQ Havepainted30
;drawing sprite
  LDA BrushY
  STA $0278

  LDA BrushX
  STA $027B

; this is for changin paint color
LDA $027A
CLC
ADC $0202
STA $027A  

;brush stroke
LDA $0201
STA $0279

LDA #$01
STA painted30

JMP end
Havepainted30:






LDA painted31
CMP #$01
BEQ Havepainted31
;drawing sprite
  LDA BrushY
  STA $027C

  LDA BrushX
  STA $027F

; this is for changin paint color
LDA $027E
CLC
ADC $0202
STA $027E  

;brush stroke
LDA $0201
STA $027D

LDA #$01
STA painted31

JMP end
Havepainted31:









LDA painted32
CMP #$01
BEQ Havepainted32
;drawing sprite
  LDA BrushY
  STA $0280

  LDA BrushX
  STA $0283

; this is for changin paint color
LDA $0282
CLC
ADC $0202
STA $0282  

;brush stroke
LDA $0201
STA $0281

LDA #$01
STA painted32

JMP end
Havepainted32:













LDA painted33
CMP #$01
BEQ Havepainted33
;drawing sprite
  LDA BrushY
  STA $0284

  LDA BrushX
  STA $0287
; this is for changin paint color
LDA $0286
CLC
ADC $0202
STA $0286  

;brush stroke
LDA $0201
STA $0285

LDA #$01
STA painted33

JMP end
Havepainted33:













LDA painted34
CMP #$01
BEQ Havepainted34
;drawing sprite
  LDA BrushY
  STA $0288

  LDA BrushX
  STA $028B

; this is for changin paint color
LDA $028A
CLC
ADC $0202
STA $028A  

;brush stroke
LDA $0201
STA $0289

LDA #$01
STA painted34

JMP end
Havepainted34:











LDA painted35
CMP #$01
BEQ Havepainted35
;drawing sprite
  LDA BrushY
  STA $028C

  LDA BrushX
  STA $028F

; this is for changin paint color
LDA $028E
CLC
ADC $0202
STA $028E    

;brush stroke
LDA $0201
STA $028D

LDA #$01
STA painted35

JMP end
Havepainted35:









LDA painted36
CMP #$01
BEQ Havepainted36
;drawing sprite
  LDA BrushY
  STA $0290

  LDA BrushX
  STA $0293

; this is for changin paint color
LDA $0292
CLC
ADC $0202
STA $0292   

;brush stroke
LDA $0201
STA $0291

LDA #$01
STA painted36

JMP end
Havepainted36:









LDA painted37
CMP #$01
BEQ Havepainted37
;drawing sprite
  LDA BrushY
  STA $0294

  LDA BrushX
  STA $0297

; this is for changin paint color
LDA $0296
CLC
ADC $0202
STA $0296     

;brush stroke
LDA $0201
STA $0295

LDA #$01
STA painted37

JMP end
Havepainted37:








LDA painted38
CMP #$01
BEQ Havepainted38
;drawing sprite
  LDA BrushY
  STA $0298

  LDA BrushX
  STA $029B

; this is for changin paint color
LDA $029A
CLC
ADC $0202
STA $029A     

;brush stroke
LDA $0201
STA $0299

LDA #$01
STA painted38

JMP end
Havepainted38:







LDA painted39
CMP #$01
BEQ Havepainted39
;drawing sprite
  LDA BrushY
  STA $029C

  LDA BrushX
  STA $029F

; this is for changin paint color
LDA $029E
CLC
ADC $0202
STA $029E  

;brush stroke
LDA $0201
STA $029D

LDA #$01
STA painted39

JMP end
Havepainted39:




LDA painted40
CMP #$01
BEQ Havepainted40
;drawing sprite
  LDA BrushY
  STA $02A0

  LDA BrushX
  STA $02A3

; this is for changin paint color
LDA $02A2
CLC
ADC $0202
STA $02A2  

;brush stroke
LDA $0201
STA $02A1

LDA #$01
STA painted40

JMP end
Havepainted40:








LDA painted41
CMP #$01
BEQ Havepainted41
;drawing sprite
  LDA BrushY
  STA $02A4

  LDA BrushX
  STA $02A7
; this is for changin paint color
LDA $02A6
CLC
ADC $0202
STA $02A6  

;brush stroke
LDA $0201
STA $02A5

LDA #$01
STA painted41

JMP end
Havepainted41:






LDA painted42
CMP #$01
BEQ Havepainted42
;drawing sprite
  LDA BrushY
  STA $02A8

  LDA BrushX
  STA $02AB

; this is for changin paint color
LDA $02AA
CLC
ADC $0202
STA $02AA  

;brush stroke
LDA $0201
STA $02A9

LDA #$01
STA painted42

JMP end
Havepainted42:








LDA painted43
CMP #$01
BEQ Havepainted43
;drawing sprite
  LDA BrushY
  STA $02AC

  LDA BrushX
  STA $02AF

; this is for changin paint color
LDA $02AE
CLC
ADC $0202
STA $02AE  

;brush stroke
LDA $0201
STA $02AD

LDA #$01
STA painted43

JMP end
Havepainted43:








LDA painted44
CMP #$01
BEQ Havepainted44
;drawing sprite
  LDA BrushY
  STA $02B0

  LDA BrushX
  STA $02B3

; this is for changin paint color
LDA $02B2
CLC
ADC $0202
STA $02B2  

;brush stroke
LDA $0201
STA $02B1

LDA #$01
STA painted44

JMP end
Havepainted44:








LDA painted45
CMP #$01
BEQ Havepainted45
;drawing sprite
  LDA BrushY
  STA $02B4

  LDA BrushX
  STA $02B7

; this is for changin paint color
LDA $02B6
CLC
ADC $0202
STA $02B6  

;brush stroke
LDA $0201
STA $02B5

LDA #$01
STA painted45

JMP end
Havepainted45:








LDA painted46
CMP #$01
BEQ Havepainted46
;drawing sprite
  LDA BrushY
  STA $02B8

  LDA BrushX
  STA $02BB

; this is for changin paint color
LDA $02BA
CLC
ADC $0202
STA $02BA   

;brush stroke
LDA $0201
STA $02B9

LDA #$01
STA painted46

JMP end
Havepainted46:











LDA painted47
CMP #$01
BEQ Havepainted47
;drawing sprite
  LDA BrushY
  STA $02BC

  LDA BrushX
  STA $02BF

; this is for changin paint color
LDA $02BE
CLC
ADC $0202
STA $02BE   

;brush stroke
LDA $0201
STA $02BD

LDA #$01
STA painted47

JMP end
Havepainted47:








LDA painted48
CMP #$01
BEQ Havepainted48
;drawing sprite
  LDA BrushY
  STA $02C0

  LDA BrushX
  STA $02C3

; this is for changin paint color
LDA $02C2
CLC
ADC $0202
STA $02C2   

;brush stroke
LDA $0201
STA $02C1

LDA #$01
STA painted48

JMP end
Havepainted48:

















LDA painted49
CMP #$01
BEQ Havepainted49
;drawing sprite
  LDA BrushY
  STA $02C4

  LDA BrushX
  STA $02C7

; this is for changin paint color
LDA $02C6
CLC
ADC $0202
STA $02C6  

;brush stroke
LDA $0201
STA $02C5

LDA #$01
STA painted49

JMP end
Havepainted49:








LDA painted50
CMP #$01
BEQ Havepainted50
;drawing sprite
  LDA BrushY
  STA $02C8

  LDA BrushX
  STA $02CB

; this is for changin paint color
LDA $02CA
CLC
ADC $0202
STA $02CA 

;brush stroke
LDA $0201
STA $02C9

LDA #$01
STA painted50

JMP end
Havepainted50:










LDA painted51
CMP #$01
BEQ Havepainted51
;drawing sprite
  LDA BrushY
  STA $02CC

  LDA BrushX
  STA $02CF

; this is for changin paint color
LDA $02CE
CLC
ADC $0202
STA $02CE 

;brush stroke
LDA $0201
STA $02CD

LDA #$01
STA painted51

JMP end
Havepainted51:













LDA painted52
CMP #$01
BEQ Havepainted52
;drawing sprite
  LDA BrushY
  STA $02D0

  LDA BrushX
  STA $02D3

; this is for changin paint color
LDA $02D2
CLC
ADC $0202
STA $02D2 

;brush stroke
LDA $0201
STA $02D1

LDA #$01
STA painted52

JMP end
Havepainted52:





LDA painted53
CMP #$01
BEQ Havepainted53
;drawing sprite
  LDA BrushY
  STA $02D4

  LDA BrushX
  STA $02D7

; this is for changin paint color
LDA $02D6
CLC
ADC $0202
STA $02D6 

;brush stroke
LDA $0201
STA $02D5

LDA #$01
STA painted53

JMP end
Havepainted53:










LDA painted54
CMP #$01
BEQ Havepainted54
;drawing sprite
  LDA BrushY
  STA $02D8

  LDA BrushX
  STA $02DB

; this is for changin paint color
LDA $02DA
CLC
ADC $0202
STA $02DA 

;brush stroke
LDA $0201
STA $02D9

LDA #$01
STA painted54

JMP end
Havepainted54:









LDA painted55
CMP #$01
BEQ Havepainted55
;drawing sprite
  LDA BrushY
  STA $02DC

  LDA BrushX
  STA $02DF

; this is for changin paint color
LDA $02DE
CLC
ADC $0202
STA $02DE   

;brush stroke
LDA $0201
STA $02DD

LDA #$01
STA painted55

JMP end
Havepainted55:











LDA painted56
CMP #$01
BEQ Havepainted56
;drawing sprite
  LDA BrushY
  STA $02E0

  LDA BrushX
  STA $02E3

 ; this is for changin paint color
LDA $02E2
CLC
ADC $0202
STA $02E2    

;brush stroke
LDA $0201
STA $02E1

LDA #$01
STA painted56

JMP end
Havepainted56:









LDA painted57
CMP #$01
BEQ Havepainted57
;drawing sprite
  LDA BrushY
  STA $02E4

  LDA BrushX
  STA $02E7

 ; this is for changin paint color
LDA $02E6
CLC
ADC $0202
STA $02E6     

;brush stroke
LDA $0201
STA $02E5

LDA #$01
STA painted57

JMP end
Havepainted57:












LDA painted58
CMP #$01
BEQ Havepainted58
;drawing sprite
  LDA BrushY
  STA $02E8

  LDA BrushX
  STA $02EB

 ; this is for changin paint color
LDA $02EA
CLC
ADC $0202
STA $02EA      

;brush stroke
LDA $0201
STA $02E9

LDA #$01
STA painted58

JMP end
Havepainted58:








LDA painted59
CMP #$01
BEQ Havepainted59
;drawing sprite
  LDA BrushY
  STA $02EC

  LDA BrushX
  STA $02EF

 ; this is for changin paint color
LDA $02EE
CLC
ADC $0202
STA $02EE    

;brush stroke
LDA $0201
STA $02ED

LDA #$01
STA painted59

JMP end
Havepainted59:







LDA painted60
CMP #$01
BEQ Havepainted60
;drawing sprite
  LDA BrushY
  STA $02F0

  LDA BrushX
  STA $02F3

 ; this is for changin paint color
LDA $02F2
CLC
ADC $0202
STA $02F2     

;brush stroke
LDA $0201
STA $02F1

LDA #$01
STA painted60

JMP end
Havepainted60:






LDA painted61
CMP #$01
BEQ Havepainted61
;drawing sprite
  LDA BrushY
  STA $02F4

  LDA BrushX
  STA $02F7

 ; this is for changin paint color
LDA $02F6
CLC
ADC $0202
STA $02F6     

;brush stroke
LDA $0201
STA $02F5

LDA #$01
STA painted61

JMP end
Havepainted61:



LDA painted62
CMP #$01
BEQ Havepainted62
;drawing sprite
  LDA BrushY
  STA $02F8

  LDA BrushX
  STA $02FB

 ; this is for changin paint color
LDA $02FA
CLC
ADC $0202
STA $02FA     

;brush stroke
LDA $0201
STA $02F9

LDA #$01
STA painted62

JMP end
Havepainted62:



end: 


Sound:
LDA #%00001000       ; Bit 3 set = enable noise channel
STA $4015
    
LDA #$34       ; Volume 4, Envelope disabled, decay rate fast

STA $400C            ; Write to Noise Envelope/Volume register

LDA #%00100000       ; Frequency index = $23 (higher frequency for sharpness)

STA $400E            ; Write to Noise Period register

LDA #%00001000       ; Load length counter (short duration)
STA $400F            ; Writing to $400F also resets envelope and length counter



RTS
















ChangeColor:

LDA $0202
CLC
ADC #$01
STA $0202


RTS



ChangeBrush:

LDA $0201
CLC
ADC #$04
STA $0201

RTS







changeBG:
LDA #%00000000
    STA $2001        ; disable rendering

loadbackground2:
    LDA $2002               ; read PPU status to reset the high/low latch
    LDA #$20
    STA $2006               ; write high byte of $2000 address
    LDA #$00
    STA $2006               ; write low byte of $2000 address

    LDA #<background2
    STA pointerLo           ; put the low byte of address of background into pointer
    LDA #>background2       ; #> is the same as HIGH() function in NESASM, used to get the high byte
    STA pointerHi           ; put high byte of address into pointer

    LDX #$00                ; start at pointer + 0
    LDY #$00
outsideloop2:

insideloop2:
    LDA (pointerLo),Y       ; copy one background byte from address in pointer + Y
    STA $2007               ; runs 256*4 times

    INY                     ; inside loop counter
    CPY #$00                
    BNE insideloop2          ; run inside loop 256 times before continuing

    INC pointerHi           ; low byte went from 0 -> 256, so high byte needs to be changed now

    INX                     ; increment outside loop counter
    CPX #$04                ; needs to happen $04 times, to copy 1KB data
    BNE outsideloop2         


    CLI 
    LDA #%10010000  ; enable NMI, sprites from pattern table 0, background from 1
    STA $2000
    LDA #%00011110  ; background and sprites enable, no left clipping
    STA $2001


RTS






TitleMusic:
 lda #$00
sta $4015


LDA firststloopdone
CMP #$01
BEQ nextsong


JSR StartTimer

nextsong:

LDA firststloopdone
CMP #$00
BEQ firstsong

JSR StartTimer2
firstsong:

RTI

StartTimer: ;this timer increments km counter
    ; Increment frame delay counter
    LDA FrameDelayCounter
    CLC
    ADC #1
    STA FrameDelayCounter

    CMP #$08             ; wait ~32 frames (adjust as needed)
    BNE SkipTimerInc     ; not yet time to increment

    ; Reset frame delay
    LDA #$00
    STA FrameDelayCounter

    ; Load current timer value
    LDA TimerCounter
    CMP #$02
    BEQ TimerDone        ; If timer == 9, jump to done routine

    ; Increment timer
    CLC
    ADC #1
    STA TimerCounter

   LDA #%00001000       ; Bit 3 set = enable noise channel
  STA $4015

; Configure Noise Channel Envelope
  LDA #%00110100       ; Volume 4, Envelope disabled, decay rate fast
                         ; Bit 7 = 0 (disable envelope)
                         ; Bit 6 = 1 (constant volume)
                         ; Bit 5-0 = 4 (volume)
  STA $400C            ; Write to Noise Envelope/Volume register

; Configure Noise Frequency
  LDA Note2       ; Frequency index = $23 (higher frequency for sharpness)
                         ; Bit 7 = 0 (non-looping random noise)
                         ; Bits 4-0 = $23 (frequency index)
  STA $400E            ; Write to Noise Period register

; Restart the length counter
  LDA #%00001000       ; Load length counter (short duration)
  STA $400F            ; Writing to $400F also resets envelope and length counter

 INC Note2


SkipTimerInc:
    RTS

TimerDone:
    ; Call your subroutine here
    JSR TimerReachedNine
    RTS


TimerReachedNine:

  LDA #$00
  STA TimerCounter

lda #%00000111  ;enable Sq1, Sq2 and Tri channels
    sta $4015
 
 
;Triangle
lda Note  ;Triangle channel on
sta $4008
lda #$DF        ;$042 is a G# in NTSC mode
sta $400A
lda #$00
sta $400B
INC Note





LDA #$01
STA firststloopdone


RTS



StartTimer2: ;this timer increments km counter
    ; Increment frame delay counter
    LDA FrameDelayCounter2
    CLC
    ADC #1
    STA FrameDelayCounter2

    CMP #$08             ; wait ~32 frames (adjust as needed)
    BNE SkipTimerInc2     ; not yet time to increment

    ; Reset frame delay
    LDA #$00
    STA FrameDelayCounter2

    ; Load current timer value
    LDA TimerCounter2
    CMP #$02
    BEQ TimerDone2        ; If timer == 9, jump to done routine

    ; Increment timer
    CLC
    ADC #1
    STA TimerCounter2

   LDA #%00001000       ; Bit 3 set = enable noise channel
  STA $4015

; Configure Noise Channel Envelope
  LDA #%00110100       ; Volume 4, Envelope disabled, decay rate fast
                         ; Bit 7 = 0 (disable envelope)
                         ; Bit 6 = 1 (constant volume)
                         ; Bit 5-0 = 4 (volume)
  STA $400C            ; Write to Noise Envelope/Volume register

; Configure Noise Frequency
  LDA Note2       ; Frequency index = $23 (higher frequency for sharpness)
                         ; Bit 7 = 0 (non-looping random noise)
                         ; Bits 4-0 = $23 (frequency index)
  STA $400E            ; Write to Noise Period register

; Restart the length counter
  LDA #%00001000       ; Load length counter (short duration)
  STA $400F            ; Writing to $400F also resets envelope and length counter

 INC Note2


SkipTimerInc2:
    RTS

TimerDone2:
    ; Call your subroutine here
    JSR TimerReachedNine2
    RTS


TimerReachedNine2:

  LDA #$00
  STA TimerCounter2


lda #%00000111  ;enable Sq1, Sq2 and Tri channels
    sta $4015
 
 
;Triangle
lda Note  ;Triangle channel on
sta $4008
lda #$FF        ;$042 is a G# in NTSC mode
sta $400A
lda #$00
sta $400B
INC Note



LDA #$00
STA firststloopdone

tthere:

RTS






attributetablechange:
;car HUD
  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F0
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F1
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F2
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F3
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F4
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F5
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F6
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F7
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007


;bottom row


  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F8
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$F9
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$FA
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$FB
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$FC
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$FD
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$FE
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007

  LDA #$23 ;$23C0 - 23FF
  STA $2006
  LDA #$FF
  STA $2006        ; Set PPU address to $3F00 (background color)

LDA #$FF
STA $2007





RTS








background:
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;not visible on NTSC
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24 


  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$B8,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$BA,$24,$24  

  .byte $24,$24,$C8,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$CA,$24,$24    

  .byte $24,$24,$C8,$26,$3C,$3D,$3E,$3F,$BB,$BC,$26,$26,$BD,$BE,$BB,$BC,$C4,$C5,$C6,$C7,$D0,$D1,$D2,$D3,$26,$26,$26,$26,$26,$CA,$24,$24  

  .byte $24,$24,$C8,$26,$4C,$4D,$4E,$4F,$CB,$CC,$26,$26,$CD,$CE,$CB,$CC,$D4,$D5,$D6,$D7,$E0,$E1,$D4,$D5,$26,$FD,$FE,$FF,$26,$CA,$24,$24    

  .byte $24,$24,$C8,$26,$5C,$5D,$5E,$5F,$DB,$DC,$26,$26,$DD,$DE,$DB,$DC,$E4,$E5,$E6,$E7,$F0,$F1,$E4,$E5,$26,$26,$26,$26,$26,$CA,$24,$24  

  .byte $24,$24,$C8,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$26,$CA,$24,$24    

  .byte $24,$24,$D8,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$D9,$DA,$24,$24  

  .byte $24,$24,$24,$0B,$22,$24,$1F,$0E,$0D,$1B,$0A,$17,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$02,$00,$02,$06,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$19,$1B,$0E,$1C,$1C,$24,$1C,$1D,$0A,$1B,$1D,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24    

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  






attributes:  ;8 x 8 = 64 bytes
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
  .byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101


  .byte $24,$24,$24,$24, $47,$47,$24,$24 
  .byte $47,$47,$47,$47, $47,$47,$24,$24 
  .byte $24,$24,$24,$24 ,$24,$24,$24,$24
  .byte $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms
  .byte $47,$47,$47,$47, $47,$47,$24,$24 
  .byte $24,$24,$24,$24 ,$24,$24,$24,$24
  .byte $24,$24,$24,$24, $55,$56,$24,$24 



palette:
.byte $21,$1A,$30,$17,  $21,$2A,$1B,$17,  $21,$1A,$11,$17,  $21,$1A,$30,$17
.byte $21,$1C,$35,$17,  $31,$15,$38,$1A,  $0F,$28,$24,$02,  $31,$16,$22,$3C











background2:
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;not visible on NTSC
  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  


  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$9A,$9B,$9C,$9D,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$9A,$9B,$9C,$9D,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$AA,$AB,$AC,$AD,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$AA,$AB,$AC,$AD,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$8A,$8B,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$8C,$8D,$8E,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24 

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$8C,$8D,$8E,$24,$24,$24,$24,$24,$24,$24,$24 

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$8A,$8B,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24 

  .byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$A7,$B7  

  .byte $A7,$A6,$24,$24,$24,$24,$A0,$A0,$24,$24,$A7,$A6,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$80,$25,$25  

  .byte $25,$25,$91,$25,$38,$37,$A0,$A0,$39,$90,$25,$25,$B3,$38,$37,$37,$36,$26,$26,$26,$26,$26,$26,$26,$26,$26,$35,$37,$90,$25,$25,$25  

  .byte $25,$25,$25,$25,$25,$25,$A0,$A0,$25,$25,$25,$25,$25,$B4,$B5,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$90,$25,$25,$25,$25  

  .byte $25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$BF,$25,$25,$25,$25,$25,$25,$25,$25,$AF  

  .byte $25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$25,$B5,$25,$25,$25,$25,$25,$25,$76,$77,$78,$25,$87,$77,$77,$25,$25,$25,$B0,$25  

  .byte $25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$C0,$25,$25,$B3,$25,$25,$25,$25,$85,$88,$85,$84,$85,$86,$85,$25,$25,$25,$B0,$25,$25  

  .byte $B5,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$C0,$25,$25,$B4,$25,$25,$25,$25,$85,$BF,$9F,$76,$25,$25,$25,$25,$B0,$25,$25,$25

  .byte $25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$25,$C0,$25,$25,$25,$25,$9F,$25,$25,$25,$25,$25,$25,$25,$B2,$B1,$25,$25,$25,$25

  .byte $C0,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$25,$25,$C0,$25,$25,$25,$25,$25,$25,$AE,$9F,$25,$25,$25,$25,$25,$25,$B0,$25,$25

  .byte $25,$C1,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$25,$25,$25,$C1,$C2,$25,$25,$AF,$25,$25,$25,$25,$25,$25,$25,$25,$B2,$25,$25,$25

  .byte $25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$25,$25,$25,$25,$25,$25,$25,$9F,$9E,$CF,$9E,$9F,$AE,$25,$25,$B2,$25,$25,$25,$25

  .byte $25,$25,$25,$26,$26,$26,$26,$26,$26,$26,$26,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25

  .byte $25,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$48,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25

  .byte $96,$97,$96,$97,$A2,$27,$A0,$A0,$27,$A3,$97,$96,$97,$96,$97,$96,$97,$96,$97,$96,$97,$96,$97,$96,$97,$96,$97,$96,$97,$96,$97,$96

  .byte $25,$25,$25,$A2,$27,$A5,$A0,$A0,$A4,$27,$A3,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25

  .byte $25,$25,$A2,$27,$A5,$25,$A0,$A0,$25,$A4,$27,$A3,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$97,$25,$25,$25,$25,$25,$25,$25,$25

  .byte $25,$A2,$27,$A5,$25,$25,$A0,$A0,$25,$25,$A4,$27,$A3,$25,$25,$96,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25

  .byte $A2,$27,$A5,$25,$25,$25,$A0,$A0,$25,$25,$25,$A4,$27,$A3,$25,$25,$25,$25,$25,$97,$96,$25,$25,$25,$25,$25,$25,$96,$25,$25,$25,$25

  .byte $27,$A5,$25,$25,$25,$25,$A0,$A0,$25,$96,$97,$25,$A4,$27,$A3,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25




attributes2:  ;8 x 8 = 64 bytes
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00001010, %00001010, %10101010, %10101010, %00001010, %00001010, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
  .byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101


  .byte $24,$24,$24,$24, $47,$47,$24,$24 
  .byte $47,$47,$47,$47, $47,$47,$24,$24 
  .byte $24,$24,$24,$24 ,$24,$24,$24,$24
  .byte $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms
  .byte $47,$47,$47,$47, $47,$47,$24,$24 
  .byte $24,$24,$24,$24 ,$24,$24,$24,$24
  .byte $24,$24,$24,$24, $55,$56,$24,$24 



palette2:
.byte $21,$1A,$30,$17,  $21,$2A,$1B,$17,  $21,$1A,$11,$17,  $21,$1A,$30,$17
.byte $21,$1C,$35,$17,  $31,$15,$38,$1A,  $0F,$28,$24,$02,  $31,$16,$22,$3C

sprites:
     ;vert tile attr horiz
  .byte $80, $00, $00, $40   ;sprite 0


  sprites2:
     ;vert tile attr horiz
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF   
  .byte $FF, $00, $00, $FF  
  .byte $FF, $00, $00, $FF  

 .segment "CHARS"
    .incbin "ArtStudio.chr"        ; Includes the 8 KB CHR-ROM graphics file
  


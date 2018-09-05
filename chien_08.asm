; Jarrett Chien
; This program is a snake game with a multicolor food particle (referred to as apple)

; define various parts of snake to corresponding memory locations
define snakeHeadL     $10 
define snakeHeadH     $11  
define snakeBodyStart $12 
define snakeLength    $03 
define direction      $02
define upDir          $77
define leftDir        $61
define downDir        $73
define rightDir       $64
define lastKey        $FF
define randomLocation $FE ; Random location is for apple placement
define appleLoByte	  $04
define appleHiByte    $05
 
JSR init
JSR initApple
JSR gameLoop
BRK
  
init:
  LDA #$0A  ; Snake will travel down this horizontal line starting at $020A
  STA snakeHeadL 
  LDA #$02
  STA snakeHeadH
  LDA #$01
  STA snakeBodyStart
  LDA #$04  ; Snake starts with a length of 2 bytes
  STA snakeLength
  LDA #downDir
  STA direction ; Snake starts off going down
  RTS

initApple:
	LDA $FE 
	STA appleLoByte
	LDA $FE
	AND #$03 ; We AND with 3 to get a value between 00 and 03. "Masking" with 03
	CLC
	ADC #$02 ; Then we add 02 to that to get a value between 02 and 05 for the high byte
	STA appleHiByte
	RTS
	
gameLoop:
  JSR readKeys
  JSR checkCollision
  JSR checkSnakeCollision
  JSR drawApple
  JSR drawSnake
  JSR updateSnake 
  JSR slowDown
  
  JMP gameLoop
  
updateSnake:
  LDX snakeLength  ; Decrement the length of the snake. We want an even value to shift over
  DEX
   
shiftValues: 
  LDA snakeHeadL, X  ; Load A register with value at snakeHeadL + (snakeLength - 1)
  STA snakeBodyStart, X ; Store the loaded value at snakeBodyStart + (snakeLength - 1)
  DEX
  BPL shiftValues ; keep branching as long as snakeLength is positive

; Moves snake down a row by adding 0x20 to HeadL
incHeadLow:
  LDA direction
  CMP #upDir
  BEQ goUp
  CMP #rightDir
  BEQ goRight
  CMP #downDir
  BEQ goDown
  CMP #leftDir
  BEQ goLeft
  RTS
  
 ; Increments HeadH once we reach end of 0200 
 ; For moving down the screen
incHeadHi:
  LDA snakeHeadH
  CLC
  ADC #$01
  STA snakeHeadH
  JSR gameCheck
  RTS
  
 ; For moving up the screen
decHeadHi:
  LDA snakeHeadH
  SEC
  SBC #$01
  STA snakeHeadH
  JSR gameCheck
  RTS

  ; End program if snakeHeadH reaches 0600 memory 
gameCheck:
  CMP #$06
  BEQ collidedWithSelf ; Using collidedWithSelf to end program because end subroutine is too far
  CMP #$01
  BEQ collidedWithSelf
  RTS
  
 ; NOP to slow down the speed of the snake 
setslowDown:
  LDX #$FF
 
slowDown:
  NOP
  DEX
  BNE slowDown
  
checkCollision:
  LDA appleLoByte
  CMP snakeHeadL ; compare the location of apple to location of hi/lo byte of snake
  BNE returnToGame ; if it is equal, then we increase snake's length by 2 (1 segment)
  LDA appleHiByte  ; if it is not equal, then just return to the game
  CMP snakeHeadH
  BNE returnToGame
  INC snakeLength
  INC snakeLength
  JSR initApple ; make a new apple in a different place
  RTS
  
checkSnakeCollision:
  LDX #$00
  LDA (snakeHeadL, X)  ; The value in memory at snakeHeadL will be the color of the snake
  CMP #$03
  BEQ collidedWithSelf ; If the color matches, then the player has lost
  RTS
  
returnToGame:
	RTS
	
collidedWithSelf: ; Using this because end subroutine is too far
	BRK
	
drawApple: ; Uses a random value to give the apple color
	LDY #$00
	LDA $FE
	CMP #$03 ; Should only draw the apple if the color is not the same as the snake's color
	BNE placeApple
	RTS

placeApple:
	STA (appleLoByte), Y 
	RTS
	
drawSnake:
  LDX snakeLength
  LDA #$00
  STA (snakeHeadL, X) ; Give appearance of snake moving down by erasing behind it
  LDX #$00 
  LDA #$03 
  STA (snakeHeadL, X)
  RTS
 
 ; goXXXX subroutines move the snake in the respective direction
goDown:
  LDA snakeHeadL
  CLC ; Make sure carry flag is not set before ADC
  ADC #$20 ; Move down exactly 1 row
  STA snakeHeadL
  BCS incHeadHi
  RTS
  
goRight:
  JSR checkCollisionR ; We check here so user has time to react before actually hitting the side
  LDA snakeHeadL
  CLC ; Make sure carry flag is not set before ADC
  ADC #$01 ; Move right one pixel
  STA snakeHeadL
  RTS
  
goUp:
  LDA snakeHeadL
  SEC ; Set the carry before subtracting
  SBC #$20 ; Move up exactly 1 row
  STA snakeHeadL
  BCC decHeadHi ; Decrement snakeHeadH when necessary
  RTS
  
goLeft:
  JSR checkCollisionL
  LDA snakeHeadL
  SEC
  SBC #$01 ; Move left one pixel
  STA snakeHeadL
  RTS

 ; Check the value in direction vs stored values for directions and go to respective subroutines if value is same
readKeys:
  LDA direction
  CMP #downDir
  BEQ down
  CMP #rightDir
  BEQ right
  CMP #upDir
  BEQ up
  CMP #leftDir
  BEQ left
  RTS
  
 ; Following direction subroutines check if user is trying to double back on the snake
 ; For example, if user is going down, user cannot go up. 
 ; We check the opposite direction and branch if it is not that direction
down:
  LDA lastKey
  CMP #upDir
  BNE updateDir
  RTS
  
up:
  LDA lastKey
  CMP #downDir
  BNE updateDir
  RTS
  
left:
  LDA lastKey
  CMP #rightDir
  BNE updateDir
  RTS
  
right:
  LDA lastKey
  CMP #leftDir
  BNE updateDir
  RTS

 ; We compare the last key press after verifying input
 ; Will branch to a subroutine that updates direction variable for respective direction
updateDir:
  LDA lastKey
  CMP #upDir
  BEQ updateUp
  CMP #rightDir
  BEQ updateRight
  CMP #downDir
  BEQ updateDown
  CMP #leftDir
  BEQ updateLeft
  RTS
 
 ; updateXXXX will store the ASCII value for the respective direction in direction variable
updateUp:
  LDA #upDir
  STA direction
  RTS

updateRight:
  LDA #rightDir
  STA direction
  RTS 
  
updateDown:
  LDA #downDir
  STA direction
  RTS

updateLeft:
  LDA #leftDir
  STA direction
  RTS
 
 ; We know that the last value on right side of screen will be an odd number and F (i.e. 1F, 3F, 5F, etc.)
 ; Using AND #$1F will let us know if the value we AND with is odd or not
 ; We compare with 1F and if the value is odd, the user has reached the end of the right side of the screen.
checkCollisionR:
  LDA snakeHeadL
  AND #$1F
  CMP #$1F
  BEQ end
  RTS
  
 ; Same as checkCollisionR except the value on the left side will always be even.
 ; If the value is even, then the user has reached the end of the left side of the screen.
checkCollisionL:
  LDA snakeHeadL
  AND #$1F
  CMP #$00
  BEQ end
  RTS
   
end:
  BRK
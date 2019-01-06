############################## Reversi ##############################
# 			    BITMAP SETUP			    #
# Bitmap Display Setup                                              #
# Unit Width in Pixels: 8                                           #
# Unit Height in Pixels: 8                                          #
# Display Width in Pixels: 512                                      #
# Display Height in Pixels: 512                                     #
# Base address for display: 0x1000080000 ($gp)                      #
#####################################################################
# 			GAMEPLAY DIRECTIONS:			    #
# Game will prompt user to enter integers for rows and columns. To  #
# place a piece, enter any numbers from 0 to 7 for both row and     #
# column to specify coordinates.				    #
# 								    #
# To resign or end the game, enter 10 in any of the prompts. Note   #
# that in multiplayer, resignation is only allowed if the player is #
# losing.							    #
#####################################################################

.data

#Game Core information

#Screen 
screenWidth: 	.word 64
screenHeight: 	.word 64

#Colors
backgroundColor:.word	0x008000	 # green
borderColor:    .word	0x000000	 # black	
whitePiece: 	.word	0xffffff	 # white
blackPiece: 	.word	0x000000	 # black

#array to store the scores in which difficulty should increase
scoreMilestones: .word 100, 250, 500, 1000, 5000, 10000
scoreArrayPosition: .word 0

#prompting players turn
player1Row:	.asciiz "Player 1, select the row that you want to place your piece: "
player1Col:	.asciiz "Player 1, select the column that you want to place your piece: "
player2Row:	.asciiz "Player 2, select the position you want to place your piece: "
player2Col:	.asciiz "Player 2, select the column that you want to place your piece: "

#game message
intro:		.asciiz "Welcome to Reversi. Would you like to play with an AI?"
player1Win:	.asciiz "            Player 1 wins"
player2Win:	.asciiz "            Player 2 wins"
AIWin:		.asciiz "                 AI Wins"
gameOver:	.asciiz "                             Game Over"
lostMessage:	.asciiz "You have died.... Your score was: "
displayP1Score:	.asciiz "Player 1 score:     "
displayP2Score:	.asciiz "Player 2 score:     "
replayMessage:	.asciiz "Would you like to replay?"

#scoreboard
player1Score:	.word 0
player2Score:	.word 0

#error prompts
error0:		.asciiz "\nERROR: Invalid move. Please select a valid coordinate.\n"
#error1:		.asciiz "Error: Invalid input."
#error2:		.asciiz "Error: A piece already exists at the specified coordinate."
#error3:		.asciiz "Error: Piece must be placed adjacent to a piece of opposite colors"

debugger:	.asciiz "DEBUG"

newline:	.asciiz "\n"

row:          	.word       # Row value
col:          	.word       # Column value

#color code matrix
colorCodeMatrix: .word 0, 0, 0, 0, 0, 0, 0, 0
		 .word 0, 0, 0, 0, 0, 0, 0, 0
		 .word 0, 0, 0, 0, 0, 0, 0, 0
		 .word 0, 0, 0, 0, 0, 0, 0, 0
		 .word 0, 0, 0, 0, 0, 0, 0, 0
		 .word 0, 0, 0, 0, 0, 0, 0, 0
		 .word 0, 0, 0, 0, 0, 0, 0, 0
		 .word 0, 0, 0, 0, 0, 0, 0, 0
		
matrixSize:	 .word 8
.eqv DATA_SIZE 4

#this array stores the screen coordinates of a direction change
#once the tail hits a position in this array, its direction is changed
#this is used to have the tail follow the head correctly
directionChangeAddressArray:	.word 0:100
#this stores the new direction for the tail to move once it hits
#an address in the above array
newDirectionChangeArray:	.word 0:100
#stores the position of the end of the array (multiple of 4)
arrayPosition:			.word 0
locationInArray:		.word 0



.text

main:
	addi $sp, $sp, -24	# make room on stack (to be primarily used for return addresses)
######################################################
# Fill Screen to Black, for reset
######################################################
	lw $a0, screenWidth
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 #total number of pixels on screen
	mul $a2, $a2, 4 #align addresses
	add $a2, $a2, $gp #add base of gp
	add $a0, $gp, $zero #loop counter
FillLoop:
	beq $a0, $a2, Init
	sw $a1, 0($a0) #store color
	addiu $a0, $a0, 4 #increment counter
	j FillLoop

######################################################
# Initialize/Reset matrix
######################################################
Init:
	
resetMatrix:
	li $t1, 0	#row
	li $t2, 0	#col
	li $t6, 0	#reset
	li $t7, 7	#boundary
	
	PrintMatrix:
	move $a0, $t1
	move $a1, $t2
	jal MatrixElementAddress
	sw $t6,($t3)
	jal MatrixElementAddress
	addi $t2, $t2, 1
	bgt $t2, $t7, MatrixJump1
	j PrintMatrix
	MatrixJump1:
	addi $t1, $t1, 1
	addi $t2, $zero, 0
	bgt $t1, $t7, MatrixJump2
	j PrintMatrix
	MatrixJump2:	

######################################################
# Initialize Variables
######################################################
ClearRegisters:

	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0		

######################################################
# Draw Border
######################################################

DrawBorder:
	li $t2, 0
	li $t1, 0	#load Y coordinate for the left border
	VerticalLoop:
	move $a1, $t1	#move y coordinate into $a1
	move $a0, $t2
	#li $a0, 8	# load x direction to 0, doesnt change
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0	# move screen coordinates into $a0
	lw $a1, borderColor	#move color code into $a1
	jal DrawPixel	#draw the color at the screen location
	add $t1, $t1, 1	#increment y coordinate
	
	bne $t1, 64, VerticalLoop	#loop through to draw entire left border
	li $t1, 0
	add $t2, $t2, 8
	ble $t2, 64, VerticalLoop
	
	li $t2, 0
	li $t1, 0	#load X coordinate for top border
	HorizontalLoop:
	move $a0, $t1	# move x coordinate into $a0
	move $a1, $t2
	#li $a1, 0	# set y coordinate to zero for top of screen
	jal CoordinateToAddress	#get screen coordinate
	move $a0, $v0	#  move screen coordinates to $a0
	lw $a1, borderColor	# store color data to $a1
	jal DrawPixel	#draw color at screen coordinates
	add $t1, $t1, 1 #increment X position
	
	bne $t1, 64, HorizontalLoop #loop through to draw entire top border
	li $t1, 0
	addi $t2, $t2, 8
	ble $t2, 64, HorizontalLoop
	
######################################################
# Initialize board pieces
######################################################
SetWhitePiece1:	
	#li $t2, 26
	#li $t1, 26	#load Y coordinate for the left border
	li $t2, 3
	li $t1, 3	#load Y coordinate for the left border
	jal StoreWhitePiece
	jal PixelCoord
	jal DrawWhitePiece

	li $t2, 4
	li $t1, 4	#load Y coordinate for the left border
	jal StoreWhitePiece
	jal PixelCoord
	jal DrawWhitePiece

SetBlackPiece1:	
	li $t2, 4
	li $t1, 3	#load Y coordinate for the left border
	jal StoreBlackPiece
	jal PixelCoord
	jal DrawBlackPiece
	
	li $t2, 3
	li $t1, 4	#load Y coordinate for the left border
	jal StoreBlackPiece
	jal PixelCoord
	jal DrawBlackPiece	
	
	jal CalculateP1Score
	jal CalculateP2Score

######################################################
# Intro
######################################################
SelectGamemode:
	li $v0, 50 #syscall for yes/no dialog
	la $a0, intro #get message
	syscall
	beqz $a0, Singleplayer
	j Multiplayer		

######################################################
# Singleplayer inputs
######################################################
Singleplayer:
	##### Player 1 #####
	PromptSinglePlayer:    	#Prompt Player 1 for row value
    	li $v0, 4          	
   	la $a0, player1Row      
   	syscall
	
	#Read first integer
    	li $v0, 5
    	la $t1, row    
    	syscall
    	
    	#Store row into the memory
    	move    $t1, $v0
    	
    	#lw $t6, player1Score
    	#lw $t7, player2Score
    	#beq $t1, 10, checkSingleP1Resign1
    	#j skipSingleP1Resign1
    	#checkSingleP1Resign1:
    	#bge $t6, $t7 singleP1DisplayError
    	#j Exit
    	#skipSingleP1Resign1:
    	
    	beq $t1, 10, ExitSingle
    	
	#Prompt Player 1 for column value
    	li $v0, 4          	
   	la $a0, player1Col     
   	syscall
	
	#Read first integer
    	li $v0, 5      
    	la $t2, col    
    	syscall
    	
    	#Store row into the memory
    	move    $t2, $v0
    	
    	#lw $t6, player1Score
    	#lw $t7, player2Score
    	#beq $t1, 10, checkSingleP1Resign2
    	#j skipSingleP1Resign2
    	#checkSingleP1Resign2:
    	#bge $t6, $t7 singleP1DisplayError
    	#j Exit
    	#skipSingleP1Resign2:
    	
    	beq $t1, 10, ExitSingle
    	
    	jal CheckSingleP1
    	move $t1, $s1
    	move $t2, $s2
    	jal StoreBlackPiece
    	jal PixelCoord
    	jal DrawBlackPiece
    	
    	# Calculate Score midgame
    	jal CalculateP1Score
    	jal CalculateP2Score
    	
    	li $v0, 4          	
   	la $a0, newline      
   	syscall   
   	
   	# play sound to signify score update
	li $v0, 31
	li $a0, 79
	li $a1, 150
	li $a2, 7
	li $a3, 127
	syscall	
	
	li $a0, 96
	li $a1, 250
	li $a2, 7
	li $a3, 127
	syscall	
	
    	##### AI #####
    	PromptAI:
    	li $t1, 0
    	li $t2, 0
    	
    	# DEBUG #
    	#li $v0, 1
    	#move $a0, $t1
    	#syscall
    	
    	AINext:
    	jal CheckAI
    	move $t1, $s1
    	move $t2, $s2
    	jal StoreWhitePiece
    	jal PixelCoord
    	jal DrawWhitePiece
    	
    	move $t1, $s1
    	move $t2, $s2
    	
    	
    	
    	j Singleplayer
	j ExitSingle
	
######################################################
# Multiplayer inputs
######################################################
Multiplayer:
	##### Player 1 #####
	PromptPlayer1:    	#Prompt Player 1 for row value
    	li $v0, 4          	
   	la $a0, player1Row      
   	syscall
	
	#Read first integer
    	li $v0, 5
    	la $t1, row    
    	syscall
    	
    	#Store row into the memory
    	move    $t1, $v0
    	
    	lw $t6, player1Score
    	lw $t7, player2Score
    	beq $t1, 10, checkP1Resign1
    	j skipP1Resign1
    	checkP1Resign1:
    	bge $t6, $t7 P1DisplayError
    	j ExitMulti
    	skipP1Resign1:
    	
	#Prompt Player 1 for column value
    	li $v0, 4          	
   	la $a0, player1Col     
   	syscall
	
	#Read first integer
    	li $v0, 5      
    	la $t2, col    
    	syscall
    	
    	#Store row into the memory
    	move    $t2, $v0
    	
    	lw $t6, player1Score
    	lw $t7, player2Score
    	beq $t1, 10, checkP1Resign2
    	j skipP1Resign2
    	checkP1Resign2:
    	bge $t6, $t7 P1DisplayError
    	j ExitMulti
    	skipP1Resign2:
    	
    	jal CheckP1
    	move $t1, $s1
    	move $t2, $s2
    	jal StoreBlackPiece
    	jal PixelCoord
    	jal DrawBlackPiece
    	
    	# Calculate Score midgame
    	jal CalculateP1Score
    	jal CalculateP2Score
    	
	li $v0, 4          	
   	la $a0, newline      
   	syscall
   	
   	# play sound to signify score update
	li $v0, 31
	li $a0, 79
	li $a1, 150
	li $a2, 7
	li $a3, 127
	syscall	
	
	li $a0, 96
	li $a1, 250
	li $a2, 7
	li $a3, 127
	syscall
    	
    	##### PLAYER 2 #####
    	PromptPlayer2:    	#Prompt Player 2 for row value
    	li $v0, 4          	
   	la $a0, player2Row      
   	syscall
	
	#Read first integer
    	li $v0, 5              
    	la $t1, row    
    	syscall
    	
    	#Store row into the memory
    	move    $t1, $v0
    	
    	lw $t6, player1Score
    	lw $t7, player2Score
    	beq $t1, 10, checkP2Resign1
    	j skipP2Resign1
    	checkP2Resign1:
    	bge $t7, $t6 P2DisplayError
    	j ExitMulti
    	skipP2Resign1:
    	
	#Prompt Player 2 for column value
    	li $v0, 4          
   	la $a0, player2Col
   	syscall
	
	#Read first integer
    	li $v0, 5      # Read first integer A
    	la $t2, col    
    	syscall
    	
    	#Store row into the memory
    	move    $t2, $v0
    	
    	lw $t6, player1Score
    	lw $t7, player2Score
    	beq $t1, 10, checkP2Resign2
    	j skipP2Resign2
    	checkP2Resign2:
    	bge $t7, $t6 P2DisplayError
    	j ExitMulti
    	skipP2Resign2:
    	
    	jal CheckP2
    	move $t1, $s1
    	move $t2, $s2
    	jal StoreWhitePiece
    	jal PixelCoord
    	jal DrawWhitePiece
    	
    	# Calculate Score midgame
    	jal CalculateP1Score
    	jal CalculateP2Score

    	li $v0, 4          	
   	la $a0, newline      
   	syscall   
   	
   	# play sound to signify score update
	li $v0, 31
	li $a0, 79
	li $a1, 150
	li $a2, 7
	li $a3, 127
	syscall	
	
	li $a0, 96
	li $a1, 250
	li $a2, 7
	li $a3, 127
	syscall	
    	
    	j Multiplayer
	j ExitMulti	
			
######################################################
# Convert board coordinates to pixel coordinates
######################################################
PixelCoord:
	
	# Intervals of 8
	addi $t3, $zero, 8
	
	# Base Pixel Coordinate
	addi $t4, $zero, 2
	
	# Row and Collumn Pixel coordinate
	mul $t5, $t1, $t3
	mul $t6, $t2, $t3
	
	# Actual pixel coordinate (2 + 8x)
	add $t1, $t4, $t5
	add $t2, $t4, $t6
	
	jr $ra

######################################################
# Draw initial white pieces
######################################################
DrawWhitePiece:
	sw $ra, ($sp)
	
	# Set game piece boundaries
	addi $t3, $t1, 5
	addi $t4, $t2, 4
	
	move $t5, $t1
	move $t6, $t2
	
	whiteLoop:
	move $a1, $t1	#move y coordinate into $a1
	move $a0, $t2
	#li $a0, $t2	# load x direction to 0, doesnt change
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0	# move screen coordinates into $a0
	lw $a1, whitePiece	#move color code into $a1
	jal DrawPixel	#draw the color at the screen location
	add $t1, $t1, 1	#increment y coordinate
	
	bne $t1, $t3, whiteLoop	#loop through to draw entire left border
	move $t1, $t5
	add $t2, $t2, 1
	ble $t2, $t4 whiteLoop
	
	lw $ra, ($sp)
	jr $ra
	
######################################################
# Draw initial black pieces
######################################################
DrawBlackPiece:
	sw $ra, ($sp)

	# Set game piece boundaries
	addi $t3, $t1, 5
	addi $t4, $t2, 4
	
	move $t5, $t1
	move $t6, $t2
	
	blackLoop:
	move $a1, $t1	#move y coordinate into $a1
	move $a0, $t2
	#li $a0, $t2	# load x direction to 0, doesnt change
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0	# move screen coordinates into $a0
	lw $a1, blackPiece	#move color code into $a1
	jal DrawPixel	#draw the color at the screen location
	add $t1, $t1, 1	#increment y coordinate

	bne $t1, $t3, blackLoop	#loop through to draw entire left border
	move $t1, $t5
	add $t2, $t2, 1
	ble $t2, $t4, blackLoop
	
	lw $ra, ($sp)
	jr $ra
	
######################################################
# Store the white piece at specified matrix location
######################################################
StoreWhitePiece:
	la $a0, colorCodeMatrix
	lw $a1, matrixSize
	li $t4, 2 #whitePiece numeric code
	
	#Get Address
	mul $t3, $t1, $a1		# t3 = rowIndez * colSize
	add $t3, $t3, $t2		# 		+ colIndex
	mul $t3, $t3, DATA_SIZE		# * DATA_SIZE
	add $t3, $t3, $a0		# + base address
	
	#Store color code in the specified element
	sw $t4, ($t3)
	
	jr $ra

######################################################
# Store the black piece at specified matrix location
######################################################
StoreBlackPiece:
	la $a0, colorCodeMatrix
	lw $a1, matrixSize
	li $t4, 1 #blackPiece numeric code
	
	#Get Address
	mul $t3, $t1, $a1		# t3 = rowIndez * colSize
	add $t3, $t3, $t2		# 		+ colIndex
	mul $t3, $t3, DATA_SIZE		# * DATA_SIZE
	add $t3, $t3, $a0		# + base address
	
	#Store color code in the specified element
	sw $t4, ($t3)
	jr $ra		

######################################################
# Check player 1 move (SINGLEPLAYER)
######################################################
CheckSingleP1:
	sw $ra, 4($sp)
	
	# Save user inputs
	move $s1, $t1
	move $s2, $t2
	
	#Check 1: If user enters invalid input
	#P2FirstCheck:
	li $t6, 0			# Lower bound
	li $t7, 7			# Upper bound
	
		#Check row
		blt $t1, $t6, singleP1DisplayError
		bgt $t1, $t7, singleP1DisplayError
    	
    		#Check column
		blt $t2, $t6, singleP1DisplayError
		bgt $t2, $t7, singleP1DisplayError
		
	#Check 2: If a piece exists at specified location
	move $a0, $t1
	move $a1, $t2
	jal MatrixElementAddress
	
	li $t9, 0	# Matrix code for empty space
	beq  $t4, $t9, singleP1SecondCheckContinue	# If empty, then continue, else error
    	j singleP1DisplayError
	singleP1SecondCheckContinue:
	
	#Check 3: If a piece of opposite color is any of the adjacent space
	addi $t7, $zero, 0	# True/False counter(True if >0, Less if =0 -> error)
	li $t6, 1	# For detection of piece of similar color at the opposite end
	
		#Check top
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 0	# Column
		jal MatrixElementAddress
	
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, singleP1ThirdCheckContinue1	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue1:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
	
		#Check bottom
		addi $a0, $t1, 1
		addi $a1, $t2, 0
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, singleP1ThirdCheckContinue2	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue2:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check left
		addi $a0, $t1, 0
		addi $a1, $t2, -1
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, singleP1ThirdCheckContinue3	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue3:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
	
		#Check right
		addi $a0, $t1, 0
		addi $a1, $t2, 1
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piecee
		bne $t4, $t5, singleP1ThirdCheckContinue4	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue4:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check top-right
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, singleP1ThirdCheckContinue5	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue5:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check top-left
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, singleP1ThirdCheckContinue6	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue6:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check bottom-right
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, singleP1ThirdCheckContinue7	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue7:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check bottom-left
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, singleP1ThirdCheckContinue8	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToBlack
		singleP1ThirdCheckContinue8:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		# If the counter returns false
		beq $t7, $zero, singleP1DisplayError
		
	lw $ra, 4($sp)
	jr $ra
	
	singleP1DisplayError:
	li $v0, 4             
    	la $a0, error0
    	syscall
    	j PromptSinglePlayer

######################################################
# Check player 1 move
######################################################
CheckP1:
	sw $ra, 4($sp)
	
	# Save user inputs
	move $s1, $t1
	move $s2, $t2
	
	#Check 1: If user enters invalid input
	#P2FirstCheck:
	li $t6, 0			# Lower bound
	li $t7, 7			# Upper bound
	
		#Check row
		blt $t1, $t6, P1DisplayError
		bgt $t1, $t7, P1DisplayError
    	
    		#Check column
		blt $t2, $t6, P1DisplayError
		bgt $t2, $t7, P1DisplayError
		
	#Check 2: If a piece exists at specified location
	move $a0, $t1
	move $a1, $t2
	jal MatrixElementAddress
	
	li $t9, 0	# Matrix code for empty space
	beq  $t4, $t9, P1SecondCheckContinue	# If empty, then continue, else error
    	j P1DisplayError
	P1SecondCheckContinue:
	
	#Check 3: If a piece of opposite color is any of the adjacent space
	addi $t7, $zero, 0	# True/False counter(True if >0, Less if =0 -> error)
	li $t6, 1	# For detection of piece of similar color at the opposite end
	
		#Check top
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 0	# Column
		jal MatrixElementAddress
	
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, P1ThirdCheckContinue1	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue1:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
	
		#Check bottom
		addi $a0, $t1, 1
		addi $a1, $t2, 0
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, P1ThirdCheckContinue2	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue2:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check left
		addi $a0, $t1, 0
		addi $a1, $t2, -1
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, P1ThirdCheckContinue3	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue3:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
	
		#Check right
		addi $a0, $t1, 0
		addi $a1, $t2, 1
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piecee
		bne $t4, $t5, P1ThirdCheckContinue4	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue4:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check top-right
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, P1ThirdCheckContinue5	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue5:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check top-left
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, P1ThirdCheckContinue6	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue6:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check bottom-right
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, P1ThirdCheckContinue7	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue7:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		#Check bottom-left
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 2	# Matrix code for white piece
		bne $t4, $t5, P1ThirdCheckContinue8	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToBlack
		P1ThirdCheckContinue8:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 1
		
		# If the counter returns false
		beq $t7, $zero, P1DisplayError
		
	lw $ra, 4($sp)
	jr $ra
	
	P1DisplayError:
	li $v0, 4             
    	la $a0, error0
    	syscall
    	j PromptPlayer1
    	
######################################################
# Check player 2 move
######################################################
CheckP2:
	sw $ra, 4($sp)
	
	# Save user inputs
	move $s1, $t1
	move $s2, $t2
	
	#Check 1: If user enters invalid input
	#P1FirstCheck:
	li $t6, 0			# Lower bound
	li $t7, 7			# Upper bound
	
		#Check row
		blt $t1, $t6, P2DisplayError
		bgt $t1, $t7, P2DisplayError
    	
    		#Check column
		blt $t2, $t6, P2DisplayError
		bgt $t2, $t7, P2DisplayError
		
	#Check 2: If a piece exists at specified location
	move $a0, $t1
	move $a1, $t2
	jal MatrixElementAddress
	
	li $t9, 0	# Matrix code for empty space
	beq  $t4, $t9, P2SecondCheckContinue
    	j P2DisplayError
	P2SecondCheckContinue:
	
	#Check3: Check for at least 1 adjcacent piece of opposite color near desired location
	addi $t7, $zero, 0	# True/False counter(True if >0, Less if =0 -> error)
	li $t6, 2	# For detection of piece of similar color at the opposite end
	
		#Check top
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 0	# Column
		jal MatrixElementAddress
	
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue1	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToWhite
		P2ThirdCheckContinue1:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check bottom
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, 0	# Column
		jal MatrixElementAddress
	
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue2	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToWhite
		P2ThirdCheckContinue2:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check left
		addi $a0, $t1, 0
		addi $a1, $t2, -1
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue3	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToWhite
		P2ThirdCheckContinue3:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
	
		#Check right
		addi $a0, $t1, 0
		addi $a1, $t2, 1
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue4	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToWhite
		P2ThirdCheckContinue4:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check top-right
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue5	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 1	# column increment
		
		jal FlipToWhite
		P2ThirdCheckContinue5:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check top-left
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue6	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToWhite
		P2ThirdCheckContinue6:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check bottom-right
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue7	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToWhite
		P2ThirdCheckContinue7:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check bottom-left
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, P2ThirdCheckContinue8	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToWhite
		P2ThirdCheckContinue8:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		# If the counter returns false
		beq $t7, $zero, P2DisplayError
		
	lw $ra, 4($sp)
	jr $ra
	
	P2DisplayError:
	li $v0, 4             
    	la $a0, error0
    	syscall
    	j PromptPlayer2
    					
######################################################
# Check AI move **************************************
######################################################
CheckAI:
	sw $ra, 4($sp)
	
	# Save user inputs
	move $s1, $t1
	move $s2, $t2
	
	#Check 1: If user enters invalid input
	#P1FirstCheck:
	li $t6, 0			# Lower bound
	li $t7, 7			# Upper bound
	
		#Check row
		blt $t1, $t6, AIError
		bgt $t1, $t7, AIError
    	
    		#Check column
		blt $t2, $t6, AIError
		bgt $t2, $t7, AIError
		
	#Check 2: If a piece exists at specified location
	move $a0, $t1
	move $a1, $t2
	jal MatrixElementAddress
	
	li $t9, 0	# Matrix code for empty space
	beq  $t4, $t9, AISecondCheckContinue
    	j AIError
	AISecondCheckContinue:
	
	#Check3: Check for at least 1 adjcacent piece of opposite color near desired location
	addi $t7, $zero, 0	# True/False counter(True if >0, Less if =0 -> error)
	li $t6, 2	# For detection of piece of similar color at the opposite end
	
		#Check top
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 0	# Column
		jal MatrixElementAddress
	
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue1	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToWhite
		AIThirdCheckContinue1:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check bottom
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, 0	# Column
		jal MatrixElementAddress
	
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue2	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 0	# column increment
		jal FlipToWhite
		AIThirdCheckContinue2:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check left
		addi $a0, $t1, 0
		addi $a1, $t2, -1
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue3	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToWhite
		AIThirdCheckContinue3:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
	
		#Check right
		addi $a0, $t1, 0
		addi $a1, $t2, 1
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue4	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 0	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToWhite
		AIThirdCheckContinue4:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check top-right
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue5	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, 1	# column increment
		
		jal FlipToWhite
		AIThirdCheckContinue5:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check top-left
		addi $a0, $t1, -1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue6	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, -1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToWhite
		AIThirdCheckContinue6:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check bottom-right
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, 1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue7	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, 1	# column increment
		jal FlipToWhite
		AIThirdCheckContinue7:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		#Check bottom-left
		addi $a0, $t1, 1	# Row
		addi $a1, $t2, -1	# Column
		jal MatrixElementAddress
		
		li $t5, 1	# Matrix code for black piece
		bne $t4, $t5, AIThirdCheckContinue8	# If opposite piece found, go to FlipPiece function, else continue
		addi $a2, $zero, 1	# row increment
		addi $a3, $zero, -1	# column increment
		jal FlipToWhite
		AIThirdCheckContinue8:
		# Restore original coordinates and variables
		move $t1, $s1
		move $t2, $s2
		li $t9, 0
		li $t6, 2
		
		# If the counter returns false
		beq $t7, $zero, AIError
	
	# DEBUG #
    	li $v0, 1
    	move $a0, $t1
    	syscall
    	
    	# DEBUG #
    	li $v0, 1
    	move $a0, $t2
    	syscall
				
	lw $ra, 4($sp)
	jr $ra
	
	AIError:
	#move $a0, $t1
	#move $a1, $t2
	li $t7, 7
	addi $t2, $t2, 1
	bgt $t2, $t7, AIJump1
	#j CheckAI
	j AINext
	AIJump1:
	addi $t1, $t1, 1
	addi $t2, $zero, 0
	#j CheckAI
	j AINext
	li $t7, 7
	bgt $t1, $t7, Singleplayer
	#j CheckAI
	#AIJump2:
	#lw $ra, 4($sp)
	#jr $ra


######################################################
#Flip white pieces to black pieces
######################################################   	
FlipToWhite:
	sw $ra, 8($sp)
	
	#Save the first element for potential flipping
	move $s3, $a0
	move $s4, $a1
    	move $t1, $s3		
    	move $t2, $s4
    	
    	#Save increment values
    	move $s6, $a2
    	move $s7, $a3
    	
    	FindWhiteEnd:
    	jal MatrixElementAddress
    	beq $t4, $t6 PerformWhiteFlip	# Jump to PerformFlip function if found end piece
    	beq $t4, $t9 ExitWhiteFlip		# Jump to ExitFlip if found empty space
    	add $t1, $t1, $s6
    	add $t2, $t2, $s7
    	
    	#DEBUG
    	#li $v0, 1
    	#move $a0, $t4
    	#syscall
    	
    	move $a0, $t1		
    	move $a1, $t2
    	j FindWhiteEnd
    	
    	PerformWhiteFlip:
    	addi $t7, $t7, 1	# Set to true

    	move $t1, $s3		
    	move $t2, $s4
    	move $a0, $s3		
    	move $a1, $s4
    	
    
    		WhiteFlipLoop:
    		# Update Matrix
		jal MatrixElementAddress
		sw $t6, ($t3)
   
		move $t8, $a0		
    		move $t9, $a1
		
		# Update graphic color
    		jal PixelCoord
		jal DrawWhitePiece
		
		# Restore $t6
		li $t6, 2
		
		move $a0, $t8		
    		move $a1, $t9
    		move $t1, $t8		
    		move $t2, $t9

    		
		add $t1, $t1, $s6
    		add $t2, $t2, $s7		

    		move $a0, $t1		
    		move $a1, $t2

    		li $t9, 2
    		
    		# Check if the next piece is the end piece
    		jal MatrixElementAddress
    		beq $t4, $t9, ExitWhiteFlip 
    		j WhiteFlipLoop
    	    			    			
    	ExitWhiteFlip:
    	lw $ra, 8($sp)
    	jr $ra
    	        	
######################################################
#Flip white pieces to black pieces
######################################################   	
FlipToBlack:
	sw $ra, 8($sp)
	
	#Save the first element for potential flipping
	move $s3, $a0
	move $s4, $a1
    	move $t1, $s3		
    	move $t2, $s4
    	
    	#Save increment values
    	move $s6, $a2
    	move $s7, $a3
    	
    	FindBlackEnd:
    	jal MatrixElementAddress
    	beq $t4, $t6 PerformBlackFlip	# Jump to PerformFlip function if found end piece
    	beq $t4, $t9 ExitBlackFlip		# Jump to ExitFlip if found empty space
    	add $t1, $t1, $s6
    	add $t2, $t2, $s7
    	move $a0, $t1		
    	move $a1, $t2   	
    	j FindBlackEnd
    	
    	PerformBlackFlip:
    	addi $t7, $t7, 1	# Set to true

    	# Reset to first flip position
    	move $t1, $s3		
    	move $t2, $s4
    	move $a0, $s3		
    	move $a1, $s4
    		
    		BlackFlipLoop:
    		# Update Matrix
		jal MatrixElementAddress
		sw $t6, ($t3)
    		
		move $t8, $a0		
    		move $t9, $a1
		
		# Update graphic color
    		jal PixelCoord
		jal DrawBlackPiece
		
		# Restore $t6
		li $t6, 1
		
		move $a0, $t8		
    		move $a1, $t9
    		move $t1, $t8		
    		move $t2, $t9
    		
		add $t1, $t1, $s6
    		add $t2, $t2, $s7		
    		
    		move $a0, $t1		
    		move $a1, $t2

    		li $t9, 1
    		
    		# Check if the next piece is the end piece
    		jal MatrixElementAddress
    		beq $t4, $t9, ExitBlackFlip 
    		
    		j BlackFlipLoop
    	    			    			
    	ExitBlackFlip:
    	lw $ra, 8($sp)
    	jr $ra
    	    	    	
######################################################
#GetMatrixElementAddress Function
######################################################   	
MatrixElementAddress:
	#move $a0, $t1		
    	#move $a1, $t2

	la $a2, colorCodeMatrix
	lw $a3, matrixSize
	
	mul $t3, $a0, $a3		# t3 = rowIndez * colSize
	add $t3, $t3, $a1		# 		+ colIndex
	mul $t3, $t3, DATA_SIZE		# * DATA_SIZE
	add $t3, $t3, $a2		# + base address
	lw $t4, ($t3)
	
	jr $ra
	
##################################################################
#CoordinatesToAddress Function
# $a0 -> x coordinate
# $a1 -> y coordinate
##################################################################
# returns $v0 -> the address of the coordinates for bitmap display
##################################################################
CoordinateToAddress:
	lw $v0, screenWidth 	#Store screen width into $v0
	mul $v0, $v0, $a1	#multiply by y position
	add $v0, $v0, $a0	#add the x position
	mul $v0, $v0, 4		#multiply by 4
	add $v0, $v0, $gp	#add global pointerfrom bitmap display
	jr $ra			# return $v0
	
##################################################################
#Draw Function
# $a0 -> Address position to draw at
# $a1 -> Color the pixel should be drawn
##################################################################
# no return value
##################################################################
DrawPixel:
	sw $a1, ($a0) 	#fill the coordinate with specified color
	jr $ra		#return

##################################################################
# Calculate Player Scores
##################################################################	
CalculateP1Score:
	sw $ra, 12($sp)
	
	li $t1, 0	# row 
	li $t2, 0	# column
	li $t5, 0	# sum
	li $t7, 7	# boundary
	
	P1ScoreLoop:
	move $a0, $t1
	move $a1, $t2
	jal MatrixElementAddress
	bne $t4, 1, P1Jump1
	addi $t5, $t5, 1
	P1Jump1:
	addi $t2, $t2, 1
	bgt $t2, $t7, P1Jump2
	j P1ScoreLoop
	P1Jump2:
	addi $t1, $t1, 1
	addi $t2, $zero, 0
	bgt $t1, $t7, P1Jump3
	j P1ScoreLoop
	P1Jump3:
	sw $t5, player1Score

	lw $ra, 12($sp)
	jr $ra	
	
CalculateP2Score:
	sw $ra, 16($sp)
	
	li $t1, 0	# row 
	li $t2, 0	# column
	li $t5, 0	# sum
	li $t7, 7	# boundary
	
	P2ScoreLoop:
	move $a0, $t1
	move $a1, $t2
	jal MatrixElementAddress
	bne $t4, 2, P2Jump1
	addi $t5, $t5, 1
	P2Jump1:
	addi $t2, $t2, 1
	bgt $t2, $t7, P2Jump2
	j P2ScoreLoop
	P2Jump2:
	addi $t1, $t1, 1
	addi $t2, $zero, 0
	bgt $t1, $t7, P2Jump3
	j P2ScoreLoop
	P2Jump3:
	sw $t5, player2Score
	
	lw $ra, 16($sp)
	jr $ra	

##################################################################
# End Game
##################################################################
ExitSingle:
	jal CalculateP1Score
	jal CalculateP2Score
	
	#play a sound tune to signify game over
	li $v0, 31
	li $a0, 28
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
		
	li $a0, 33
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 47
	li $a1, 1000
	li $a2, 32
	li $a3, 127
	syscall
	
	li $v0, 55 		#syscall value for dialog
	la $a0, gameOver 	#get message
	syscall
	
	li $v0, 56 		#syscall value for dialog
	la $a0, displayP1Score	#get message
	lw $a1, player1Score	#get score
	syscall
	
	li $v0, 56 		#syscall value for dialog
	la $a0, displayP2Score	#get message
	lw $a1, player2Score	#get score
	syscall
	
	lw $t0, player1Score
	lw $t1, player2Score
	
	bgt $t0, $t1, P1Wins
	li $v0, 55 		#syscall value for dialog
	la $a0, AIWin 	#get message
	syscall
	j ReplaySingle
	P1Wins:
	li $v0, 55 		#syscall value for dialog
	la $a0, player1Win 	#get message
	syscall
	
	ReplaySingle:
	li $v0, 50 		#syscall for yes/no dialog
	la $a0, replayMessage 	#get message
	syscall
	
	beqz $a0, main		#jump back to start of program

	#end program
	li $v0, 10
	syscall
		
ExitMulti:
	jal CalculateP1Score
	jal CalculateP2Score
	
	#play a sound tune to signify game over
	li $v0, 31
	li $a0, 28
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
		
	li $a0, 33
	li $a1, 250
	li $a2, 32
	li $a3, 127
	syscall
	
	li $a0, 47
	li $a1, 1000
	li $a2, 32
	li $a3, 127
	syscall
	
	li $v0, 55 		#syscall value for dialog
	la $a0, gameOver 	#get message
	syscall
	
	li $v0, 56 		#syscall value for dialog
	la $a0, displayP1Score	#get message
	lw $a1, player1Score	#get score
	syscall
	
	li $v0, 56 		#syscall value for dialog
	la $a0, displayP2Score	#get message
	lw $a1, player2Score	#get score
	syscall
	
	lw $t0, player1Score
	lw $t1, player2Score
	
	bgt $t0, $t1, singleP1Wins
	li $v0, 55 		#syscall value for dialog
	la $a0, player2Win 	#get message
	syscall
	j ReplayMulti
	singleP1Wins:
	li $v0, 55 		#syscall value for dialog
	la $a0, player1Win 	#get message
	syscall
	
	ReplayMulti:
	li $v0, 50 		#syscall for yes/no dialog
	la $a0, replayMessage	#get message
	syscall
	
	beqz $a0, main		#jump back to start of program

	#end program
	li $v0, 10
	syscall

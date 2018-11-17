.data
	inputLong: .asciiz "Input is too long."
	emptyInput: .asciiz "Input is empty."
	invalidNumber: .asciiz "Invalid base-30 number."
	userInput: .space 1000	#reserving the 1000 bytes of memory for userInput
	fourCharacters: .space 4
.text
main:
	#asking the user for input
	li $v0, 8
	la $a0, userInput
	li $a1, 1000	
	syscall
	la $a1, userInput
	li $t9, 0				#if it is 0, then a valid character is not found. 1 means a non-space character is found

length_loop:
	lb $a0,($a1)        			# read the character
	addi $a1, $a1, 1
	
	beq $a0, 0, loop1_exit_check		#if it is a null character check if the input is empty
	beq $a0, 10, loop1_exit_check		#if there is an end line character then I will check if the input is empty or if it has valid input
	
	beq $a0, 32, length_loop		#if there is a space in front or back of the input, we just carry on with the loop
	
	beq $t9, 1, inputLongError 		# this code is executed if there is no space or endline. 
						#for the first time, the value in $t9 = 0, hence inputLongError is not thrown
						#however, if we get here for the second time, it means that a non-space character was found 
						# already, soo an input too long error is thrown. 
	li $t9, 1				# $t9 = 1 means that a non-space character is discovered
	# in these lines I am storing 4 characters after a non-space character is found in  another string named fourCharacters. 
	la $s6, fourCharacters
	#storing the first non-space character to the starting address of fourCharacters
	lb $a0, -1($a1)
	sb $a0, 0($s6)

	lb $a0, 0($a1) 			#storing the second non-space character to the starting address of fourCharacters
	sb $a0, 1($s6)
	
	lb $a0, 1($a1) 			#storing the third non-space character to the starting address of fourCharacters
	sb $a0, 2($s6)
	lb $a0, 2($a1) 			#storing the fourth non-space character to the starting address of fourCharacters
	sb $a0, 3($s6)
	
	addi $a1, $a1, 3 		# I have added 3 to $a1 because I have already read 4 characters from input string
	j length_loop

loop1_exit_check:
	beq $t9, 0, emptyInputError 		# if $t9 = 0 then, it means no non-space character is found.

	# this is the starting of the new loop that calculates the sum and also finds out if there are any invalid characters in the input
	li $s5, 0			# this register holds the final sum of the Base-30 number
	li $t4, 1			# this register holds the exponent of 30. At first, it is 1, then 36, then 36*36
	li $t7, 0			# this is my loop counter. when it equals 3 the loop exits. 
	la $s6, fourCharacters+4
validCharactersLoop:
	beq $t7, 4, loop2_exit_check		#if the value of the counter = 4, then the loop exits
	addi $t7, $t7, 1 			# incrementing the value of the counter
	addi $s6, $s6, -1			#increasing the value of the address to load 
	lb $t0, ($s6)				# $s6 has the address of the fourth or the last byte of the input in first iteration
	
	beq $t0, 10, validCharactersLoop  	# if there is an end line character then I will continue the loop
	beq $t0, 32, whatKindOfSpace		# if there is a space in front or back of the input, we just carry on with the loop
	beq $t0, 0, validCharactersLoop		# if it is a null character, then it will just skip and continue the loop

	li $a3, 1				# the program counter reaches this point if the character is not null, space or endline.
	slti $t2, $t0, 58       	  		#checking if it is a valid digit
						#digit...  if t0 < 58, then t2=1 
	li $t3, 47
	slt $t3, $t3, $t0                        # if 47 < t0,  t3 = 1 
	and $t3, $t3, $t2  			# if t3 and t2 are same, t3  = 1 
	addi $t9, $t0, -48			# the t9 register is used for my calculation in the later phase
	beq $t3, 1, multiply 	

#uppercase
	slti $t2, $t0, 85	 		#checking if it is a valid uppercase letter. my range is A to T
	li $t3, 64 
	slt $t3, $t3, $t0 
	and $t3, $t3, $t2  			# if t3 and t2 are same, t3  = 1 
	addi $t9, $t0, -55     
	beq $t3, 1, multiply 	
#lowercase					#checking for a lower case valid letter
	slti $t2, $t0, 117				
	li $t3, 96
	slt $t3, $t3, $t0
	and $t3, $t3, $t2  			# if t3 and t2 are same, t3  = 1 
	addi $t9, $t0, -87
	bne $t3, 1, invalidNumberError
	
multiply:
	mul $t5, $t4, $t9			# $t5 contains the product of the base- 30 exponent and our input number
	add $s5, $s5, $t5			# that product is added to the register that stores the sum 
	mul $t4, $t4, 30  
	j validCharactersLoop	
whatKindOfSpace:				# this evaluates if the space is in between the character or at the trailing point
	beq $a3, 1, invalidNumberError		# once non-null, non-space, non-endline is found, a3 = 1, if it is in between the characters, then it goes to invalid input
	j validCharactersLoop			#if it is a trailing space, go back to loop
	 
loop2_exit_check:
	li $v0, 1
	add $a0, $zero, $s5 
	syscall
	j exit
inputLongError: 				#this code will be executed If the string has more than 4 characters.,
	li $v0, 4				#the program prints the message of "Input is too long."
	la $a0, inputLong		
	syscall
	j exit
emptyInputError: 				#this code will be executed if the input string is empty
	li $v0, 4				#If the string has zero characters, the program prints the message of "Input is empty."
	la $a0, emptyInput
	syscall
	j exit
	
invalidNumberError: 				#If the string includes at least one character not in the specified set, the program prints the 
	li $v0, 4				#message of "Invalid base-30 number." which is (3+27)
	la $a0, invalidNumber
	syscall
	
				
exit:
li $v0, 10			#tell the system to prepare for exit
syscall


.data
inputdata: .word 1160030, 25, 500
answer:    .word 0x4486a180,0x40a00000, 0x41B2E389
iteration: .word 5

str1:      .string "\n The testing number is: "
str2:      .string "\n The correct root number is:"
str3:      .string "\n The calculated root number is:"
str4:      .string "\n The answer is CORRECT"
str5:      .string "\n The answer is WRONG"
str6:      .string "\n we got total"
str7:      .string "\n error"




.text
main:
    la s3, inputdata
    li s1, 2
    li s2, 0
    la s4, answer
    mv a5, x0
    mloop:
    lw a0, 0(s3)
    mv s0, a0
    jal ra, Newtons_method
    
    lw a4, 0(s4)

    jal ra, printResult
    addi s4, s4, 4
    addi s2, s2, 1
    addi s3, s3, 4
    blt s2, s1, mloop
    jal ra, conclude
    #Exit the program
    li a7, 10
    ecall
    
# a0: the input/output data
# a2: iteration 
Newtons_method:
    addi sp, sp, -8
    sw ra, 4(sp)
    # round input
    sw a0, 0(sp)
    
    # get initial guess
    add t0, a0, x0
    jal ra, CLZ
    add a0, t0, x0

    addi a0, a0, -32
    sub a0, x0, a0
    srli a0, a0, 1
    
    mv t3, a0
    jal ra, int2float
    mv a0, t3


    bne a0, x0, nExit
        li a0, 0x40000000
    nExit:
   

    # a1 is the input data
    # a2 is the  iteration time, a3 is the total iteration time
    lw a1, 0(sp)
    mv t3, a1
    jal ra, int2float
    mv a1, t3

    mv a2, x0
    lw a3, iteration

    loop:
        bge a2, a3, outloop  #if a2 >= a3 jump to output loop
        add t0, a0, x0
        add t1, a1, x0
        jal ra, div_float # t4 = t1/t0
        add t0, a0, x0
        jal ra, add_float # t1 = t4 + t0
        li t0, 0x40000000
        jal ra div_float # t4 = t1/t0
        add a0, t4, x0   # a0(output) = t4
        addi a2, a2, 1
        j loop
    outloop:  
    lw ra 4(sp)
    addi sp, sp, 8
    jr ra

# input data t0 + t4
# t1 output
# t3 mantissa
# t4 sign
# t6 exp
add_float:
    addi sp, sp, -4
    sw ra, 0(sp)
    ######
    # handle special case
    ######
    
    # calculate abs
    li t2, 0x7fffffff
    and t1, t0, t2    # t1 = abs (t0)
    and t2, t4, t2    # t2 = abs (t4)
    
    # we always make sure   (abs(t4) > abs(t0))
    bge t2, t1, aExit1
    # switch t0 and t4
    mv t3, t0
    mv t0, t4
    mv t4, t3 
     # switch t1 and t2
    mv t3, t1
    mv t1, t2
    mv t2, t3 
    aExit1:
    srli t6, t2, 23
    srli t5, t1, 23
    # compute the t4's mantissa
    li t3 0x7fffff
    and t2, t2, t3
    and t1, t1, t3
    bge x0, t6, aExit2
        li t3, 0x800000
        or t2, t2, t3
    aExit2: 
    
    bge x0, t5, aExit3
        li t3, 0x800000
        or t1, t3, t1
    aExit3:
    # now we have t4 -> t2(mantissa), t6 (exp)
    #             t0 -> t1(mantissa), t5 (exp)
        
        sub t5, t6, t5 # t5 is the diff of exp
        srl t1, t1, t5
        srli t0, t0, 31
        srli t4, t4, 31
        # now t0, t4 are the sign bit
        xor t0, t0, t4
        beq t0, x0, aElse4
            sub t3, t2, t1
            j aExit4
        aElse4:
            add t3, t2, t1
    aExit4:
        
        # we can release t2, t1, t0, t5
        # t3 mantissa
        # t4 sign
        # t6 exp
    li t0, 0x1000000
    and t0, t0, t3
    beq t0, x0 aElse5
        srli t3, t3, 1
        addi t6, t6, 1
        j aExit5
    aElse5:
        beq t3, x0, aExit5
        li t0, 0x800000
        and t0, t3, t0
        bne t0, x0, aExit5
            slli t3, t3, 1
            addi t6, t6, -1
            j aElse5
    aExit5:
        add t1, x0, x0
        bge x0, t6, add_out
 
        li t2, 0x7fffff 
        and t1, t3, t2
        slli t6, t6, 23
        or t1, t1, t6
        slli t4, t4, 31
        or t1, t1, t4


    add_out:
        lw ra, 0(sp)
        addi sp, sp, 4
        jr ra



# t0 is the input/output data
# t1 abd t2 are the temperatory data
CLZ:
    srli t1, t0, 1    # t1 = t0 >> 1
    or t0, t0, t1     # t0 = t1 | t0
    srli t1, t0, 2    # t1 = t0 >> 2
    or t0, t0, t1     # t0 = t1 | t0
    srli t1, t0, 4    # t1 = t0 >> 4
    or t0, t0, t1     # t0 = t1 | t0
    srli t1, t0, 8    # t1 = t0 >> 8
    or t0, t0, t1     # t0 = t1 | t0
    srli t1, t0, 16   # t1 = t0 >> 16
    or t0, t0, t1     # t0 = t1 | t0  
    
    srli t1, t0, 1    # t1 = t0 >> 1
    li t2, 0x55555555
    and t1, t1, t2
    sub t0, t0, t1

    srli t1, t0, 2
    li t2, 0x33333333
    and t1, t1, t2
    and t0, t0, t2
    add t0, t0, t1

    srli t1, t0, 4
    li t2, 0x0f0f0f0f
    add t0, t1, t0
    and t0, t0, t2

    srli t1, t0, 8
    add t0, t0, t1
    srli t1, t0, 16
    add t0, t0, t1

    andi t0, t0, 0x1f
    addi t0, t0, -32
    sub t0, x0, t0
    jr ra


# t0 exponental part
# t1 mantissa part
# t3 input/output number
int2float:
    addi sp, sp, -4
    sw ra, 0(sp)
    add t0, t3, x0

    jal ra, CLZ

    addi t0, t0, 1
    addi t0, t0, -32
    sub t0, x0, t0


    
    addi t1, t0, -23
    sub t1, x0, t1
    sll t3, t3, t1
    li t1, 0x800000
    xor t3, t3, t1
    addi t0, t0, 127

    slli t0, t0, 23
    or t3, t3, t0
intout:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra



# t0, t1, input number t1/t0
# t2 sign
# t3 exp
# t1 mantissa 
# t4 output 
div_float:
    addi sp, sp, -4
    sw ra, 0(sp)
    add t4, x0, x0
    beq t1, x0, div_out
    li t4, 0x7fffffff
    beq t0, x0, div_out
    
    # separate the t1 data into sign|exp|mantissa
    # t1 sign t2
    srli t2, t1, 31     # t2 = t1 >> 31
    # t1 exp t3
    srli t3, t1, 23     # t3 = t1 >> 23
    andi t3, t3, 0xff   # t3 = t3 & 0xff
    

    li t4, 0x7FFFFF     # t4 = 0x7FFFFF
    and t1, t1, t4      # t1 = t1 & 0x7FFFFF
    li t4, 0x800000 # t4 = 0x800000
    bge x0, t3, dElse1  # if t3 <= 0 jump to dElse1
        or t1, t1, t4   # t1 = t1 | 0x800000
        j dExit1        # jump to dExit1
    dElse1:
        slli t1, t1, 1
        addi t3, t3, -1
        and t5, t1, t4
        bne t5, x0, dElse1

    dExit1:
    # save the data t2, t3
    addi sp, sp, -8 
    sw t2, 0(sp)    # 0(sp) the t1's sign value
    sw t3, 4(sp)    # 4(sp) t1's exp



    # separate the t0 data into sign|exp|mantissa
    # t0 sign t2
    srli t2, t0, 31     # t2 = t0 >> 1
    andi t2, t2, 1      # t2 = t2 & 1
    # t1 exp t3
    srli t3, t0, 23     # t3 = t0 >> 23
    andi t3, t3, 0xff   # t3 = t3 & 0xff
    li t4, 0x7FFFFF # t4 = 0x7FFFFF
    and t0, t0, t4  # t0 = t0 & 0x7FFFFF 
    li t4, 0x800000 # t4 = 0x800000
    
    bge x0, t3, dElse2  # if 0 < t3 jump to dElse2 
        or t0, t0, t4   # t0 = t0 | 0x800000
        j dExit2        # jump to dExit1
    dElse2:
        slli t0, t0, 1
        addi t3, t3, -1
        and t5, t0, t4
        bne t5, x0, dElse2
    dExit2:
        
    lw t4, 0(sp)        # t4 = t1's sign value
    xor t2, t2, t4      # t2 = t2 ^ t4
    lw t4, 4(sp)        # t4 = t1's exp value
    addi t4, t4, 127    # t4 = t4 +127 
    sub t3, t4, t3      # t3 = t4 - t3
    addi sp, sp, 8      # recover the sp position
    
    
    bge t1, t0, dExit3 # if t1 < t0 align mantissa 
        slli t1, t1, 1
        addi t3, t3, -1
    dExit3:
   
    
    # t5 iteration number
    li t5, 25
    
    add t4, x0, x0      # t4 = 0;
    bge t3, x0, dExit4
        add t5, t5, t3
        add t3, x0, x0
        blt t5, x0, div_out
    dExit4:
    # division loop output t4
    li t6, 0
  
    dloop:
        bge t6, t5, doutloop
        slli t4, t4, 1  # t4 = t4 << 1
        blt t1, t0, dExit5
            sub t1, t1, t0
            ori t4, t4, 1
        dExit5:
        slli t1, t1, 1
        addi t6, t6, 1
        j dloop
    doutloop:

    # round result
    # odd t0
    # rnd t1
    # sticky t5
    xori t5, t1, 1
    andi t1, t4, 1
    andi t0, t4, 2
    
    srli t4, t4, 1 
    or t0, t0, t5
    and t1, t1, t0
    add t4, t4, t1
    

    # normalize the result if needed
    bne t3, x0, dExit6
    li t1, 9
    bge t0, t1, dExit6
        addi sp, sp, -4
        sw t2, 0(sp)
        jal ra CLZ
        lw t2, 0(sp)
        addi sp, sp, 4
        sub t1, t1, t0
        srl t4, t4, t1
        add t3, t3, t1
    dExit6:

    li t5 0x7fffff
    and t4, t4, t5 # mantissa = mantissa & 0x7fffff
    slli t3, t3, 23 # exp << 23
    slli t2, t2, 31 # exp << 31
    or t4, t4, t3
    or t4, t4, t2
    
    div_out:
        lw ra, 0(sp)
        addi sp, sp, 4
        jr ra
    
 printResult:
     mv t0, s0 # original data
     mv t1, a0 # root data
     mv t2, a4 # answer
     
     la a0, str1
     li a7, 4
     ecall
     
     mv a0, t0 
     li a7, 1
     ecall
     
     la a0, str2
     li a7, 4
     ecall
     

     mv a0, a4 
     li a7, 1
     ecall
     
     la a0, str3
     li a7, 4
     ecall
     
     mv a0, t1 
     li a7, 1
     ecall
     
     beq a4, a0, CORRECT
     addi a5, a5, 1
     la a0, str4
     li a7, 4
     ecall
     j printout
    CORRECT:
     la a0, str4
     li a7, 4
     ecall
     printout:
     ret
    
conclude:
     la a0, str6
     li a7, 4
     ecall
     mv a0, a5
     li a7, 1
     ecall
     la a0, str7
     li a7, 4
     ecall
     ret
    
    
    
    
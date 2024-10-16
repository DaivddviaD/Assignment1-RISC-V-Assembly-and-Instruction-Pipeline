.data
input: .word   0xC1CC0000, 0b00111100000111010100100101010010, 0b01000111110001011010001011000000
answer:.word   0xC1CC, 0b0011110000011101, 0b0100011111000110
str1:     .string "float32: "
str2:     .string "\ncalculated float16: "
str3:     .string "\ncorrect float16: "
str4:     .string "\nWRONG\n"
str5:     .string "\nCORRECT\n"
str6:     .string "\nWe got total "
str7:     .string "error\n"

.text
main:
    la s1, input
    li s2, 3
    li s3, 0
    la s4, answer
    
    li a5, 0
loop:
    lw s0, 0(s1)
    lw s5, 4(s4)
    jal ra, fp32_to_fp16
    
    j printResult
    addi s3, s3, 1
    addi s1, s1, 4
    addi s4, s4, 4
    blt s3, s2, loop
    j conclusion
    li a7,10
    ecall               

    
fp32_to_fp16:
    addi sp, sp, -8
    sw ra, 8(sp)
    sw s0, 0(sp)
    mv t0, s0
    slli t0, t0, 1
    srli t0, t0, 24
    addi t1, x0, 0xff
    srli a0, s0, 16
    bne t0, t1, Else
        ori a0, a0, 64
        j Exit
    Else:
     andi a0, a0, 1
     li t2, 0x7fff
     add a0, a0, t2
     add a0, s0, a0
     srli a0, a0, 0x10
   Exit:
     lw s0, 0(sp)
     lw ra, 8(sp)
     addi sp, sp, 8
     jr ra
 
printResult:
     mv t0, s0  # original data
     mv t1, a0  # calculate data
     mv t2, s5  # answer
     
     la a0, str1 #"float32: "
     li a7, 4
     ecall
     
     mv a0, t0 
     li a7, 1
     ecall
     
     la a0, str2 #"calculated float16: "
     li a7, 4
     ecall
 
     mv a0, t1 
     li a7, 1
     ecall
     
     la a0, str3 #"correct float16: "
     li a7, 4
     ecall
     
     mv a0, t2 
     li a7, 1
     ecall
     
     beq t1, t2, CORRECT
     addi a5, a5, 1
     la a0, str4
     li a7, 4
     ecall
     j printout
    CORRECT:
     la a0, str5
     li a7, 4
     ecall
     printout:
     ret
conclusion:
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
    
    
.data
.align 2                  
slot:
    .word 0               

.text
.globl main
main:
    la t0, slot           
    li t1, 1000000          

loop:
    sw t1, 0(t0)           
    lw t2, 0(t0)          
    addi t1, t1, -1        
    bne t1, zero, loop     

    li a7, 10             
    ecall
.equ N, 1000000            

.data
.align 2
slot:
    .word 0                

.text
.globl main
main:
    la   t0, slot         
    li   t1, N             

loop:
    addi t2, t2, 1         
    addi t3, t3, 1         
    addi t1, t1, -1        
    bne  t1, zero, loop   

    li   a7, 10            
    ecall
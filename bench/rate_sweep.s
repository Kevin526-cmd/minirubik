.equ N, 1000000            

.data
.align 2
buf:
    .word 0               

.text
.globl main
main:
    la   t0, buf          
    li   t1, N             

loop:
    sw   t1, 0(t0)         
    addi t0, t0, 4        
    addi t1, t1, -1        
    bne  t1, zero, loop    
    
    li   a7, 10            
    ecall
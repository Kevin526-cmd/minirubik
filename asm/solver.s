    .data
input:  .string "21345671111111"
weight: .half 720, 120, 24, 6, 2, 1, 0
p_arr:  .zero 7                
o_arr:  .zero 7                

    .text
main:
    la   t0, input              
    la   t1, p_arr             
    la   t2, o_arr              
    li   t3, 0                  
    li   t4, 7
loop1:
    lbu  t5, 0(t0)              
    addi t5, t5, -49            
    sb   t5, 0(t1)              
    lbu  t6, 7(t0)              
    addi t6, t6, -49
    sb   t6, 0(t2)              

    slli a1, t3, 2
    add  a1, a1, t6

    bnez t5, skip_a
    mv   s2, a1
skip_a:
    li   a2, 1       
    bne  t5, a2, skip_b
    mv   s3, a1
skip_b:

    addi t0, t0, 1             
    addi t1, t1, 1
    addi t2, t2, 1
    addi t3, t3, 1              
    blt  t3, t4, loop1          
    addi s1, s1, 0

    li   s1, 0                 
    la   t2, o_arr             
    li   t3, 0                 
    li   t4, 6                  
loop2:
    lbu  t6, 0(t2)             
    slli a1, s1, 1             
    add  a1, a1, s1            
    add  s1, a1, t6             
    addi t2, t2, 1
    addi t3, t3, 1
    blt  t3, t4, loop2

    li   s0, 0
    la   t1, p_arr
    la   t2, weight
    li   t3, 0
    li   t4, 7
loop_i:
    add  a1, t1, t3
    lbu  t5, 0(a1)
    slli a2, t3, 1
    add  a2, a2, t2
    lhu  a3, 0(a2)
    addi a4, t3, 1
loop_j:
    bge  a4, t4, next_i
    add  a5, t1, a4
    lbu  t6, 0(a5)
    bgeu t6, t5, skip_add
    add  s0, s0, a3
skip_add:
    addi a4, a4, 1
    j    loop_j
next_i:
    addi t3, t3, 1
    blt  t3, t4, loop_i

    la   s10, dist_po
    la   s11, dist_o
    mv   a0, s0
    mv   a1, s1
    mv   a2, s2
    mv   a3, s3
    jal  ra, heur
    li   a7, 1
    ecall
    li   a0, 32
    li   a7, 11
    ecall

    mv   a0, s0
    li   a7, 1
    ecall                       
    li   a0, 32                 
    li   a7, 11
    ecall                       

    mv   a0, s1         
    li   a7, 1
    ecall
    li   a0, 32
    li   a7, 11
    ecall

    mv   a0, s2         
    li   a7, 1
    ecall
    li   a0, 32
    li   a7, 11
    ecall

    mv   a0, s3          
    li   a7, 1
    ecall

    li   a7, 10          
    ecall  
    
heur:
    andi t0, a2, 3            
    andi t1, a3, 3           
    slli t2, a0, 3              
    add  t2, t2, a0             
    slli t3, t0, 1              
    add  t3, t3, t0            
    add  t2, t2, t3
    add  t2, t2, t1
    add  t2, t2, s10           
    lbu  t2, 0(t2)           
    add  t3, s11, a1           
    lbu  t3, 0(t3)             
    mv   a0, t2
    bgeu  t2, t3, heur_done
    mv a0, t3      

heur_done:
    ret    
    .data
input:  .string "21345671111111"
weight: .half 720, 120, 24, 6, 2, 1, 0
p_arr:  .byte 0, 0, 0, 0, 0, 0, 0, 7
o_arr:  .zero 8              
    .align 1                 
stP:       .zero 32
stO:       .zero 32
stA:       .zero 16
stB:       .zero 16
cur_face:  .zero 16
cur_turn:  .zero 16
path_face: .zero 16
path_turn: .zero 16  

    .align 2
row_perm:   .word 0, 10080, 20160   
row_orient: .word 0, 1458, 2916      
row_cubie:  .word 0, 28, 56  
rows:       .zero 36
face_ch:    .string "RBD"

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
    la   s9, stP
    la   a6, rows           
    la   t0, permutation
    la   t1, orientation
    la   t2, cubie_move
    sw   t0, 0(a6)           
    sw   t1, 4(a6)
    sw   t2, 8(a6)
    li   t3, 10080
    add  t0, t0, t3          
    addi t1, t1, 1458
    addi t2, t2, 28
    sw   t0, 12(a6)          
    sw   t1, 16(a6)
    sw   t2, 20(a6)
    add  t0, t0, t3
    addi t1, t1, 1458
    addi t2, t2, 28
    sw   t0, 24(a6)         
    sw   t1, 28(a6)
    sw   t2, 32(a6)
    jal  ra, render
    mv   a0, s0
    mv   a1, s1
    mv   a2, s2
    mv   a3, s3
    jal  ra, solve
    mv   s8, a0              
    li   a7, 1               
    ecall
    li   a0, 58              
    li   a7, 11
    ecall

    mv   s4, s0              
    mv   s5, s1              
    li   s6, 0               
v_loop:
    bge  s6, s8, v_check
    add  t3, s9, s6
    lbu  t4, 128(t3)         
    lbu  t5, 144(t3)        

    li   a0, 32              
    li   a7, 11
    ecall
    la   t0, face_ch
    add  t0, t0, t4
    lbu  a0, 0(t0)           
    ecall
    li   t0, 1
    bne  t5, t0, v_not2
    li   a0, 50              
    ecall
v_not2:
    li   t0, 2
    bne  t5, t0, v_not3
    li   a0, 39              
    ecall
v_not3:

    slli t6, t4, 2           
    slli t0, t4, 3
    add  t6, t6, t0
    add  t6, t6, a6
    lw   t1, 0(t6)           
    lw   t2, 4(t6)           
    addi t5, t5, 1           
v_turn:
    slli t0, s4, 1
    add  t0, t1, t0
    lhu  s4, 0(t0)           
    slli t0, s5, 1
    add  t0, t2, t0
    lhu  s5, 0(t0)           
    addi t5, t5, -1
    bnez t5, v_turn
    add  t3, s9, s6         
    lbu  a0, 128(t3)
    lbu  a1, 144(t3)
    addi a1, a1, 1
    jal  ra, led_step
    addi s6, s6, 1
    j    v_loop

v_check:
    li   a0, 32
    li   a7, 11
    ecall
    or   t0, s4, s5          
    li   a0, 1              
    beqz t0, v_print
    li   a0, 0               
v_print:
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


search_iter:
    addi sp, sp, -4
    sw   ra, 0(sp)          

    li   s4, 0              
    li   s6, 99             

    sh   a0, 0(s9)              
    sh   a1, 32(s9)              
    sb   a2, 64(s9)             
    sb   a3, 80(s9)              
    sb   x0, 96(s9)             
    sb   x0, 112(s9)             
    bnez a0, si_loop        
    bnez a1, si_loop        
    li   a0, 0              
    j    si_ret

si_loop:
    li   a0, -1
    bltz s4, si_ret              
    add  a4, s9, s4
    slli a5, s4, 1
    add  a5, s9, a5
    lbu  s7, 96(a4)

    li   t0, 3
    bne  s7, t0, face_ok
    addi s4, s4, -1
    j    si_loop

face_ok:
    lbu  s8, 112(a4)             
    bnez s8, not_same
    blez s4, not_same
    lbu  t0, 127(a4)             
    bne  s7, t0, not_same
    addi t0, s7, 1
    sb   t0, 96(a4)             
    j    si_loop

not_same:
    li   t0, 2
    bne  s8, t0, turn_inc
    addi t0, s7, 1
    sb   t0, 96(a4)              
    sb   x0, 112(a4)            
    j    adv_done
turn_inc:
    addi t0, s8, 1
    sb   t0, 112(a4)            

adv_done:
    mv   t5, a4
    mv   t2, a5
    beqz s8, src_ok
    addi t5, a4, 1
    addi t2, a5, 2

src_ok:
    slli t6, s7, 2           
    slli t0, s7, 3          
    add  t6, t6, t0          
    add  t6, t6, a6          
    lw   t0, 0(t6)           
    lw   t1, 4(t6)          
    lw   t4, 8(t6)           

    lhu  t3, 0(t2)           
    lhu  a1, 32(t2)
    lbu  a2, 64(t5)
    lbu  a3, 80(t5)
    slli t3, t3, 1           
    slli a1, a1, 1
    add  t3, t0, t3
    add  a1, t1, a1
    add  a2, t4, a2
    add  a3, t4, a3
    lhu  a0, 0(t3)           
    lhu  a1, 0(a1)
    lbu  a2, 0(a2)
    lbu  a3, 0(a3)
    sh   a0, 2(a5)          
    sh   a1, 34(a5)
    sb   a2, 65(a4)
    sb   a3, 81(a4)

    andi t0, a2, 3           
    andi t1, a3, 3           
    slli t2, a0, 3
    add  t2, t2, a0          
    slli t3, t0, 1
    add  t3, t3, t0          
    add  t2, t2, t3
    add  t2, t2, t1
    add  t2, t2, s10
    add  t3, s11, a1        
    lbu  t2, 0(t2)
    lbu  a0, 0(t3)
    addi t6, s4, 1           
    bgeu a0, t2, h_ok
    mv   a0, t2

h_ok:
    add  t0, a0, t6              
    ble  t0, s5, no_prune        
    bge  t0, s6, si_loop         
    mv   s6, t0                  
    j    si_loop

no_prune:
    sb   s7, 128(a4)             
    sb   s8, 144(a4)             

    bnez a0, go_deeper
    addi a0, s4, 1
    j    si_ret

go_deeper:
    addi s4, s4, 1
    sb   x0, 97(a4)              
    sb   x0, 113(a4)             
    j    si_loop

si_ret:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

solve:
    addi sp, sp, -4
    sw   ra, 0(sp)
    mv   a0, s0
    mv   a1, s1
    mv   a2, s2
    mv   a3, s3
    jal  ra, heur
    mv   s5, a0
    
solve_loop:
    mv   a0, s0
    mv   a1, s1
    mv   a2, s2
    mv   a3, s3
    jal  ra, search_iter
    bgez a0, solve_done
    mv   s5, s6
    j    solve_loop

solve_done:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
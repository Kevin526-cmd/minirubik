    .data
input:  .string "54721631111111"
weight: .half 720, 120, 24, 6, 2, 1, 0
p_arr:  .zero 7                
o_arr:  .zero 7                
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
    jal  ra, solve
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


search_iter:
    addi sp, sp, -4
    sw   ra, 0(sp)          

    li   s4, 0              
    li   s6, 99             

    la   t1, stP            
    sh   a0, 0(t1)
    la   t1, stO            
    sh   a1, 0(t1)
    la   t1, stA            
    sb   a2, 0(t1)
    la   t1, stB            
    sb   a3, 0(t1)

    la   t1, cur_face       
    sb   x0, 0(t1)
    la   t1, cur_turn       
    sb   x0, 0(t1)

    bnez a0, si_loop        
    bnez a1, si_loop        
    li   a0, 0              
    j    si_ret

si_loop:
    li   a0, -1
    bltz s4, si_ret              

    la   t1, cur_face
    add  t1, t1, s4
    lbu  s7, 0(t1)

    li   t0, 3
    bne  s7, t0, face_ok
    addi s4, s4, -1
    j    si_loop
face_ok:

    # turn = cur_turn[d]
    la   t1, cur_turn
    add  t1, t1, s4
    lbu  s8, 0(t1)

    # if (turn==0 && d>0 && face==path_face[d-1]) { cur_face[d]=face+1; continue; }
    bnez s8, not_same
    blez s4, not_same
    la   t1, path_face                         
    add  t1, t1, s4
    lbu  t0, -1(t1)
    bne  s7, t0, not_same
    addi t0, s7, 1
    la   t1, cur_face                       
    add  t1, t1, s4
    sb   t0, 0(t1)
    j    si_loop

not_same:

    # 推進書籤：turn==2 ? (face+1, turn=0) : turn+1
    li   t0, 2
    bne  s8, t0, turn_inc
    addi t0, s7, 1
    la   t1, cur_face
    add  t1, t1, s4
    sb   t0, 0(t1)               
    la   t1, cur_turn                        
    add  t1, t1, s4
    sb   x0, 0(t1)
    j    adv_done
turn_inc:
    addi t0, s8, 1
    la   t1, cur_turn                        
    add  t1, t1, s4
    sb   t0, 0(t1)
adv_done:

    # 來源格 t5 = (turn==0) ? d : d+1
    mv   t5, s4
    beqz s8, src_ok
    addi t5, s4, 1
src_ok:
    slli t6, s7, 2               

    la   t1, stP
    slli t2, t5, 1
    add  t2, t1, t2
    lhu  t3, 0(t2)               
    la   t0, row_perm
    add  t0, t0, t6
    lw   t0, 0(t0)               
    la   t4, permutation
    add  t4, t4, t0              
    slli t3, t3, 1
    add  t4, t4, t3
    lhu  t3, 0(t4)               
    slli t2, s4, 1
    add  t2, t1, t2
    sh   t3, 2(t2)               

    la   t1, stO
    slli t2, t5, 1
    add  t2, t1, t2
    lhu  t3, 0(t2)
    la   t0, row_orient
    add  t0, t0, t6
    lw   t0, 0(t0)
    la   t4, orientation
    add  t4, t4, t0
    slli t3, t3, 1
    add  t4, t4, t3
    lhu  t3, 0(t4)
    slli t2, s4, 1
    add  t2, t1, t2
    sh   t3, 2(t2)

    la   t1, stA
    add  t2, t1, t5
    lbu  t3, 0(t2)               
    la   t0, row_cubie
    add  t0, t0, t6
    lw   t0, 0(t0)
    la   t4, cubie_move
    add  t4, t4, t0
    add  t4, t4, t3              
    lbu  t3, 0(t4)
    add  t2, t1, s4
    sb   t3, 1(t2)               


    la   t1, stB
    add  t2, t1, t5
    lbu  t3, 0(t2)
    la   t0, row_cubie
    add  t0, t0, t6
    lw   t0, 0(t0)
    la   t4, cubie_move
    add  t4, t4, t0
    add  t4, t4, t3
    lbu  t3, 0(t4)
    add  t2, t1, s4
    sb   t3, 1(t2)

    la   t1, stP
    slli t2, s4, 1
    add  t1, t1, t2
    lhu  a0, 2(t1)               
    la   t1, stO
    add  t1, t1, t2
    lhu  a1, 2(t1)               
    la   t1, stA
    add  t1, t1, s4
    lbu  a2, 1(t1)               
    la   t1, stB
    add  t1, t1, s4
    lbu  a3, 1(t1)               
    jal  ra, heur                

    add  t0, a0, s4
    addi t0, t0, 1
    ble  t0, s5, no_prune
    bge  t0, s6, si_loop         
    mv   s6, t0                  
    j    si_loop
no_prune:

    la   t0, path_face                        
    add  t0, t0, s4
    sb   s7, 0(t0)
    la   t0, path_turn                        
    add  t0, t0, s4
    sb   s8, 0(t0)

    bnez a0, go_deeper
    addi a0, s4, 1
    j    si_ret

go_deeper:
    addi s4, s4, 1
    la   t1, cur_face                       
    add  t1, t1, s4
    sb   x0, 0(t1)
    la   t1, cur_turn                       
    add  t1, t1, s4
    sb   x0, 0(t1)
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
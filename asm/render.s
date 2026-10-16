    .data
p_tmp:  .zero 8
o_tmp:  .zero 8

    .text
led_step:
    addi sp, sp, -4
    sw   ra, 0(sp)
    mv   a2, a1
ls_loop:
    jal  ra, led_move
    addi a2, a2, -1
    bnez a2, ls_loop
    jal  ra, render
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

led_move:
    slli t0, a0, 3
    sub  t0, t0, a0          
    la   t1, mv_src
    add  t1, t1, t0
    la   t2, mv_tw
    add  t2, t2, t0
    la   t3, p_arr
    la   t4, o_arr
    la   t5, p_tmp
    la   t6, o_tmp
    li   a3, 0               
lm_loop:
    add  a4, t1, a3
    lbu  a4, 0(a4)           
    add  a5, t3, a4
    lbu  a5, 0(a5)          
    add  a7, t5, a3
    sb   a5, 0(a7)           
    add  a5, t4, a4
    lbu  a5, 0(a5)           
    add  a7, t2, a3
    lbu  a7, 0(a7)           
    add  a5, a5, a7
    li   a7, 3
    blt  a5, a7, lm_nomod
    addi a5, a5, -3          
lm_nomod:
    add  a7, t6, a3
    sb   a5, 0(a7)           
    addi a3, a3, 1
    li   a7, 7
    blt  a3, a7, lm_loop
    li   a3, 0               
lm_copy:
    add  a4, t5, a3
    lbu  a5, 0(a4)
    add  a4, t3, a3
    sb   a5, 0(a4)
    add  a4, t6, a3
    lbu  a5, 0(a4)
    add  a4, t4, a3
    sb   a5, 0(a4)
    addi a3, a3, 1
    li   a7, 7
    blt  a3, a7, lm_copy
    ret

render:
    li   t6, LED_MATRIX_0_BASE
    li   a3, 0               
r_pos:
    la   t0, p_arr
    add  t0, t0, a3
    lbu  t1, 0(t0)           
    la   t0, o_arr
    add  t0, t0, a3
    lbu  t2, 0(t0)           
    slli a4, t1, 1
    add  a4, a4, t1          
    slli a5, t2, 1
    add  a5, a5, t2          
    slli t3, a3, 1
    add  t3, t3, a3          
    li   t4, 0               
r_slot:
    la   t0, rot3
    add  t0, t0, a5
    add  t0, t0, t4
    lbu  t0, 0(t0)          
    la   t1, cub_col
    add  t1, t1, a4
    add  t1, t1, t0
    lbu  t1, 0(t1)           
    slli t1, t1, 2
    la   t0, palette
    add  t0, t0, t1
    lw   t5, 0(t0)           
    add  t0, t3, t4         
    slli t0, t0, 1
    la   t1, slot_pix
    add  t1, t1, t0
    lhu  t1, 0(t1)           
    slli t1, t1, 2
    add  t1, t1, t6         
    sw   t5, 0(t1)           
    sw   t5, 4(t1)
    sw   t5, 8(t1)
    sw   t5, 12(t1)
    sw   t5, 140(t1)         
    sw   t5, 144(t1)
    sw   t5, 148(t1)
    sw   t5, 152(t1)
    sw   t5, 280(t1)         
    sw   t5, 284(t1)
    sw   t5, 288(t1)
    sw   t5, 292(t1)
    addi t4, t4, 1
    li   t0, 3
    blt  t4, t0, r_slot
    addi a3, a3, 1
    li   t0, 8
    blt  a3, t0, r_pos
    li   t0, 1000000          
r_wait:
    addi t0, t0, -1
    bnez t0, r_wait
    ret

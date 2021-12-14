#include <PR/rcp.h>

.rsp

#include "n_aspMain.data.s"

.create CODE_FILE, 0x04001080

#define DMA_SRC r2
#define DMA_DEST r1

#define DMA_WSRC r1
#define DMA_WDEST r2

#define DMA_LEN r3

#define dmem r0


#define OSTask r1
#define task_data_ptr 0x30
#define task_data_size 0x34
#define task_ucode_text 0x10
#define task_ucode_data 0x18

#define data_ptr r28
#define data_len r27

#define acmd_W0 r26
#define acmd_W1 r25

overlay0address:
entry:
/* [000] */ mfc0 r5, dpc_status
/* [004] */ lw data_ptr, task_data_ptr(OSTask)
/* [008] */ lw data_len, task_data_size(OSTask)
/* [00c] */ andi r4, r5, 0x1
/* [010] */ beqz r4, sub_040010AC
/* [014] */  andi r4, r5, 0x100
/* [018] */ beqz r4, sub_040010AC
/* [01c] */  mfc0 r4, dpc_status

@@b:
/* [020] */ andi r4, r4, 0x100
/* [024] */ bgtz r4, @@b
/* [028] */  mfc0 r4, dpc_status

sub_040010AC:
/* [02c] */ addi r24, r0, 0xfa0
/* [030] */ lw r5, task_ucode_text(OSTask)
/* [034] */ lw r4, 0x0(dmem)
/* [038] */ add r4, r4, r5
/* [03c] */ sw r4, 0x0(dmem)
/* [040] */ lw r4, 0x8(dmem)
/* [044] */ add r4, r4, r5
/* [048] */ sw r4, 0x8(dmem)
/* [04c] */ lw r5, task_ucode_data(OSTask)
/* [050] */ sw r5, 0xff8(dmem)
/* [054] */ jal func_04001150
/* [058] */  add DMA_SRC, r0, data_ptr
/* [05c] */ mfc0 r2, sp_dma_busy

func_040010E0:
@@b:
/* [060] */ bnez r2, @@b
/* [064] */  mfc0 r2, sp_dma_busy

dispatch_next_acmd:
/* [068] */ lw acmd_W0, 0x0(r29)
/* [06c] */ lw acmd_W1, 0x4(r29)
/* [070] */ addi data_ptr, 0x8
/* [074] */ srl r1, acmd_W0, 23
/* [078] */ andi r1, r1, 0xFE
/* [07c] */ lh r1, 0x10(r1)
/* [080] */ jr r1
/* [084] */  addi data_len, -8
/* [088] */ break 0

acmd_next:
/* [08c] */ bgtz r30, dispatch_next_acmd
/* [090] */  addi r29, r29, 0x8
/* [094] */ blez data_len, @@f
/* [098] */  ori r1, r0, SP_SET_TASKDONE
/* [09c] */ jal func_04001150
/* [0a0] */  add DMA_SRC, r0, data_ptr
/* [0a4] */ j func_040010E0
/* [0a8] */  mfc0 r2, sp_dma_busy
@@f:
@@b:
/* [0ac] */ mfc0 r2, sp_dma_busy
/* [0b0] */ bnez r2, @@b
/* [0b4] */  nop
/* [0b8] */ mtc0 r0, sp_semaphore
/* [0bc] */ mtc0 r1, sp_status
/* [0c0] */ break 0
/* [0c4] */  nop


// infinite loop
@@halt:
    b @@halt
     nop

func_04001150:
    addi r5, ra, 0x0
    addi r3, r27, 0x0
    addi r4, r3, 0xfec0
    blez r4, @@f
     addi DMA_DEST, r0, 0x2c0
    addi DMA_LEN, r0, 0x140
@@f:
    addi r30, DMA_LEN, 0x0
    jal dma_read
     addi DMA_LEN, -1
    jr r5
     addi r29, r0, 0x2c0

; args:
;   r1: to
;   r2: from
;   r3: len
dma_read:
    mfc0 r4, sp_dma_full
@@b:
    bnez r4, @@b
     mfc0 r4, sp_dma_full
    mtc0 DMA_DEST, sp_mem_addr
    mtc0 DMA_SRC, sp_dram_addr
    jr ra
     mtc0 DMA_LEN, sp_rd_len

; args:
;   r1: from
;   r2: to
;   r3: len
dma_write:
    mfc0 r4, sp_dma_full
@@b:
    bnez r4, @@b
     mfc0 r4, sp_dma_full
    mtc0 DMA_WSRC, sp_mem_addr
    mtc0 DMA_WDEST, sp_dram_addr
    jr ra
     mtc0 DMA_LEN, sp_wr_len

dma_wait_finish:
@@b:
    mfc0 r4, sp_dma_busy
    bnez r4, @@b
     nop
    jr ra
     nop

/* [148] */ lh r3, 0x4(dmem)
/* [14c] */ lw r2, 0x0(dmem)
/* [150] */ lh r1, 0xe(dmem)
/* [154] */ add r2, r2, r1
/* [158] */ sub r3, r3, r1
/* [15c] */ lh r1, 0x6(dmem)
/* [160] */ sub r2, r2, r1
/* [164] */ add r3, r3, r1
/* [168] */ jal dma_read
/* [16c] */ lh r1, 0xe(dmem)
/* [170] */ lw r2, 0xff8(dmem)
/* [174] */ addi r2, r2, 0x10
/* [178] */ addi r1, r0, 0x10
/* [17c] */ jal dma_read
/* [180] */  addi DMA_LEN, r0, 0x2B0 - 1
/* [184] */ jal dma_wait_finish
/* [188] */ nop
/* [18c] */ j acmd_next
/* [190] */ addi r30, r30, 0xfff8

acmd_MP3:
/* [194] */ lh r1, 0xe(dmem)
/* [198] */ lw r2, 0x8(dmem)
/* [19c] */ jal dma_read
/* [1a0] */  lh DMA_LEN, 0xc(dmem)
/* [1a4] */ jal dma_wait_finish
/* [1a8] */ nop
/* [1ac] */ j Overlay1LoadAddress
/* [1b0] */ nop
/* [1b4] */ nop

Overlay1LoadAddress:
/* [1b8] */ nop
/* [1bc] */ nop

acmd_CLEARBUFF:
/* [1c0] */ andi r2, acmd_W1, 0xffff
/* [1c4] */ vxor $v1, $v1, $v1
/* [1c8] */ andi r1, acmd_W0, 0xffff
/* [1cc] */ addi r1, r1, 0x500
@@b:
/* [1d0] */ sdv $v1[0], 0x0(r1)
/* [1d4] */ sdv $v1[0], 0x8(r1)
/* [1d8] */ addi r2, r2, 0xfff0
/* [1dc] */ bgtz r2, @@b
/* [1e0] */ addi r1, r1, 0x10
/* [1e4] */ j acmd_next
/* [1e8] */ addi r30, r30, 0xfff8

acmd_LOADBUFF:
/* [1ec] */ sll r3, acmd_W0, 8
/* [1f0] */ srl r3, r3, 20
/* [1f4] */ beqz r3, acmd_next
/* [1f8] */ addi r30, r30, 0xfff8
/* [1fc] */ andi r1, acmd_W0, 0xfff
/* [200] */ addi r1, r1, 0x500
/* [204] */ sll r2, acmd_W1, 8
/* [208] */ srl r2, r2, 8
/* [20c] */ jal dma_read
/* [210] */ addi r3, r3, 0xffff
/* [214] */ mfc0 r1, sp_dma_busy
@@b2:
/* [218] */ bnez r1, @@b2
/* [21c] */ mfc0 r1, sp_dma_busy
/* [220] */ j acmd_next
/* [224] */ nop

acmd_SAVEBUFF:
/* [228] */ sll r3, acmd_W0, 8
/* [22c] */ srl r3, r3, 20
/* [230] */ beqz r3, acmd_next
/* [234] */ addi r30, r30, 0xfff8
/* [238] */ andi r1, acmd_W0, 0xfff
/* [23c] */ addi r1, r1, 0x500
/* [240] */ sll r2, acmd_W1, 8
/* [244] */ srl r2, r2, 8
/* [248] */ jal dma_write
/* [24c] */ addi r3, r3, 0xffff
/* [250] */ mfc0 r1, sp_dma_busy
@@b3:
/* [254] */ bnez r1, @@b3
/* [258] */ mfc0 r1, sp_dma_busy
/* [25c] */ j acmd_next
/* [260] */ nop

acmd_LOADADPCM:
/* [264] */ sll r2, acmd_W1, 8
/* [268] */ srl r2, r2, 8
/* [26c] */ addi r1, r0, 0x400
/* [270] */ andi r3, acmd_W0, 0xffff
/* [274] */ jal dma_read
/* [278] */ addi r3, r3, 0xffff
/* [27c] */ mfc0 r1, sp_dma_busy
@@b4:
/* [280] */ bnez r1, @@b4
/* [284] */ mfc0 r1, sp_dma_busy
/* [288] */ j acmd_next
/* [28c] */ addi r30, r30, 0xfff8

acmd_SETVOL:
/* [290] */ srl r3, acmd_W0, 16
/* [294] */ andi r1, r3, 0x4
/* [298] */ beqz r1, sub_04001340
/* [29c] */ andi r1, r3, 0x2
/* [2a0] */ beqz r1, sub_04001334
/* [2a4] */ srl r2, acmd_W1, 16
/* [2a8] */ sh acmd_W0, 0x50(r24)
/* [2ac] */ sh r2, 0x4c(r24)
/* [2b0] */ sh acmd_W1, 0x4e(r24)

sub_04001334:
/* [2b4] */ sh acmd_W0, 0x46(r24)
/* [2b8] */ sh r2, 0x48(r24)
/* [2bc] */ sh acmd_W1, 0x4a(r24)

sub_04001340:
/* [2c0] */ srl r2, acmd_W1, 16
/* [2c4] */ sh acmd_W0, 0x40(r24)
/* [2c8] */ sh r2, 0x42(r24)
/* [2cc] */ sh acmd_W1, 0x44(r24)
/* [2d0] */ j acmd_next
/* [2d4] */ addi r30, r30, 0xfff8

acmd_INTERLEAVE:
/* [2d8] */ addi r1, r0, 0x170
/* [2dc] */ addi r4, r0, 0x500
/* [2e0] */ addi r2, r0, 0x9e0
/* [2e4] */ addi r3, r0, 0xb50
sub_04001368:
/* [2e8] */ lqv $v1[0], 0x0(r2)
/* [2ec] */ lqv $v2[0], 0x0(r3)
/* [2f0] */ addi r1, r1, 0xfff0
/* [2f4] */ addi r2, r2, 0x10
/* [2f8] */ addi r3, r3, 0x10
/* [2fc] */ ssv $v1[0], 0x0(r4)
/* [300] */ ssv $v2[0], 0x2(r4)
/* [304] */ ssv $v1[2], 0x4(r4)
/* [308] */ ssv $v2[2], 0x6(r4)
/* [30c] */ ssv $v1[4], 0x8(r4)
/* [310] */ ssv $v2[4], 0xa(r4)
/* [314] */ ssv $v1[6], 0xc(r4)
/* [318] */ ssv $v2[6], 0xe(r4)
/* [31c] */ ssv $v1[8], 0x10(r4)
/* [320] */ ssv $v2[8], 0x12(r4)
/* [324] */ ssv $v1[10], 0x14(r4)
/* [328] */ ssv $v2[10], 0x16(r4)
/* [32c] */ ssv $v1[12], 0x18(r4)
/* [330] */ ssv $v2[12], 0x1a(r4)
/* [334] */ ssv $v1[14], 0x1c(r4)
/* [338] */ ssv $v2[14], 0x1e(r4)
/* [33c] */ bgtz r1, sub_04001368
/* [340] */ addi r4, r4, 0x20
/* [344] */ j acmd_next
/* [348] */ addi r30, r30, 0xfff8


acmd_DMEMMOVE:
/* [34c] */ andi r1, acmd_W1, 0xffff
/* [350] */ andi r2, acmd_W0, 0xffff
/* [354] */ addi r2, r2, 0x500
/* [358] */ srl r3, acmd_W1, 16
/* [35c] */ addi r3, r3, 0x500
@@b:
/* [360] */ ldv $v1[0], 0x0(r2)
/* [364] */ ldv $v2[0], 0x8(r2)
/* [368] */ addi r1, r1, 0xfff0
/* [36c] */ addi r2, r2, 0x10
/* [370] */ sdv $v1[0], 0x0(r3)
/* [374] */ sdv $v2[0], 0x8(r3)
/* [378] */ bgtz r1, @@b
/* [37c] */  addi r3, r3, 0x10

/* [380] */ j acmd_next
/* [384] */ addi r30, r30, 0xfff8

acmd_SETLOOP:
/* [388] */ sll r1, acmd_W1, 8
/* [38c] */ srl r1, r1, 8
/* [390] */ sw r1, 0xffc(dmem)
/* [394] */ j acmd_next
/* [398] */ addi r30, r30, 0xfff8

acmd_MP3ADDY:
/* [39c] */ sll r1, acmd_W1, 8
/* [3a0] */ srl r1, r1, 8
/* [3a4] */ sw r1, 0xff4(dmem)
/* [3a8] */ sll r2, acmd_W0, 8
/* [3ac] */ srl r2, r2, 8
/* [3b0] */ sw r2, 0xff0(dmem)
/* [3b4] */ j acmd_next
/* [3b8] */ addi r30, r30, 0xfff8

acmd_ADPCM:
/* [3bc] */ lqv $v31[0], 0x60(dmem)
/* [3c0] */ srl r23, acmd_W1, 12
/* [3c4] */ vxor $v25, $v25, $v25
/* [3c8] */ andi r23, r23, 0xf
/* [3cc] */ vxor $v24, $v24, $v24
/* [3d0] */ addi r23, r23, 0x500
/* [3d4] */ vxor $v13, $v13, $v13
/* [3d8] */ andi r1, acmd_W1, 0xfff
/* [3dc] */ vxor $v14, $v14, $v14
/* [3e0] */ addi r1, r1, 0x500
/* [3e4] */ vxor $v15, $v15, $v15
/* [3e8] */ srl r21, acmd_W1, 16
/* [3ec] */ vxor $v16, $v16, $v16
/* [3f0] */ andi r21, r21, 0xfff
/* [3f4] */ vxor $v17, $v17, $v17
/* [3f8] */ sll r20, acmd_W0, 8
/* [3fc] */ vxor $v18, $v18, $v18
/* [400] */ srl r20, r20, 8
/* [404] */ vxor $v19, $v19, $v19
/* [408] */ addi r3, r0, 0x1f
/* [40c] */ srl r13, acmd_W1, 28
/* [410] */ andi r2, r13, 0x1
/* [414] */ bgtz r2, sub_040014F4
/* [418] */  addi r22, r23, 0x1
/* [41c] */ andi r2, r13, 0x2
/* [420] */ beqz r2, @@f
/* [424] */ addi r2, r20, 0x0
/* [428] */ lw r2, 0xffc(dmem)
@@f:
/* [42c] */ mfc0 r13, sp_dma_full

@@b2:
/* [430] */ bne r13, r0, @@b2
/* [434] */  mfc0 r13, sp_dma_full

/* [438] */ mtc0 r1, sp_mem_addr
/* [43c] */ mtc0 r2, sp_dram_addr
/* [440] */ mtc0 r3, sp_rd_len
/* [444] */ addi r19, r0, 0x30
/* [448] */ addi r18, r0, 0x400
/* [44c] */ ldv $v25[0], 0x0(r19)
/* [450] */ ldv $v24[8], 0x0(r19)
/* [454] */ ldv $v23[0], 0x8(r19)
/* [458] */ ldv $v23[8], 0x8(r19)
/* [45c] */ mfc0 r5, sp_dma_busy
@@b3:
/* [460] */ bnez r5, @@b3
/* [464] */ mfc0 r5, sp_dma_busy
/* [468] */ add r0, r0, r0
/* [46c] */ j sub_04001518
/* [470] */ lqv $v27[0], 0x10(r1)
sub_040014F4:
/* [474] */ addi r19, r0, 0x30
/* [478] */ vxor $v27, $v27, $v27
/* [47c] */ addi r18, r0, 0x400
/* [480] */ ldv $v25[0], 0x0(r19)
/* [484] */ ldv $v24[8], 0x0(r19)
/* [488] */ ldv $v23[0], 0x8(r19)
/* [48c] */ ldv $v23[8], 0x8(r19)
/* [490] */ sqv $v27[0], 0x0(r1)
/* [494] */ sqv $v27[0], 0x10(r1)
sub_04001518:
/* [498] */ beq r21, r0, sub_040016C8
/* [49c] */ addi r1, r1, 0x20
/* [4a0] */ ldv $v12[0], 0x0(r22)
/* [4a4] */ lbu r10, 0x0(r23)
/* [4a8] */ addi r13, r0, 0xc
/* [4ac] */ addi r12, r0, 0x1
/* [4b0] */ andi r14, r10, 0xf
/* [4b4] */ sll r14, r14, 5
/* [4b8] */ vand $v10, $v25, $v12[0]
/* [4bc] */ add r16, r14, r18
/* [4c0] */ vand $v9, $v24, $v12[1]
/* [4c4] */ srl r17, r10, 4
/* [4c8] */ vand $v8, $v25, $v12[2]
/* [4cc] */ sub r17, r13, r17
/* [4d0] */ vand $v7, $v24, $v12[3]
/* [4d4] */ addi r13, r17, 0xffff
/* [4d8] */ sll r12, r12, 15
/* [4dc] */ srlv r11, r12, r13
/* [4e0] */ mtc2 r11, $v22[0]
/* [4e4] */ lqv $v21[0], 0x0(r16)
/* [4e8] */ lqv $v20[0], 0x10(r16)
/* [4ec] */ addi r16, r16, 0xfffe
/* [4f0] */ lrv $v19[0], 0x20(r16)
/* [4f4] */ addi r16, r16, 0xfffe
/* [4f8] */ lrv $v18[0], 0x20(r16)
/* [4fc] */ addi r16, r16, 0xfffe
/* [500] */ lrv $v17[0], 0x20(r16)
/* [504] */ addi r16, r16, 0xfffe
/* [508] */ lrv $v16[0], 0x20(r16)
/* [50c] */ addi r16, r16, 0xfffe
/* [510] */ lrv $v15[0], 0x20(r16)
/* [514] */ addi r16, r16, 0xfffe
/* [518] */ lrv $v14[0], 0x20(r16)
/* [51c] */ addi r16, r16, 0xfffe
/* [520] */ lrv $v13[0], 0x20(r16)
sub_040015A4:
/* [524] */ addi r22, r22, 0x9
/* [528] */ vmudn $v30, $v10, $v23
/* [52c] */ addi r23, r23, 0x9
/* [530] */ vmadn $v30, $v9, $v23
/* [534] */ lbu r10, 0x0(r23)
/* [538] */ vmudn $v29, $v8, $v23
/* [53c] */ ldv $v12[0], 0x0(r22)
/* [540] */ vmadn $v29, $v7, $v23
/* [544] */ addi r13, r0, 0xc
/* [548] */ blez r17, sub_040015D8
/* [54c] */ andi r14, r10, 0xf
/* [550] */ vmudm $v30, $v30, $v22[0]
/* [554] */ vmudm $v29, $v29, $v22[0]
sub_040015D8:
/* [558] */ sll r14, r14, 5
/* [55c] */ vmudh $v11, $v21, $v27[6]
/* [560] */ add r16, r14, r18
/* [564] */ vmadh $v11, $v20, $v27[7]
/* [568] */ vmadh $v11, $v19, $v30[0]
/* [56c] */ vmadh $v11, $v18, $v30[1]
/* [570] */ srl r17, r10, 4
/* [574] */ vmadh $v11, $v17, $v30[2]
/* [578] */ vmadh $v11, $v16, $v30[3]
/* [57c] */ sub r17, r13, r17
/* [580] */ vmadh $v28, $v15, $v30[4]
/* [584] */ addi r13, r17, 0xffff
/* [588] */ vmadh $v11, $v14, $v30[5]
/* [58c] */ vmadh $v11, $v13, $v30[6]
/* [590] */ vmadh $v11, $v30, $v31[3]
/* [594] */ srlv r11, r12, r13
/* [598] */ vsar $v26, $v6, $v28[1]
/* [59c] */ mtc2 r11, $v22[0]
/* [5a0] */ vsar $v28, $v6, $v28[0]
/* [5a4] */ vand $v10, $v25, $v12[0]
/* [5a8] */ vand $v9, $v24, $v12[1]
/* [5ac] */ vand $v8, $v25, $v12[2]
/* [5b0] */ vand $v7, $v24, $v12[3]
/* [5b4] */ vmudn $v11, $v26, $v31[1]
/* [5b8] */ vmadh $v28, $v28, $v31[1]
/* [5bc] */ vmudh $v11, $v19, $v29[0]
/* [5c0] */ addi r15, r16, 0xfffe
/* [5c4] */ vmadh $v11, $v18, $v29[1]
/* [5c8] */ lrv $v19[0], 0x20(r15)
/* [5cc] */ vmadh $v11, $v17, $v29[2]
/* [5d0] */ addi r15, r15, 0xfffe
/* [5d4] */ vmadh $v11, $v16, $v29[3]
/* [5d8] */ lrv $v18[0], 0x20(r15)
/* [5dc] */ vmadh $v11, $v15, $v29[4]
/* [5e0] */ addi r15, r15, 0xfffe
/* [5e4] */ vmadh $v11, $v14, $v29[5]
/* [5e8] */ lrv $v17[0], 0x20(r15)
/* [5ec] */ vmadh $v11, $v13, $v29[6]
/* [5f0] */ addi r15, r15, 0xfffe
/* [5f4] */ vmadh $v11, $v29, $v31[3]
/* [5f8] */ lrv $v16[0], 0x20(r15)
/* [5fc] */ vmadh $v11, $v21, $v28[6]
/* [600] */ addi r15, r15, 0xfffe
/* [604] */ vmadh $v11, $v20, $v28[7]
/* [608] */ lrv $v15[0], 0x20(r15)
/* [60c] */ vsar $v26, $v6, $v27[1]
/* [610] */ addi r15, r15, 0xfffe
/* [614] */ vsar $v27, $v6, $v27[0]
/* [618] */ lrv $v14[0], 0x20(r15)
/* [61c] */ addi r15, r15, 0xfffe
/* [620] */ lrv $v13[0], 0x20(r15)
/* [624] */ lqv $v21[0], 0x0(r16)
/* [628] */ vmudn $v11, $v26, $v31[1]
/* [62c] */ lqv $v20[0], 0x10(r16)
/* [630] */ vmadh $v27, $v27, $v31[1]
/* [634] */ addi r21, r21, 0xffe0
/* [638] */ sqv $v28[0], 0x0(r1)
/* [63c] */ addi r1, r1, 0x20
/* [640] */ bgtz r21, sub_040015A4
/* [644] */ sqv $v27[0], -0x10(r1)

sub_040016C8:
/* [648] */ addi r1, r1, 0xffe0
/* [64c] */ jal dma_write
/* [650] */ addi r2, r20, 0x0
/* [654] */ addi r30, r30, 0xfff8
/* [658] */ mfc0 r5, sp_dma_busy
@@b05:
/* [65c] */ bnez r5, @@b05
/* [660] */ mfc0 r5, sp_dma_busy
/* [664] */ j acmd_next
/* [668] */ and r0, r0, r0


// TODO: confirm
acmd_POLEF:
/* [66c] */ addi r20, r0, 0x400
/* [670] */ vxor $v26, $v26, $v26
/* [674] */ lw r17, 0x0(r20)
/* [678] */ beq r17, r0, sub_0400196C
/* [67c] */ addi r30, r30, 0xfff8
/* [680] */ addi r23, acmd_W0, 0x500
/* [684] */ ldv $v18[0], 0x0(r20)
/* [688] */ vxor $v25, $v25, $v25
/* [68c] */ add r2, acmd_W1, r0
/* [690] */ addi r21, r23, 0xfffc
/* [694] */ addi r19, r23, 0xfffe
/* [698] */ vxor $v24, $v24, $v24
/* [69c] */ vxor $v23, $v23, $v23
/* [6a0] */ addi r3, r0, 0x7
/* [6a4] */ vxor $v22, $v22, $v22
/* [6a8] */ addi r22, r0, 0x170
/* [6ac] */ vxor $v21, $v21, $v21
/* [6b0] */ srl r16, acmd_W0, 16
/* [6b4] */ vxor $v20, $v20, $v20
/* [6b8] */ andi r16, r16, 0x1
/* [6bc] */ vxor $v19, $v19, $v19
/* [6c0] */ lw r18, 0x2(r20)
/* [6c4] */ bgtz r16, sub_040017C0
/* [6c8] */ addi r1, r24, 0x0
/* [6cc] */ mfc0 r16, sp_dma_full
@@b06:
/* [6d0] */ bne r16, r0, @@b06
/* [6d4] */ mfc0 r16, sp_dma_full
/* [6d8] */ mtc0 r1, sp_mem_addr
/* [6dc] */ mtc0 r2, sp_dram_addr
/* [6e0] */ mtc0 r3, sp_rd_len
/* [6e4] */ llv $v26[0], 0x10(r20)
/* [6e8] */ addi r20, r20, 0xfffe
/* [6ec] */ ldv $v25[0], 0x10(r20)
/* [6f0] */ addi r20, r20, 0x2
/* [6f4] */ llv $v24[4], 0x10(r20)
/* [6f8] */ addi r20, r20, 0xfffe
/* [6fc] */ ldv $v23[4], 0x10(r20)
/* [700] */ addi r20, r20, 0x2
/* [704] */ llv $v22[8], 0x10(r20)
/* [708] */ addi r20, r20, 0xfffe
/* [70c] */ ldv $v21[8], 0x10(r20)
/* [710] */ addi r20, r20, 0x2
/* [714] */ llv $v20[12], 0x10(r20)
/* [718] */ lsv $v19[14], 0x10(r20)
/* [71c] */ lsv $v19[0], 0x12(r20)
/* [720] */ mfc0 r5, sp_dma_busy
@@b07:
/* [724] */ bnez r5, @@b07
/* [728] */ mfc0 r5, sp_dma_busy
/* [72c] */ llv $v15[0], 0x0(r1)
/* [730] */ beq r18, r0, sub_0400180C
/* [734] */ llv $v28[12], 0x4(r1)
/* [738] */ j sub_0400182C
/* [73c] */ lsv $v11[0], 0x2(r1)
sub_040017C0:
/* [740] */ llv $v26[0], 0x10(r20)
/* [744] */ addi r20, r20, 0xfffe
/* [748] */ vxor $v15, $v15, $v15
/* [74c] */ ldv $v25[0], 0x10(r20)
/* [750] */ addi r20, r20, 0x2
/* [754] */ vxor $v11, $v11, $v11
/* [758] */ llv $v24[4], 0x10(r20)
/* [75c] */ addi r20, r20, 0xfffe
/* [760] */ vxor $v28, $v28, $v28
/* [764] */ ldv $v23[4], 0x10(r20)
/* [768] */ addi r20, r20, 0x2
/* [76c] */ llv $v22[8], 0x10(r20)
/* [770] */ addi r20, r20, 0xfffe
/* [774] */ ldv $v21[8], 0x10(r20)
/* [778] */ addi r20, r20, 0x2
/* [77c] */ llv $v20[12], 0x10(r20)
/* [780] */ lsv $v19[14], 0x10(r20)
/* [784] */ bne r18, r0, sub_0400182C
/* [788] */ lsv $v19[0], 0x12(r20)
sub_0400180C:
/* [78c] */ lqv $v30[0], 0x0(r23)
/* [790] */ lrv $v15[0], 0x10(r21)
/* [794] */ vsub $v31, $v30, $v15
/* [798] */ vmulf $v16, $v19, $v28[6]
/* [79c] */ vmulf $v31, $v31, $v18[0]
/* [7a0] */ vadd $v16, $v16, $v16
/* [7a4] */ j sub_04001944
/* [7a8] */  vmov $v29[7], $v28[7]
sub_0400182C:
/* [7ac] */ lqv $v30[0], 0x0(r23)
/* [7b0] */ lrv $v11[0], 0x10(r19)
/* [7b4] */ lrv $v15[0], 0x10(r21)
/* [7b8] */ vmulf $v30, $v30, $v18[0]
/* [7bc] */ vmulf $v11, $v11, $v18[1]
/* [7c0] */ vmulf $v15, $v15, $v18[0]
/* [7c4] */ vmulf $v16, $v19, $v28[6]
/* [7c8] */ vadd $v31, $v30, $v11
/* [7cc] */ vadd $v16, $v16, $v16
/* [7d0] */ vadd $v31, $v31, $v15
sub_04001854:
/* [7d4] */ vmulf $v17, $v26, $v28[7]
/* [7d8] */ vadd $v27, $v16, $v31[0]
/* [7dc] */ vmov $v29[7], $v28[7]
/* [7e0] */ addi r22, r22, 0xfff0
/* [7e4] */ vadd $v17, $v17, $v17
/* [7e8] */ vadd $v28, $v27, $v17
/* [7ec] */ vadd $v27, $v17, $v31[1]
/* [7f0] */ vmulf $v16, $v25, $v28[0]
/* [7f4] */ vor $v14, $v29, $v29
/* [7f8] */ lqv $v11[0], 0x10(r19)
/* [7fc] */ vmov $v29[0], $v28[0]
/* [800] */ vadd $v16, $v16, $v16
/* [804] */ vadd $v28, $v27, $v16
/* [808] */ vadd $v27, $v16, $v31[2]
/* [80c] */ vmulf $v17, $v24, $v28[1]
/* [810] */ lrv $v11[0], 0x20(r19)
/* [814] */ bne r18, r0, sub_040018A0
/* [818] */ vmov $v29[1], $v28[1]
/* [81c] */ sqv $v14[0], -0x10(r23)
sub_040018A0:
/* [820] */ vadd $v17, $v17, $v17
/* [824] */ vadd $v28, $v27, $v17
/* [828] */ or r18, r0, r0
/* [82c] */ vadd $v27, $v17, $v31[3]
/* [830] */ vmulf $v16, $v23, $v28[2]
/* [834] */ vmov $v29[2], $v28[2]
/* [838] */ vmulf $v11, $v11, $v18[1]
/* [83c] */ lqv $v30[0], 0x10(r23)
/* [840] */ vadd $v16, $v16, $v16
/* [844] */ vadd $v28, $v27, $v16
/* [848] */ vadd $v27, $v16, $v31[4]
/* [84c] */ vmulf $v17, $v22, $v28[3]
/* [850] */ vmov $v29[3], $v28[3]
/* [854] */ vadd $v17, $v17, $v17
/* [858] */ lqv $v15[0], 0x10(r21)
/* [85c] */ vmulf $v30, $v30, $v18[0]
/* [860] */ vadd $v28, $v27, $v17
/* [864] */ vadd $v27, $v17, $v31[5]
/* [868] */ vmulf $v16, $v21, $v28[4]
/* [86c] */ vmov $v29[4], $v28[4]
/* [870] */ vadd $v16, $v16, $v16
/* [874] */ lrv $v15[0], 0x20(r21)
/* [878] */ vadd $v11, $v11, $v30
/* [87c] */ vadd $v28, $v27, $v16
/* [880] */ vadd $v27, $v16, $v31[6]
/* [884] */ vmulf $v17, $v20, $v28[5]
/* [888] */ vmov $v29[5], $v28[5]
/* [88c] */ vmulf $v13, $v15, $v18[0]
/* [890] */ vadd $v17, $v17, $v17
/* [894] */ vadd $v28, $v27, $v17
/* [898] */ vadd $v27, $v17, $v31[7]
/* [89c] */ vmulf $v16, $v19, $v28[6]
/* [8a0] */ addi r21, r21, 0x10
/* [8a4] */ vmov $v29[6], $v28[6]
/* [8a8] */ addi r19, r19, 0x10
/* [8ac] */ vadd $v31, $v11, $v13
/* [8b0] */ vadd $v16, $v16, $v16
/* [8b4] */ vadd $v28, $v27, $v16
/* [8b8] */ bgtz r22, sub_04001854
/* [8bc] */ addi r23, r23, 0x10
/* [8c0] */ vmov $v29[7], $v28[7]
sub_04001944:
/* [8c4] */ vor $v14, $v29, $v29
/* [8c8] */ slv $v15[0], 0x0(r1)
/* [8cc] */ slv $v29[12], 0x4(r1)
/* [8d0] */ jal dma_write
/* [8d4] */ sqv $v14[0], -0x10(r23)
/* [8d8] */ mfc0 r5, sp_dma_busy
@@b08:
/* [8dc] */ bnez r5, @@b08
/* [8e0] */ mfc0 r5, sp_dma_busy
/* [8e4] */ j acmd_next
/* [8e8] */  nop
sub_0400196C:
/* [8ec] */ srl r19, acmd_W1, 24
/* [8f0] */ addi r20, r0, 0x400
/* [8f4] */ vxor $v21, $v21, $v21
/* [8f8] */ beq r19, r0, sub_04001984
/* [8fc] */ addi r23, r0, 0x500
/* [900] */ addi r23, r0, 0x670
sub_04001984: ; literally 1984
/* [904] */ lqv $v28[0], 0x10(r20)
/* [908] */ vxor $v22, $v22, $v22
/* [90c] */ mtc2 acmd_W0, $v18[10]
/* [910] */ vxor $v23, $v23, $v23
/* [914] */ sll acmd_W0, acmd_W0, 2
/* [918] */ vxor $v24, $v24, $v24
/* [91c] */ mtc2 acmd_W0, $v20[0]
/* [920] */ vxor $v25, $v25, $v25
/* [924] */ sll r2, acmd_W1, 8
/* [928] */ vxor $v26, $v26, $v26
/* [92c] */ srl r2, r2, 8
/* [930] */ vxor $v27, $v27, $v27
/* [934] */ addi r3, r0, 0x7
/* [938] */ addi r19, r0, 0x4
/* [93c] */ mtc2 r19, $v18[0]
/* [940] */ addi r22, r0, 0x170
/* [944] */ vmudm $v20, $v28, $v20[0]
/* [948] */ srl r19, acmd_W0, 16
/* [94c] */ andi r19, r19, 0x1
/* [950] */ bgtz r19, sub_04001A40
/* [954] */ sqv $v20[0], 0x10(r20)
/* [958] */ addi r1, r24, 0x0
/* [95c] */ mfc0 r19, sp_dma_full
@@b09:
/* [960] */ bne r19, r0, @@b09
/* [964] */ mfc0 r19, sp_dma_full
/* [968] */ mtc0 r1, sp_mem_addr
/* [96c] */ mtc0 r2, sp_dram_addr
/* [970] */ mtc0 r3, sp_rd_len
/* [974] */ addi r20, r20, 0xfffe
/* [978] */ lrv $v27[0], 0x20(r20)
/* [97c] */ addi r20, r20, 0xfffe
/* [980] */ lrv $v26[0], 0x20(r20)
/* [984] */ addi r20, r20, 0xfffe
/* [988] */ lrv $v25[0], 0x20(r20)
/* [98c] */ addi r20, r20, 0xfffe
/* [990] */ lrv $v24[0], 0x20(r20)
/* [994] */ addi r20, r20, 0xfffe
/* [998] */ lrv $v23[0], 0x20(r20)
/* [99c] */ addi r20, r20, 0xfffe
/* [9a0] */ lrv $v22[0], 0x20(r20)
/* [9a4] */ addi r20, r20, 0xfffe
/* [9a8] */ lrv $v21[0], 0x20(r20)
/* [9ac] */ mfc0 r5, sp_dma_busy
@@b10:
/* [9b0] */ bnez r5, @@b10
/* [9b4] */ mfc0 r5, sp_dma_busy
/* [9b8] */ j sub_04001A7C
/* [9bc] */ ldv $v30[8], 0x0(r1)
sub_04001A40:
/* [9c0] */ addi r20, r20, 0xfffe
/* [9c4] */ vxor $v30, $v30, $v30
/* [9c8] */ lrv $v27[0], 0x20(r20)
/* [9cc] */ addi r20, r20, 0xfffe
/* [9d0] */ lrv $v26[0], 0x20(r20)
/* [9d4] */ addi r20, r20, 0xfffe
/* [9d8] */ lrv $v25[0], 0x20(r20)
/* [9dc] */ addi r20, r20, 0xfffe
/* [9e0] */ lrv $v24[0], 0x20(r20)
/* [9e4] */ addi r20, r20, 0xfffe
/* [9e8] */ lrv $v23[0], 0x20(r20)
/* [9ec] */ addi r20, r20, 0xfffe
/* [9f0] */ lrv $v22[0], 0x20(r20)
/* [9f4] */ addi r20, r20, 0xfffe
/* [9f8] */ lrv $v21[0], 0x20(r20)
sub_04001A7C:
/* [9fc] */ lqv $v31[0], 0x0(r23)
sub_04001A80:
/* [a00] */ vmudh $v20, $v28, $v30[7]
/* [a04] */ vmadh $v20, $v27, $v31[0]
/* [a08] */ addi r22, r22, 0xfff0
/* [a0c] */ vmadh $v20, $v26, $v31[1]
/* [a10] */ vmadh $v20, $v25, $v31[2]
/* [a14] */ sqv $v30[0], -0x10(r23)
/* [a18] */ vmadh $v20, $v24, $v31[3]
/* [a1c] */ vmadh $v30, $v23, $v31[4]
/* [a20] */ vmadh $v20, $v22, $v31[5]
/* [a24] */ vmadh $v20, $v21, $v31[6]
/* [a28] */ vmadh $v20, $v31, $v18[5]
/* [a2c] */ lqv $v31[0], 0x10(r23)
/* [a30] */ vsar $v29, $v19, $v30[1]
/* [a34] */ vsar $v30, $v19, $v30[0]
/* [a38] */ vmudn $v20, $v29, $v18[0]
/* [a3c] */ vmadh $v30, $v30, $v18[0]
/* [a40] */ bgtz r22, sub_04001A80
/* [a44] */ addi r23, r23, 0x10
/* [a48] */ addi r1, r23, 0xfff8
/* [a4c] */ jal dma_write
/* [a50] */ sqv $v30[0], -0x10(r23)
/* [a54] */ mfc0 r5, sp_dma_busy
@@b11:
/* [a58] */ bnez r5, @@b11
/* [a5c] */ mfc0 r5, sp_dma_busy
/* [a60] */ j acmd_next
/* [a64] */ nop

acmd_NOOP:
/* [a68] */ addi r2, r0, 0x170
/* [a6c] */ addi r1, acmd_W0, 0x500
/* [a70] */ mtc2 acmd_W1, $v1[0]
/* [a74] */ srl r3, acmd_W1, 16
/* [a78] */ mtc2 r3, $v1[2]
sub_04001AFC:
/* [a7c] */ lqv $v2[0], 0x0(r1)
/* [a80] */ addi r2, r2, 0xfff0
/* [a84] */ addi r1, r1, 0x10
/* [a88] */ vmudh $v3, $v2, $v1[0]
/* [a8c] */ vmudm $v3, $v3, $v1[1]
/* [a90] */ bgtz r2, sub_04001AFC
/* [a94] */ sqv $v3[0], -0x10(r1)
/* [a98] */ j acmd_next
/* [a9c] */  addi r30, r30, 0xfff8

acmd_RESAMPLE:
/* [aa0] */ sll r2, acmd_W0, 8
/* [aa4] */ vxor $v23, $v23, $v23
/* [aa8] */ srl r2, r2, 8
/* [aac] */ addi r3, r0, 0xf
/* [ab0] */ srl r21, acmd_W1, 30
/* [ab4] */ bgtz r21, sub_04001B80
/* [ab8] */ addi r1, r24, 0x0
/* [abc] */ mfc0 r4, sp_dma_full

@@b12:
/* [ac0] */ bnez r4, @@b12
/* [ac4] */  mfc0 r4, sp_dma_full
/* [ac8] */ mtc0 r1, sp_mem_addr
/* [acc] */ mtc0 r2, sp_dram_addr
/* [ad0] */ mtc0 r3, sp_rd_len
/* [ad4] */ srl r20, acmd_W1, 2
/* [ad8] */ andi r20, r20, 0xfff
/* [adc] */ addi r20, r20, 0x4f8
/* [ae0] */ lqv $v31[0], 0x50(dmem)
/* [ae4] */ lqv $v25[0], 0x40(dmem)
/* [ae8] */ mfc0 r5, sp_dma_busy
@@b13:
/* [aec] */ bnez r5, @@b13
/* [af0] */ mfc0 r5, sp_dma_busy
/* [af4] */ ldv $v19[0], 0x0(r24)
/* [af8] */ j sub_04001B9C
/* [afc] */ lsv $v24[14], 0x8(r24)
sub_04001B80:
/* [b00] */ srl r20, acmd_W1, 2
/* [b04] */ andi r20, r20, 0xfff
/* [b08] */ addi r20, r20, 0x4f8
/* [b0c] */ lqv $v31[0], 0x50(dmem)
/* [b10] */ vxor $v19, $v19, $v19
/* [b14] */ lqv $v25[0], 0x40(dmem)
/* [b18] */ vxor $v24, $v24, $v24
sub_04001B9C:
/* [b1c] */ mtc2 r20, $v21[4]
/* [b20] */ addi r4, r0, 0xc0
/* [b24] */ mtc2 r4, $v21[6]
/* [b28] */ vsub $v25, $v25, $v31
/* [b2c] */ srl r4, acmd_W1, 14
/* [b30] */ mtc2 r4, $v21[8]
/* [b34] */ addi r4, r0, 0x40
/* [b38] */ mtc2 r4, $v21[10]
/* [b3c] */ vsub $v25, $v25, $v31
/* [b40] */ lqv $v30[0], 0x60(dmem)
/* [b44] */ lqv $v29[0], 0x70(dmem)
/* [b48] */ lqv $v28[0], 0x80(dmem)
/* [b4c] */ vmudm $v24, $v31, $v24[7]
/* [b50] */ lqv $v27[0], 0x90(dmem)
/* [b54] */ vmadm $v23, $v25, $v21[4]
/* [b58] */ lqv $v26[0], 0xa0(dmem)
/* [b5c] */ vmadn $v24, $v31, $v30[0]
/* [b60] */ sdv $v19[0], 0x0(r20)
/* [b64] */ lqv $v25[0], 0x40(dmem)
/* [b68] */ vmudn $v22, $v31, $v21[2]
/* [b6c] */ addi r22, r0, 0x170
/* [b70] */ vmadn $v22, $v23, $v30[2]
/* [b74] */ andi r4, acmd_W1, 0x3
/* [b78] */ vmudl $v20, $v24, $v21[5]
/* [b7c] */ beqz r4, sub_04001C08
/* [b80] */ addi r23, r0, 0x500
/* [b84] */ addi r23, r0, 0x670
sub_04001C08:
/* [b88] */ ssv $v24[7], 0x8(r24)
/* [b8c] */ vmudn $v20, $v20, $v30[4]
/* [b90] */ sqv $v22[0], -0x50(dmem)
/* [b94] */ vmadn $v20, $v31, $v21[3]
/* [b98] */ sqv $v20[0], -0x40(dmem)
/* [b9c] */ lh r21, 0xfb0(dmem)
/* [ba0] */ lh r13, 0xfc0(dmem)
/* [ba4] */ lh r17, 0xfb8(dmem)
/* [ba8] */ lh r9, 0xfc8(dmem)
/* [bac] */ lh r20, 0xfb2(dmem)
/* [bb0] */ lh r12, 0xfc2(dmem)
/* [bb4] */ lh r16, 0xfba(dmem)
/* [bb8] */ lh r8, 0xfca(dmem)
/* [bbc] */ lh r19, 0xfb4(dmem)
/* [bc0] */ lh r11, 0xfc4(dmem)
/* [bc4] */ lh r15, 0xfbc(dmem)
/* [bc8] */ lh r7, 0xfcc(dmem)
/* [bcc] */ lh r18, 0xfb6(dmem)
/* [bd0] */ lh r10, 0xfc6(dmem)
/* [bd4] */ lh r14, 0xfbe(dmem)
/* [bd8] */ lh r6, 0xfce(dmem)
sub_04001C5C:
/* [bdc] */ ldv $v19[0], 0x0(r21)
/* [be0] */ vmudm $v24, $v31, $v24[7]
/* [be4] */ ldv $v18[0], 0x0(r13)
/* [be8] */ vmadh $v24, $v31, $v23[7]
/* [bec] */ ldv $v19[8], 0x0(r17)
/* [bf0] */ vmadm $v23, $v25, $v21[4]
/* [bf4] */ ldv $v18[8], 0x0(r9)
/* [bf8] */ vmadn $v24, $v31, $v30[0]
/* [bfc] */ ldv $v17[0], 0x0(r20)
/* [c00] */ vmudn $v22, $v31, $v21[2]
/* [c04] */ ldv $v16[0], 0x0(r12)
/* [c08] */ ldv $v17[8], 0x0(r16)
/* [c0c] */ vmadn $v22, $v23, $v30[2]
/* [c10] */ ldv $v16[8], 0x0(r8)
/* [c14] */ vmudl $v20, $v24, $v21[5]
/* [c18] */ ldv $v15[0], 0x0(r19)
/* [c1c] */ ldv $v14[0], 0x0(r11)
/* [c20] */ ldv $v15[8], 0x0(r15)
/* [c24] */ ldv $v14[8], 0x0(r7)
/* [c28] */ vmudn $v20, $v20, $v30[4]
/* [c2c] */ ldv $v13[0], 0x0(r18)
/* [c30] */ vmadn $v20, $v31, $v21[3]
/* [c34] */ ldv $v12[0], 0x0(r10)
/* [c38] */ ldv $v13[8], 0x0(r14)
/* [c3c] */ vmulf $v11, $v19, $v18
/* [c40] */ ldv $v12[8], 0x0(r6)
/* [c44] */ vmulf $v10, $v17, $v16
/* [c48] */ sqv $v22[0], -0x50(dmem)
/* [c4c] */ vmulf $v9, $v15, $v14
/* [c50] */ sqv $v20[0], -0x40(dmem)
/* [c54] */ lh r21, 0xfb0(dmem)
/* [c58] */ lh r13, 0xfc0(dmem)
/* [c5c] */ vmulf $v8, $v13, $v12
/* [c60] */ lh r17, 0xfb8(dmem)
/* [c64] */ vadd $v11, $v11, $v11[1q]
/* [c68] */ lh r9, 0xfc8(dmem)
/* [c6c] */ vadd $v10, $v10, $v10[1q]
/* [c70] */ lh r20, 0xfb2(dmem)
/* [c74] */ vadd $v9, $v9, $v9[1q]
/* [c78] */ lh r12, 0xfc2(dmem)
/* [c7c] */ vadd $v8, $v8, $v8[1q]
/* [c80] */ lh r16, 0xfba(dmem)
/* [c84] */ vadd $v11, $v11, $v11[2h]
/* [c88] */ lh r8, 0xfca(dmem)
/* [c8c] */ vadd $v10, $v10, $v10[2h]
/* [c90] */ lh r19, 0xfb4(dmem)
/* [c94] */ vadd $v9, $v9, $v9[2h]
/* [c98] */ lh r11, 0xfc4(dmem)
/* [c9c] */ vadd $v8, $v8, $v8[2h]
/* [ca0] */ lh r15, 0xfbc(dmem)
/* [ca4] */ vmudn $v7, $v29, $v11[0h]
/* [ca8] */ lh r7, 0xfcc(dmem)
/* [cac] */ vmadn $v7, $v28, $v10[0h]
/* [cb0] */ lh r18, 0xfb6(dmem)
/* [cb4] */ vmadn $v7, $v27, $v9[0h]
/* [cb8] */ lh r10, 0xfc6(dmem)
/* [cbc] */ vmadn $v7, $v26, $v8[0h]
/* [cc0] */ lh r14, 0xfbe(dmem)
/* [cc4] */ lh r6, 0xfce(dmem)
/* [cc8] */ addi r22, r22, 0xfff0
/* [ccc] */ blez r22, sub_04001D5C
/* [cd0] */ sqv $v7[0], 0x0(r23)
/* [cd4] */ j sub_04001C5C
/* [cd8] */ addi r23, r23, 0x10
sub_04001D5C:
/* [cdc] */ ldv $v19[0], 0x0(r21)
/* [ce0] */ ssv $v24[0], 0x8(r24)
/* [ce4] */ jal dma_write
/* [ce8] */ sdv $v19[0], 0x0(r24)
/* [cec] */ addi r30, r30, 0xfff8
/* [cf0] */ mfc0 r5, sp_dma_busy
@@b14:
/* [cf4] */ bnez r5, @@b14
/* [cf8] */  mfc0 r5, sp_dma_busy
/* [cfc] */ j acmd_next
/* [d00] */ nop

acmd_ENVMIXER:
/* [d04] */ sll r2, acmd_W1, 8
/* [d08] */ srl r2, r2, 8
/* [d0c] */ lqv $v31[0], 0x50(dmem)
/* [d10] */ lqv $v10[0], 0x60(dmem)
/* [d14] */ lqv $v30[0], 0xb0(dmem)
/* [d18] */ vxor $v0, $v0, $v0
/* [d1c] */ srl r14, acmd_W0, 16
/* [d20] */ andi r15, r14, 0x1
/* [d24] */ bgtz r15, sub_04001DD0
/* [d28] */ addi r1, r24, 0x0
/* [d2c] */ jal dma_read
/* [d30] */ addi r3, r0, 0x4f
/* [d34] */ mfc0 r5, sp_dma_busy
@@b15:
/* [d38] */ bnez r5, @@b15
/* [d3c] */  mfc0 r5, sp_dma_busy
/* [d40] */ lqv $v20[0], 0x0(r24)
/* [d44] */ lqv $v21[0], 0x10(r24)
/* [d48] */ lqv $v18[0], 0x20(r24)
/* [d4c] */ lqv $v19[0], 0x30(r24)
sub_04001DD0:
/* [d50] */ lqv $v24[0], 0x40(r24)
/* [d54] */ addi r16, r0, 0x500
/* [d58] */ addi r21, r0, 0x9e0
/* [d5c] */ addi r20, r0, 0xb50
/* [d60] */ addi r19, r0, 0xcc0
/* [d64] */ addi r18, r0, 0xe30
/* [d68] */ addi r17, r0, 0x170
/* [d6c] */ mfc2 r22, $v24[8]
/* [d70] */ vand $v9, $v31, $v24[6]
/* [d74] */ vand $v8, $v31, $v24[7]
/* [d78] */ vsub $v9, $v0, $v9
/* [d7c] */ vsub $v8, $v0, $v8
/* [d80] */ vxor $v8, $v8, $v9
/* [d84] */ beq r15, r0, sub_04001EDC
/* [d88] */ mfc2 r23, $v24[2]
/* [d8c] */ addi r3, r0, 0x4f
/* [d90] */ vxor $v20, $v20, $v20
/* [d94] */ lsv $v20[14], 0x50(r24)
/* [d98] */ vxor $v21, $v21, $v21
/* [d9c] */ lqv $v17[0], 0x0(r16)
/* [da0] */ vxor $v18, $v18, $v18
/* [da4] */ mtc2 acmd_W0, $v18[14]
/* [da8] */ vmudl $v23, $v30, $v24[2]
/* [dac] */ lqv $v29[0], 0x0(r21)
/* [db0] */ vmadn $v23, $v30, $v24[1]
/* [db4] */ lqv $v27[0], 0x0(r19)
/* [db8] */ vmadh $v20, $v31, $v20[7]
/* [dbc] */ lqv $v28[0], 0x0(r20)
/* [dc0] */ vmadn $v21, $v31, $v0[0]
/* [dc4] */ bgez r23, sub_04001E54
/* [dc8] */ vxor $v19, $v19, $v19
/* [dcc] */ j sub_04001E58
/* [dd0] */ vge $v20, $v20, $v24[0]
sub_04001E54:
/* [dd4] */ vlt $v20, $v20, $v24[0]
sub_04001E58:
/* [dd8] */ vxor $v17, $v9, $v17
/* [ddc] */ vmudl $v23, $v30, $v24[5]
/* [de0] */ lqv $v26[0], 0x0(r18)
/* [de4] */ vmadn $v23, $v30, $v24[4]
/* [de8] */ addi r17, r17, 0xfff0
/* [dec] */ vmadh $v18, $v31, $v18[7]
/* [df0] */ addi r16, r16, 0x10
/* [df4] */ vmadn $v19, $v31, $v0[0]
/* [df8] */ vmulf $v16, $v20, $v24[6]
/* [dfc] */ bgez r22, sub_04001E8C
/* [e00] */ vmulf $v15, $v20, $v24[7]
/* [e04] */ j sub_04001E90
/* [e08] */ vge $v18, $v18, $v24[3]
sub_04001E8C:
/* [e0c] */ vlt $v18, $v18, $v24[3]
sub_04001E90:
/* [e10] */ vmulf $v29, $v29, $v10[5]
/* [e14] */ vmacf $v29, $v17, $v16
/* [e18] */ vmulf $v27, $v27, $v10[5]
/* [e1c] */ vmacf $v27, $v17, $v15
/* [e20] */ vxor $v17, $v8, $v17
/* [e24] */ vmulf $v16, $v18, $v24[6]
/* [e28] */ vmulf $v15, $v18, $v24[7]
/* [e2c] */ sqv $v29[0], 0x0(r21)
/* [e30] */ vmulf $v28, $v28, $v10[5]
/* [e34] */ addi r21, r21, 0x10
/* [e38] */ vmacf $v28, $v17, $v16
/* [e3c] */ sqv $v27[0], 0x0(r19)
/* [e40] */ vmulf $v26, $v26, $v10[5]
/* [e44] */ addi r19, r19, 0x10
/* [e48] */ vmacf $v26, $v17, $v15
/* [e4c] */ sqv $v28[0], 0x0(r20)
/* [e50] */ addi r20, r20, 0x10
/* [e54] */ sqv $v26[0], 0x0(r18)
/* [e58] */ addi r18, r18, 0x10
sub_04001EDC:
/* [e5c] */ vaddc $v21, $v21, $v24[2]
/* [e60] */ vadd $v20, $v20, $v24[1]
sub_04001EE4:
/* [e64] */ lqv $v29[0], 0x0(r21)
/* [e68] */ vaddc $v19, $v19, $v24[5]
/* [e6c] */ lqv $v17[0], 0x0(r16)
/* [e70] */ bgez r23, sub_04001F00
/* [e74] */ vadd $v18, $v18, $v24[4]
/* [e78] */ j sub_04001F04
/* [e7c] */ vge $v20, $v20, $v24[0]
sub_04001F00:
/* [e80] */ vlt $v20, $v20, $v24[0]
sub_04001F04:
/* [e84] */ vxor $v17, $v9, $v17
/* [e88] */ bgez r22, sub_04001F18
/* [e8c] */ lqv $v27[0], 0x0(r19)
/* [e90] */ j sub_04001F1C
/* [e94] */ vge $v18, $v18, $v24[3]
sub_04001F18:
/* [e98] */ vlt $v18, $v18, $v24[3]
sub_04001F1C:
/* [e9c] */ vmulf $v16, $v20, $v24[6]
/* [ea0] */ sqv $v20[0], 0x0(r24)
/* [ea4] */ vmulf $v15, $v20, $v24[7]
/* [ea8] */ sqv $v21[0], 0x10(r24)
/* [eac] */ vmulf $v29, $v29, $v10[5]
/* [eb0] */ vmacf $v29, $v17, $v16
/* [eb4] */ lqv $v28[0], 0x0(r20)
/* [eb8] */ vmulf $v27, $v27, $v10[5]
/* [ebc] */ lqv $v26[0], 0x0(r18)
/* [ec0] */ vmacf $v27, $v17, $v15
/* [ec4] */ vxor $v17, $v8, $v17
/* [ec8] */ addi r17, r17, 0xfff0
/* [ecc] */ vaddc $v21, $v21, $v24[2]
/* [ed0] */ addi r16, r16, 0x10
/* [ed4] */ vadd $v20, $v20, $v24[1]
/* [ed8] */ sqv $v29[0], 0x0(r21)
/* [edc] */ vmulf $v16, $v18, $v24[6]
/* [ee0] */ addi r21, r21, 0x10
/* [ee4] */ vmulf $v15, $v18, $v24[7]
/* [ee8] */ sqv $v27[0], 0x0(r19)
/* [eec] */ vmulf $v28, $v28, $v10[5]
/* [ef0] */ addi r19, r19, 0x10
/* [ef4] */ vmacf $v28, $v17, $v16
/* [ef8] */ vmulf $v26, $v26, $v10[5]
/* [efc] */ vmacf $v26, $v17, $v15
/* [f00] */ sqv $v28[0], 0x0(r20)
/* [f04] */ addi r20, r20, 0x10
/* [f08] */ blez r17, sub_04001F98
/* [f0c] */ sqv $v26[0], 0x0(r18)
/* [f10] */ j sub_04001EE4
/* [f14] */ addi r18, r18, 0x10
sub_04001F98:
/* [f18] */ sqv $v18[0], 0x20(r24)
/* [f1c] */ sqv $v19[0], 0x30(r24)
/* [f20] */ jal dma_write
/* [f24] */ sqv $v24[0], 0x40(r24)
/* [f28] */ j acmd_next
/* [f2c] */ addi r30, r30, 0xfff8

acmd_MIXER:
/* [f30] */ lqv $v31[0], 0x60(dmem)
/* [f34] */ andi r22, acmd_W1, 0xffff
/* [f38] */ addi r22, r22, 0x500
/* [f3c] */ lqv $v28[0], 0x0(r22)
/* [f40] */ srl r23, acmd_W1, 16
/* [f44] */ addi r23, r23, 0x500
/* [f48] */ lqv $v29[0], 0x0(r23)
/* [f4c] */ mtc2 acmd_W0, $v30[0]
/* [f50] */ addi r21, r0, 0x170

@@b:
/* [f54] */ vmulf $v27, $v28, $v31[5]
/* [f58] */ addi r21, r21, 0xfff0
/* [f5c] */ addi r23, r23, 0x10
/* [f60] */ addi r22, r22, 0x10
/* [f64] */ vmacf $v27, $v29, $v30[0]
/* [f68] */ lqv $v28[0], 0x0(r22)
/* [f6c] */ lqv $v29[0], 0x0(r23)
/* [f70] */ bgtz r21, @@b
/* [f74] */ sqv $v27[0], -0x10(r22)
/* [f78] */ j acmd_next
/* [f7c] */ addi r30, r30, 0xfff8
.align 8
Overlay0End:

.if Overlay0End > 0x04002000
    .error "Not enough room in IMEM for Overlay 0"
.endif


.headersize Overlay1LoadAddress - orga()
#include "mp3.s"

.close



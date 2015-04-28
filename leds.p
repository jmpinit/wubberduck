#include <pru.h>

#define PRU0_CTRL   0x22000
#define PRU1_CTRL   0x24000

#define CTPPR0      0x28
#define CTPPR1      0x2C 

#define OWN_RAM     0x000
#define OTHER_RAM   0x020
#define SHARED_RAM  0x100
#define DDR_OFFSET  0

#define ADDR_SHARED_RAM 0x80000000
#define ADDR_DDR_RAM    0xc0000000

#define GPIO0_CLOCK 0x44e00408
#define GPIO1_CLOCK 0x44e000ac
#define GPIO2_CLOCK 0x44e000b0

#define RET_REG     r28.w0

#include "led_macros.p"

.macro eight
.mparam value
    mov     r10, value
    call    write_data
    mov     r10, value
    call    write_data
    mov     r10, value
    call    write_data
    mov     r10, value
    call    write_data
    mov     r10, value
    call    write_data
    mov     r10, value
    call    write_data
    mov     r10, value
    call    write_data
    mov     r10, value
    call    write_data
.endm

.setcallreg RET_REG

.origin 0

start:
    // enable OCP master port
    lbco    r0, CONST_PRUCFG, 4, 4
    clr     r0, r0, 4
    sbco    r0, CONST_PRUCFG, 4, 4

    // map shared RAM
    mov     r0, SHARED_RAM
    mov     r1, PRU1_CTRL + CTPPR0
    sbbo    r0, r1, 0, 4

    // map ddr
    mov     r0, DDR_OFFSET << 8
    mov     r1, PRU1_CTRL + CTPPR1
    sbbo    r0, r1, 0, 4

    // unsuspend the GPIO clocks
    StartClocks

main_loop:
color_red:
    mov     r10, 0
    call    write_data

    eight   0xff0000ff
    eight   0xff0000ff
    eight   0xff0000ff
    eight   0xff0000ff

    mov     r10, 0xffffffff
    call    write_data

    Delay   LONG_TIME

color_green:
    mov     r10, 0
    call    write_data

    eight   0xff00ff00
    eight   0xff00ff00
    eight   0xff00ff00
    eight   0xff00ff00

    mov     r10, 0xffffffff
    call    write_data

    Delay   LONG_TIME

color_blue:
    mov     r10, 0
    call    write_data

    eight   0xffff0000
    eight   0xffff0000
    eight   0xffff0000
    eight   0xffff0000

    mov     r10, 0xffffffff
    call    write_data

    Delay   LONG_TIME

    // check for kill signal
    //lbco    r0, CONST_DDR, 0, 4
    //qbne    die, r0.b3, 0

    jmp     main_loop

die:
    // FIXME
    // save return val
    mov     r0, ADDR_DDR_RAM
    mov     r5, r0

    mov     r0, ADDR_DDR_RAM
    sbbo    r5, r0, 0, 4
    
    // notify host program of finish
    mov     r31.b0, PRU0_ARM_INTERRUPT + 16
    halt

write_data:
    mov     r9, 32
write_data_next:
    qbbs    write_data_1, r10, 0
write_data_0:
    mov     r0, GPIO1 | GPIO_CLEARDATAOUT
    mov     r1, 0xff0ff
    sbbo    r1, r0, 0, 4

    mov     r0, GPIO2 | GPIO_CLEARDATAOUT
    mov     r1, 0x3fffc
    sbbo    r1, r0, 0, 4

    qba     write_data_end
write_data_1:
    mov     r0, GPIO1 | GPIO_SETDATAOUT
    mov     r1, 0xff0ff
    sbbo    r1, r0, 0, 4

    mov     r0, GPIO2 | GPIO_SETDATAOUT
    mov     r1, 0x3fffc
    sbbo    r1, r0, 0, 4
write_data_end:
    IOLow   GPIO2, 22 // clock out
    Delay   0xf000

    IOHigh  GPIO2, 22
    Delay   0xf000

    lsr     r10, r10, 1
    
    dec     r9
    qbne    write_data_next, r9, 0

    ret

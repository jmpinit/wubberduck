#define LONG_TIME       0xf00000

.macro inc
.mparam reg
    add     reg, reg, 1
.endm

.macro dec
.mparam reg
    sub     reg, reg, 1
.endm

.macro Delay
.mparam len
    mov     r0, len
delay_loop:
    sub     r0, r0, 1
    qbne    delay_loop, r0, 0
.endm

// value to set pin on gpio high into r0
.macro IOHigh
.mparam gpio, bit
    mov     r0, gpio | GPIO_SETDATAOUT
    mov     r1, 1 << bit
    sbbo    r1, r0, 0, 4
.endm

// value to set pin on gpio low into r0
.macro IOLow
.mparam gpio, bit
    mov     r0, gpio | GPIO_CLEARDATAOUT
    mov     r1, 1 << bit
    sbbo    r1, r0, 0, 4
.endm

.macro StartClocks
    mov     r0, 1 << 1 // set bit 1 in reg to enable clock
    mov     r1, GPIO0_CLOCK
    sbbo    r0, r1, 0, 4
    mov     r1, GPIO1_CLOCK
    sbbo    r0, r1, 0, 4
    mov     r1, GPIO2_CLOCK
    sbbo    r0, r1, 0, 4
.endm

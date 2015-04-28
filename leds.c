#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>

#include "prussdrv.h"
#include <pruss_intc_mapping.h>

#define PRU_NUM 	 1

#define PRUSS_SHARED_DATARAM    4
#define DDR_BASEADDR    0x80000000

#define PPM_READ_BUF_LEN    1024

static int mem_fd;
static void *ddrMem;

int main(int argc, char* argv[]) {
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;

    // init pru driver
    prussdrv_init();

    // open PRU interrupt
    int ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret) {
        printf("prussdrv_open open failed\n");
        return ret;
    }

    // init interrupt
    prussdrv_pruintc_init(&pruss_intc_initdata);

    // open memory device
    mem_fd = open("/dev/mem", O_RDWR);
    if (mem_fd < 0) {
        printf("Failed to open /dev/mem (%s)\n", strerror(errno));
        return -1;
    }

    // map the DDR memory
    ddrMem = mmap(0, 0x0FFFFFFF, PROT_WRITE | PROT_READ, MAP_SHARED, mem_fd, DDR_BASEADDR);

    if (ddrMem == NULL) {
        printf("Failed to map the device (%s)\n", strerror(errno));
        close(mem_fd);
        return -1;
    }

    // load and execute PRU program
    prussdrv_exec_program(PRU_NUM, "/home/developer/code/apa102c/leds.bin");

    printf("program running.\n");
    
    /*getchar();

    printf("sending kill signal.\n");
    ((uint8_t*)ddrMem)[3] = 0xff;

    printf("waiting on PRU...\n");
    prussdrv_pru_wait_event(PRU_EVTOUT_0);
    prussdrv_pru_clear_event(PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);

    // disable pru
    prussdrv_pru_disable(PRU_NUM);
    prussdrv_exit ();

    // FIXME
    // print return val
    uint32_t returnVal = ((uint32_t*)ddrMem)[0];
    printf("PRU returned %x\n", returnVal);*/

    // undo memory mapping
    munmap(ddrMem, 0x0FFFFFFF);
    close(mem_fd);

    printf("done\n");

    return(0);
}


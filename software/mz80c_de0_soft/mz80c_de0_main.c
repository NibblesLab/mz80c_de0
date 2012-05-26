/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include "system.h"
#include <stdio.h>
#include "unistd.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "diskio.h"
#include "mz80c_de0_main.h"
#include "mzctrl.h"
#include "key.h"
#include "menu.h"
#include "file.h"
#include "ff.h"

extern volatile z80_t z80_status;

FATFS fs;
DIR dirs;
FILINFO finfo;
unsigned char fname[13];

int main()
{
	unsigned int x,y;
	int k;

	button_int_regist();
	key_int_regist();

	f_mount(0,&fs);

	MZ_release();

	/* Event loop never exits. */
	while (1){
		x=0; y=0;
		while(z80_status.status==0);
		MZ_Brequest();
		do {
			k=menu(0,0,0);
			switch(k){
			case 3:
				direct_load();
			default:
				break;
			}
			break;
		}while(1);
		z80_status.status=0;
		MZ_Brelease();
	}

	return 0;
}
